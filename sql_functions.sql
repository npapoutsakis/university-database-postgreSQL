-- Phase 1
-- Σιγανός Σωκράτης  2019030097
-- Παπουτσάκης Νίκος 2019030206


-- HELPERS

-- https://stackoverflow.com/questions/38619072/how-to-replace-multiple-special-characters-in-postgres-9-5
-- Used for translating greek to english characters for email creation
CREATE OR REPLACE FUNCTION TRANSLATE_GREEK_ENGLISH(text)
RETURNS text AS $$
DECLARE
	text_from text[] := ARRAY['α','β','γ','δ','ε','ζ','η','θ','ι','κ','λ','μ','ν','ξ','ο','π','ρ','σ','τ','υ','φ','χ','ψ','ω'];
	text_to text[] := ARRAY['a','b','g','d','e','z','h','th','i','k','l','m','n','ks','o','p','r','s','t','u','f','h','ps','w'];
	res record;
BEGIN
   	SELECT string_agg(coalesce(text_to[array_position(text_from, c)],c),'') AS text INTO res
    FROM regexp_split_to_table($1,'') g(c);
	  
	RETURN res.text;
END;
$$ LANGUAGE plpgsql;
-- Usage: SELECT TRANSLATE_GREEK_ENGLISH(greek_lower_text);			



-- (2) Διαχείριση Δεδομένων 
-- 2.1

-- CREATE STUDENTS
CREATE OR REPLACE FUNCTION create_students(entries integer, entry_date text)
RETURNS VOID
AS $$
DECLARE
	i integer := 1;
	entry_year text := to_char(entry_date::date, 'yyyy'); -- grab entry year from entry_date
	last_entry_id_rec record;
	last_entry_id integer;
	name_rec record;
	father_name_rec record;
	surname_rec record;
	student_amka text;
	student_email text;
	email_num integer;
	student_am text;
	student_type integer; -- 0 or 1 depending if foreign student
BEGIN
	-- Get specified year's last entry's unique number (AAAAA)
	SELECT(substring(s.am from 6))::integer AS ID INTO last_entry_id_rec
	FROM "Student" s
	WHERE date_part('year', s.entry_date)::text = entry_year
	ORDER BY substring(s.am from 6) DESC
	LIMIT 1;
	
	IF last_entry_id_rec.ID IS NOT NULL THEN
		last_entry_id := last_entry_id_rec.ID;
	ELSE
		last_entry_id := 0;
	END IF;

	-- Start entries
	FOR i IN 1 .. entries LOOP
		-- PERSON
		-- Random values for name, father_name and surname
		SELECT name INTO name_rec FROM "Name" ORDER BY RANDOM() LIMIT 1;
		SELECT name INTO father_name_rec FROM "Name" WHERE sex = 'M' ORDER BY RANDOM() LIMIT 1; -- father_name must be male
		SELECT surname INTO surname_rec FROM "Surname" ORDER BY RANDOM() LIMIT 1;
		
		-- email (nickname || number || @tuc.gr)
		email_num := floor(random()*10000); -- random integer < 10000
		student_email := TRANSLATE_GREEK_ENGLISH(lower(substring(name_rec.name for 1)) || lower(substring(surname_rec.surname for 8))) || LPAD(email_num::text, 4, '0') || '@tuc.gr';
		
		-- STUDENT
		-- am numbers: entry_year || student_type || id
		student_type := floor(random()*100)::integer % 2; -- 0 or 1
		student_am := entry_year || student_type::text || LPAD((last_entry_id+i)::text, 5, '0'); -- left padding of text with zero's
		
		-- Generate amka, check that amka is unique
		LOOP
			student_amka := LPAD((random()*100000000000)::bigint::text, 11, '0');
			EXIT WHEN NOT EXISTS (SELECT 1 FROM "Person" p WHERE p.amka = student_amka);
		END LOOP;
		
		INSERT INTO "Person"(amka, name, father_name, surname, email)
			VALUES(student_amka, name_rec.name, father_name_rec.name, surname_rec.surname, student_email);
			
		INSERT INTO "Student"(amka, am, entry_date)
			VALUES(student_amka, student_am, entry_date::date);
	END LOOP;
END;
$$ LANGUAGE plpgsql;
-- Usage: SELECT create_students(220, '2009-01-01');

-- CREATE PROFESSORS
-- https://stackoverflow.com/questions/1677165/how-do-i-query-values-of-an-enum-in-postgresql
-- Used for querying enum_types: unnest(enum_range(NULL::rank_type))
CREATE OR REPLACE FUNCTION create_professors(entries integer)
RETURNS VOID
AS $$
DECLARE
	i integer;
	name_rec record;
	father_name_rec record;
	surname_rec record;
	professor_amka text;
	professor_email text;
	professor_rank_rec record;
	professor_lab_rec record;
	email_num integer;
BEGIN
	-- Start entries
	FOR i IN 1 .. entries LOOP
		-- PERSON
		-- Random values for name, father_name and surname
		SELECT name INTO name_rec FROM "Name" ORDER BY RANDOM() LIMIT 1;
		SELECT name INTO father_name_rec FROM "Name" WHERE sex = 'M' ORDER BY RANDOM() LIMIT 1; -- father_name must be male
		SELECT surname INTO surname_rec FROM "Surname" ORDER BY RANDOM() LIMIT 1;
		
		-- email (nickname || number || @tuc.gr)
		email_num := floor(random()*10000); -- random integer < 10000
		professor_email := TRANSLATE_GREEK_ENGLISH(lower(substring(name_rec.name for 1)) || lower(substring(surname_rec.surname for 8))) || LPAD(email_num::text, 4, '0') || '@tuc.gr';
		
		-- Generate amka, check that amka is unique
		LOOP
			professor_amka := LPAD((random()*100000000000)::bigint::text, 11, '0');
			EXIT WHEN NOT EXISTS (SELECT 1 FROM "Person" p WHERE p.amka = professor_amka);
		END LOOP;
		
		-- PROFESSOR
		SELECT lab_code INTO professor_lab_rec FROM "Lab" ORDER BY RANDOM() LIMIT 1;
		SELECT * INTO professor_rank_rec FROM unnest(enum_range(NULL::rank_type)) AS rank ORDER BY RANDOM() LIMIT 1;
		
		INSERT INTO "Person"(amka, name, father_name, surname, email)
			VALUES(professor_amka, name_rec.name, father_name_rec.name, surname_rec.surname, professor_email);
			
		INSERT INTO "Professor"(amka, labjoins, rank)
			VALUES(professor_amka, professor_lab_rec.lab_code, professor_rank_rec.rank);
	END LOOP;
