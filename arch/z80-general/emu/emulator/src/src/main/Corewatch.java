package main;

import java.awt.Color;
import java.awt.Font;
import java.awt.FontFormatException;
import java.io.IOException;
import java.io.InputStream;

import javax.swing.JFrame;
import javax.swing.JTextArea;

public class Corewatch extends JFrame{
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	public JTextArea text;
	
	private final int sizeX = 391;
	private final int sizeY = 245;
	
	private int c = 0;
	
	private byte buffer[] = new byte[0x100];
	
	private String createBlankDisplay() {
		String out = "";
		int i = 0;
		while (i != 16) {
			out = out + "00000000000000000000000000000000\n";
			i++;
		}
		return out;
	}
	
	public void setWatchPoint(int w) {
		this.setTitle("Corewatch @ 0X" + decToHex(w,4));
	}
	
	public void resetBuffer() {
		c = 0;
	}
	
	public void writeByte(byte b) {
		buffer[c] = b;
		c++;
	}
	
	public void redrawDisplay() {
		int i = 0;
		int c = 0;
		String out = "";
		while (i != 16) {
			int o = 0;
			while (o != 16) {
				out = out + decToHex(buffer[c],2);
				c++;
				o++;
			}
			out = out + "\n";
			i++;
		}
		text.setText(out);
	}
	
	public Corewatch() {
		Font font = null;
		InputStream is = Corewatch.class.getResourceAsStream("/res/c64ProMono.ttf");
		try {
			Font tFont = Font.createFont(Font.PLAIN, is);
			font = tFont.deriveFont(Font.PLAIN, 12);
		} catch (FontFormatException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		text = new JTextArea(createBlankDisplay());
		text.setBounds(0,0,sizeX,sizeY);
		text.setEditable(false);
		text.setFocusable(true);
		text.setBackground(Color.BLACK);
		text.setForeground(Color.GREEN);
		text.setFont(font);
		this.add(text);
		this.setTitle("Corewatch @ 0X0000");
		this.setResizable(false);
		this.setSize(sizeX, sizeY);
		this.setLayout(null);
		this.setVisible(true);
		this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
	}
	
	private String decToHex(int i, int l) {
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
}
