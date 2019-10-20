package main;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Scanner;
public class Main implements NotifyOps{
	
	 private Z80 z80;
	 private MemIoOps memIo;
	 private Terminal t;
	 private Corewatch core;
	 
	 static String rootPath = "ROOT/";
	 
	 private int corePointer = 0;
	 
	 private BufferedInputStream prg = null;
	 
	 private Scanner sc = new Scanner(System.in);
	 
	 private boolean halt = false;
	 
	private final static byte z80Ram[] = new byte[0x10000];
	
	public Main() {
		
		memIo = new MemIoOps(0, 0);
        memIo.setRam(z80Ram);
        z80 = new Z80(memIo, this);
        t = new Terminal();
        core = new Corewatch();
	}
	public static void main(String[] args) {
		Main m = new Main();
		m.run();
	}
	
	public void run() {
		String programName = "kernel.bin";
		String booterName = "console.prg";
		try {
			prg = new BufferedInputStream(new FileInputStream(booterName));
		} catch (IOException ex) {
			System.out.println(ex.getMessage());
		}
		
		try (BufferedInputStream in = new BufferedInputStream( new FileInputStream(programName) )) {
            int count = in.read(z80Ram, 0x0000, 0xFFFF);
            System.out.println("Read " + count + " bytes from " + programName);
        } catch (IOException ex) {
            System.out.println(ex.getMessage());
            return;
        }
        
        z80.reset();
        memIo.reset();

        System.out.println("Starting program " + programName);
        z80.setBreakpoint(0x0005, true);
        int t = 0;
        int v = 0;
        while(true) {
        	long lastTime = System.currentTimeMillis();
        	int i = 0;
        	while (i != 1700) {
        		if (!halt) z80.execute();
        		//For debugging purposes only, disabled
        		v++;
        		if (v == t) {
        			v = 0;
        			System.out.print(">");
        			t = sc.nextInt();
        			System.out.println("PROC " + z80Ram[32] + " SP: " + String.format("0x%04X", z80.getRegSP()) + " AF: " + String.format("0x%04X", z80.getRegAF()) + " BC: " + String.format("0x%04X", z80.getRegBC()) +" DE: " + String.format("0x%04X", z80.getRegDE()) +" HL: " + String.format("0x%04X", z80.getRegHL()) + " PC: " + String.format("0x%04X", z80.getRegPC()) + " (PC): " + String.format("0x%02X", z80Ram[z80.getRegPC()]) + " I: " + i);
        		}
        		i++;
        		if (t == -1) System.out.println("PROC " + z80Ram[32] + " SP: " + String.format("0x%04X", z80.getRegSP()) + " AF: " + String.format("0x%04X", z80.getRegAF()) + " BC: " + String.format("0x%04X", z80.getRegBC()) +" DE: " + String.format("0x%04X", z80.getRegDE()) +" HL: " + String.format("0x%04X", z80.getRegHL()) + " PC: " + String.format("0x%04X", z80.getRegPC()) + " (PC): " + String.format("0x%02X", z80Ram[z80.getRegPC()]) + " I: " + i);
        	}
           	core.resetBuffer();
        	int o = 0;
        	while (o != 256) {
        		core.writeByte(z80Ram[corePointer + o]);
        		o++;
        	}
        	core.redrawDisplay();
        	memIo.interrupt();
        	
        	while (System.currentTimeMillis() < lastTime+2);
        }
        
		
	}

	// 0: Reset
	// 1: Read Char
	// 2: Write Char
	// 3: Read From Loader
	// 4: Set Core Watch Address
	// 5: Write To FSD
	// 6: FSD Ready Write
	// 7: Read FSD
	// 8: FSD Ready Read
	// 9: Debug Alert
	
	int commandState = 0;
	
	int inputState = 0;
	
	int bufferIterator = 0;
	
	ArrayList<Integer> output = new ArrayList<Integer>();
	
	String fileName = "";
	
	int sectorNumber = 0;
	int subDevice = 0;
	
	String fileTemp = "";
	File f = null;
	
	String sectorBuffer = "";
	String entryBuffer = "";
	
