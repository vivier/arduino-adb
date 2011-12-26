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
 * Wacom Protocol from
 * http://tabletmagic.cvs.sourceforge.net/viewvc/tabletmagic/wacom-adb/doc/analysis.txt?revision=1.1
 */

static const int ADB_pin_in = 2;
static const int ADB_int = 0;

static unsigned char header;
static int header_bit;
static unsigned char data[8];
static int data_bit, data_byte;
unsigned int valid;

static void print_bin(int val) {
  for (int i = 0; i < 8; i++)
  if (val & (0x80 >> i))
  Serial.print('1');
  else
  Serial.print('0');
  Serial.println("");
}

static void dump_hex(int length, unsigned char *value) {
  for (int i = 0; i < length; i++) {
    if (value[i] == 0) {
      Serial.print("00");
      continue;
    }
    if (value[i] < 0x10) {
      Serial.print("0");
    }
    Serial.print(value[i], HEX);
  }
  Serial.println("");
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

static inline void adb_decode(unsigned char header, int length,
                              unsigned char *data) {
  int addr = (header >> 4) & 0x0f;
  int cmd = (header >> 2) & 0x03;
  int reg = header & 0x03;
  
  if (reg == 3) {
    Serial.print(addr);
    Serial.print(' ');
    print_cmd(cmd, reg);
    Serial.print(' ');
    if ((data[0] & (1 << 7)) == 0) {
      Serial.print('E');
    } else {
      Serial.print(' ');
    }
    if (data[0] & (1 << 6)) {
      Serial.print('S');
    } else {
      Serial.print(' ');
    }
    Serial.print(' ');
    Serial.print(data[0] & 0x0f);
    Serial.print(' ');
    Serial.println(data[1], HEX);
    return;
  }
  switch(addr) {
  case 2: /* KEYBOARD */
    if (reg == 0) {
      Serial.print("Key ");
      if (data[0] & 0x80) {
        Serial.print("up ");
      }
      else {
        Serial.print("down ");
      }
      Serial.println(data[0] & 0x7f, HEX);
      if (data[1]  != 0xff) {
        Serial.print("Key ");
        if (data[1] & 0x80) {
          Serial.print("up ");
        }
        else {
          Serial.print("down ");
        }
        Serial.println(data[1] & 0x7f, HEX);
      }
    } else {
      Serial.print("keyboard undecoded reg ");
      Serial.println(reg);
      dump_hex(length, data);
    }
    break;
  case 3: /* MOUSE */
    if (reg == 0) {
      Serial.print("MOUSE: button ");
      if (data[0] & 0x80) {
        Serial.print("up   X:");
      }
      else {
        Serial.print("down X:");
      }
      Serial.print((char)(data[0] << 1) >> 1);
      Serial.print(" Y:");
      Serial.println((char)(data[1] << 1) >> 1);
    } else if (reg == 1) {
      Serial.print("Mouse type: ");
      Serial.write(data[0]);
      Serial.write(data[1]);
      Serial.write(data[2]);
      Serial.write(data[3]);
      Serial.println("");
      Serial.print("Resolution: ");
      Serial.print((data[4] << 8) + data[5]);
      Serial.println(" dpi");
      Serial.print("class: ");
      Serial.println(data[6]);
      Serial.print("Buttons: ");
      Serial.println(data[7]);
    } else {
      Serial.print("mouse undecoded reg ");
      Serial.println(reg);
      dump_hex(length, data);
    }
    break;
  case 4: /* GRAPHIC TABLET */
    if (reg == 0) {
      if (length == 8)
      print_bin(data[7]);
     //dump_hex(length, data);
    } else {
      Serial.print("graphic tablet undecoded reg ");
      Serial.println(reg);
      dump_hex(length, data);
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
      header = 0;
      header_bit = 0;
      return;
    }
    
    /* state machine */
    
    switch(state) {
    case DATA:
      if (is_one(duration)) {
        data[data_byte] |= 0x80 >> data_bit;
      }
      data_bit++;
      if (data_bit == 8) {
        if (data_byte == 7) {
          valid = 1;
          state = IDLE;
          return;
        }
        data_bit = 0;
        data_byte++;
        data[data_byte] = 0;
      }
      break;
    case HEADER:
      if (is_one(duration)) {
        header |= 0x80 >> header_bit; 
      }
      header_bit++;
      if (header_bit == 9) {
        /* stop bit is ignored */
        state = START;
        data_bit = 0;
        data_byte = 0;
        data[0] = 0;
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
        if (data_byte > 0) {
          valid = 1;
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
  valid = 0;
}

void loop(void) {
  int valid_header;
  int valid_len;
  unsigned char valid_data[8];
  int have_data = 0;
  noInterrupts();  
  if (valid) {
    valid_header = header;
    valid_len = data_byte;
    for (int i = 0; i < data_byte; i++) {
      valid_data[i] = data[i];
    }
    valid = 0;
    have_data = 1;
  }
  interrupts();
  if (have_data) {
    adb_decode(valid_header, valid_len, valid_data);
  }
}
  