END;
$$ LANGUAGE plpgsql;
--Usage: SELECT create_professors(3);

-- CREATE LAB TEACHERS
CREATE OR REPLACE FUNCTION create_lab_teachers(entries integer)
RETURNS VOID
AS $$
DECLARE
	i integer;
	name_rec record;
	father_name_rec record;
	surname_rec record;
	teacher_amka text;
	teacher_email text;
	teacher_level_rec record;
	teacher_lab_rec record;
	email_num integer;
BEGIN
	-- Start entries
	FOR i IN 1 .. entries LOOP
		-- PERSON
		-- Random values for name, father_name and surname
		SELECT name INTO name_rec FROM "Name" ORDER BY RANDOM() LIMIT 1;
		SELECT name INTO father_name_rec FROM "Name" WHERE sex = 'M' ORDER BY RANDOM() LIMIT 1; -- father_name must be male
		SELECT surname INTO surname_rec FROM "Surname" ORDER BY RANDOM() LIMIT 1;
		
		-- email (nickname || number || @tuc.gr)
		email_num := floor(random()*10000); -- random integer < 10000
		teacher_email := TRANSLATE_GREEK_ENGLISH(lower(substring(name_rec.name for 1)) || lower(substring(surname_rec.surname for 8))) || LPAD(email_num::text, 4, '0') || '@tuc.gr';
		
		-- Generate amka, check that amka is unique
		LOOP
			teacher_amka := LPAD((random()*100000000000)::bigint::text, 11, '0');
			EXIT WHEN NOT EXISTS (SELECT 1 FROM "Person" p WHERE p.amka = teacher_amka);
		END LOOP;
		
		-- LAB TEACHER
		SELECT lab_code INTO teacher_lab_rec FROM "Lab" ORDER BY RANDOM() LIMIT 1;
		SELECT * INTO teacher_level_rec FROM unnest(enum_range(NULL::level_type)) AS level ORDER BY RANDOM() LIMIT 1;
		
		INSERT INTO "Person"(amka, name, father_name, surname, email)
			VALUES(teacher_amka, name_rec.name, father_name_rec.name, surname_rec.surname, teacher_email);
			
		INSERT INTO "LabTeacher"(amka, labworks, level)
			VALUES(teacher_amka, teacher_lab_rec.lab_code, teacher_level_rec.level);
	END LOOP;
END;
$$ LANGUAGE plpgsql;
--Usage: SELECT create_lab_teachers(10);


--2.2

-- INSERT GRADES
CREATE OR REPLACE FUNCTION insert_random_grades(semester_id integer)
RETURNS VOID AS
$BODY$
DECLARE
	--Cursors, curs -> performs inner join and returns table with semester_id and register_status = 'approved'
	curs CURSOR FOR SELECT cr.serial_number, cr.course_code, r.amka, cr.lab_min, cr.exam_min, cr.exam_percentage FROM "CourseRun" cr
    			  	INNER JOIN "Register" r ON (cr.course_code = r.course_code AND cr.serial_number = r.serial_number)
				  	WHERE cr.semesterrunsin = semester_id AND r.register_status = 'approved';
	
	--reg_curs is a cursor that points to this specific query, if the function is called with random semester_id the register_status will be changed.
	--so the function will not perform any action
	reg_curs CURSOR FOR SELECT * FROM "Register" WHERE register_status = 'approved';
	
	--Variables
	cursor_data record;
	temp_exam_grade numeric;
	temp_lab_grade numeric;
	temp_final_grade numeric;
BEGIN
	
	IF semester_id <= 0 THEN
		RETURN;
	ELSE
		--open cursors
		OPEN curs;
		OPEN reg_curs;

 		LOOP
			--get attribute info and store
			--fetch moves cursor by 1 automatically
			FETCH curs INTO cursor_data;	
			
			EXIT WHEN NOT FOUND;
			
			--Move forward to take position in first row
			MOVE FORWARD 1 IN reg_curs;
			
			--Updates on Register table
			IF cursor_data.exam_percentage = 0 THEN		-- No Lab, final grade is same as exam grade		
				temp_exam_grade := FLOOR(random()*9 + 1);
				
				UPDATE "Register" SET exam_grade = temp_exam_grade, final_grade = temp_exam_grade WHERE CURRENT OF reg_curs;
				
				IF temp_exam_grade >= 5 THEN				
					UPDATE "Register" SET register_status = ('pass')::register_status_type WHERE CURRENT OF reg_curs;
				ELSE
					UPDATE "Register" SET register_status = ('fail')::register_status_type WHERE CURRENT OF reg_curs;
				END IF;
				
 			ELSE 										-- Has Lab, final grade is computed using exam_percentage
				temp_lab_grade := FLOOR(random()*9 + 1);
				temp_exam_grade := FLOOR(random()*9 + 1);
				
				IF temp_lab_grade < cursor_data.lab_min THEN
					UPDATE "Register" SET final_grade = 0, exam_grade = temp_exam_grade, lab_grade = temp_lab_grade, register_status = ('fail')::register_status_type WHERE CURRENT OF reg_curs;
				ELSIF temp_exam_grade < cursor_data.exam_min THEN
					UPDATE "Register" SET final_grade = temp_exam_grade, exam_grade = temp_exam_grade, lab_grade = temp_lab_grade, register_status = ('fail')::register_status_type WHERE CURRENT OF reg_curs;
				ELSE
					temp_final_grade := (temp_exam_grade*cursor_data.exam_percentage*0.01)+(1-(cursor_data.exam_percentage*0.01))*temp_lab_grade;
					
					UPDATE "Register" SET final_grade = temp_final_grade, exam_grade = temp_exam_grade, lab_grade = temp_lab_grade WHERE CURRENT OF reg_curs;
					
					-- If both exam and lab grades are accepted check if final is greater than 5.
					IF temp_final_grade >= 5 THEN
						UPDATE "Register" SET register_status = ('pass')::register_status_type WHERE CURRENT OF reg_curs;
					ELSE
						UPDATE "Register" SET register_status = ('fail')::register_status_type WHERE CURRENT OF reg_curs;
					END IF;				
				END IF;	
			END IF;
		END LOOP;
	
	--Close cursors
	CLOSE reg_curs;
	CLOSE curs;

	END IF;
END;	
$BODY$
LANGUAGE 'plpgsql';
-- Usage: SELECT insert_random_grades(24);


-- 2.3

-- CREATE TYPICAL/FOREIGN/SEASONAL PROGRAM 

