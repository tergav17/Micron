# Z80 SKERN
  The Z80 SKERN (Simple Kernel) is the kernel that the z80-general programs run on top of. It is written in Z80 assembly, and it provides all of the basic functions needed to run MICRON. These include context switching, process handling, memory managment, pipe managment, and program loading. In addition, when the kernel first loads, it will start a process that loads the CONSOLE into memory, and acts as the SY device.
  
  In order to compile the kernel, I just use zmac to assemble it into a binary file (.cim) and copy it as kernel.bin for the emulator. To adapt this kernel. You will probably need to change where all of the parts of the kernel are in memory, along with how the boot process loads the CONSOLE, and how it handles SIO and the boot device.
