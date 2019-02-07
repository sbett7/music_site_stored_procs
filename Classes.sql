USE sbett7_music_school1;

CREATE TABLE Classes (
	classID INT AUTO_INCREMENT,
    teacherID INT,
	className VARCHAR(30) NOT NULL,
	classTimeType ENUM ('30', '60') NOT NULL,
    classGroupType ENUM ('Private', 'Group') NOT NULL,
	classDateTime DATETIME NOT NULL,
	instrument VARCHAR(30) NOT NULL,
	description TEXT,
	location VARCHAR (30) DEFAULT 10,
    maxEnrolled INT,
    
	PRIMARY KEY (classID),
	CONSTRAINT class_instrument FOREIGN KEY (instrument) REFERENCES Instruments(instrumentName) ON DELETE CASCADE,
    CONSTRAINT class_teacher_id FOREIGN KEY (teacherID) REFERENCES Teachers(teacherID) ON DELETE CASCADE
) CHARACTER SET utf8, ENGINE=MyISAM;

CREATE TABLE AttendsClass (
	classID INT NOT NULL,
	teacherID INT NOT NULL,
	studentID INT NOT NULL,
	PRIMARY KEY (classID, studentID),
	CONSTRAINT attend_classID FOREIGN KEY (classID) REFERENCES Classes(classID) ON DELETE CASCADE,
	CONSTRAINT attend_teacherID FOREIGN KEY (teacherID) REFERENCES Teachers(teacherID) ON DELETE CASCADE,
	CONSTRAINT attend_studentID FOREIGN KEY (studentID) REFERENCES Students(studentID) ON DELETE CASCADE
)CHARACTER SET utf8, ENGINE=MyISAM;

