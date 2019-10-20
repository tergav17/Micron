package com;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Scanner;

public class Compiler {
	
	private String firstStage = "C3[START]";
	
	private int addressCounter = 0x0B;
	
	private ArrayList<String> source = new ArrayList<String>();
	
	private HashMap<String,Integer> labelTable = new HashMap<String,Integer>();
	private HashMap<String,Integer> byteTable = new HashMap<String,Integer>();
	private HashMap<String,Integer> shortTable = new HashMap<String,Integer>();
	private HashMap<String,Integer> memTable = new HashMap<String,Integer>();
	private HashMap<String,Integer> stringTable = new HashMap<String,Integer>();
	
	public int compile(File in, File out) {
		System.out.println("Starting Compiler");
		Scanner sc = null;
		try {
			sc = new Scanner(in);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
		while (sc.hasNext()) {
			String scIn = sc.nextLine();
			if (scIn.length() != 0) {
				scIn = deSpace(scIn);
				if (scIn.length() != 0) if (scIn.charAt(0) != ';' ) source.add(scIn);
			}
			
		}
		int i = 0;
		while (!source.get(i).equals("@START")) {
			String line = source.get(i);
			String[] args = line.split(" ");
			if (args.length > 0) {
				if (args[0].equals("BYTE") && args.length == 4) {
					String symbolName = args[1];
					symbolName = prepareSymbol(symbolName);
					if (doesSymbolExist(symbolName)) {System.out.println("Repeat Definition On Line " + (i+1)); return 1;}
					if (!args[2].equals("=")) {System.out.println("Syntax Error On Line " + (i+1)); return 1;}
					int value = Integer.valueOf(args[3]);
					if (value>255 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
					String hexValue = decToHex(value,2);
					firstStage = firstStage + hexValue;
					byteTable.put(symbolName, addressCounter);
					System.out.println("	Inserted Symbol Into Byte Table As " + symbolName + " At 0X" + decToHex(addressCounter,4));
					addressCounter++;
				} else if (args[0].equals("MEM") && args.length == 2) {
					String symbolName = args[1];
					symbolName = prepareSymbol(symbolName);
					if (doesSymbolExist(symbolName)) {System.out.println("Repeat Definition On Line " + (i+1)); return 1;}
					firstStage = firstStage + "0000";
					memTable.put(symbolName, addressCounter);
					addressCounter = addressCounter + 2;
				} else if (args[0].equals("SHORT") && args.length == 4) {
					String symbolName = args[1];
					symbolName = prepareSymbol(symbolName);
					if (doesSymbolExist(symbolName)) {System.out.println("Repeat Definition On Line " + (i+1)); return 1;}
					if (!args[2].equals("=")) {System.out.println("Syntax Error On Line " + (i+1)); return 1;}
					int value = Integer.valueOf(args[3]);
					if (value>65535 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
					String hexValue = decToHex(value,4);
					hexValue = swapHighLowBytes(hexValue);
					firstStage = firstStage + hexValue;
					shortTable.put(symbolName, addressCounter);
					System.out.println("	Inserted Symbol Into Short Table As " + symbolName + " At 0X" + decToHex(addressCounter,4));
					addressCounter = addressCounter + 2;
				} else if (args[0].equals("STRING") && args.length > 3) {
					if (!args[2].equals("=")) {System.out.println("Syntax Error On Line " + (i+1)); return 1;}
					String symbol = args[1];
					String symbolName = prepareSymbol(getAddressableSymbolName(symbol));
					if (symbolName.equals("!ERR")) {System.out.println("Bad String Definition On Line " + (i+1)); return 1;}
					String symbolArg = getAddressableSymbolArgument(symbol);
					if (symbolArg.equals("!ERR")) {System.out.println("Bad String Definition On Line " + (i+1)); return 1;}
					if (doesSymbolExist(symbolName)) {System.out.println("Repeat Definition On Line " + (i+1)); return 1;}
					if (stringTable.containsKey(symbolName)) {System.out.println("Repeat Definition On Line " + (i+1)); return 1;}
					if (!isInteger(symbolArg)) {System.out.println("Bad String Length On Line " + (i+1)); return 1;}
					int length = Integer.valueOf(symbolArg);
					if (length>255 || length<0) {System.out.println("Bad String Length On Line " + (i+1)); return 1;}
					int o = 0;
					while (line.charAt(o) != '=' && o != line.length()) {
						o++;
					}
					if (o == line.length()) {System.out.println("Bad String Definition On Line " + (i+1)); return 1;}
					o++;
					if (o == line.length()) {System.out.println("Bad String Definition On Line " + (i+1)); return 1;}
					o++;
					if (o == line.length()) {System.out.println("Bad String Definition On Line " + (i+1)); return 1;}
					String value = "";
					while (o != line.length()) {
						value = value + line.charAt(o);
						o++;
					}
					System.out.println(value);
					stringTable.put(symbolName, addressCounter);
					System.out.println("	Inserted Symbol Into String Table As " + symbolName + " At 0X" + decToHex(addressCounter,4));
					int counter = 0;
					o = 0;
					boolean isInQ = false;
					String intTemp = "";
					while (o != value.length()) {
						if (value.charAt(o) == '"') isInQ = !isInQ;
						if (value.charAt(o) != '"') {
							if (isInQ) {
								firstStage = firstStage + decToHex(value.charAt(o),2);
								addressCounter++;
								counter++;
							} else if (isInteger(String.valueOf(value.charAt(o)))) {
								intTemp = intTemp + value.charAt(o);
							} else if (value.charAt(o) == ',') {
								if (intTemp.length() != 0) {
									int intValue = Integer.valueOf(intTemp);
									if (intValue>255 || intValue<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
									firstStage = firstStage + decToHex(intValue,2);
									addressCounter++;
									counter++;
									intTemp = "";
								}
							} else {
								System.out.println("Value Error On Line " + (i+1));
								return 1;
							}
						}
						o++;
					}
					while (counter != length) {
						firstStage = firstStage + "00";
						addressCounter++;
						counter++;
					}
					
					
				} else {
					System.out.println("Unidentified Symbol On Line " + (i+1));
					return 1;
				}
			}
			i++;
			if (i == source.size()) {
				System.out.println("No Code To Compile");
				return 1;
			}
		}
		i++;
		shortTable.put("#SIO",0x02);
		System.out.println("	Inserted Symbol Into Short Table As #SIO At 0X" + decToHex(0,4));
		shortTable.put("#SYS",0x04);
		System.out.println("	Inserted Symbol Into Short Table As #SYS At 0X" + decToHex(2,4));
		memTable.put("#COM",0x06);
		System.out.println("	Inserted Symbol Into Mem Table As #COM At 0X" + decToHex(2,6));
		labelTable.put("START",addressCounter);
		System.out.println("	Inserted Symbol Into Label Table As START At 0X" + decToHex(addressCounter,4));
		while (!(i >= source.size())) {
			String line = source.get(i);
			String[] args = line.split(" ");
			if (args.length > 0) {
				if (args[0].charAt(args[0].length() - 1) == ':') {
					if (args[0].length() > 1) {
						String symbolName = args[0].substring(0,args[0].length()-1);
						if (doesSymbolExist(symbolName)) {System.out.println("Repeat Definition On Line " + (i+1)); return 1;}
						labelTable.put(symbolName, addressCounter);
						System.out.println("	Inserted Symbol Into Label Table As " + symbolName + " At 0X" + decToHex(addressCounter,4));
					} else {
						System.out.println("Unidentified Symbol On Line " + (i+1));
						return 1;
					}
				} else {
					if (args[0].equals("GOTO") && args.length == 2) {
						String symbolName = args[1];
						firstStage = firstStage + "C3[" + symbolName + "]";
						addressCounter = addressCounter + 3;
					} else if (args[0].equals("GOSUB") && args.length == 2) {
						String symbolName = args[1];
						firstStage = firstStage + "CD[" + symbolName + "]";
						addressCounter = addressCounter + 3;
					}  else if (args[0].equals("MOVE") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 2) {
							if (isSymbolMem(subArgs[0]) && isSymbolMem(subArgs[1])) {
								firstStage = firstStage + "2A[" + subArgs[1] + "]22[" + subArgs[0] + "]";
								addressCounter = addressCounter + 6;
							} else {
								System.out.println("Argument Error On Line " + (i+1));
								return 1;
							}
						} else {
							System.out.println("Argument Error On Line " + (i+1));
							return 1;
						}
					} else if (args[0].equals("ALLOC") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 3) {
							String memTarget = subArgs[0];
							String length = subArgs[1];
							String error = subArgs[2];
							if (isSymbolMem(memTarget)) {
								if(prepareBytePrimitive(length,i) == 1) return 1;
								firstStage = firstStage + "4F32[" +  memTarget + "+1]160CCD!7932[" + memTarget + "]7A";
								addressCounter = addressCounter + 14;
								if(prepareByteTargetPrimitive(error,i) == 1) return 1;
							} else {
								System.out.println("Argument Error On Line " + (i+1));
								return 1;
							}
						} else {
							System.out.println("Argument Error On Line " + (i+1));
							return 1;
						}
					} else if (args[0].equals("DALLOC") && args.length == 2) {
						String memTarget = args[1];
						if (isSymbolMem(memTarget)) {
							firstStage = firstStage + "3A[" + memTarget + "]5F3A[" + memTarget + "+1]4F160BCD!";
							addressCounter = addressCounter + 13;
						} else {
							System.out.println("Argument Error On Line " + (i+1));
							return 1;
						}
					} else if (args[0].equals("PIPE") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 2) {
							if (isSymbolShort(subArgs[0])) {
								firstStage = firstStage + "160C0E01CD!7AFE00200E1612CD!7932[" + subArgs[0] + "]3E0032[" + subArgs[0] + "+1]7A";
								addressCounter = addressCounter + 27;
								if(prepareByteTargetPrimitive(subArgs[1],i) == 1) return 1;
							} else {
								System.out.println("Argument Error On Line " + (i+1));
								return 1;
							}
						} else {
							System.out.println("Argument Error On Line " + (i+1));
							return 1;
						}
					} else if (args[0].equals("DPIPE") && args.length == 2) {
						if (isSymbolShort(args[1])) {
							firstStage = firstStage + "3A[" + args[1] + "]5F0E00160BCD!3A[" + args[1] + "]16114FCD!";
							addressCounter = addressCounter + 20;
						} else {
							System.out.println("Argument Error On Line " + (i+1));
							return 1;
						}
					} else if (args[0].equals("HWRITE") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 3) {
							if (isSymbolShort(subArgs[0])) {
								if(prepareBytePrimitive(subArgs[1],i) == 1) return 1;
								firstStage = firstStage + "5F3A[" + subArgs[0] + "]4F1614CD!7A";
								addressCounter = addressCounter + 11;
								if(prepareByteTargetPrimitive(subArgs[2],i) == 1) return 1;
							} else {
								System.out.println("Argument Error On Line " + (i+1));
								return 1;
							}
						} else {
							System.out.println("Argument Error On Line " + (i+1));
							return 1;
						}
					} else if (args[0].equals("READ") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 3) {
							if (isSymbolShort(subArgs[0])) {
								firstStage = firstStage + "3A[" + subArgs[0] + "]4F1616CD!7A43";
								addressCounter = addressCounter + 11;
								if(prepareByteTargetPrimitive(subArgs[2],i) == 1) return 1;
								firstStage = firstStage + "78";
								addressCounter++;
								if(prepareByteTargetPrimitive(subArgs[1],i) == 1) return 1;
							} else {
								System.out.println("Argument Error On Line " + (i+1));
								return 1;
							}
						} else {
							System.out.println("Argument Error On Line" + (i+1));
							return 1;
						}
					} else if (args[0].equals("WRITE") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 3) {
							if (isSymbolShort(subArgs[0])) {
								if(prepareBytePrimitive(subArgs[1],i) == 1) return 1;
								firstStage = firstStage + "5F3A[" + subArgs[0] + "]4F1615CD!7A";
								addressCounter = addressCounter + 11;
								if(prepareByteTargetPrimitive(subArgs[2],i) == 1) return 1;
							} else {
								System.out.println("Argument Error On Line " + (i+1));
								return 1;
							}
						} else {
							System.out.println("Argument Error On Line " + (i+1));
							return 1;
						}
					} else if (args[0].equals("HREAD") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 3) {
							if (isSymbolShort(subArgs[0])) {
								firstStage = firstStage + "3A[" + subArgs[0] + "]4F1617CD!7A43";
								addressCounter = addressCounter + 11;
								if(prepareByteTargetPrimitive(subArgs[2],i) == 1) return 1;
								firstStage = firstStage + "78";
								addressCounter++;
								if(prepareByteTargetPrimitive(subArgs[1],i) == 1) return 1;
							} else {
								System.out.println("Argument Error On Line " + (i+1));
								return 1;
							}
						} else {
							System.out.println("Argument Error On Line " + (i+1));
							return 1;
						}
					} else if (args[0].equals("LET") && args.length > 3)  {
						String targetSymbol = args[1];
						if (args[2].equals("=")) {
							if (isSymbolShort(targetSymbol)) {
								if (args.length == 4) {
									if (isInteger(args[3])) {
										int value = Integer.valueOf(args[3]);
										if (value>65535 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
										firstStage = firstStage + "21" + swapHighLowBytes(decToHex(value,4)) + "22[" + targetSymbol + "]";
										addressCounter = addressCounter + 6;
									} else if (isSymbolShort(args[3])) {
										firstStage = firstStage + "2A[" + args[3] + "]22[" + targetSymbol + "]";
										addressCounter = addressCounter + 6;
									} else{
										System.out.println("Argument Error On Line " + (i+1));
										return 1;
									}
								}
							} else  {
								if (args.length == 4) {
									if (isInteger(args[3])) {
										int value = Integer.valueOf(args[3]);
										if (value>255 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
										firstStage = firstStage + "3E" + decToHex(value,2);
										addressCounter = addressCounter + 2;
										if(prepareByteTargetPrimitive(targetSymbol,i) == 1) return 1;
									} else {
										if(prepareBytePrimitive(args[3],i) == 1) return 1;
										if(prepareByteTargetPrimitive(targetSymbol,i) == 1) return 1;
										
									}
								}
							}
						} else if (args[2].equals("=+")) {
							if (isSymbolShort(targetSymbol)) {
								if (args.length == 4) {
									if (isInteger(args[3])) {
										int value = Integer.valueOf(args[3]);
										if (value>65535 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
										firstStage = firstStage + "2A[" + targetSymbol + "]11" + swapHighLowBytes(decToHex(value,4)) + "1922[" + targetSymbol + "]";
										addressCounter = addressCounter + 10;
									} else if (isSymbolShort(args[3])) {
										firstStage = firstStage + "2A[" + targetSymbol + "]ED5B[" + args[3] + "]1922[" + targetSymbol + "]";
										addressCounter = addressCounter + 11;
									} else{
										System.out.println("Argument Error On Line " + (i+1));
										return 1;
									}
								}
							} else {
								if (args.length == 4) {
									if (isInteger(args[3])) {
										int value = Integer.valueOf(args[3]);
										if (value>255 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
										if(prepareBytePrimitive(targetSymbol,i) == 1) return 1;
										firstStage = firstStage + "C6" + decToHex(value,2);
										if(prepareByteTargetPrimitive(targetSymbol,i) == 1) return 1;
										addressCounter = addressCounter + 2;
									} else {
										if(prepareBytePrimitive(args[3],i) == 1) return 1;
										firstStage = firstStage + "47"; 
										if(prepareBytePrimitive(targetSymbol,i) == 1) return 1;
										firstStage = firstStage + "80";
										if(prepareByteTargetPrimitive(targetSymbol,i) == 1) return 1;
										addressCounter = addressCounter + 2;
									}
								}
							}
						} else if (args[2].equals("=-")) {
							if (isSymbolShort(targetSymbol)) {
								if (args.length == 4) {
									if (isInteger(args[3])) {
										int value = Integer.valueOf(args[3]);
										if (value>65535 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
										firstStage = firstStage + "2A[" + targetSymbol + "]11" + swapHighLowBytes(decToHex(value,4)) + "A7ED5222[" + targetSymbol + "]";
										addressCounter = addressCounter + 12;
									} else if (isSymbolShort(args[3])) {
										firstStage = firstStage + "2A[" + targetSymbol + "]ED5B[" + args[3] + "]A7ED5222[" + targetSymbol + "]";
										addressCounter = addressCounter + 13;
									} else{
										System.out.println("Argument Error On Line " + (i+1));
										return 1;
									}
								}
							} else {
								if (args.length == 4) {
									if (isInteger(args[3])) {
										int value = Integer.valueOf(args[3]);
										if (value>255 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
										if(prepareBytePrimitive(targetSymbol,i) == 1) return 1;
										firstStage = firstStage + "D6" + decToHex(value,2);
										if(prepareByteTargetPrimitive(targetSymbol,i) == 1) return 1;
										addressCounter = addressCounter + 2;
									} else {
										if(prepareBytePrimitive(args[3],i) == 1) return 1;
										firstStage = firstStage + "47"; 
										if(prepareBytePrimitive(targetSymbol,i) == 1) return 1;
										firstStage = firstStage + "90";
										if(prepareByteTargetPrimitive(targetSymbol,i) == 1) return 1;
										addressCounter = addressCounter + 2;
									}
								}
							}
						} else {
							System.out.println("Unidentified Symbol On Line " + (i+1));
							return 1;
						}
					} else if (args[0].equals("IF") && args.length == 6) {
						if (isInteger(args[1])) {
							System.out.println("Bad Comparison On Line " + (i+1));
							return 1;
						}
						if (!false) {
							if (args[2].equals("=") || args[2].equals(">"))  {
								if(prepareBytePrimitive(args[1],i) == 1) return 1;
								firstStage = firstStage + "47";
								addressCounter++;
								if(prepareBytePrimitive(args[3],i) == 1) return 1;
								firstStage = firstStage + "B8";
								addressCounter++;
								if (args[2].equals("=")) {
									if (args[4].equals("GOTO")) {
										firstStage = firstStage + "CA["+args[5]+"]";
										addressCounter = addressCounter + 3;
									} else if (args[4].equals("GOSUB")) {
										firstStage = firstStage + "CC["+args[5]+"]";
										addressCounter = addressCounter + 3;
									} else {
										System.out.println("Bad Operator On Line " + (i+1));
										return 1;
									}
								} else if (args[2].equals(">")) {
									if (args[4].equals("GOTO")) {
										firstStage = firstStage + "DA["+args[5]+"]";
										addressCounter = addressCounter + 3;
									} else if (args[4].equals("GOSUB")) {
										firstStage = firstStage + "DC["+args[5]+"]";
										addressCounter = addressCounter + 3;
									} else {
										System.out.println("Bad Operator On Line " + (i+1));
										return 1;
									}
								}
							} else if (args[2].equals("<")) {
								if(prepareBytePrimitive(args[3],i) == 1) return 1;
								firstStage = firstStage + "47";
								addressCounter++;
								if(prepareBytePrimitive(args[1],i) == 1) return 1;
								firstStage = firstStage + "B8";
								addressCounter++;
								if (args[4].equals("GOTO")) {
									firstStage = firstStage + "DA["+args[5]+"]";
									addressCounter = addressCounter + 3;
								} else if (args[4].equals("GOSUB")) {
									firstStage = firstStage + "DC["+args[5]+"]";
									addressCounter = addressCounter + 3;
								} else {
									System.out.println("Bad Operator On Line " + (i+1));
									return 1;
								}
							} else {
								System.out.println("Bad Conditional On Line " + (i+1));
								return 1;
							}
						}
					} else if (args[0].equals("FORFIT") && args.length == 1) {
						firstStage = firstStage + "1600CD!";
						addressCounter = addressCounter + 5;
					} else if (args[0].equals("RETURN") && args.length == 1) {
						firstStage = firstStage + "C9";
						addressCounter++;
					} else if (args[0].equals("INC") && args.length == 2) {
						firstStage = firstStage + "21[" + args[1] + "]34";
						addressCounter = addressCounter + 4;
					} else if (args[0].equals("DEC") && args.length == 2) {
						firstStage = firstStage + "21[" + args[1] + "]35";
						addressCounter = addressCounter + 4;
					} else if (args[0].equals("SPLIT") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 3) {
							if(prepareBytePrimitive(subArgs[0],i) == 1) return 1;
							firstStage = firstStage + "47E60F";
							addressCounter = addressCounter + 3;
							if(prepareByteTargetPrimitive(subArgs[1],i) == 1) return 1;
							firstStage = firstStage + "78E6F0CB0FCB0FCB0FCB0F";
							addressCounter = addressCounter + 11;
							if(prepareByteTargetPrimitive(subArgs[2],i) == 1) return 1;
						}
					} else if (args[0].equals("PIDSTAT") && args.length == 2) {
						String subArgs[] = args[1].split(",");
							if (subArgs.length == 2) {
							if(prepareBytePrimitive(subArgs[0],i) == 1) return 1;
							firstStage = firstStage + "16035FCD!7B";
							addressCounter = addressCounter + 7;
							if(prepareByteTargetPrimitive(subArgs[1],i) == 1) return 1;
						}
					} else if (args[0].equals("GETPID") && args.length == 2) {
						firstStage = firstStage + "1609CD!7B";
						addressCounter = addressCounter + 6;
						if(prepareByteTargetPrimitive(args[1],i) == 1) return 1;
					} else if (args[0].equals("INITPRG") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 2) {
							if(prepareBytePrimitive(subArgs[0],i) == 1) return 1;
							firstStage = firstStage + "161C5FCD!7A";
							addressCounter = addressCounter + 7;
							if(prepareByteTargetPrimitive(subArgs[1],i) == 1) return 1;
						}
					} else if (args[0].equals("LOADPRG") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 2) {
							if (isSymbolShort(subArgs[0]) && isSymbolMem(subArgs[1])) {
								firstStage = firstStage + "16201E18CD!16201E06CD!16203A[" + subArgs[0] + "]5FCD!" + "16203A[" + subArgs[0] + "+1]5FCD!16201E00CD!16201E00CD!16203A[" + subArgs[1] + "]5FCD!" + "16203A[" + subArgs[1] + "+1]5FCD!";
								//firstStage = firstStage + "16201E18CD!";
								//addressCounter = addressCounter + 7;
								addressCounter = addressCounter + 64;
							}
						}
					} else if (args[0].equals("WRITEPRG") && args.length == 2) {
						String subArgs[] = args[1].split(",");
						if (subArgs.length == 2) {
							if(prepareBytePrimitive(subArgs[0],i) == 1) return 1;
							firstStage = firstStage + "161D5FCD!7A";
							addressCounter = addressCounter + 7;
							if(prepareByteTargetPrimitive(subArgs[1],i) == 1) return 1;
						}
					} else if (args[0].equals("PONG") && args.length == 2) {
						firstStage = firstStage + "3A[" + args[1] + "]5F1621CD!";
						addressCounter = addressCounter + 9;
					} else if (args[0].equals("PING") && args.length == 2) {
						if(prepareBytePrimitive(args[1],i) == 1) return 1;
						firstStage = firstStage + "5F1621CD!";
						addressCounter = addressCounter + 6;
					} else if (args[0].equals("KILL") && args.length == 2) {
						if(prepareBytePrimitive(args[1],i) == 1) return 1;
						firstStage = firstStage + "5F1601CD!";
						addressCounter = addressCounter + 6;
						if(prepareBytePrimitive(args[1],i) == 1) return 1;
						firstStage = firstStage + "5F1610CD!";
						addressCounter = addressCounter + 6;
						if(prepareBytePrimitive(args[1],i) == 1) return 1;
						firstStage = firstStage + "5F160ACD!";
						addressCounter = addressCounter + 6;
						
					} else if (args[0].equals("FREEMEM") && args.length == 2) {
						if (isSymbolShort(args[1])) {
							firstStage = firstStage + "160ECD!7B32[" + args[1] + "]3E0032[" + args[1] + "+1]";
							addressCounter = addressCounter + 14;
						} 
					} else if (args[0].equals("FREESEC") && args.length == 2) {
						if (isSymbolShort(args[1])) {
							firstStage = firstStage + "160FCD!7B32[" + args[1] + "]3E0032[" + args[1] + "+1]";
							addressCounter = addressCounter + 14;
						} 
					} else if (args[0].equals("CLOCK1") && args.length == 2) {
						firstStage = firstStage + "1604CD!7B";
						addressCounter = addressCounter + 6;
						if(prepareByteTargetPrimitive(args[1],i) == 1) return 1;
					} else if (args[0].equals("CLOCK2") && args.length == 2) {
						firstStage = firstStage + "1605CD!7B";
						addressCounter = addressCounter + 6;
						if(prepareByteTargetPrimitive(args[1],i) == 1) return 1;
					} else if (args[0].equals("CLOCK3") && args.length == 2) {
						firstStage = firstStage + "1606CD!7B";
						addressCounter = addressCounter + 6;
						if(prepareByteTargetPrimitive(args[1],i) == 1) return 1;
					} else if (args[0].equals("CLOCK4") && args.length == 2) {
						firstStage = firstStage + "1607CD!7B";
						addressCounter = addressCounter + 6;
						if(prepareByteTargetPrimitive(args[1],i) == 1) return 1;
					} else {
						System.out.println("Unidentified Symbol On Line " + (i+1));
						return 1;
					}
				}
			}
			i++;
		}
		
		System.out.println("Finished Compiling Primary Stage At 0X" + decToHex(addressCounter,4));
		System.out.println("Compiled Primary Stage " + firstStage);
		int blocksLong = (int) Math.floor((addressCounter * 1.0) / 256);
		blocksLong = blocksLong + 2;
		System.out.println("Resulting Binary " + (addressCounter - 0) + " Bytes Long (" + blocksLong + " Blocks Long)");
		System.out.println("Loaded Binary " + (addressCounter) + " Bytes Long");
		
		String binary = decToAscii(blocksLong);
		i = 0;
		while (i != firstStage.length()) {
			char c = firstStage.charAt(i);
			if (c == '!') {
				binary =  binary + hexToAscii("1B") + hexToAscii("42");
			} else if (c == '[') {
				i++;
				String symbolName = "";
				while (firstStage.charAt(i) != ']' && firstStage.charAt(i) != '+') {
					symbolName = symbolName + firstStage.charAt(i);
					i++;
				}
				int offset = 0;
				if (firstStage.charAt(i) == '+') {
					i++;
					String value = "";
					while (firstStage.charAt(i) != ']') {
						value = value + firstStage.charAt(i);
						i++;
					}
					offset = Integer.valueOf(value);
				}
				String hexValue = getHexValueOfSymbol(symbolName,offset+256);
				if (hexValue.equals("!ERR")) {System.out.println("Bad Label " + symbolName); return 1;}
				binary = binary + prepareByte(getLowByte(hexValue)) + hexToAscii("1B") + hexToAscii("41") + prepareByte(getHighByte(hexValue));
			} else {
				String hex = c + "" + firstStage.charAt(i+1);
				i++;
				//System.out.println(i);
				if (hex.equals("1B")) binary = binary + hexToAscii("1B") + ((char) 0);
				else binary = binary + hexToAscii(hex);
			}
			i++;
		}
		binary = binary + hexToAscii("1B");
		binary = binary + hexToAscii("03");
		System.out.println("Written " + binary.length() + " Bytes");
		try {
			OutputStream f = new FileOutputStream(out);
			i = 0;
			while (binary.length() != i) {
				//System.out.println((int) binary.charAt(i));
				f.write(binary.charAt(i));
				i++;
			}
			f.close();
		} catch (IOException e) {
			System.out.println("Invalid File");
			return 1;
		}
		return 0;
	}
	