	public int breakpoint(int address, int opcode) {
        switch (z80.getRegC()) {
            case 0:
                System.out.println("Z80 reset after " + memIo.getTstates() + " t-states");
                break;
            case 1:
            	int nextChar = t.popNextChar();
            	z80.setRegE(nextChar);
            	break;
            case 2:
                t.print((char) z80.getRegE());
                break;
            case 3:
				try {
					int rd = prg.read();
					if (rd != -1) z80.setRegE(rd);
				} catch (IOException e) {
					e.printStackTrace();
				}
				break;
            case 4:
            	corePointer = 256 * (2);
            	core.setWatchPoint(corePointer);
            	break;
            case 5:
            	int in = z80.getRegE();
            	if (commandState == 0) {
            		if (in == 1) {
            			commandState = 1;
            			inputState = 0;
            			bufferIterator = 0;
            			sectorBuffer = "";
            			fileName = "";
            			f = null;
            			sectorNumber = 0;
            			subDevice = 0;
            		} else if (in == 2) {
            			commandState = 2;
            			inputState = 0;
            			bufferIterator = 0;
            			sectorBuffer = "";
            			fileName = "";
            			f = null;
            			sectorNumber = 0;
            			subDevice = 0;
            		} else if (in == 3) {
            			commandState = 3;
            			inputState = 0;
            			bufferIterator = 0;
            			sectorBuffer = "";
            			fileName = "";
            			f = null;
            			sectorNumber = 0;
            			subDevice = 0;
            		} else if (in == 4) {
            			commandState = 4;
            			inputState = 0;
            			bufferIterator = 0;
            			sectorBuffer = "";
            			fileName = "";
            			f = null;
            			sectorNumber = 0;
            			subDevice = 0;
            		} else if (in == 7) {
            			commandState = 7;
            			inputState = 0;
            			subDevice = 0;
            			sectorNumber = 0;
            		} else if (in == 8) {
            			commandState = 8;
            			inputState = 0;
            			subDevice = 0;
            			sectorNumber = 0;
            		} else if (in == 9) {
            			commandState = 9;
            			inputState = 0;
            			subDevice = 0;
            			sectorNumber = 0;
            		} else if (in == 10) {
            			commandState = 10;
            			inputState = 0;
            			subDevice = 0;
            			sectorNumber = 0;
            		} else if (in == 11) {
            			commandState = 11;
            			inputState = 0;
            			subDevice = 0;
            			sectorNumber = 0;
            		} else if (in == 12) {
            			commandState = 12;
            			inputState = 0;
            			subDevice = 0;
            			sectorNumber = 0;
            		}
            	} else if (commandState == 1) {
            		if (inputState == 0) {
            			subDevice = in;
            			inputState++;
            		} else if (inputState == 1) {
            			sectorNumber = in;
            			inputState++;
            		} else if (inputState == 2) {
            			sectorNumber = sectorNumber + (256*in);
            			inputState++;
            		} else if (inputState == 3) {
            			if (in != 0) {
            				fileName = fileName + (char) in;
            			} else {
            				System.out.println("Reading Sector " + sectorNumber + " From " + fileName + " On Subdevice " + subDevice);
                			f = new File(rootPath + subDevice + "/" + fileName);
                			if (f.exists()) {
                				if (subDevice > -1 && subDevice < 8) {
                					mountFile(f);
                					int fileReadCounter = 128 * sectorNumber;
                					if (fileReadCounter < fileTemp.length()) {
                						output.add(0);
                						int i = 0;
                						while (i != 128) {
                							output.add((int) fileTemp.charAt(fileReadCounter + i));
                							commandState = 0;
                							i++;
                						}
                					} else {
                						output.add(17);
                						System.out.println("Bad Sector Access");
                						commandState = 0;
                					}
                					
                					
                				} else {
                					System.out.println("Bad Subdevice");
                					output.add(19);
                					commandState = 0;
                				}
                			} else {
                				System.out.println("File Does Not Exist");
                			    output.add(16);
                				commandState = 0;
                			}
            			}
            		}
            	} else if (commandState == 2) {
            		if (inputState == 0) {
            			subDevice = in;
            			inputState++;
            		} else if (inputState == 1) {
            			sectorNumber = in;
            			inputState++;
            		} else if (inputState == 2) {
            			sectorNumber = sectorNumber + (256*in);
            			inputState++;
            		} else if (inputState == 3) {
            			if (in != 0) {
            				fileName = fileName + (char) in;
            			} else {
            				System.out.println("Writing Sector " + sectorNumber + " From " + fileName + " On Subdevice " + subDevice);
                			f = new File(rootPath + subDevice + "/" + fileName);
                			if (f.exists()) {
                				if (subDevice > -1 && subDevice < 8) {
                					mountFile(f);
                					if ((((int) Math.floor((fileTemp.length() * 1.0)/128.0)) - sectorNumber) == 0) {
                						int i = 0;
                						while (i != 128) {
                							fileTemp = fileTemp + (char) 0;
                							i++;
                						}
                					}
                					if (sectorNumber < (int) Math.floor((fileTemp.length() * 1.0)/128.0)) {
                						inputState = 4;
                						bufferIterator = 0;
                						output.add(0);
                					} else {
                						System.out.println("Bad Sector Access");
                						output.add(17);
                						commandState = 0;
                					}
                				} else {
                					System.out.println("Bad Subdevice");
                					output.add(19);
                					commandState = 0;
                				}
                			} else {
                				System.out.println("File Does Not Exist");
                			    output.add(16);
                				commandState = 0;
                			}
            			}
            		} else if (inputState == 4) {
            			fileTemp = setCharAt(fileTemp,(char) in, bufferIterator + (128*sectorNumber));
            			bufferIterator++;
            			if (bufferIterator == 128) {
            				commandState = 0;
            				unmountFile(f);
            			}
            		}
            	}  else if (commandState == 3) {
            		if (inputState == 0) {
            			subDevice = in;
            			inputState++;
            		} else if (inputState == 1) {
            			sectorNumber = in;
            			inputState++;
            		} else if (inputState == 2) {
            			sectorNumber = sectorNumber + (256*in);
            			inputState++;
            		} else if (inputState == 3) {
            			if (in != 0) {
            				fileName = fileName + (char) in;
            			} else {
            				System.out.println("Creating File " + fileName + " With " + sectorNumber + " Sectors On Subdevice " + subDevice);
                			f = new File(rootPath + subDevice + "/" + fileName);
                			try {
								f.createNewFile();
							} catch (IOException e) {
								e.printStackTrace();
							}
                			if (f.exists()) {
                				if (subDevice > -1 && subDevice < 8) {
                					output.add(createWithSectors(f,sectorNumber));
                					commandState = 0;
                				} else {
                					System.out.println("Bad Subdevice");
                					output.add(19);
                					commandState = 0;
                				}
                			} else {
                				System.out.println("File Does Not Exist");
                			    output.add(16);
                				commandState = 0;
                			}
            			}
            		}
            	}  else if (commandState == 4) {
            		if (inputState == 0) {
            			subDevice = in;
            			inputState = 2;
            		} else if (inputState == 2) {
            			if (in != 0) {
            				fileName = fileName + (char) in;
            			} else {
            				System.out.println("Deleting File " + fileName + " With " + sectorNumber + " Sectors On Subdevice " + subDevice);
            				if (subDevice > -1 && subDevice < 8) {
	                			f = new File(rootPath + subDevice + "/" + fileName);
	                			if (f.delete()) {
	                				System.out.println("File Removed");
	                				output.add(0);
	                				commandState = 0;
	                			} else {
	                				System.out.println("File Not Removed");
	                				output.add(16);
	                				commandState = 0;
	                			}
            				} else {
            					System.out.println("Bad Subdevice");
            					output.add(19);
            					commandState = 0;
            				}
            			}
            		}
            	} else if (commandState == 7 || commandState == 8 || commandState == 9) {
            		if (inputState == 0) {
            			subDevice = in;
            			inputState++;
            		} 
            		if (inputState == 1) {
            			if (commandState == 7) System.out.println("Getting Status Of Subdevice " + subDevice);
            			if (commandState == 8) System.out.println("Mounting Subdevice " + subDevice);
            			if (commandState == 9) System.out.println("Unmounting Subdevice " + subDevice);
            			if (subDevice > -1 && subDevice < 8) {
            				output.add(0);
            				commandState = 0;
            			} else {
            				System.out.println("Bad Subdevice!");
        					output.add(19);
        					commandState = 0;
            			}
            		}
            	}  else if (commandState == 10) {
            		if (inputState == 0) {
            			subDevice = in;
            			inputState++;
            		} 
            		if (inputState == 1) {
            			System.out.println("Formatting Subdevice " + subDevice);
            			if (subDevice > -1 && subDevice < 8) {
            				File dir = new File(rootPath + subDevice);
            				for(File file: dir.listFiles()) 
            				    if (!file.isDirectory()) 
            				        file.delete();
            				output.add(0);
            				commandState = 0;
            			} else {
            				System.out.println("Bad Subdevice");
        					output.add(19);
        					commandState = 0;
            			}
            		}
            	} else if (commandState == 11) {
            		if (inputState == 0) {
            			subDevice = in;
            			inputState++;
            		} else if (inputState == 1) {
            			sectorNumber = in;
            			System.out.println("Reading Directory Entry " + sectorNumber + " From Subdevice " + subDevice);
            			String entry = getDirectoryEntry(subDevice, sectorNumber);
            			if (entry.equals("!ERR")) {
            				System.out.println("Bad Directory Access");
            				output.add(16);
            			} else {
            				int i = 0;
            				output.add(0);
            				while (i != 16) {
            					output.add((int) entry.charAt(i));
            					//System.out.println(entry.charAt(i));
            					i++;
            				}
            			}
            			commandState = 0;
            		}
            	} else if (commandState == 12) {
            		if (inputState == 0) {
            			subDevice = in;
            			inputState++;
            		}
            		if (inputState == 1) {
            			System.out.println("Getting Size Of Subdevice " + subDevice);
            			if (subDevice > -1 && subDevice < 8) {
            				output.add(0);
            				output.add(0);
            				output.add(0);
            				output.add(255);
            				commandState = 0;
            			} else {
            				System.out.println("Bad Subdevice");
        					output.add(19);
        					commandState = 0;
            			}
            		}
            	}
            	break;
            case 6:
            	z80.setRegE(1);
            	break;
            case 7:
            	if (output.size() != 0) {
            		z80.setRegE(output.get(0));
            		output.remove(0);
            	} else {
            		z80.setRegE(0);
            	}
            	break;
            case 8:
            	if (output.size() != 0) {
            		z80.setRegE(1);
            	} else {
            		z80.setRegE(0);
            	}
            	break;
            case 9:
             
            	System.out.println("Alert " + z80.getRegE());
            	//if (z80.getRegE() == 255) halt = true;
            	break;
            default:
                System.out.println("SIO Call " + z80.getRegC() + " From Proc " + z80Ram[32]);
        }
        //halt = false;
        return opcode;
	}