-- Create a Custom Unit for a Seasonal Program, and insert inside the custom unit an array of Course Runs
CREATE OR REPLACE FUNCTION create_custom_unit(program_id integer, custom_unit_id integer, course_codes text[])
RETURNS VOID
AS $$
DECLARE

	credits integer;

BEGIN
	
	IF NOT EXISTS(SELECT * FROM "SeasonalProgram" WHERE "ProgramID" = program_id) THEN
		RAISE EXCEPTION 'Seasonal Program with ProgramID = % doesnt exist', program_id;
	END IF;
	
	-- Find total credits of courses
	credits := SUM(units) FROM "Course"
			WHERE course_code = ANY(course_codes);
	
	-- Add courses to program
	INSERT INTO "ProgramOffersCourse"("ProgramID", "CourseCode")
	(
		SELECT program_id, course_code FROM "Course"
		WHERE course_code = ANY(course_codes)
	);
	
	-- Create custom unit
	INSERT INTO "CustomUnits"("CustomUnitID", "SeasonalProgramID", "Credits")
		VALUES(custom_unit_id, program_id, credits);
	
	-- Add each course to new custom unit
	INSERT INTO "RefersTo"("CourseRunCode", "CourseRunSerial", "CustomUnitID", "SeasonalProgramID")
	(
		SELECT cr.course_code, cr.serial_number, custom_unit_id, program_id FROM "CourseRun" cr
			INNER JOIN "Semester" s ON s.semester_id = cr.semesterrunsin
			INNER JOIN "Program" p ON p."Year" = s.academic_year::text
		WHERE p."ProgramID" = program_id
		AND cr.course_code = ANY(course_codes)
	);
	
END;
$$ LANGUAGE plpgsql;

-- CREATE PROGRAM
CREATE OR REPLACE FUNCTION create_program(program_type integer,lang text,
season semester_season_type, start_year text, duration integer, min_courses integer, min_credits integer, 
DiplomaType diploma_type, obligatory boolean, comittee_num integer)
RETURNS VOID
AS $$
DECLARE
	program_rec record;
	total_students integer;
	random_num integer;
	last_id_rec record;
	program_id integer;
