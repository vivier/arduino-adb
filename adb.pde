/*
 * info from Apple Macintosh Family Hardware Reference
 * ISBN 0-201-19255-1
 *
 * Technical Note HW01: ADB - The Untold Story: Space Aliens Ate My Mouse
 * http://hackipedia.org/Platform/Apple/Hardware/ADB/apple_adb_hw_01.html
 *
 * Synaptics TouchPad Interfacing Guide
 * http://ccdw.org/~cjj/l/docs/ACF126.pdf
 *
 * Wacom Protocol for intuios GD-405M from
 * http://sourceforge.net/apps/mediawiki/linuxwacom/index.php?title=Serial_Protocol_IV
 */

#include "adb.h"

static const int ADB_pin_in = 2;
static const int ADB_int = 0;

static ADB_packet_t ADB_packet[2];
static int current_packet = 0;

static inline int ADB_client_get(void) {
  return current_packet;
}

static inline int ADB_provider_get(void) {
  return (current_packet + 1) & 1;
}

static inline void ADB_provider_commit(void) {
  current_packet = (current_packet + 1) & 1;
}

static void print_bin(int length, unsigned char *value) {
  for (int i = 0; i < length; i++) {
    if (value[i >> 3] & (0x80 >> i)) {
      Serial.print('1');
    } else {
      Serial.print('0');
    }
  }
}

static inline void set_bit(int n, unsigned char *value) {
  value[n >> 3] |= 0x80 >> (n & 7);
}

static inline void clear_bit(int n, unsigned char *value) {
  value[n >> 3] &= ~(0x80 >> (n & 7));
}

static void dump_hex(int length, unsigned char *value) {
  for (int i = 0; i < length; i++) {
    if (value[i] == 0) {
      Serial.print("00");
    } else {
      if (value[i] < 0x10) {
        Serial.print("0");
      }
      Serial.print(value[i], HEX);
    }
  }
  Serial.write(0x0a);
}


static void dump_wacom(int length, unsigned char *value) {
  for (int i = 0; i < length; i++) {
      Serial.write(value[i]);
  }
}

static void print_cmd(int cmd, int reg) {
  switch(cmd) {
  case 0:
    if (reg == 0) {
      Serial.print("SendReset");
    } else if (reg == 1) {
      Serial.print("Flush");
    } else {
      Serial.print("Reserved");
    }
    break;
  case 2:
    Serial.print("Listen");
    break;
  case 3:
    Serial.print("Talk");
    break;
  default:
    Serial.print("Reserved");
    break;
  }
}

static inline void adb_decode(ADB_packet_t *p) {
  int addr = (p->header >> 4) & 0x0f;
  int cmd = (p->header >> 2) & 0x03;
  int reg = p->header & 0x03;
  
  if (reg == 3) {
    Serial.print(addr);
    Serial.print(' ');
    print_cmd(cmd, reg);
    Serial.print(' ');
    if ((p->data[0] & (1 << 7)) == 0) {
      Serial.print('E');
    } else {
      Serial.print(' ');
    }
    if (p->data[0] & (1 << 6)) {
      Serial.print('S');
    } else {
      Serial.print(' ');
    }
    Serial.print(' ');
    Serial.print(p->data[0] & 0x0f);
    Serial.print(' ');
    Serial.println(p->data[1], HEX);
    return;
  }
  switch(addr) {
  case 2: /* KEYBOARD */
    if (reg == 0) {
      Serial.print("Key ");
      if (p->data[0] & 0x80) {
        Serial.print("up ");
      }
      else {
        Serial.print("down ");
      }
      Serial.println(p->data[0] & 0x7f, HEX);
      if (p->data[1]  != 0xff) {
        Serial.print("Key ");
        if (p->data[1] & 0x80) {
          Serial.print("up ");
        }
        else {
          Serial.print("down ");
        }
        Serial.println(p->data[1] & 0x7f, HEX);
      }
    } else {
      Serial.print("keyboard undecoded reg ");
      Serial.println(reg);
      dump_hex(p->bit >> 3, p->data);
    }
    break;
  case 3: /* MOUSE */
    if (reg == 0) {
      Serial.print("MOUSE: button ");
      if (p->data[0] & 0x80) {
        Serial.print("up   X:");
      }
      else {
        Serial.print("down X:");
      }
      Serial.print((char)(p->data[0] << 1) >> 1);
      Serial.print(" Y:");
      Serial.println((char)(p->data[1] << 1) >> 1);
    } else if (reg == 1) {
      Serial.print("Mouse type: ");
      Serial.write(p->data[0]);
      Serial.write(p->data[1]);
      Serial.write(p->data[2]);
      Serial.write(p->data[3]);
      Serial.println("");
      Serial.print("Resolution: ");
      Serial.print((p->data[4] << 8) + p->data[5]);
      Serial.println(" dpi");
      Serial.print("class: ");
      Serial.println((int)p->data[6]);
      Serial.print("Buttons: ");
      Serial.println((int)p->data[7]);
    } else {
      Serial.print("mouse undecoded reg ");
      Serial.println(reg);
      dump_hex(p->bit >> 3, p->data);
    }
    break;
  case 4: /* GRAPHIC TABLET */
    if (reg == 0) {
     dump_wacom(p->bit >> 3, p->data);
    } else {
      Serial.print("graphic tablet undecoded reg ");
      Serial.println(reg);
      dump_hex(p->bit >> 3, p->data);
    }
    break;
  }
}

