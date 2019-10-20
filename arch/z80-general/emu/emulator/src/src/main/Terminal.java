package main;

import java.awt.Color;
import java.awt.Font;
import java.awt.FontFormatException;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.swing.JFrame;
import javax.swing.JTextArea;

public class Terminal extends JFrame{
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	public JTextArea text;
	
	public List<Character> outputBuffer = Collections.synchronizedList(new ArrayList<Character>()); 
	
	private final int sizeX = 487;
	private final int sizeY = 367;
	private final int col = 40;
	
	private int cCounter = 0;
	
	public boolean hasNextChar() {
		return outputBuffer.size() != 0;
	}
	
	public int popNextChar() {
		if (hasNextChar()) {
			int out = outputBuffer.get(0);
			outputBuffer.remove(0);
			return out;
		}
		return 0;
	}
	
	public void print(char c) {
		if (!(c == 65535 || c == 8 || c == 0 || c == 27)) {
			text.setText(text.getText() + c);
			if (c == 10) {
				cCounter = 0;
			} else {
				cCounter++;
				if (cCounter == col) {
					text.setText(text.getText() + "\n");
					cCounter = 0;
				} 
			}
			if (countLines(text.getText()) > 25) {
				while (text.getText().charAt(0) != 10) {
					text.setText(text.getText().substring(1));
				}
				text.setText(text.getText().substring(1));
			}
		} else if (c == 8 && text.getText().length() != 0) {
			text.setText(text.getText().substring(0, text.getText().length() - 1));
		}
	}
	
	public int countLines(String str){
	    if(str == null || str.isEmpty())
	    {
	        return 0;
	    }
	    int lines = 1;
	    int pos = 0;
	    while ((pos = str.indexOf("\n", pos) + 1) != 0) {
	        lines++;
	    }
	    return lines;
	}
	
	public Terminal() {
		Font font = null;
		InputStream is = Terminal.class.getResourceAsStream("/res/c64ProMono.ttf");
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
		
		text = new JTextArea("");
		text.setBounds(0,0,sizeX,sizeY);
		text.setEditable(false);
		text.setFocusable(true);
		text.addKeyListener(new KeyboardAdapter(this));
		text.setBackground(Color.BLACK);
		text.setForeground(Color.GREEN);
		text.setFont(font);
		this.add(text);
		this.setTitle("MICRONBox V1.0");
		this.setResizable(false);
		this.setSize(sizeX, sizeY);
		this.setLayout(null);
		this.setVisible(true);
		this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
	}
}