	private String setCharAt(String s, char c, int i) {
		return s.substring(0,i)+c+s.substring(i+1);
	}
	
	private void mountFile(File f) {
		fileTemp = "";
		try {
			BufferedInputStream fin = new BufferedInputStream(new FileInputStream(f));
			boolean cont = true;
			while (cont) {
				int i = 0;
				while (i != 128) {
					int in = fin.read();
					if (in != -1) {
						fileTemp = fileTemp + (char) in;
					} else {
						cont = false;
						fileTemp = fileTemp + (char) 0;
					}
					i++;
				}
				if (fin.available() == 0) break;
			}
			//System.out.println(fileTemp.length());
			fin.close();
		} catch (Exception e) {
			System.out.println("Cannot Mount File " + f.getAbsolutePath());
			//e.printStackTrace();
		}
	}
	
	private String getDirectoryEntry(int device, int entry) {
		String ent = "";
		File d = new File(rootPath + device);
		File[] files = d.listFiles();
		if (files.length <= entry) return "!ERR";
		int hasNext = 0;
		if (files.length-1 <= entry) hasNext = 1;
		String f = files[entry].getName();
		int i = 0;
		int g = 0;
		boolean readingName = true;
		while (i != 8) {
			if (readingName) {
				ent = ent + f.charAt(g);
				g++;
				if (f.charAt(g) == '.') readingName = false;
			} else {
				ent = ent + (char) 0;
			}
			i++;
		}
		g++;
		i = 0;
		while (i != 3) {
			ent = ent + f.charAt(g);
			g++;
			i++;
		}
		double size = files[entry].length();
		size = size / 128.0;
		size = Math.ceil(size);
		int sizeHigh = (int) Math.floor(size / 256);
		int sizeLow = (int) (size - (256.0*sizeHigh));
		ent = ent + (char) sizeLow + (char) sizeHigh + (char) 0 + (char) 0 + (char) hasNext;
		return ent;
	}

	private int createWithSectors(File f, int sectorNum) {
		try {
			sectorNum = sectorNum * 128;
			if (sectorNum < 128) sectorNum = 128;
			BufferedOutputStream fout = new BufferedOutputStream(new FileOutputStream(f));
			int i = 0;
			while (i != sectorNum) {
				fout.write(0);
				i++;
			}
			fout.close();
		} catch (Exception e) {
			System.out.println("Cannot Create File " + f.getAbsolutePath());
			return 21;
		}
		return 0;
	}
	
	private void unmountFile(File f) {
		System.out.println("Unmounting File " + f.getName() + " With Length Of " + fileTemp.length());
		try {
			BufferedOutputStream fout = new BufferedOutputStream(new FileOutputStream(f));
			int i = 0;
			while (i != fileTemp.length()) {
				fout.write(fileTemp.charAt(i));
				i++;
			}
			fout.close();
		} catch (Exception e) {
			System.out.println("Cannot Unmount File " + f.getAbsolutePath());
		}
	}
	
	@Override
	public void execDone() {
		// TODO Auto-generated method stub
		
	}
}