BEGIN
	
	-- Get last inserted ProgramID
	SELECT "ProgramID" INTO last_id_rec
		FROM "Program" p
	ORDER BY "ProgramID" DESC
	LIMIT 1;

	-- Get new ProgramID
	IF last_id_rec IS NOT NULL THEN
		program_id := last_id_rec."ProgramID" + 1;
	ELSE
		program_id := 1;
	END IF;
	
	CASE program_type
		WHEN 1 THEN -- Typical Program
			-- Add all course runs of specified year
			-- Add all students of entry_date = start_year and later
			-- Students must not attend seasonal program
			-- Students that attend previous typical program should be transferred to the new one

			-- Get most recent typical program, if exists
			SELECT DISTINCT p."ProgramID", sp."ProgramID", flp."ProgramID", p."Year" FROM "Program" p				
				LEFT JOIN "SeasonalProgram" sp ON sp."ProgramID" = p."ProgramID"
				LEFT JOIN "ForeignLanguageProgram" flp ON flp."ProgramID" = p."ProgramID"
			INTO program_rec
			WHERE flp."ProgramID" IS NULL AND sp."ProgramID" IS NULL
			ORDER BY p."ProgramID" DESC
			LIMIT 1;
			
			-- trying to create older typical program than current one, invalid
			if program_rec."Year" > start_year THEN
				RAISE EXCEPTION 'Older typical program of year % already exists', start_year;
				RETURN; 
			END IF;
			
			-- NO PREVIOUS PROGRAM, PROGRAM FOR entries_datee >= start_year 
			-- PROGRAM FOR NEW YEAR, UPDATE ALL JOINS FOR entries_date >= new_start_year
			-- PROGRAM FOR SAME YEAR, UPDATE JOINS, ONLY ADD NEW ENTRIES
			
			-- Typical program doesnt exist
			IF program_rec IS NULL THEN 

				-- Get num of students that will be added to the program
				total_students := SUM(t."Count")
				FROM(
					SELECT to_char(entry_date, 'yyyy'), COUNT(*) AS "Count"
					FROM "Student"
						WHERE to_char(entry_date, 'yyyy') >= start_year
					GROUP BY to_char(entry_date, 'yyyy')
					ORDER BY to_char(entry_date, 'yyyy')
				) AS t;
				
				INSERT INTO "Program"("ProgramID", "Duration", "MinCourses", "MinCredits", "Obligatory", "CommitteeNum", "DiplomaType", "NumOfParticipants", "Year")
					VALUES(program_id, duration, min_courses, min_credits, obligatory, comittee_num, DiplomaType, total_students, start_year);
				
				-- After program is created, find students that must be added to typical program				
				INSERT INTO "Joins"("StudentAMKA", "ProgramID")
				(
					SELECT s.amka, program_id FROM "Student" s
						LEFT JOIN "Joins" j ON j."StudentAMKA" = s.amka
						LEFT JOIN "SeasonalProgram" sp ON sp."ProgramID" = j."ProgramID"
					WHERE to_char(s.entry_date, 'yyyy') >= start_year 
					AND  sp."ProgramID" IS NULL -- Only students that have not entered a seasonal program can enter typical program
				);
			
			-- Previous typical program exists
			ELSIF program_rec."Year" < start_year THEN 
				
				-- Get num of students that will be added to the program
				total_students := SUM(t."Count")
				FROM(
					SELECT to_char(entry_date, 'yyyy'), COUNT(*) AS "Count"
					FROM "Student"
						WHERE to_char(entry_date, 'yyyy') >= start_year
					GROUP BY to_char(entry_date, 'yyyy')
					ORDER BY to_char(entry_date, 'yyyy')
				) AS t;
				
				INSERT INTO "Program"("ProgramID", "Duration", "MinCourses", "MinCredits", "Obligatory", "CommitteeNum", "DiplomaType", "NumOfParticipants", "Year")
					VALUES(program_id, duration, min_courses, min_credits, obligatory, comittee_num, DiplomaType, total_students, start_year);
				
				-- Transfer students from previous typical program to new one
				UPDATE "Joins" j SET "ProgramID" = program_id
				FROM "Student" s
				WHERE j."ProgramID" = program_rec."ProgramID" AND j."StudentAMKA" = s.amka
				AND to_char(s.entry_date, 'yyyy') >= start_year;

				-- Insert possible new students that have been added to db and are not in previous typical program
				INSERT INTO "Joins"
				(
					SELECT DISTINCT s.amka, program_id FROM "Student" s
						LEFT JOIN "Joins" j ON j."StudentAMKA" = s.amka
						LEFT JOIN "SeasonalProgram" sp ON sp."ProgramID" = j."ProgramID"
					WHERE to_char(s.entry_date, 'yyyy') >= start_year 
					AND sp."ProgramID" IS NULL -- Student not in a seasonal program
					AND j."StudentAMKA" IS NULL -- Student not in Joins, currently not in any typical program	
				);
				
				-- UPDATE Number of participants for previous typical program
				-- total students = joins of previous typical program after inserting the new typical program
				total_students := SUM(t."Count")
				FROM(
					SELECT "ProgramID", COUNT(*) AS "Count"
					FROM "Joins"
						WHERE "ProgramID" = program_rec."ProgramID"
					GROUP BY "ProgramID"
					ORDER BY "ProgramID"
				) AS t;
				
				UPDATE "Program" SET "NumOfParticipants" = total_students
					WHERE "ProgramID" = program_rec."ProgramID";

			-- Update current typical program
			ELSIF program_rec."Year" = start_year THEN
				-- Get num of students that will be added to the program
				total_students := SUM(t."Count")
				FROM(
					SELECT to_char(entry_date, 'yyyy'), COUNT(*) AS "Count"
					FROM "Student"
						WHERE to_char(entry_date, 'yyyy') >= program_rec."Year"
					GROUP BY to_char(entry_date, 'yyyy')
					ORDER BY to_char(entry_date, 'yyyy')
				) AS t;
				
				-- Update changes to typical program
				UPDATE "Program" SET "Duration" = duration, "MinCourses" = min_courses, "MinCredits" = min_credits,
					"Obligatory" = obligatory, "CommitteeNum" = comittee_num, "DiplomaType" = DiplomaType, "NumOfParticipants" = total_students
				WHERE "ProgramID" = program_rec."ProgramID";
				
				-- Insert possible new students
				INSERT INTO "Joins" 
				(
					SELECT DISTINCT s.amka, program_rec."ProgramID" FROM "Student" s
						LEFT JOIN "Joins" j ON j."StudentAMKA" = s.amka
						LEFT JOIN "SeasonalProgram" sp ON sp."ProgramID" = j."ProgramID"
					WHERE to_char(s.entry_date, 'yyyy') >= start_year 
					AND sp."ProgramID" IS NULL -- Student not in a seasonal program
					AND j."StudentAMKA" IS NULL -- Student not in Joins, currently not in any typical program	
				);
			END IF;
			
			-- If new typical program, create courses
			IF program_rec IS NULL OR program_rec."Year" <> start_year THEN
				INSERT INTO "ProgramOffersCourse"
				(
					SELECT program_id, c.course_code 
					FROM "Course" c 
				);
			END IF;

		WHEN 2 THEN -- ForeignLanguage Program, same format as typical program
		-- Only foreign students and 1-10 greek students that have graduated
		-- See greek students after, first check foreign
			
			-- Add all course runs of specified year
			-- Add some foreign students of entry_date = start_year and later
			-- Students must not attend seasonal program
			-- Students that attend previous typical program should be transferred to the new one

			-- Get most recent foreign language program of same language, if exists
			SELECT fp."ProgramID", p."Year" FROM "ForeignLanguageProgram" fp
				INNER JOIN "Program" p ON p."ProgramID" = fp."ProgramID"
			INTO program_rec
			WHERE fp."Language" = LOWER(lang)
			ORDER BY "ProgramID" DESC
			LIMIT 1;
			
			-- trying to create older typical program than current one, invalid
			-- Cannot update foreign language program
			IF program_rec."Year" >= start_year THEN
				RAISE EXCEPTION 'Older or current % language program of year % already exists', LOWER(lang), start_year;
				RETURN; 
				
			-- Foreign lang program doesnt exist or create foreign lang program for next year
			ELSIF (program_rec IS NULL) OR (program_rec."Year" < start_year) THEN

				-- Get num of students that will be added to the program
				total_students := SUM(t."Count")
				FROM(
					SELECT to_char(entry_date, 'yyyy'), COUNT(*) AS "Count"
					FROM "Student"
					WHERE to_char(entry_date, 'yyyy') = start_year
					AND substring(am from 5 for 1) = '1'
					GROUP BY to_char(entry_date, 'yyyy')
					ORDER BY to_char(entry_date, 'yyyy')
				) AS t;
				
				-- random num of post-grad students (1-10)
				random_num := floor(RANDOM()*9+1);
				total_students := total_students + random_num;
				
				-- Create foreign language program
				INSERT INTO "Program"("ProgramID", "Duration", "MinCourses", "MinCredits", "Obligatory", "CommitteeNum", "DiplomaType", "NumOfParticipants", "Year")
					VALUES(program_id, duration, min_courses, min_credits, obligatory, comittee_num, DiplomaType, total_students, start_year);
				
				INSERT INTO "ForeignLanguageProgram"("ProgramID", "Language")
					VALUES(program_id, lang);
				
				-- Find foreign students of start_year and add them to program			
				INSERT INTO "Joins"("StudentAMKA", "ProgramID")
				(
					SELECT amka, program_id FROM "Student"
					WHERE to_char(entry_date, 'yyyy') = start_year
					AND substring(am from 5 for 1) = '1'
				);
				
				-- Add random number of post-grad students (1-10) to add to foreign language program
				INSERT INTO "Joins"("StudentAMKA", "ProgramID")
				(
					SELECT "StudentAMKA", program_id FROM "Diploma"
					ORDER BY RANDOM()
					LIMIT random_num
				);
				
				-- Create courses for program
				INSERT INTO "ProgramOffersCourse"
				(
					SELECT program_id, c.course_code 
					FROM "Course" c 
				);
			END IF;
			
		WHEN 3 THEN -- Seasonal Program
		-- Random number of students
		-- Function for adding custom units (ProgramId, enothta_name, array of course_codes)
		
			-- Get most recent Seasonal Program
			SELECT sp."ProgramID", p."Year" FROM "SeasonalProgram" sp
				INNER JOIN "Program" p ON p."ProgramID" = sp."ProgramID"
			INTO program_rec
			WHERE sp."Season"::semester_season_type = season
			ORDER BY "ProgramID" DESC
			LIMIT 1;
			
			-- trying to create older typical program than current one, invalid
			IF program_rec."Year" > start_year THEN
				RAISE EXCEPTION 'Older typical program of year % already exists', start_year;
				RETURN; 
			ELSE
			
				total_students := floor(RANDOM()*9+1);
				
				INSERT INTO "Program"("ProgramID", "Duration", "MinCourses", "MinCredits", "Obligatory", "CommitteeNum", "DiplomaType", "NumOfParticipants", "Year")
					VALUES(program_id, duration, min_courses, min_credits, obligatory, comittee_num, DiplomaType, total_students, start_year);
				
				INSERT INTO "SeasonalProgram"("ProgramID", "Season")
					VALUES(program_id, season);
				
				-- Insert random students to seasonal program that do not attend a typical/foreign program
				INSERT INTO "Joins"("StudentAMKA", "ProgramID")
				(
					SELECT amka, program_id 
					FROM "Student" s
					WHERE s.amka NOT IN
					(
						SELECT "StudentAMKA"
						FROM "Joins"
					)
					ORDER BY RANDOM()
					LIMIT total_students
				);
			END IF;
			
	END CASE;
		
