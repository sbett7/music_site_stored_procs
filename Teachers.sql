

CREATE TABLE Teachers (
	teacherID INT NOT NULL AUTO_INCREMENT,
	pwd VARCHAR(255) NOT NULL,
	firstName VARCHAR(15) NOT NULL,
	lastName VARCHAR(15) NOT NULL,
	DOB DATE NOT NULL,
	gender ENUM ('M', 'F') NOT NULL,
	mobilePhone VARCHAR (10) NOT NULL,
	emailAddress VARCHAR (30) NOT NULL UNIQUE,
    occupationStatus ENUM ('Employed', 'Applicant', 'Terminated'),
    profilePicture VARCHAR(5000) DEFAULT 'http://kobra.heliohost.org/IFB299%20Music%20School/public/img/teachertwo.jpg',
	PRIMARY KEY (teacherID)
)CHARACTER SET utf8, ENGINE=MyISAM;

CREATE TABLE TeacherQualifications (
	teacherID INT NOT NULL,
	qualification VARCHAR(255),
	description TEXT,
	PRIMARY KEY (teacherID, qualification),
	FOREIGN KEY (teacherID) REFERENCES Teachers(teacherID) ON DELETE CASCADE
) CHARACTER SET utf8, ENGINE=MyISAM;

CREATE TABLE TeacherFeedback(
	teacherID INT,
    studentID INT,
    rating INT NOT NULL,
    comments TEXT,
    PRIMARY KEY(teacherID, studentID),
    FOREIGN KEY(teacherID) REFERENCES Teachers (teacherID) ON DELETE CASCADE,
    FOREIGN KEY(studentID) REFERENCES Students (studentID),
    CONSTRAINT ratingCheck CHECK (rating <= 5)
) CHARACTER SET utf8, ENGINE=MyISAM;

CREATE TABLE TeacherInstruments (
	teacherID INT NOT NULL,
	instrument VARCHAR(30),
	instrumentLevel ENUM('Intermediate', 'Advanced', 'Expert'),
	PRIMARY KEY (teacherID, instrument),
	FOREIGN KEY (teacherID) REFERENCES Teachers(teacherID) ON DELETE CASCADE,
	FOREIGN KEY (instrument) REFERENCES Instruments(instrumentName)
) CHARACTER SET utf8, ENGINE=MyISAM;

CREATE TABLE TeacherSpokenLanguages (
	teacherID INT NOT NULL,
	spokenLanguage VARCHAR(30),
	spokenLanguagesAptitude ENUM('Intermediate', 'Advanced', 'Expert'),
	PRIMARY KEY (teacherID, spokenLanguage),
	FOREIGN KEY (teacherID) REFERENCES Teachers(teacherID) ON DELETE CASCADE
)CHARACTER SET utf8, ENGINE=MyISAM;




DELIMITER $$
CREATE PROCEDURE add_teacher(
	IN _pwd VARCHAR(255),
    IN _firstName VARCHAR(15),
    IN _lastName VARCHAR(15),
    IN _DOB DATE,
    IN _gender ENUM ('M', 'F'),
    IN _mobilePhone VARCHAR (10),
    IN _emailAddress VARCHAR (30),
    IN _occupationStatus ENUM ('Employed', 'Applicant', 'Terminated')
)
BEGIN
	IF _pwd IS NULL
		OR _firstName IS NULL
        OR _lastName IS NULL
		OR _DOB IS NULL
        OR _gender IS NULL
        OR _mobilePhone IS NULL
        OR _emailAddress IS NULL THEN
			SELECT "ERROR: Not all of the required fields have been filled.";
	ELSEIF (SELECT emailAddress FROM Teachers WHERE emailAddress=_emailAddress) IS NOT NULL THEN
		SELECT "ERROR: An account is already registered with that email address";
	ELSE
		INSERT INTO Teachers(
			pwd, firstName, lastName, DOB, gender, 
			mobilePhone, emailAddress, occupationStatus
		)
		VALUES (
			SHA1(_pwd), _firstName, _lastName, _DOB, _gender,
			_mobilePhone, _emailAddress, _occupationStatus
		);
        SELECT "Successfully Added Teacher Entry";
    END IF;
END$$

