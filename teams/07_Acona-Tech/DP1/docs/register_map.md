# Register Map
| Offset    | Register         | Access | Description                            |
| :-------- | :--------------- | :----- | :------------------------------------- |
| 0x00      | AES\_CTRL        | R/W    | Control register (start, mode, enable) |
| 0x04      | AES\_STATUS      | R      | Status register (busy, done, error)    |
| 0x08      | AES\_INT\_EN     | R/W    | Interrupt enable register              |
| 0x0C      | AES\_INT\_STATUS | R/W1C  | Interrupt status (write-1-to-clear)    |
| 0x10-0x1C | AES\_KEY\[0-3\]  | W      | 128-bit Key (4 × 32-bit words)         |
| 0x20-0x2C | AES\_DIN\[0-3\]  | W      | 128-bit Input Data                     |
| 0x30-0x3C | AES\_DOUT\[0-3\] | R      | 128-bit Output Data                    |


# AES_CTRL (0x00) - Control Register (R/W)

| Bit     | Name       | Access | Reset | Description                                | Function Group   |
| :-----: | :--------: | :----: | :---: | :----------------------------------------: | :--------------: | 
| \[0\]   | START      | R/W    | 0     | Write 1 to start operation (self-clearing) | Control          | 
| \[1\]   | MODE       | R/W    | 0     | 0 = Encrypt, 1 = Decrypt                   | Configuration    | 
| \[2\]   | KEY\_VALID | R      | 0     | Key has been loaded (read-only status)     | Status           | 
| \[7:3\] | Reserved   | \-     | 0     | Reserved for future use                    | Reserved         | 

# AES_STATUS (0x04) - Status Register (R)

| Bit     | Name        | Access | Reset | Description                            | Status Type   |
| :-----: | :---------: | :----: | :---: | :------------------------------------: | :-----------: | 
| \[0\]   | BUSY        | R      | 0     | Operation in progress                  | Activity      | 
| \[1\]   | DONE        | R      | 0     | Operation complete                     | Completion    | 
| \[2\]   | ERROR       | R      | 0     | Error occurred (invalid operation)     | Error         | 
| \[3\]   | KEY\_VALID  | R      | 0     | Key registers have been written        | Configuration | 
| \[4\]   | DIN\_VALID  | R      | 0     | Input data registers have been written | Configuration | 
| \[7:5\] | Reserved    | R      | 0     | Reserved                               | Reserved      | 


# AES_INT_STATUS (0x0C) - Interrupt Status Register (R/W1C)

| Bit     | Name          | Access | Reset | Description                             | Interrupt Event | Default Status | Is Writable |
| :-----: | :-----------: | :----: | :---: | :-------------------------------------: | :-------------: | :------------: | :---------: |
| \[0\]   | DONE\_IE      | R/W    | 0     | Enable interrupt on operation complete  | Completion      | FALSE          | TRUE        |
| \[1\]   | ERROR\_IE     | R/W    | 0     | Enable interrupt on error               | Error           | FALSE          | TRUE        |
| \[7:2\] | Reserved      | \-     | 0     | Reserved                                | N/A             | N/A            | FALSE       |

# AES_KEY[0-3] (0x10-0x1C) - Key Registers (W)

| Register  | Offset | Description          | Access |  
| :-------: | :----: | :------------------: | :----: |  
| AES\_KEY0 | 0x10   | Key bits \[31:0\]    | W      | 
| AES\_KEY1 | 0x14   | Key bits \[63:32\]   | W      | 
| AES\_KEY2 | 0x18   | Key bits \[95:64\]   | W      | 
| AES\_KEY3 | 0x1C   | Key bits \[127:96\]  | W      |


# AES_DIN[0-3] (0x20-0x2C) - Data Input Registers (W)

| Register  | Offset | Description         | Access | Reset Value |
| :-------: | :----: | :-----------------: | :----: | :---------: |
| AES\_DIN0 | 0x20   | Input bits \[31:0\] | W      | 0x00000000  |
| AES\_DIN1 | 0x24   | Input bits [63:32]  | W      | 0x00000000  |
| AES\_DIN2 | 0x28   | Input bits [95:64]  | W      | 0x00000000  |
| AES\_DIN3 | 0x2C   | Input bits [127:96] | W      | 0x00000000  |

# AES_DOUT[0-3] (0x30-0x3C) - Data Output Registers (R)

| Register   | Offset | Description             | Access | Reset Value |
| :--------: | :----: | :---------------------: | :----: | :---------: |
| AES\_DOUT0 | 0x30   | Output bits \[31:0\]    | R      | 0x00000000  |
| AES\_DOUT1 | 0x34   | Output bits  [63:32]    | R      | 0x00000000  |
| AES\_DOUT2 | 0x38   | Output bits  [95:64]    | R      | 0x00000000  |
| AES\_DOUT3 | 0x3C   | Output bits  [127:96]   | R      | 0x00000000  |



 