END;
$$ LANGUAGE plpgsql;
--Usage: SELECT create_program(1, NULL, NULL, '2010', 12, 20, 50, 'degree', true, 2)
-- 		 SELECT create_program(2, 'english', NULL, '2023', 12, 20, 50, 'degree', true, 2)
--
--       SELECT create_program(3, NULL, 'winter', '2011', 12, 20, 50, 'degree', true, 2)
--		 SELECT create_custom_unit(3, 1, ARRAY['ΑΓΓ 101', 'ΠΛΗ 101'])
--
-- TESTING FOREIGN LANGUAGE: 
--			CREATE SOME FOREIGN STUDENTS
--			SELECT create_students(220, '2023-01-01'); 
--
-- 			CREATE PROGRAM FOR POST-GRADS
-- 			SELECT create_program(1, NULL, NULL, '2010', 12, 20, 50, 'degree', true, 2)		
--
--			CREATE SOME POST-GRAD STUDENTS
-- 			INSERT INTO "Diploma"
-- 			(
-- 				SELECT ROW_NUMBER() OVER(), 10, 'diploma', amka, 1
-- 				FROM "Student"
-- 				WHERE to_char(entry_date, 'yyyy') = '2010'
-- 			)


-- (3)

--3.1
--find_information_using_am(student_am text)
CREATE OR REPLACE FUNCTION find_information_using_am(student_am text)
RETURNS TABLE (am character(10), amka varchar, name varchar, surname varchar, father_name varchar, email varchar)
AS $BODY$
BEGIN
RETURN QUERY
	SELECT s.am, s.amka, p.name, p.surname, p.father_name, p.email 
	FROM "Student" s
	JOIN "Person" p ON (p.amka = s.amka)
	WHERE s.am = student_am; 
END
$BODY$
LANGUAGE 'plpgsql';
--Usage: SELECT * FROM find_information_using_am('2015000001');

--3.2
--get_students_fullname_from_course(code)
CREATE OR REPLACE FUNCTION get_students_fullname_from_course(code character)
RETURNS TABLE(am character, name varchar, lname varchar) 
AS $BODY$
BEGIN
RETURN QUERY
	SELECT s.am, p.name, p.surname FROM "Person" p
	INNER JOIN "Student" s ON s.amka = p.amka
	INNER JOIN "Register" r ON r.amka = s.amka
	INNER JOIN "CourseRun" cr ON (cr.course_code = r.course_code AND r.serial_number = cr.serial_number)
	INNER JOIN "Semester" sem ON sem.semester_id = cr.semesterrunsin
	WHERE cr.course_code = code AND sem.semester_status = 'present'
	ORDER BY s.am ASC;
END
$BODY$
LANGUAGE 'plpgsql';
--Usage: SELECT * FROM get_students_fullname_from_course('ΠΛΗ 102');

-- 3.3 - Get Full name and Positions
CREATE OR REPLACE FUNCTION get_fullname_and_positions()
RETURNS TABLE ("Surname" varchar, "Name" varchar, "Position" text)
AS $$
	SELECT p.surname, p.name, 'Student' FROM "Person" p
		INNER JOIN "Student" s ON s.amka = p.amka
	UNION
	SELECT p.surname, p.name, 'Professor' FROM "Person" p
		INNER JOIN "Professor" pr ON pr.amka = p.amka
	UNION
	SELECT p.surname, p.name, 'Lab Teacheer' FROM "Person" p
		INNER JOIN "LabTeacher" l ON l.amka = p.amka
$$ LANGUAGE SQL;
-- Usage: SELECT * FROM get_fullname_and_positions()

--3.4
--get_obligatory_courses(am, pID)
CREATE OR REPLACE FUNCTION get_obligatory_courses(student_am character(10), program_id integer)
RETURNS TABLE ("Course Code" character(10),  "Course Title" text)
AS $BODY$
BEGIN
  RETURN QUERY
    SELECT c.course_code, (c.course_title)::text FROM "Course" c
    WHERE c.obligatory = true
   	AND c.course_code NOT IN (
		  SELECT r.course_code
		  FROM "Register" r
		  INNER JOIN "Student" s ON s.amka = r.amka
		  INNER JOIN "Joins" j ON j."StudentAMKA" = s.amka
		  INNER JOIN "ProgramOffersCourse" poc ON poc."CourseCode" = r.course_code
		  WHERE s.am = student_am AND j."ProgramID" = program_id AND poc."ProgramID" = program_id AND r.register_status = 'pass'
    )
    AND EXISTS (
      SELECT * FROM "Joins" j
      INNER JOIN "Student" s ON s.amka = j."StudentAMKA"
      WHERE s.am = student_am AND j."ProgramID" = program_id
    )
    ORDER BY c.course_code;
END $BODY$ 
LANGUAGE plpgsql;
--Usage: SELECT * FROM get_obligatory_courses('2010000001', 1);

-- 3.5
CREATE OR REPLACE FUNCTION get_sector_labs()
RETURNS TABLE (sector_code integer, sector_title varchar, hours integer)
AS $$
	SELECT s.sector_code, s.sector_title, COUNT(cr.course_code) as hours FROM "Sector" s
		INNER JOIN "Lab" l ON l.sector_code = s.sector_code
		INNER JOIN "CourseRun" cr ON cr.labuses = l.lab_code
	GROUP BY s.sector_code
	ORDER BY hours DESC
$$
LANGUAGE SQL;
--Usage: SELECT * FROM get_sector_labs();

-- 3.6
CREATE OR REPLACE FUNCTION get_qualified_students(program_id integer)
RETURNS TABLE (amka varchar, courses bigint, units bigint)
AS $BODY$
DECLARE
	program_rec record;