	public String prepareByte(char s) {
		if (s == 27) {
			return s + "" + ((char) 0);
		}
		return s + "";
	}
	
	public int prepareByteTargetPrimitive(String target, int i) {
		if (isSymbolByte(target)) {
			firstStage = firstStage + "32[" + target + "]";
			addressCounter = addressCounter + 3;
			return 0;
		}
		if (isAddressable(target)) {
			String name = getAddressableSymbolName(target);
			String arg = getAddressableSymbolArgument(target);
			if (isSymbolString(name)) {
				if (isInteger(arg)) {
					int value = Integer.valueOf(arg);
					if (value>65535 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
					firstStage = firstStage + "32[" + name + "+" + value + "]";
					addressCounter = addressCounter + 3;
					return 0;
				} else if (isSymbolShort(arg)) {
					firstStage = firstStage + "21[" + name + "]ED5B[" + arg + "]1977";
					addressCounter = addressCounter + 9;
					return 0;
				} else {
					firstStage = firstStage + "4F";
					addressCounter++;
					if(prepareBytePrimitive(arg,i) == 1) return 1;
					firstStage = firstStage + "21[" + name + "]5F16001971";
					addressCounter = addressCounter + 8;
					return 0;
				}
				
			}
			if (isSymbolShort(name)) {
				if (arg.equals("0")) {
					firstStage = firstStage + "32[" + name + "]";
					addressCounter = addressCounter + 3;
					return 0;
				} 
				if (arg.equals("1")) {
					firstStage = firstStage + "32[" + name + "+1]";
					addressCounter = addressCounter + 3;
					return 0;
				}
				System.out.println("Target Error On Line " + (i+1));
				return 1;
			}
			if (isSymbolMem(name)) {
				if (isInteger(arg)) {
					int value = Integer.valueOf(arg);
					if (value>65535 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
					firstStage = firstStage + "473A[" + name + "]21" + swapHighLowBytes(decToHex(value,4)) + "846770";
					addressCounter = addressCounter + 10;
					return 0;
				} else if (isSymbolShort(arg)) {
					firstStage = firstStage + "473A[" + name + "]2A[" + arg + "]846770";
					addressCounter = addressCounter + 10;
					return 0;
				} else {
					firstStage = firstStage + "47";
					addressCounter++;
					if(prepareBytePrimitive(arg,i) == 1) return 1;
					firstStage = firstStage + "6F3A[" + name + "]6770";
					addressCounter = addressCounter + 6;
					return 0;
				}
			}
		}
		System.out.println("Target Error On Line " + (i+1));
		System.out.println(source.get(i));
		System.out.println(target);
		return 1;
	}
	
	public int prepareBytePrimitive(String argument, int i) {
		if (isInteger(argument)) {
			int value = Integer.valueOf(argument);
			if (value>255 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
			firstStage = firstStage + "3E" + decToHex(value,2);
			addressCounter = addressCounter + 2;
			return 0;
		}
		if (isSymbolByte(argument)) {
			firstStage = firstStage + "3A[" + argument + "]";
			addressCounter = addressCounter + 3;
			return 0;
		}
		if (isAddressable(argument)) {
			String name = getAddressableSymbolName(argument);
			String arg = getAddressableSymbolArgument(argument);
			if (isSymbolString(name)) {
				if (isInteger(arg)) {
					int value = Integer.valueOf(arg);
					if (value>65535 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
					firstStage = firstStage + "3A[" + name + "+" + value + "]";
					addressCounter = addressCounter + 3;
					return 0;
				} else if (isSymbolShort(arg)) {
					firstStage = firstStage + "21[" + name + "]ED5B[" + arg + "]197E";
					addressCounter = addressCounter + 9;
					return 0;
				} else {
					if(prepareBytePrimitive(arg,i) == 1) return 1;
					firstStage = firstStage + "21[" + name + "]5F1600197E";
					addressCounter = addressCounter + 8;
					return 0;
				}
			}
			if (isSymbolShort(name)) {
				if (arg.equals("0")) {
					firstStage = firstStage + "3A[" + name + "]";
					addressCounter = addressCounter + 3;
					return 0;
				}
				if (arg.equals("1")) {
					firstStage = firstStage + "3A[" + name + "+1]";
					addressCounter = addressCounter + 3;
					return 0;
				}
			}
			if (isSymbolMem(name)) {
				if (isInteger(arg)) {
					int value = Integer.valueOf(arg);
					if (value>65535 || value<0) {System.out.println("Value Error On Line " + (i+1)); return 1;}
					firstStage = firstStage + "3A[" + name + "]21" + swapHighLowBytes(decToHex(value,4)) + "84677E";
					addressCounter = addressCounter + 9;
					return 0;
				} else if (isSymbolShort(arg)) {
					firstStage = firstStage + "3A[" + name + "]2A[" + arg + "]84677E";
					addressCounter = addressCounter + 9;
					return 0;
				} else {
					if(prepareBytePrimitive(arg,i) == 1) return 1;
					firstStage = firstStage + "6F3A[" + name + "]677E";
					addressCounter = addressCounter + 6;
					return 0;
				}
			}
		}
		System.out.println("Invalid Argument On Line " + (i+1)); 
		return 1;
	}
	
	public boolean isAddressable(String symbol) {
		return (!getAddressableSymbolName(symbol).equals("!ERR")) && (!getAddressableSymbolArgument(symbol).equals("!ERR"));
	}
	
	public String getAddressableSymbolName(String symbol) {
		String name = "";
		int i = 0;
		//System.out.println(symbol);
		while (symbol.charAt(i) != '[') {
			name = name + symbol.charAt(i);
			i++;
			if (i == symbol.length()) break;
		}
		if (i == symbol.length()) name = "!ERR";
		return name;
	}
	
	public String getAddressableSymbolArgument(String symbol) {
		String arg = "";
		int i = 0;
		while (symbol.charAt(i) != '[' && i != symbol.length()) {
			i++;
		}
		if (i == symbol.length()) return "!ERR";
		i++;
		if (i == symbol.length()) return "!ERR";
		int offset = 0;
		while (symbol.charAt(i) != ']' || offset != 0) {
			if (symbol.charAt(i) == '[') offset++;
			if (symbol.charAt(i) == ']') offset--;
			arg = arg + symbol.charAt(i);
			i++;
			if (i == symbol.length()) break;
		}
		if (i == symbol.length()) arg = "!ERR";
		return arg;
	}
	

	public String getHexValueOfSymbol(String symbol,int o) {
		if (isSymbolByte(symbol)) {
			return decToHex(byteTable.get(symbol)+o,4);
		} if (isSymbolLabel(symbol)) {
			return decToHex(labelTable.get(symbol)+o,4);
		} if (isSymbolShort(symbol)) {
			return decToHex(shortTable.get(symbol)+o,4);
		} if (isSymbolString(symbol)) {
			return decToHex(stringTable.get(symbol)+o,4);
		} if (isSymbolMem(symbol)) {
			return decToHex(memTable.get(symbol)+o,4);
		}else {
			return "!ERR";
		}
	}
	
	public boolean isSymbolByte(String symbol) {
		return byteTable.containsKey(symbol);
	}
	
	public boolean isSymbolString(String symbol) {
		return stringTable.containsKey(symbol);
	}
	
	public boolean isSymbolShort(String symbol) {
		return shortTable.containsKey(symbol);
	}
	
	public boolean isSymbolLabel(String symbol) {
		return labelTable.containsKey(symbol);
	}
	
	public boolean isSymbolMem(String symbol) {
		return memTable.containsKey(symbol);
	}
	
	public String swapHighLowBytes(String in) {
		String high = in.charAt(0) + "" +  in.charAt(1);
		String low = in.charAt(2) + "" + in.charAt(3);
		return low+high;
	}
	
	public char getHighByte(String in) {
		String high = in.charAt(0) + "" +  in.charAt(1);
		return (char) hexToDec(high);
	}
	
	public char getLowByte(String in) {
		String low = in.charAt(2) + "" + in.charAt(3);
		return (char) hexToDec(low);
	}
	
	public String prepareSymbol(String symbol) {
		if (symbol.length() > 200) symbol = symbol.substring(0, 8);
		symbol.toUpperCase();
		return symbol;
	}
	
	public boolean doesSymbolExist(String symbol) {
		boolean exists = false;
		if (labelTable.containsKey(symbol)) exists = true;
		if (byteTable.containsKey(symbol)) exists = true;
		if (shortTable.containsKey(symbol)) exists = true;
		if (stringTable.containsKey(symbol)) exists = true;
		if (memTable.containsKey(symbol)) exists = true;
		return exists;
	}
	
	public String decToAscii(int i) {
		return ((char) i) + "";
	}
	
	public int asciiToDec(String ascii) {
		return hexToDec(asciiToHex(ascii));
	}
	
	public String hexToAscii(String hexStr) {
	    StringBuilder output = new StringBuilder("");
	     
	    for (int i = 0; i < hexStr.length(); i += 2) {
	        String str = hexStr.substring(i, i + 2);
	        //System.out.println(str);
	        output.append((char) Integer.parseInt(str, 16));
	    }
	     
	    return output.toString();
	}
	
	public String asciiToHex(String asciiStr) {
	    char[] chars = asciiStr.toCharArray();
	    StringBuilder hex = new StringBuilder();
	    for (char ch : chars) {
	    	String hexString = Integer.toHexString((int) ch);
	    	if (hexString.length() == 1) {
	    		hexString = "0" + hexString;
	    	}
	        hex.append(hexString);
	    }
	 
	    return hex.toString();
	}
	
	public int hexToDec(String hex) {
		return Integer.parseInt(hex, 16);
	}
	
	public String decToHex(int i, int l) {
		String out = Integer.toHexString(i).toUpperCase(); 
		if (l != -1) {
			while (out.length() < l) {
				out = "0" + out;
			}
			while (out.length() > l) {
				out = out.substring(1, out.length());
			}
		}
		return out;
	}
	
	public String deSpace(String s) {
		while ((s.charAt(0) == ' ' || s.charAt(0) == '	')) {
			s = s.substring(1, s.length());
			if (s.length() == 0) {
				break;
			}
		}
		return s;
	}

	public String putInString(String str, int pos, char c) {
		while (pos >= str.length()) {
			str = str + (char) 0;
		}
		str = str.substring(0,pos) + c + str.substring(pos + 1);
		return str;
	}
	
	public static boolean isInteger(String s) {
	    return isInteger(s,10);
	}

	public static boolean isInteger(String s, int radix) {
	    if(s.isEmpty()) return false;
	    for(int i = 0; i < s.length(); i++) {
	        if(i == 0 && s.charAt(i) == '-') {
	            if(s.length() == 1) return false;
	            else continue;
	        }
	        if(Character.digit(s.charAt(i),radix) < 0) return false;
	    }
	    return true;
	}
}

