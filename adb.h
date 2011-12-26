typedef struct {
  
  /* content */
  
  unsigned char header;
  unsigned char data[8];
  
  /* state */
  
  int bit;
  int valid;
} ADB_packet_t;