BEGIN
	
	SELECT * INTO program_rec FROM "Program" p WHERE p."ProgramID" = program_id;

	IF program_rec IS NULL THEN
		RAISE EXCEPTION 'Program with id: % doesnt exist', program_id;
	END IF;	
	
	IF program_rec."Obligatory" IS TRUE THEN -- Thesis needed
		RETURN QUERY
		SELECT r.amka,  COUNT(cr.course_code), SUM(c.units) FROM "CourseRun" cr
			INNER JOIN "Course" c ON c.course_code = cr.course_code
			INNER JOIN "Register" r ON (r.course_code = cr.course_code AND r.serial_number = cr.serial_number)
			INNER JOIN "Joins" j ON j."StudentAMKA" = r.amka
			INNER JOIN "Program" p ON p."ProgramID" = j."ProgramID"
		WHERE r.register_status = 'pass' AND p."ProgramID" = program_id
		AND EXISTS
		(
			SELECT * FROM "Thesis" t
			WHERE t."ProgramID" = program_id
			AND t."StudentAMKA" = r.amka
			AND t."Grade" >= 5
		)
		GROUP BY r.amka, p."ProgramID"
		HAVING COUNT(cr.course_code) >= p."MinCourses" AND SUM(c.units) >= p."MinCredits";
		
	ELSE -- No thesis needed (false, NULL)
	
		RETURN QUERY
		SELECT r.amka,  COUNT(cr.course_code), SUM(c.units) FROM "CourseRun" cr
			INNER JOIN "Course" c ON c.course_code = cr.course_code
			INNER JOIN "Register" r ON (r.course_code = cr.course_code AND r.serial_number = cr.serial_number)
			INNER JOIN "Joins" j ON j."StudentAMKA" = r.amka
			INNER JOIN "Program" p ON p."ProgramID" = j."ProgramID"
		WHERE r.register_status = 'pass' AND p."ProgramID" = program_id
		GROUP BY r.amka, p."ProgramID"
		HAVING COUNT(cr.course_code) >= p."MinCourses" AND SUM(c.units) >= p."MinCredits";		
		
	END IF;
END $BODY$
LANGUAGE 'plpgsql';
--Usage: SELECT * FROM get_qualified_students(2);

-- 3.7
--get_lab_hours_per_teacher();
CREATE OR REPLACE FUNCTION get_lab_hours_per_teacher()
RETURNS TABLE (amka varchar, p_sur varchar, name varchar, total_hr bigint)
AS $BODY$
BEGIN
RETURN QUERY
	SELECT p.amka, p.surname, p.name, sum(c.lab_hours) as "WorkLoad" FROM "Person" p
		INNER JOIN "Supports" s ON s.amka = p.amka
		INNER JOIN "CourseRun" cr ON (cr.course_code = s.course_code and cr.serial_number = s.serial_number)
		INNER JOIN "Course" c ON c.course_code = cr.course_code
		INNER JOIN "Semester" sem ON sem.semester_id = cr.semesterrunsin
		WHERE sem.semester_status = 'present'
		GROUP BY p.amka
	UNION
	SELECT p.amka, p.surname, p.name, 0 as "WorkLoad" FROM "Person" p
		INNER JOIN "LabTeacher" l ON l.amka = p.amka
		WHERE p.amka NOT IN (
				SELECT s.amka FROM "Supports" s
				INNER JOIN "CourseRun" cr ON (cr.course_code = s.course_code and cr.serial_number = s.serial_number)
				INNER JOIN "Course" c ON cr.course_code = c.course_code
				INNER JOIN "Semester" sem ON sem.semester_id = cr.semesterrunsin
				WHERE sem.semester_status = 'present'
		)
	ORDER BY amka;
END $BODY$
LANGUAGE 'plpgsql';
--Usage: SELECT * FROM get_lab_hours_per_teacher();

--3.8
--get_all_courses_related_to(course code)
CREATE OR REPLACE FUNCTION get_all_courses_related_to(c_code character(7))
RETURNS TABLE (cr_code character(7), cr_title text)
AS $BODY$ BEGIN

RETURN QUERY
	WITH RECURSIVE dependent_courses AS (
	  SELECT *
	  FROM "Course_depends"
	  WHERE dependent = c_code
	  UNION
	  SELECT cd.dependent, cd.main, cd.mode
	  FROM dependent_courses dc
	  JOIN "Course_depends" cd ON cd.dependent = dc.main
	)
	SELECT DISTINCT d.main, (c.course_title)::text FROM dependent_courses d
		INNER JOIN "Course" c ON c.course_code = d.main
	ORDER BY d.main;

END $BODY$
LANGUAGE 'plpgsql';
--Usage: SELECT * FROM get_all_courses_related_to('ΤΗΛ 302');

-- 3.9
CREATE OR REPLACE FUNCTION get_professors()
RETURNS TABLE(amka varchar, name varchar, surname varchar) 
AS $$

	SELECT name, surname, prof.amka FROM "Professor" prof
		INNER JOIN "Person" ON "Person".amka = prof.amka
	WHERE EXISTS
	(

		SELECT pr.amka FROM "Program" p
			INNER JOIN "ProgramOffersCourse" poc ON poc."ProgramID" = p."ProgramID"
			INNER JOIN "Course" c ON c.course_code = poc."CourseCode"
			INNER JOIN "CourseRun" cr ON cr.course_code = c.course_code 
			INNER JOIN "Semester" s ON s.semester_id = cr.semesterrunsin
			INNER JOIN "Teaches" t ON (t.course_code = cr.course_code AND t.serial_number = cr.serial_number)
			INNER JOIN "Professor" pr ON pr.amka = t.amka
		WHERE s.start_date >= make_date(p."Year"::int, 10, 1) AND  s.end_date <= make_date(p."Year"::int + 5, 6, 10) -- only for 10 semesters of specified program
		AND NOT EXISTS -- Only typical programs
		(
			SELECT "ProgramID" FROM "SeasonalProgram"
			WHERE "ProgramID" = p."ProgramID"
			UNION 
			SELECT "ProgramID" FROM "ForeignLanguageProgram"
			WHERE "ProgramID" = p."ProgramID"
		)
		AND prof.amka = pr.amka

	)
	AND EXISTS
	(
		SELECT pr.amka FROM "Program" p
			INNER JOIN "ForeignLanguageProgram" flp ON flp."ProgramID" = p."ProgramID" -- Only foreign lang program
			INNER JOIN "ProgramOffersCourse" poc ON poc."ProgramID" = p."ProgramID"
			INNER JOIN "Course" c ON c.course_code = poc."CourseCode"
			INNER JOIN "CourseRun" cr ON cr.course_code = c.course_code 
			INNER JOIN "Semester" s ON s.semester_id = cr.semesterrunsin
			INNER JOIN "Teaches" t ON (t.course_code = cr.course_code AND t.serial_number = cr.serial_number)
			INNER JOIN "Professor" pr ON pr.amka = t.amka
		WHERE s.start_date >= make_date(p."Year"::int, 10, 1) AND  s.end_date <= make_date(p."Year"::int + 5, 6, 10) -- only for 10 semesters of specified program
		AND prof.amka = pr.amka
	)
	AND EXISTS
	(
		SELECT pr.amka FROM "Program" p
			INNER JOIN "SeasonalProgram" sp ON sp."ProgramID" = p."ProgramID" -- Only Seasonal Program
			INNER JOIN "ProgramOffersCourse" poc ON poc."ProgramID" = p."ProgramID"
			INNER JOIN "Course" c ON c.course_code = poc."CourseCode"
			INNER JOIN "CourseRun" cr ON cr.course_code = c.course_code 
			INNER JOIN "Semester" s ON s.semester_id = cr.semesterrunsin
			INNER JOIN "Teaches" t ON (t.course_code = cr.course_code AND t.serial_number = cr.serial_number)
			INNER JOIN "Professor" pr ON pr.amka = t.amka
		WHERE s.academic_year::text = p."Year" AND s.academic_season::text = sp."Season"
		AND prof.amka = pr.amka
	)