static inline int is_one(int duration)
{
  if (duration < 45) {
    return 1;
  }
  return 0;
}

static void ADB_edge(void) {
  static unsigned long m;
  static unsigned long prevm = 0;
  static int duration;
  int level;
  static enum {
    IDLE,
    SYNC,
    HEADER,
    DATA,
    START,
  } state = IDLE;
  ADB_packet_t *p = &ADB_packet[ADB_provider_get()];
  
  if (p->valid) {
    Serial.println("OVERFLOW");
    return;
  }
  
  m = micros();
  level = digitalRead(ADB_pin_in);
  
  /* compute previous level duration */
  
  duration = m - prevm;
  prevm = m;
  
  if (level) {
    
    /* check RESET */
    
    if (duration >= 3000) {
      /* reset */
      state = IDLE;
      return;
    }
    
    /* check ATTENTION */
    
    if (duration > 700) {
      /* attention */
      state = SYNC;
      p->bit = 0;
      return;
    }
    
    /* state machine */
    
    switch(state) {
    case DATA:
      if (is_one(duration)) {
        set_bit(p->bit, p->data);
      } else {
        clear_bit(p->bit, p->data);
      }
      p->bit++;
      if (p->bit == 64) {
        p->valid = 1;
        ADB_provider_commit();
        state = IDLE;
        return;
      }
      break;
    case HEADER:
      if (is_one(duration)) {
        set_bit(p->bit, &p->header);
      } else {
        clear_bit(p->bit, &p->header);
      }
      p->bit++;
      if (p->bit == 9) {
        /* stop bit is ignored */
        state = START;
        p->bit = 0;
        return;
      }
      break;
    case START:
      if (is_one(duration)) {
        state = DATA;
      } else {
        state = IDLE;
      }
      break;
    }
  } else {
    switch(state) {
    case SYNC:
      if (duration > 60 && duration < 75) {
        state = HEADER;
      } else {
        state = IDLE;
      }
      break;
    case DATA:
      if (duration > 300) {
        if (p->bit > 0) {
          p->valid = 1;
          ADB_provider_commit();
        }
        state = IDLE;
      }
      break;
    case START:
      if (duration > 260) {
        state = IDLE;
      } else {
       /* stop to start */
      } 
    }
  }
}
  
void setup(void) {
  pinMode(ADB_pin_in, INPUT);
  digitalWrite(ADB_pin_in, HIGH); /* pull-up active */
  attachInterrupt(ADB_int, ADB_edge, CHANGE);
  Serial.begin(115200);
  ADB_packet[0].valid = 0;
  ADB_packet[1].valid = 0;
}

void loop(void) {
  int current;
  current = ADB_client_get();
  if (ADB_packet[current].valid) {
    adb_decode(&ADB_packet[current_packet]);
    ADB_packet[current].valid = 0;
  }
}
