# MICRON CONSOLE Source
  On top of the kernel, the MICRON CONSOLE is loaded in on startup by the booter along with the SY file system driver. It acts as the command line interface (CLI), along with handling all of the commands that user programs issue. It keeps track of all of the running user programs and devices.
  Currently, I have yet to clean up or comment the source code for this thing yet, to beware all who enter. Also know that there still could be some bugs lurking around in this revision of the CONSOLE.

  The current version of CONSOLE is capible of supporting 16 processes, with 8 drivers able to be attatched. This can be increased to 256 processes with 64 drivers by modifying the source code, but at the cost of more memory used.
