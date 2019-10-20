# MICRONBox Emulator
  MICRONBox emulates a simple Z80 system with 64kb at ~4MHz. It also provides a filesystem interface, so testing binaries made with the cross compiler is fairly easy. All outputs displayed on the emulated terminal, and has the memory allocation table displayed in the other window. It works decently well for what it needs to do, but has a few bugs (inconsistent speed and random lockups when displaying characters on the terminal).
  
# Usage
  In order to run MICRONBox, an image of the kernel (kernel.bin) and the console (console.prg) need to be in the same directory as the executable jar. In addition, the root file with atleast subdevice 0 also needs to be present

```
MICRONBox.jar
kernel.bin
console.prg
ROOT
-0
--DIR.PRG
--EC.PRG
etc...
```

This emulator is based off of [this Z80 core.](https://github.com/jsanchezv/Z80Core)