DELIMITER $$
CREATE PROCEDURE update_teacher_details(
	IN _teacherID INT,
    IN _pwd VARCHAR(160), 
    IN _firstName VARCHAR(15), 
	IN _lastName VARCHAR(15), 
    IN _mobilePhone VARCHAR (12), 
    IN _emailAddress VARCHAR (30), 
    IN _occupationStatus VARCHAR (30)
)
BEGIN
	IF _pwd IS NULL
		OR _firstName IS NULL
        OR _lastName IS NULL
        OR _mobilePhone IS NULL
        OR _emailAddress IS NULL THEN
			SELECT "ERROR: Not all of the required fields have been filled.";
	ELSEIF (SELECT emailAddress FROM Teachers WHERE emailAddress=_emailAddress AND teacherID !=_teacherID) IS NOT NULL THEN
		SELECT "ERROR: An account is already registered with that email address";
	ELSE
		UPDATE Teachers
		SET pwd=SHA1(_pwd), firstName=_firstName, lastName=_lastName,
			mobilePhone=_mobilePhone, emailAddress=_emailAddress, 
			occupationStatus=_occupationStatus
		WHERE teacherID=_teacherID;
        SELECT "Successfully updated account information.";
    END IF;
END$$

DELIMITER $$
CREATE PROCEDURE get_teacher_session(
	IN _emailAddress VARCHAR (30), 
	IN _pwd VARCHAR (160)
)
BEGIN
	IF(SELECT check_teacher_account_exists(_emailAddress, SHA1(_pwd)) IS TRUE) THEN
		SELECT * 
		FROM Teachers
		WHERE emailAddress = _emailAddress AND pwd = SHA1(_pwd);
	ELSE
		SELECT "Your email address and/or password is wrong.";
	END IF;
    
END$$