$$
LANGUAGE SQL;
-- Usage: SELECT * FROM get_professors();

-- (4)

-- 4.1.1 - 4.1.2
-- Trigger 1: Check Future Semester
CREATE OR REPLACE FUNCTION check_future_semester()
RETURNS TRIGGER 
AS $BODY$
DECLARE
	latest_semester record;
	curr_sem_id integer;
	month_start_date integer;
BEGIN
  
    IF TG_OP = 'INSERT' THEN
		
		IF NEW.semester_status = 'future' THEN
			
			-- check for existing semester_id	
			IF EXISTS (
				SELECT * FROM "Semester" WHERE semester_id = NEW.semester_id
			) 
			THEN
				RAISE EXCEPTION E'\nNew Future Semester cannot have already existing id. Current Semester ID is %\n\n', (SELECT MAX(semester_id) FROM "Semester");
			END IF;
			
			-- Id must be in correct order
			IF NEW.semester_id > (SELECT MAX(semester_id) FROM "Semester") + 1 THEN
				RAISE EXCEPTION E'\nNew Future Semester ID is not on correct order. Please correct Semester ID by inserting %\n\n', ((SELECT MAX(semester_id) FROM "Semester") + 1);
			END IF;
			
			--Check if the new future semester ovelaps previous semester dates
			IF EXISTS (
				SELECT * FROM "Semester"
				WHERE (NEW.start_date, NEW.end_date) OVERLAPS (start_date, end_date) AND semester_id <> NEW.semester_id
			) 
			THEN
				RAISE EXCEPTION E'\nNew Future Semester Ovelapping\n\n';
			END IF;
			
			-- Check for compatible season and time
			month_start_date := EXTRACT(MONTH FROM NEW.start_date);
			IF (NEW.academic_season = 'spring' AND month_start_date = 10) OR (NEW.academic_season = 'winter' AND month_start_date = 3) THEN
				RAISE EXCEPTION E'\nWrong Season and Dates!\n\n';
			END IF;
			
			-- Now we check for time sequence
			-- For each academic year: winter semester year-10-01 <-> (year+1)-01-15
			--						   spring semester (year+1)-03-01 <-> (year+1)-06-10
			
			-- Get most recent semester
			SELECT * INTO latest_semester FROM "Semester" WHERE semester_id = (SELECT MAX(semester_id) FROM "Semester");
			
			-- SELECT * FROM "Semester" WHERE semester_id = (SELECT MAX(semester_id) FROM "Semester");
			
			-- Cant insert future semester with year lower than current
			IF NEW.academic_year < latest_semester.academic_year THEN
				RAISE EXCEPTION E'\nAcademic year cannot be lower than present!\nLatest Semester entry has attributes: %, %, %, %\n\n', latest_semester.academic_year, 
				latest_semester.academic_season, latest_semester.start_date, latest_semester.end_date;
			END IF;
			
			-- Check academic year
			IF NEW.academic_year = latest_semester.academic_year AND latest_semester.academic_season = 'winter' THEN
				RAISE EXCEPTION E'\nYear is not inserted correctly! Correct academic year is %\nLatest Semester entry has attributes: %, %, %, %\n\n',(NEW.academic_year+1), latest_semester.academic_year, 
				latest_semester.academic_season, latest_semester.start_date, latest_semester.end_date;
			END IF;	
			
			-- if academic year is greater than the current one, we have to check for time sequence
			-- Semester insertion occurs only if it has the right attributes and it is correct with time
			-- e.g. cant insert semester with year 2029 while present is on 2023
			IF NEW.academic_year >= latest_semester.academic_year 
				AND (EXTRACT(YEAR FROM NEW.start_date))::integer != (EXTRACT(YEAR FROM latest_semester.end_date))::integer THEN
				RAISE EXCEPTION E'\nSemesters does not follow time regulations! Correct academic year is %\nLatest Semester entry has attributes: %, %, %, %\n\n', EXTRACT(YEAR FROM latest_semester.end_date), latest_semester.academic_year, 
				latest_semester.academic_season, latest_semester.start_date, latest_semester.end_date;
			END IF;
			
			-- Semester duration can not be more that (start_date-end_date)::days
			IF (NEW.end_date - NEW.start_date) > 120 OR NEW.end_date < NEW.start_date THEN 
				RAISE EXCEPTION E'\nTime Duration of Semester is invalid!\n\n';
			END IF;	
			
			RETURN NEW;
			
		ELSEIF NEW.semester_status IN ('past', 'present') THEN
			RAISE EXCEPTION E'\nCannot insert semester with status past or present!\n\n';		
		END IF;
		
	ELSIF TG_OP = 'UPDATE' THEN
    	
		IF NEW.semester_status = 'present' THEN
		
			-- Check update occurs on past semester
			IF EXISTS (
				SELECT * FROM "Semester" WHERE semester_id = NEW.semester_id AND semester_status = 'past'
			)
			THEN
				RAISE EXCEPTION E'\nCannot set present status to an old semester\n\n';
			END IF;

			-- Take id of present semester
			curr_sem_id := (SELECT semester_id FROM "Semester" WHERE semester_status = 'present')::integer;
			
			-- Also check, if new future semester is valid with time sequence
			IF NEW.semester_id > curr_sem_id + 1 THEN
				RAISE EXCEPTION E'\nThe semester you want to set as present, does not follow time sequence\n\n';
			END IF; 

			-- Now update the current to past
			UPDATE "Semester"
			SET semester_status = 'past'
			WHERE semester_status = 'present' AND semester_id <> NEW.semester_id;
			
			-- Now update future to present
			UPDATE "Semester"
			SET semester_status = 'present'
			WHERE semester_status = 'future' AND semester_id <> NEW.semester_id
			AND start_date > (SELECT end_date FROM "Semester" WHERE semester_status = 'present') AND NEW.semester_id <= curr_sem_id + 1;			
		END IF;	
		RETURN NEW;	
	END IF;
	
