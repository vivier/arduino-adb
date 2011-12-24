/*
 * info from Apple Macintosh Family Hardware Reference
 * ISBN 0-201-19255-1
 *
 */

#define ADB_pin                  2

#define ADB_KEYBOARD_ADDR        2
#define ADB_MOUSE_ADDR           3
#define ADB_GRAPHIC_TABLET_ADDR  4

/* All in microseconds */

#define BITCELL_TIME             100
#define LOW_TIME_0               60
#define LOW_TIME_1               30
#define LOW_TIME_ATTENTION       800
#define LOW_TIME_STOP_BIT        65
#define LOW_TIME_START_BIT       25
#define LOW_TIME_SERVICE_REQUEST 300

#define HIGH_TIME_SYNC           60
#define HIGHT_STOP_TO_START      200

/* in milliseconds */

#define LOW_TIME_RESET_MS   3

static inline void adb_send_reset(int pin) {
  digitalWrite(pin, LOW);
  delay(LOW_TIME_RESET_MS);
  digitalWrite(pin, HIGH);
}

static inline void adb_send(int pin, int low_time) {
  digitalWrite(pin, LOW);
  delayMicroseconds(low_time);
  digitalWrite(pin, HIGH);
}

static inline void adb_send_0(int pin) {
  adb_send(pin, LOW_TIME_0);
  delayMicroseconds(BITCELL_TIME - LOW_TIME_0);
}

static inline void adb_send_1(int pin) {
  adb_send(pin, LOW_TIME_1);
  delayMicroseconds(BITCELL_TIME - LOW_TIME_1);
}

static inline void adb_send_start_bit(int pin) {
  adb_send(pin, LOW_TIME_START_BIT);
  delayMicroseconds(BITCELL_TIME - LOW_TIME_START_BIT);

}

static inline void adb_send_stop_bit(int pin) {
  adb_send(pin, LOW_TIME_STOP_BIT);
  delayMicroseconds(BITCELL_TIME - LOW_TIME_STOP_BIT);
}

static inline void adb_send_bit(int pin, int bit)
{
  if (bit) {
    adb_send_1(pin);
  } 
  else {
    adb_send_0(pin);
  }
}

static inline void adb_send_attention(int pin) {
  adb_send(pin, LOW_TIME_ATTENTION);
  delayMicroseconds(HIGH_TIME_SYNC);
}

static inline void adb_send_address(int pin, int address) {
  adb_send_bit(pin, address & 8);
  adb_send_bit(pin, address & 4);
  adb_send_bit(pin, address & 2);
  adb_send_bit(pin, address & 1);
}

static inline void adb_send_register(int pin, int reg) {
  adb_send_bit(pin, reg & 2);
  adb_send_bit(pin, reg & 1);
}

static inline void adb_send_SendReset(int pin) {
  adb_send_attention(pin);

  adb_send_0(pin);
  adb_send_0(pin);
  adb_send_0(pin);
  adb_send_0(pin);

  adb_send_0(pin);
  adb_send_0(pin);

  adb_send_0(pin);
  adb_send_0(pin);

  adb_send_stop_bit(pin);
}

static inline void adb_send_Flush(int pin, int address) {
  adb_send_attention(pin);

  adb_send_address(pin, address);

  adb_send_0(pin);
  adb_send_0(pin);

  adb_send_0(pin);
  adb_send_1(pin);  

  adb_send_stop_bit(pin);
}

static inline void adb_send_Listen(int pin, int address, int reg) {
  adb_send_attention(pin);

  adb_send_address(pin, address);

  adb_send_0(pin);
  adb_send_0(pin);

  adb_send_register(pin, reg);

  adb_send_stop_bit(pin);
}

static inline void adb_send_Talk(int pin, int address, int reg) {
  adb_send_attention(pin);

  adb_send_address(pin, address);

  adb_send_0(pin);
  adb_send_0(pin);

  adb_send_register(pin, reg);

  adb_send_stop_bit(pin);
}

static inline void adb_send_byte(int pin, unsigned char byte) {
  adb_send_bit(pin, byte & 0x80);
  adb_send_bit(pin, byte & 0x40);
  adb_send_bit(pin, byte & 0x20);
  adb_send_bit(pin, byte & 0x10);
  adb_send_bit(pin, byte & 0x08);
  adb_send_bit(pin, byte & 0x04);
  adb_send_bit(pin, byte & 0x02);
  adb_send_bit(pin, byte & 0x01);
}

static inline void adb_send_data_1(int pin, unsigned char *data)
{
  adb_send_start_bit(pin);
  adb_send_byte(pin, data[0]);
  adb_send_stop_bit(pin);
}

static inline void adb_send_data_2(int pin, unsigned char *data)
{
  adb_send_start_bit(pin);
  adb_send_byte(pin, data[0]);
  adb_send_byte(pin, data[1]);
  adb_send_stop_bit(pin);
}

static inline void adb_send_data_3(int pin, unsigned char *data)
{
  adb_send_start_bit(pin);
  adb_send_byte(pin, data[0]);
  adb_send_byte(pin, data[1]);
  adb_send_byte(pin, data[2]);
  adb_send_stop_bit(pin);
}

static inline void adb_send_data_4(int pin, unsigned char *data)
{
  adb_send_start_bit(pin);
  adb_send_byte(pin, data[0]);
  adb_send_byte(pin, data[1]);
  adb_send_byte(pin, data[2]);
  adb_send_byte(pin, data[3]);
  adb_send_stop_bit(pin);
}

static inline void adb_send_data_5(int pin, unsigned char *data)
{
  adb_send_start_bit(pin);
  adb_send_byte(pin, data[0]);
  adb_send_byte(pin, data[1]);
  adb_send_byte(pin, data[2]);
  adb_send_byte(pin, data[3]);
  adb_send_byte(pin, data[4]);
  adb_send_stop_bit(pin);
}

