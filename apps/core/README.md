# Core Applications
  In this directory are the 13 "core" utilities. All of them are fairly simple, and compile to less that 2kb of memory. All of these utilities should be in availiable in the working directory, as some applications may need to fork them for functionality. In addition, they can be used from the command line to do system managment and simple file manipluation.
 
 # Directory List (DIR.PRG)
  Cut and dry as them come. Will spit out a directory listing. The directory to be listed can be specified in the argument, if not, the working directory will be listed.

  Examples:
```
.DIR
```
Will list the current working directory.
  
```
.DIR SY2:
```
Will list the directory of device SY on subdevice 2.
  
# Echo (EC.PRG)
  Will spit out anything that is typed in the argument. Another extremely simple one.
 
  Examples:
```
.EC HELLO WORLD
```
Outputs "HELLO WORLD" to the terminal.

# Format (FM.PRG)
  Tells the device driver specified to format a subdevice.

  Examples:
```
.FM DX0:
```
Subdevice 0 on device DX will be formatted.

# Free Memory (FR.PRG)
  Spits out the free memory on the system. First outputs the total number of free blocks, then will output the largest continuous segment of free blocks in memory. All outputs are in hexadecimal.
  
  Examples:
```
.FR
```
Outputs free memory in blocks (256 byte long segments of memory).

# List Devices (LD.PRG)
  Lists all of the devices currently attatched to the system.
  
  Examples:
```
.LD
```
Will list devices attatched to the system.

# List Processes (LP.PRG)
  Will list all of the processes currently running. The process IDs will be displayed in hexadecimal. In addition, it will list if they are sleeping (S) or awake (W).
  
  Examples:
```
.LP
```
Will list and processes currently running

# Mount (MN.PRG)
  Will mount the specified subdevice. If the file system driver does not support mounting, then it will be ignored
  
  Examples:
```
.MN DU7:
```
Tells the driver DU to mount subdevice 7.

# Pipe (PI.PRG)
  This will pipe the outputs of a program into a specified file. The process will terminate when the secified program that was forked terminates.
  
  Examples:
```
.PI TEST.TXT EC THIS IS A TEST
```
The text "THIS IS A TEST" will be piped into the file TEST.TXT in the working directory.

```
PI SY1:COPY.TXT TY SY2:SOURCE.TXT
```
The file SOURCE.TXT on SY2: will be copied to COPY.TXT on SY1:

# Remove (RM.PRG)
  This program removes a specified file.
  
  Examples:
```
.RM DU0:DATA.BIN
```
Will remove the file DATA.BIN on DU0:

# Directory Size (SZ.PRG)
  Spits out the size (in 128 byte sectors) of the specified directory. The value is outputted in hexadecimal.
  
  Examples:
```
.SZ SY0:
```
The size of SY0: is outputted.

# Type File (TY.PRG)
  Will type the contents of a file onto the terminal.
  
  Examples:
```
.TY HELLO.TXT
```
The contents of HELLO.TXT will be typed onto the terminal

# Unmount (UM.PRG)
  Will unmount the specified subdevice. If the file system driver does not support unmounting, then it will be ignored
  
  Examples:
```
.MN DK0:
```
Tells the driver DK to unmount subdevice 0.

# Write File (WR.PRG)
  This utility will create a new specified file. When that file is created, ```*``` will be typed onto the terminal. Anything that the user types will be outputted onto the terminal and written into the new file. When ESC is pressed, the program terminates.
  
  Examples:
```
.WR TEXT.TXT
```
Will create and write the file TEXT.TXT
