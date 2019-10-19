package main;

import java.io.File;
import java.io.IOException;
import java.util.Scanner;

import com.Compiler;



public class Main {
	
	private static Scanner sc = new Scanner(System.in);
	private static Compiler com = new Compiler();
	
	public static void main(String[] args) {
		System.out.println("MICRON BASIC Compiler");
		System.out.println("V1.0, Gavin Tersteeg");
		
		String sfin = "";
		String sfout = "";
		
		if (args.length != 2) {
			System.out.println("Input File?");
			sfin = sc.nextLine();
			System.out.println("Output File?");
			sfout = sc.nextLine();
		} else {
			sfin = args[0];
			sfout = args[1];
		}
		File fin = new File(sfin);
		File fout = new File(sfout);
		
		if (!fout.exists()) {
			try {
				fout.createNewFile();
			} catch (IOException e) {
				System.out.println("Cannot Create File!");
			}
		}
		
		if (fin.exists() && fin.isFile() && fout.exists() && fout.isFile()) {
			if (com.compile(fin, fout) == 0) {
				System.out.println("Compiler Success!");
			}   else {
				System.out.println("Compiler Incomplete!");
			}
		} else {
			System.out.println("Invalid Files");
		}
		
		System.out.println("Done");
		sc.close();
	}
}