static inline void adb_send_data_6(int pin, unsigned char *data)
{
  adb_send_start_bit(pin);
  adb_send_byte(pin, data[0]);
  adb_send_byte(pin, data[1]);
  adb_send_byte(pin, data[2]);
  adb_send_byte(pin, data[3]);
  adb_send_byte(pin, data[4]);
  adb_send_byte(pin, data[5]);
  adb_send_stop_bit(pin);
}

static inline void adb_send_data_7(int pin, unsigned char *data)
{
  adb_send_start_bit(pin);
  adb_send_byte(pin, data[0]);
  adb_send_byte(pin, data[1]);
  adb_send_byte(pin, data[2]);
  adb_send_byte(pin, data[3]);
  adb_send_byte(pin, data[4]);
  adb_send_byte(pin, data[5]);
  adb_send_byte(pin, data[6]);
  adb_send_stop_bit(pin);
}

static inline void adb_send_data_8(int pin, unsigned char *data)
{
  adb_send_start_bit(pin);
  adb_send_byte(pin, data[0]);
  adb_send_byte(pin, data[1]);
  adb_send_byte(pin, data[2]);
  adb_send_byte(pin, data[3]);
  adb_send_byte(pin, data[4]);
  adb_send_byte(pin, data[5]);
  adb_send_byte(pin, data[6]);
  adb_send_byte(pin, data[7]);
  adb_send_stop_bit(pin);
}

void setup(void) {
  pinMode(ADB_pin, OUTPUT);

  Serial.begin(115200);
}
enum {
  IDLE,
  SYNC,
  ADDR1,
  ADDR2,
  ADDR3,
  ADDR4,
  CMD1,
  CMD2,
  REG1,
  REG2,
  STOP,
  START,
  DATA,
} 
state = IDLE;

static inline int is_one(int dur)
{
  if (dur < 50) {
    return 1;
  }
  return 0;
}

void loop(void) {
  int addr, cmd, reg;
  unsigned int bit, value;
  int prev_level = -1;
  unsigned long prevm = 0;
  int dur;
#if 0
  pinMode(ADB_pin, OUTPUT);
  adb_send_reset(ADB_pin);
  adb_send_Talk(ADB_pin, ADB_KEYBOARD_ADDR, 3);
#endif
  pinMode(ADB_pin, INPUT);
  //digitalWrite(ADB_pin, HIGH);
  //  delayMicroseconds(140);
  while(1) {
    int level = digitalRead(ADB_pin);
    if (prev_level != level) {
      unsigned  long m = micros();
      dur = m - prevm;
      prevm = m;
      if (prev_level == 0) {
        if (dur > 3000) {
          /* reset */
          state = IDLE;
          prev_level = level;
          Serial.println("RESET");
          continue;
        } 
        else if (dur > 700) {
          /* Attention */
          state = SYNC;
          prev_level = level;
          addr = 0;
          reg = 0;
          cmd = 0;
          bit = 0;
          value = 0;
          continue;
        }
      }
      switch(state) {
      case IDLE:
        break;
      case SYNC:
        if (prev_level == 1) {
          /* sync high level */
          if (dur > 60 && dur < 75) {
            state = ADDR1;
          } 
          else {
            state = IDLE;
          }
        }
        break;
      case ADDR1:
        if (prev_level == 0) {
          if (is_one(dur)) {
            addr = 8;
          }
          state = ADDR2;
        }
        break;
      case ADDR2:
        if (prev_level == 0) {
          if (is_one(dur)) {
            addr |= 4;
          }
          state = ADDR3;
        }
        break;
      case ADDR3:
        if (prev_level == 0) {
          if (is_one(dur)) {
            addr |= 2;
          }
          state = ADDR4;
        }
        break;
      case ADDR4:
        if (prev_level == 0) {
          if (is_one(dur)) {
            addr |= 1;
          }
          state = CMD1;
        }
        break;
      case CMD1:
        if (prev_level == 0) {
          if (is_one(dur)) {
            cmd = 2;
          }
          state = CMD2;
        }
        break;
      case CMD2:
        if (prev_level == 0) {
          if (is_one(dur)) {
            cmd |= 1;
          } 
          state = REG1;
        }
        break;
      case REG1:
        if (prev_level == 0) {
          if (is_one(dur)) {
            reg = 2;
          }
          state = REG2;
        }
        break;
      case REG2:
        if (prev_level == 0) {
          if (is_one(dur)) {
            reg |= 1;
          } 
          state = STOP;
        }
        break;
      case STOP:
        if (prev_level == 0) {
          if (is_one(dur)) {
            state = IDLE;
          } 
          else if (dur > 400) {
            Serial.println("SR");
            state = DATA;;
          } else {
            state = START;
          }
        }
        break; 
      case START:
        if (prev_level == 0) {
          if (is_one(dur)) {
            state = DATA;
          } 
          else {
            Serial.print(addr);
            Serial.print(" ");
            Serial.print(cmd);
            Serial.print(" ");
            Serial.println(reg);
            state = IDLE;
          }
        } 
        else if (dur > 260) { /* stop to start */
          state = IDLE;
        }
        break;
      case DATA:
        if (prev_level == 0) {
          if (is_one(dur)) {
            value |= 0x8000 >> bit;
          }
          bit++;
          if (bit == 16) {
            Serial.print(addr);
            Serial.print(' ');
            Serial.print(cmd);
            Serial.print(' ');
            Serial.print(reg);
            Serial.print(' ');
            Serial.println(value, HEX);
            state = IDLE;
          }
        }
        break;
      }
      prev_level = level;
    }
  }
}