DELIMITER $$
CREATE PROCEDURE add_teacher_instrument(
	IN _teacherID INT,
    IN _instrumentName VARCHAR(30),
    IN proficiency ENUM('Intermediate','Advanced','Expert')
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher is listed with this ID";
	ELSEIF _instrumentName IS NULL
		OR proficiency IS NULL
        OR (SELECT COUNT(*) FROM Instruments WHERE instrumentName=_instrumentName) = 0 THEN
			SELECT "ERROR: Required Fields are incorrect/empty";
	ELSEIF (
			SELECT COUNT(*) 
            FROM TeacherInstruments 
            WHERE teacherID=_teacherID AND instrument=_instrumentName
		) != 0 THEN
			SELECT "ERROR: Duplicate Entry Found";
	ELSE
		INSERT INTO TeacherInstruments(teacherID, instrument, instrumentLevel)
		VALUES(_teacherID, _instrumentName, proficiency);
        SELECT "Successfully added an instrument to the teacher";
	END IF;
END$$

DELIMITER $$
CREATE PROCEDURE get_teacher_instrument(
	IN _teacherID INT
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher is listed with this ID";
	ELSE
		SELECT instrument, instrumentLevel 
		FROM TeacherInstruments
		WHERE teacherID=_teacherID;
	END IF;
END$$

DELIMITER $$
CREATE PROCEDURE add_teacher_language(
	IN _teacherID INT,
    IN _spokenLanguage VARCHAR(30),
    IN aptitude ENUM('Intermediate','Advanced','Expert')
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher is listed with this ID";
	ELSEIF _spokenLanguage IS NULL
		OR aptitude IS NULL THEN
			SELECT "ERROR: Required Fields are incorrect/empty";
	ELSEIF (
			SELECT COUNT(*) 
            FROM TeacherSpokenLanguages 
            WHERE teacherID=_teacherID AND spokenLanguage=_spokenLanguage
		) != 0 THEN
			SELECT "ERROR: Duplicate Entry Found";
	ELSE
		INSERT INTO TeacherSpokenLanguages(teacherID, spokenLanguage, spokenLanguagesAptitude)
		VALUES(_teacherID, _spokenLanguage, aptitude);
        SELECT "Successfully added a spoken language to the teacher";
	END IF;
END$$

DELIMITER $$
CREATE PROCEDURE get_teacher_languages(
	IN _teacherID INT
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher is listed with this ID";
	ELSE
		SELECT spokenLanguage, spokenLanguagesAptitude 
		FROM TeacherSpokenLanguages
		WHERE teacherID=_teacherID;
	END IF;
END$$

DELIMITER $$
CREATE PROCEDURE add_teacher_qualifications(
	IN _teacherID INT,
    IN _qualification VARCHAR(255),
    IN _description TEXT
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher is listed with this ID";
	ELSEIF _qualification IS NULL
		OR _description IS NULL THEN
			SELECT "ERROR: Required Fields are incorrect/empty";
	ELSEIF (
			SELECT COUNT(*) 
            FROM TeacherQualifications 
            WHERE teacherID=_teacherID AND qualification=_qualification
		) != 0 THEN
			SELECT "ERROR: Duplicate Entry Found";
	ELSE
		INSERT INTO TeacherQualifications(teacherID, qualification, description)
		VALUES(_teacherID, _qualification, _description);
        SELECT "Successfully added a qualification to the teacher";
	END IF;
END$$


DELIMITER $$
CREATE PROCEDURE get_teacher_qualifications(
	IN _teacherID INT
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher is listed with this ID";
	ELSE
		SELECT qualification, description 
		FROM TeacherQualifications
		WHERE teacherID=_teacherID;
	END IF;
END$$

DELIMITER $$
CREATE PROCEDURE add_teacher_feedback(
	IN _teacherID INT,
    IN _studentID INT,
    IN _rating INT,
    IN _comments TEXT
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher is listed with this ID";
	ELSEIF (SELECT studentID FROM Students WHERE studentID=_studentID) IS NULL THEN
		SELECT "ERROR: No student is listed with that student ID";
	ELSEIF _rating IS NULL THEN
			SELECT "ERROR: Required Field is incorrect/empty";
	ELSEIF (
			SELECT COUNT(*) 
            FROM TeacherFeedback 
            WHERE teacherID=_teacherID AND studentID=_studentID
		) != 0 THEN
			SELECT "ERROR: Duplicate Entry Found";
	ELSE
		INSERT INTO TeacherFeedback(teacherID, studentID, rating, comments)
		VALUES(_teacherID, _studentID, _rating, _comments);
        SELECT "Successfully added feedback to the teacher";
	END IF;
END$$


DELIMITER $$
CREATE PROCEDURE get_teacher_feedback(
	IN _teacherID INT
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher is listed with this ID";
	ELSE
		SELECT rating, comments
		FROM TeacherFeedback
		WHERE teacherID=_teacherID;
    END IF;
END $$

DELIMITER $$
CREATE PROCEDURE change_teacher_password(
	IN _emailAddress VARCHAR(30),
    IN _pwd VARCHAR(255)
)
BEGIN
	IF _pwd IS NULL THEN
		SELECT "ERROR: Password Field is Empty";
        
    ELSEIF (SELECT check_teacher_email_exists(_emailAddress) = 1) THEN
		UPDATE Teachers
		SET pwd = _pwd
		WHERE emailAddress=SHA1(_emailAddress);
        SELECT "Successfully updated password";
	ELSE
		SELECT "Email address is not listed";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_teacher_id(
	IN _emailAddress VARCHAR(30)
)
BEGIN
	DECLARE _teacherID INT;
    
    SET _teacherID = (SELECT teacherID 
    FROM Teachers
    WHERE emailAddress=_emailAddress);
    
    IF _teacherID IS NULL THEN
		SELECT "ERROR: No Entry Found";
	ELSE
		SELECT _teacherID;
	END IF;

END $$

DELIMITER $$
CREATE PROCEDURE update_teacher_profile_image(
	_teacherID INT,
    _profilePicture VARCHAR(5000)
)
BEGIN
	IF (SELECT teacherID FROM Teachers WHERE teacherID=_teacherID) IS NULL THEN
		SELECT "ERROR: No teacher is listed with this teacher ID.";
	ELSEIF _profilePicture IS NULL THEN
		SELECT "ERROR: Not all of the required fields have been filled.";
	ELSE
		UPDATE Teachers
		SET profilePicture=_profilePicture
		WHERE teacherID=_teacherID;
        SELECT "Successfully updated profile picture";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_list_of_teachers_by_employment_type(
	employmentType ENUM('Employed', 'Applicant', 'Terminated')
)
BEGIN
	
    SELECT * FROM Teachers
    WHERE 
    CASE employmentType
		WHEN 'Employed' THEN
			occupationStatus='Employed'
        WHEN 'Applicant' THEN
			occupationStatus='Applicant'
		WHEN 'Terminated' THEN
			occupationStatus='Terminated'
		END
	ORDER BY lastName ASC;
END$$

DELIMITER $$
CREATE PROCEDURE change_teacher_employment_status(
	_teacherID INT, 
    employmentType ENUM('Employed', 'Applicant', 'Terminated')
)
BEGIN
	UPDATE Teachers
    SET occupationStatus=employmentType
    WHERE teacherID=_teacherID
    LIMIT 1;
END $$


DELIMITER //
CREATE FUNCTION check_teacher_email_exists(
	_emailAddress VARCHAR(30)
)
RETURNS INT
BEGIN
	DECLARE result INT;
    SET result = (
		SELECT COUNT(*)
		FROM Teachers
		WHERE emailAddress=_emailAddress
        );
	IF result = 1 THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
    END IF;    
END//

DELIMITER //
CREATE FUNCTION check_teacher_account_exists(
	_emailAddress VARCHAR(30),
    _pwd VARCHAR(160)
)
RETURNS INT
BEGIN
	DECLARE result INT;
    SET result = (
		SELECT COUNT(*)
		FROM Teachers
		WHERE emailAddress=_emailAddress AND pwd=_pwd
        );
	IF result = 1 THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
    END IF;    
END//







