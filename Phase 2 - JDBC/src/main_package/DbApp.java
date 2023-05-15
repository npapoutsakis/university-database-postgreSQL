//			PLH303 - Phase 2

//	Authors: Papoutsakis Nikolaos 2019030206
//			 Siganos Swkratis 	  2019030097

package main_package;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.*;
import java.util.concurrent.TimeUnit;

public class DbApp {
	
	private Connection db_connection;
	
	public DbApp() {
		this.db_connection = null;
	}
	

	public void launch() {
		
		System.out.println("Starting connection....");
		
		try {		
			// Load Driver
			Class.forName("org.postgresql.Driver");
			
			// Connect to database
			db_connect("localhost", "5432", "PLH303_LAB", "postgres", "123");
			
			// Application started
			checkUserInput();
			
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return;
	}
	
	
	// Terminates connection with database
	public void end_session() {
		System.out.println("Terminating connection....");
		
		db_terminate_connection();
		
		// Add a delay of 1.2 sec, just for fun :)
		try {
			TimeUnit.SECONDS.sleep(1);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		
		System.out.println("\n\nTerminated! See Ya!");
		
		return;
	}
	

	private void db_connect(String ip, String port, String db_name, String username, String password) {
		try {
			db_connection = DriverManager.getConnection("jdbc:postgresql://" + ip + ":" + port + "/" + db_name, username, password);	
		} catch (SQLException e) {
			System.out.println("Connection not established");
		}	
		return;
	}


	private void db_terminate_connection() {
		try {
			db_connection.close();
		}
		catch (SQLException e) {
			System.out.println("Connection did not terminate successfully");
		}
	}
	
	
	// Input Handler
	public void checkUserInput() {
		
		int choice = Integer.MIN_VALUE;
		
		// If user input is 5, then terminate connection
		while(choice != 5) {
				
			// print menu
			printMenu();
			
			// Get choice from user
			choice = readPositiveInt("");
			
			switch(choice) {
				case 1:
					getStudentGrade();
					break;
				case 2:
					changeStudentGrade();
					break;
				case 3:
					
					break;
				case 4:
					
					break;
				case 5:
					end_session();
					break;
				default:
					System.out.println("ERROR: Invalid Input. Try Again!");
			}
		}
	
		return;
	}
	
	private void changeStudentGrade() {
		
		
		
		
		waitUser();
		return;
	}
	
	
	// 1.1
	private void getStudentGrade() {		
		// Statement with parameters
		PreparedStatement pr_statement;

		try {
			pr_statement = 
			this.db_connection.prepareStatement("SELECT s.am, r.course_code, r.final_grade, r.exam_grade, r.lab_grade, r.register_status FROM \"Register\" r\r\n"
					+ "INNER JOIN \"Student\" s USING (amka)\r\n"
					+ "WHERE am = ?\r\n"
					+ "AND course_code = ?\r\n"
					+ "AND r.serial_number = (\r\n"
					+ "		SELECT MAX(serial_number) FROM \"Register\" WHERE amka = (\r\n"
					+ "			SELECT amka FROM \"Student\" \r\n"
					+ "			WHERE am = ?\r\n"
					+ "			AND course_code = ?\r\n"
					+ "		)\r\n"
					+ ")");
											
			// Get info
			String am = readString("Give student AM: ");
			String c_code = readString("Give Course Code: ");		
			
			// Setting parameters
			pr_statement.setString(1, am);
			pr_statement.setString(2, c_code);
			pr_statement.setString(3, am);
			pr_statement.setString(4, c_code);
				
			// Get returned data
			ResultSet output = pr_statement.executeQuery();
			
			if(output.next()) {
				System.out.println("\nAM: "+am+"\nCourse: "+c_code+"\nFinal Grade: "+output.getInt(3)+"\nExam Grade: "+output.getFloat(4)+"\nLab Grade: "+output.getFloat(5));
				System.out.println("Status: "+ output.getString(6).toUpperCase()+"\n");
			}
			else 
				System.out.println("Cannot find such pair");
		
		}	
		catch(Exception e){
			e.printStackTrace();
		}
		
		waitUser();
		
		return;
	}
	
	
	/**
	 * It reads an positive integer, zero included, from standard input
	 * and returns it as value. In case of an error it returns -1
	 * 
	 * @param message The message that is appeared to the user asking for input
	 */
	private int readPositiveInt(String message) {	
		BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
		String str;
		int num;
		
		System.out.print(message);			
		try {
			str = in.readLine();
			num = Integer.parseInt(str);
			if (num < 0 ){
				return -1;
			}
			else {
				return num;
			}			
		}
		catch (IOException e) {			
			return -1;
		}
		catch (NumberFormatException e1) {			
			return -1;
		}
	}
	
	
	/**
	 * It reads a string from standard input and returns it as value. 
	 * In case of an error it returns null
	 * 
	 * @param message The message that is appeared to the user asking for input
	 */
	private String readString(String message) {
		BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
		System.out.print(message);
		try {
			return in.readLine();	
		}
		catch (IOException e) {
			return null;
		}			
	}

	
	private void waitUser() {
		readString("Press Any Key to continue...");
		return;
	}

	// Printing choice menu
	private void printMenu() {
		System.out.println("\n\n-------------JAVA JDBC API----------------");		
		System.out.println("Select one of the available choices:\n");
		System.out.println("1. Get course grade of student............");
		System.out.println("2. Change student grade...................");
		System.out.println("3. TODO");
		System.out.println("4. TODO");
		System.out.println("5. Exit Application.......................");
		System.out.println("------------------------------------------");
		System.out.print("Choice: ");
		return;
	}
	
}