END $BODY$ 
LANGUAGE plpgsql;

-- Create Trigger
CREATE TRIGGER future_sem_trigger BEFORE INSERT OR UPDATE
ON "Semester"
FOR EACH ROW EXECUTE FUNCTION check_future_semester();

-- DROP TRIGGER IF EXISTS future_sem_trigger ON "Semester";
-- DROP FUNCTION IF EXISTS check_future_semester();

-- 4.1.3
-- Trigger Function: Create proposed student enrollments in courses when a future semester becomes present
CREATE OR REPLACE FUNCTION create_proposed_registries()
RETURNS TRIGGER
AS $BODY$
BEGIN

	IF TG_OP = 'UPDATE' THEN
		
		IF NEW.semester_status = 'present' AND OLD.semester_status = 'future' THEN
			
			-- Update CourseRun table and insert courses depending of season
			INSERT INTO "CourseRun"(course_code, serial_number, exam_min, lab_min, exam_percentage, labuses, semesterrunsin)
			(
				SELECT course_code, serial_number + 1, exam_min, lab_min, exam_percentage, labuses, NEW.semester_id 
				FROM "CourseRun" cr
				WHERE cr.semesterrunsin = NEW.semester_id - 2	--takes the courses of last year
			);
				
			-- Insert new proposed registries for the current semester
			INSERT INTO "Register" (amka, serial_number, course_code, register_status)
			(
			  SELECT s.amka, cr.serial_number, cr.course_code, 'proposed'
			  FROM "Student" s
			  CROSS JOIN "CourseRun" cr
			  WHERE cr.semesterrunsin = NEW.semester_id
			  AND NOT EXISTS (
			  	SELECT * FROM "Register" r
					INNER JOIN "CourseRun" crr ON crr.course_code = r.course_code and crr.serial_number = r.serial_number
				  	INNER JOIN "Semester" sem ON sem.semester_id = crr.semesterrunsin
				  	WHERE r.amka = s.amka
				  	AND r.register_status = 'pass'
				  	AND sem.academic_season = NEW.academic_season
			  )
			);

		END IF;
		RETURN NEW;
		
	END IF;

END $BODY$
LANGUAGE 'plpgsql';

-- Create Trigger
CREATE TRIGGER create_proposed_registries_trigger
AFTER UPDATE ON "Semester"
FOR EACH ROW EXECUTE FUNCTION create_proposed_registries();
-- DROP TRIGGER IF EXISTS create_proposed_registries_trigger ON "Semester";
-- DROP FUNCTION IF EXISTS create_proposed_registries();


-- 4.1.4
-- Trigger Function: Calculate final grades()
CREATE OR REPLACE FUNCTION calculate_final_student_grades()
RETURNS TRIGGER
AS $BODY$
BEGIN

	IF TG_OP = 'UPDATE' THEN
		IF NEW.semester_status = 'past' AND OLD.semester_status = 'present' THEN
			PERFORM insert_random_grades(OLD.semester_id);
		END IF;
		RETURN NEW;
	END IF;

END $BODY$
LANGUAGE 'plpgsql';

-- Create Trigger
CREATE TRIGGER calculate_final_student_grades_trigger
AFTER UPDATE ON "Semester"
FOR EACH ROW EXECUTE FUNCTION calculate_final_student_grades();
-- DROP TRIGGER IF EXISTS calculate_final_student_grades_trigger ON "Semester";
-- DROP FUNCTION IF EXISTS calculate_final_student_grades();

-- 4.2
-- Trigger Function: Check committee's num per thesis
CREATE OR REPLACE FUNCTION check_committee_num() 
RETURNS TRIGGER
AS $BODY$

DECLARE
	committee_info record;
BEGIN

	SELECT p."ProgramID" AS program_id, p."CommitteeNum" AS max_committee_num, COUNT(*) AS committee_num INTO committee_info
	FROM new_table c
		INNER JOIN "Thesis" t ON t."ThesisID" = c."ThesisID"
		INNER JOIN "Program" p ON p."ProgramID" = t."ProgramID"
	GROUP BY p."ProgramID", t."ThesisID";

	IF committee_info.committee_num > committee_info.max_committee_num THEN -- More than allowed committees
		RAISE EXCEPTION 'Maximum number of % committees has been breached', committee_info.max_committee_num;
	END IF;
	
	RETURN NULL;

END $BODY$ 
LANGUAGE 'plpgsql';

CREATE TRIGGER committee_trigg AFTER INSERT
ON "Committee"
REFERENCING NEW TABLE AS new_table
FOR EACH STATEMENT EXECUTE FUNCTION check_committee_num();
-- DROP TRIGGER IF EXISTS committee_trigg ON "Committee";
-- DROP FUNCTION IF EXISTS check_committee_num();

-- (5)

--5.1
--View
CREATE OR REPLACE VIEW semester_table AS
    SELECT DISTINCT cr.course_code, c.course_title, string_agg(per.name || ' ' || per.surname, ', ') AS "Instructors"
    FROM "CourseRun" cr
		INNER JOIN "Teaches" t ON t.course_code = cr.course_code AND t.serial_number = cr.serial_number
		INNER JOIN "Professor" p ON p.amka = t.amka
		INNER JOIN "Person" per ON per.amka = p.amka
		INNER JOIN "Course" c ON c.course_code = cr.course_code
		INNER JOIN "Semester" s ON s.semester_id = cr.semesterrunsin
    WHERE s.semester_status = 'present' AND p.amka IS NOT NULL
    GROUP BY cr.course_code, c.course_title
	ORDER BY cr.course_code;
--Usage: SELECT * FROM semester_table;