DELIMITER $$
CREATE PROCEDURE add_class(
    IN _className VARCHAR(30),
    IN _teacherID INT,
    IN _classTimeType ENUM ('30', '60'),
    IN _classGroupType ENUM ('Private', 'Group'),
    IN _classDateTime DATETIME,
    IN _instrument VARCHAR(30),
    IN _description TEXT,
    IN _location VARCHAR (30),
    IN _maxEnrolled INT
)
BEGIN
	IF _classGroupType = 'Private' THEN
		SET _maxEnrolled = 1;
	ELSEIF _maxEnrolled IS NULL THEN
		SET _maxEnrolled = 10;
	END IF;
    
	IF _className IS NULL
		OR _teacherID IS NULL
        OR _classTimeType IS NULL
        OR _classGroupType IS NULL
        OR _instrument IS NULL
        OR _classDateTime IS NULL THEN
			SELECT "ERROR: Not all of the required fields have been filled.";
     ELSEIF (SELECT instrumentName FROM Instruments where instrumentName=_instrument) IS NULL THEN
		SELECT "ERROR: There is no entry for this instrument type";
	ELSEIF (SELECT teacherID FROM Teachers where teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: There is no teacher with that ID listed";
	ELSEIF (SELECT teacherID FROM Classes WHERE classDateTime=_classDateTime AND teacherID=_teacherID) IS NOT NULL THEN
		SELECT "ERROR: This teacher is already teaching a class at this time.";
	ELSE
		INSERT INTO Classes(
			className, teacherID, classTimeType, classGroupType, classDateTime, instrument, 
			description, location, maxEnrolled
		)
		VALUES (
			_className, _teacherID, _classTimeType, _classGroupType, _classDateTime, _instrument,
			_description, _location, _maxEnrolled
		);
        SELECT "Successfully created a class entry";
    END IF;
END$$

DELIMITER $$
CREATE PROCEDURE update_class_details(
	IN _classID INT,
    IN _className VARCHAR(30),
    IN _classTimeType ENUM ('30', '60'),
    IN _classGroupType ENUM ('Private', 'Group'),
    IN _classDateTime DATETIME,
    IN _instrument VARCHAR(30),
    IN _description TEXT,
    IN _location VARCHAR (30),
    IN _maxEnrolled INT
    
)
BEGIN
	IF _classGroupType = 'Private' THEN
		SET _maxEnrolled = 1;
	ELSEIF _maxEnrolled IS NULL THEN
		SET _maxEnrolled = 10;
	END IF;
    
	IF _className IS NULL
        OR _classTimeType IS NULL
        OR _classGroupType IS NULL
        OR _instrument IS NULL
        OR _classDateTime IS NULL THEN
			SELECT "ERROR: Not all of the required fields have been filled.";
	ELSEIF (SELECT instrumentName FROM Instruments where instrumentName=_instrument) IS NULL THEN
		SELECT "ERROR: There is no entry for this instrument type";
	ELSEIF (SELECT COUNT(*) FROM Classes WHERE classID=_classID) = 0 THEN
		SELECT "ERROR: No classes are listed with this ID";
	ELSE
		UPDATE Classes
        SET className=_className, classTimeType=_classTimeType,
			classGroupType=_classGroupType, instrument=_instrument,
            description=_description, location=_location
		WHERE classID = _classID;
        SELECT "Successfully updated class information";
    END IF;
END $$

DELIMITER $$
CREATE PROCEDURE remove_class(
	IN _classID INT
)
BEGIN
	IF (SELECT classID FROM Classes WHERE classID=_classID) IS NULL THEN
		SELECT "ERROR: No classes with that ID are listed";
	ELSE
		DELETE FROM Classes
        WHERE classID=_classID
        LIMIT 1;
        SELECT "Successfully deleted the class";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE add_attends_class_entry(
	IN _classID INT,
    IN _studentID INT
)
BEGIN
	IF (SELECT classID FROM Classes WHERE classID=_classID) IS NULL THEN
		SELECT "ERROR: No classes with that ID are listed";
	ELSEIF (SELECT studentID FROM Students WHERE studentID=_studentID) IS NULL THEN
		SELECT "ERROR: No students with that ID are listed";
	ELSEIF (SELECT COUNT(*) FROM AttendsClass WHERE studentID=_studentID AND classID=_classID) != 0  THEN
		SELECT "ERROR: This student is already enrolled into this class";
	ELSEIF (
			SELECT (c.maxEnrolled - COUNT(ac.studentID)) AS enrolments 
            FROM AttendsClass ac NATURAL JOIN Classes c 
            WHERE classID=_classID
        ) <= 0 THEN
		SELECT "ERROR: Maximum enrolments reached for this class";
	ELSE
		INSERT INTO AttendsClass(
			classID, studentID
		)
		VALUES(
			_classID, _studentID
		);
        SELECT "Successfully added the student to the class";
	END IF;
END$$

DELIMITER $$
CREATE PROCEDURE remove_attends_class_entry(
	_classID INT,
    _studentID INT
)
BEGIN
	IF (SELECT COUNT(*) FROM Classes WHERE classID=_classID) = 0 THEN
		SELECT "ERROR: No classes with that ID are listed";
	ELSEIF (SELECT studentID FROM Students WHERE studentID=_studentID) IS NULL THEN
		SELECT "ERROR: No students with that ID are listed";
	ELSEIF (SELECT DISTINCT classID FROM AttendsClass WHERE studentID=_studentID AND classID=_classID) IS NULL THEN
		SELECT "ERROR: The student does not attend a class with this class ID";
	ELSE
		DELETE FROM AttendsClass 
        WHERE studentID=_studentID AND classID=_classID
        LIMIT 1;
        SELECT "Successfully removed student enrolment";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_student_class_roster(
    IN _classID INT
)
BEGIN
	IF (SELECT classID FROM Classes WHERE classID=_classID) IS NULL THEN
		SELECT "ERROR: No classes with this ID has been listed";
	ELSEIF (SELECT COUNT(*) FROM AttendsClass WHERE classID=_classID) = 0 THEN
		SELECT "ERROR: No students are currently attending this class";
	ELSE
		SELECT firstName, lastName, emailAddress
		FROM Students
		WHERE studentID IN(
			SELECT studentID
			FROM AttendsClass
			WHERE classID=_classID
		)
		ORDER BY lastName ASC;
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_teacher_does_class(
	IN _classID INT
)
BEGIN
	IF (SELECT classID FROM Classes WHERE classID=_classID) IS NULL THEN
		SELECT "ERROR: No classes with this ID has been listed";
	ELSE
		SELECT firstName, lastName, emailAddress
		FROM Teachers
		WHERE teacherID=(
			SELECT teacherID
			FROM Classes
			WHERE classID=_classID
			);
	END IF;
END $$


DELIMITER $$
CREATE PROCEDURE get_classes_student_attends(
	IN _studentID INT
)
BEGIN
	IF (SELECT studentID FROM Students WHERE studentID=_studentID) IS NULL THEN
		SELECT "ERROR: No students with that ID are listed";
	ELSEIF(SELECT COUNT(*) FROM AttendsClass WHERE studentID=_studentID) = 0 THEN
		SELECT "ERROR: The student with this ID does not attend any classes";
	ELSE
		SELECT *
		FROM Classes class
		JOIN
			(SELECT firstName, lastName, emailAddress FROM Teachers) teacher
			ON teacher.firstName=(SELECT firstName FROM Teachers WHERE teacherID=class.teacherID) 
            AND teacher.lastName=(SELECT lastName FROM Teachers WHERE teacherID=class.teacherID) 
		WHERE class.classID IN (SELECT classID FROM AttendsClass WHERE studentID=_studentID);
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_class_details(
	IN _classID INT
)
BEGIN
	IF (SELECT classID FROM Classes WHERE classID=_classID) IS NOT NULL THEN
		SELECT *
		FROM Classes
		JOIN
			(SELECT firstName, lastName, emailAddress FROM Teachers) teacher
			ON teacher.firstName=(SELECT firstName FROM Teachers WHERE teacherID=Classes.teacherID) 
            AND teacher.lastName=(SELECT lastName FROM Teachers WHERE teacherID=Classes.teacherID) 
		WHERE classID=_classID;
    ELSE
		SELECT "ERROR: No class with this class ID is listed";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_classes_for_teacher(
	IN _teacherID INT
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher with this teacher ID is listed";
	ELSEIF (SELECT COUNT(*) FROM Classes WHERE teacherID=_teacherID) = 0 THEN
		SELECT "ERROR: This Teacher does not teach any classses";
	ELSE
		SELECT *
		FROM Classes
		WHERE teacherID = _teacherID;
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_list_of_future_classes(
	
)
BEGIN
	IF (SELECT COUNT(*) From Classes WHERE DATE(classDateTime) >= CURDATE()) = 0 THEN
		SELECT "ERROR: No future classes exist";
	ELSE
		SELECT Classes.*, t.firstName, t.lastName, t.emailAddress, (Classes.maxEnrolled - COUNT(ac.studentID)) AS availableEnrolments
			FROM Classes NATURAL JOIN AttendsClass ac NATURAL JOIN Teachers t
		WHERE DATE(classDateTime) >= CURDATE()
        GROUP BY Classes.classID
        ORDER BY Classes.className;
	END IF;
END $$
CALL get_list_of_future_classes();

DELIMITER $$
CREATE PROCEDURE get_list_of_past_classes(
	
)
BEGIN
	IF (SELECT COUNT(*) From Classes WHERE DATE(classDateTime) < CURDATE()) = 0 THEN
		SELECT "ERROR: No past classes exist";
	ELSE
		SELECT Classes.*, t.firstName, t.lastName, t.emailAddress, (Classes.maxEnrolled - COUNT(ac.studentID)) AS availableEnrolments
			FROM Classes NATURAL JOIN AttendsClass ac NATURAL JOIN Teachers t
		WHERE DATE(classDateTime) < CURDATE()
        GROUP BY Classes.classID
        ORDER BY Classes.className;
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE search_classes(
	-- Filters For Searching
	_className VARCHAR(30),
    _classTimeType ENUM('Private', 'Group'),
    _classDateTime DATETIME,
    _instrument VARCHAR(30),
    _instrumentType VARCHAR(30),
    _teacherFirstName VARCHAR(50),
    _teacherLastName VARCHAR(50),
    _teacherGender ENUM('M', 'F'),
    _teacherRating INT,
    _teacherSpokenLanguages VARCHAR(30),
    
    -- Page Sorting
    pageNumber INT,
    pageSize INT,
    
    -- Sort Columns
    sortColumns VARCHAR(30)
)
BEGIN
	DECLARE _trClassName VARCHAR(30);
    DECLARE _trInstrument VARCHAR(30);
    DECLARE _trInstrumentType VARCHAR(30);
    DECLARE _trTeacherFirstName VARCHAR(30);
    DECLARE _trTeacherLastName VARCHAR(30);
    DECLARE _trTeacherSpokenLanguages VARCHAR(30);
    
    SET _trClassName = LTRIM(RTRIM(_className));
    SET _trInstrument = LTRIM(RTRIM(_instrument));
    SET _trInstrumentType = LTRIM(RTRIM(_instrumentType));
    SET _trTeacherFirstName = LTRIM(RTRIM(_teacherFirstName));
    SET _trTeacherLastName = LTRIM(RTRIM(_teacherLastName));
    SET _trTeacherSpokenLanguages = LTRIM(RTRIM(_teacherSpokenLanguages));
    
    WITH CTE_Results
    AS (
		SELECT (ORDER BY
			
        
    
    )
    
END $$

