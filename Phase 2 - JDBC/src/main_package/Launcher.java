package main_package;

public class Launcher {

	public static void main(String[] args) {	
		DbApp app = new DbApp();
	
		// Start connection to database using driver and prints choice menu
		app.launch();
		
		return;
	}
	
}
