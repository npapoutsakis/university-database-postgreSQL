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
		
		// Add a delay of 1s, just for fun :)
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
					getAnalyticalAssessment();
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
	
	
	// 1.4
	private void getAnalyticalAssessment() {
		
		// Statement with parameters
		PreparedStatement nameStatement, gradesStatement;
		
		try {
			
			String studentInfoQuery = "SELECT s.am, p.name, p.surname FROM \"Person\" p\r\n"
									+ "INNER JOIN \"Student\" s ON s.amka = p.amka\r\n"
									+ "WHERE am =  ?\r\n"
									+ "";
			
			
			String getGradesQuery = "SELECT DISTINCT  \r\n"
									+ "	cr.semesterrunsin - (\r\n"
									+ "			SELECT MIN(cr.semesterrunsin) \r\n"
									+ "			FROM \"CourseRun\" cr \r\n"
									+ "			INNER JOIN \"Register\" r ON (cr.course_code = r.course_code AND cr.serial_number = r.serial_number) \r\n"
									+ "			WHERE r.amka = s.amka) + 1 AS \"SemesterNo\", \r\n"
									+ "c.course_title, cr.course_code, r.final_grade, r.register_status\r\n"
									+ "FROM \"Student\" s\r\n"
									+ "INNER JOIN \"Register\" r ON r.amka = s.amka\r\n"
									+ "INNER JOIN \"CourseRun\" cr ON (cr.course_code = r.course_code AND cr.serial_number = r.serial_number)\r\n"
									+ "INNER JOIN \"Semester\" sem ON sem.semester_id = cr.semesterrunsin\r\n"
									+ "INNER JOIN \"Course\" c ON c.course_code = cr.course_code\r\n"
									+ "WHERE am = ? AND r.register_status IN ('pass', 'fail')\r\n"
									+ "ORDER BY \"SemesterNo\"";
			
			//First get the student info
			nameStatement = db_connection.prepareStatement(studentInfoQuery);
			
			// Get student am
			String am = readString("Give student AM: ");
			
			nameStatement.setString(1, am);
			
			// Execute first query
			ResultSet studentInfo = nameStatement.executeQuery();
			
			// Check if has info
			if(!studentInfo.next()) {
			   
				//ResultSet is empty
			    System.out.println("Cannot find AM in database!");
			    
			    //Release
			    studentInfo.close();
			    nameStatement.close();
			    
			    waitUser();
			    
			    return;
			} 
			else {
			    
				String name, surname;
				
				name = studentInfo.getString(2);
				surname = studentInfo.getString(3);
				
				System.out.println("\n\t\t\t#Analytical Assessment#");
				System.out.println("Student Info: ");
				System.out.println("\tAM:      "+am);
				System.out.println("\tName:    "+name);
				System.out.println("\tSurname: "+surname+"\n");
				
				// made the first row, now access database to get grades aka new execution		    
				// Do not need them any more
				studentInfo.close();
			    nameStatement.close();
			    
			    // Prepare grade query
			    gradesStatement = db_connection.prepareStatement(getGradesQuery);
			    gradesStatement.setString(1, am);
			    
			    ResultSet grades = gradesStatement.executeQuery();
			    
		        // Header
		        System.out.printf("\t%-15s%-8s%-10s%-10s\n", "Course Code", "Grade", "Status", "Course Title");
			    
		        
		        if(!grades.next()) {
					
		        	//ResultSet is empty
				    System.out.println("Student has no grades at all!");
				    
				    //Release
				    grades.close();
				    gradesStatement.close();
				    
				    waitUser();
				    
				    return;	
		        }
		        else {
		        	
		        	int id = grades.getInt(1);
		        	
				    // Gather info
		        	System.out.printf("\n\tSemester ID: %d\n", id);
		        	System.out.printf("\t %-15s%-8s%-10s%-10s\n", grades.getString(3), grades.getFloat(4),grades.getString(5).toUpperCase(), grades.getString(2));
				    
		        	while(grades.next()) {	        
				        // Change id when semester changes
				    	if(grades.getInt(1) != id) {
				    		id = grades.getInt(1);
				    		System.out.printf("\n\tSemester ID: %d\n", id);
				    	}	
				    	// Print table rows
				        System.out.printf("\t %-15s%-8s%-10s%-10s\n", grades.getString(3), grades.getFloat(4),grades.getString(5).toUpperCase(), grades.getString(2));
				    }
				    
				    System.out.printf("\n");
				    
				    // Release
				    grades.close();
				    gradesStatement.close();
		        	
		        }   
		        
			}
			
		} 
		catch (SQLException e) {
			e.printStackTrace();
		}
		
		waitUser();
		
		return;
	}
	
	
	// 1.2
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
			this.db_connection.prepareStatement("SELECT s.am, r.course_code, r.final_grade, r.exam_grade, r.lab_grade, r.register_status "
					+ "FROM \"Register\" r\r\n"
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
		
			pr_statement.close();
			
			output.close();
			
		}	
		catch(Exception e){
			e.printStackTrace();
		}
		
		waitUser();
		
		return;
	}
	
	
	// It reads an positive integer, zero included, from standard input and returns it as value. In case of an error it returns -1
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
	
	
	//It reads a string from standard input and returns it as value. In case of an error it returns null
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
		System.out.println("4. Analytical assessment of student.......");
		System.out.println("5. Exit Application.......................");
		System.out.println("------------------------------------------");
		System.out.print("Choice: ");
		return;
	}
	
}
