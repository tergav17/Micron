package main;

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;

public class KeyboardAdapter implements KeyListener {
	
	Terminal t;
	
	public KeyboardAdapter(Terminal term) {
		t = term;
	}

	@Override
	public void keyPressed(KeyEvent e) {
		if (!(e.getKeyChar() == 65535 || e.getKeyChar() == 0 || e.getKeyChar() == 0)) { 
			t.outputBuffer.add(e.getKeyChar());
		}
	}

	@Override
	public void keyReleased(KeyEvent e) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void keyTyped(KeyEvent e) {
		// TODO Auto-generated method stub
		
	}

}
