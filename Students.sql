use sbett7_music_school1;
CREATE TABLE IF NOT EXISTS Students(
	studentID INT NOT NULL AUTO_INCREMENT,
	pwd VARCHAR(160) NOT NULL,
	firstName VARCHAR(15) NOT NULL,
	lastName VARCHAR(15) NOT NULL,
	DOB DATE NOT NULL,
	gender ENUM ('M', 'F') NOT NULL,
	streetNo VARCHAR(5),
	street VARCHAR(30),
	suburb VARCHAR(30),
	postcode INT(4),
	state ENUM ('QLD', 'NSW', 'NT', 'WA', 'SA', 'TAS', 'VIC', 'ACT'),	
    mobilePhone VARCHAR (12) NOT NULL,
	emailAddress VARCHAR (30) NOT NULL UNIQUE,
	facebookDetails VARCHAR(5000),
    profilePicture VARCHAR(5000) DEFAULT 'http://kobra.heliohost.org/IFB299%20Music%20School/public/img/teachertwo.jpg',
	PRIMARY KEY (studentID),
	CONSTRAINT postcodeCheck CHECK (postcode LIKE '[1-9][0-9][0-9][0-9]')
)CHARACTER SET utf8, ENGINE=MyISAM;
SELECT * From Students WHERE firstName='Jeremy' AND lastName='James';

CREATE TABLE IF NOT EXISTS Parents(
	parentID INT AUTO_INCREMENT,
	firstName VARCHAR(15) NOT NULL,
	lastName VARCHAR(15) NOT NULL,
	mobilePhone VARCHAR (12) NOT NULL,
	emailAddress VARCHAR (30) NOT NULL UNIQUE,
	PRIMARY KEY (parentID)
) CHARACTER SET utf8, ENGINE=MyISAM;

CREATE TABLE IF NOT EXISTS ParentChild(
	parentID INT NOT NULL,
	studentID INT NOT NULL,
	CONSTRAINT parentKey FOREIGN KEY (parentID) REFERENCES Parents(parentID) ON DELETE CASCADE ON UPDATE CASCADE, 
	CONSTRAINT studentKey FOREIGN KEY (studentID) REFERENCES Students(studentID) ON DELETE CASCADE ON UPDATE CASCADE
)CHARACTER SET utf8, ENGINE=MyISAM;




# Stored Procedures
DELIMITER $$
CREATE PROCEDURE add_student(
	IN _pwd VARCHAR(160), 
    IN _firstName VARCHAR(15), 
	IN _lastName VARCHAR(15), 
    IN _DOB DATE, 
    IN _gender ENUM('M','F'), 
    IN _streetNo VARCHAR(4), 
    IN _street VARCHAR(30), 
    IN _suburb VARCHAR (30), 
	IN _postcode VARCHAR(4),
    IN _state ENUM ('QLD', 'NSW', 'NT', 'WA', 'SA', 'TAS', 'VIC', 'ACT'),
    IN _mobilePhone VARCHAR (12), 
    IN _emailAddress VARCHAR (30), 
    IN _facebookDetails VARCHAR (5000)
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
    ELSEIF (SELECT check_student_age(_DOB)) IS FALSE THEN
		SELECT "ERROR: Applicant is too young.";
	ELSEIF (SELECT emailAddress FROM Students WHERE emailAddress=_emailAddress) IS NOT NULL THEN
		SELECT "ERROR: An account is already registered with that email address";
    
	ELSE
		INSERT INTO Students(
			pwd, firstName, lastName, DOB, gender, streetNo, street,
			suburb, state, postcode, mobilePhone, emailAddress, facebookDetails
		)
		VALUES(
			SHA1(_pwd), _firstName, _lastName, _DOB, _gender, _streetNo, _street,
			_suburb, _state, _postcode, _mobilePhone, _emailAddress, _facebookDetails
		);
        SELECT "Successful";
	END IF;
END$$

DELIMITER $$
CREATE PROCEDURE update_student_details(
	IN _studentID INT,
    IN _pwd VARCHAR(160), 
    IN _firstName VARCHAR(15), 
	IN _lastName VARCHAR(15), 
    IN _streetNo VARCHAR(4), 
    IN _street VARCHAR(30), 
    IN _suburb VARCHAR (30), 
    IN _postcode VARCHAR(4),
    IN _state ENUM ('QLD', 'NSW', 'NT', 'WA', 'SA', 'TAS', 'VIC', 'ACT'),
    IN _mobilePhone VARCHAR (12), 
    IN _emailAddress VARCHAR (30), 
    IN _facebookDetails VARCHAR (5000)
)
BEGIN
	IF _pwd IS NULL
		OR _firstName IS NULL
        OR _lastName IS NULL
        OR _mobilePhone IS NULL
        OR _emailAddress IS NULL THEN
			SELECT "ERROR: Not all of the required fields have been filled.";
	ELSEIF (SELECT emailAddress FROM Students WHERE emailAddress=_emailAddress AND studentID !=_studentID) IS NOT NULL THEN
		SELECT "ERROR: An account is already registered with that email address";
        
	ELSE
		UPDATE Students
		SET pwd=SHA1(_pwd), firstName=_firstName, lastName=_lastName, streetNo=_streetNo,
			street=_street, suburb=_suburb, state=_state, postcode=_postcode, 
			mobilePhone=_mobilePhone, emailAddress=_emailAddress, 
			facebookDetails=_facebookDetails
		WHERE studentID=_studentID;
        SELECT "Successfully updated account information.";
    END IF;
END$$

DELIMITER $$
CREATE PROCEDURE get_student_session(
	IN _emailAddress VARCHAR (30), 
	IN _pwd VARCHAR (160)
)
BEGIN
	IF(SELECT check_student_account_exists(_emailAddress, SHA1(_pwd))) IS TRUE THEN
		SELECT * 
		FROM Students
		WHERE emailAddress = _emailAddress AND pwd = SHA1(_pwd);
	ELSE
		SELECT "Your email address and/or password is incorrect.";
	END IF;
    
END$$

DELIMITER $$
CREATE PROCEDURE add_parent(
	IN _firstName VARCHAR(15),
    IN _lastName VARCHAR(15),
    IN _mobilePhone VARCHAR(12),
    IN _emailAddress VARCHAR(30)
)
BEGIN
	IF _firstName IS NULL
		AND _lastName IS NULL
        AND _mobilePhone IS NULL
        AND _emailAddress IS NULL THEN
			SELECT "No Parent Information Provided";
	ELSEIF _firstName IS NULL 
		OR _lastName IS NULL
        OR _mobilePhone IS NULL 
        OR _emailAddress IS NULL THEN
			SELECT "ERROR: Required Fields have not been filled";
	ELSEIF (SELECT parentID FROM Parents WHERE 
			firstName=_firstName AND lastName=_lastName AND mobilePhone=_mobilePhone
            AND emailAddress=_emailAddress
            ) IS NOT NULL THEN
			SELECT "ERROR: Duplicate Parent Entry Found";
	ELSE
		INSERT INTO Parents(firstName, lastName, mobilePhone, emailAddress)
		VALUES (_firstName, _lastName, _mobilePhone, _emailAddress);
        SELECT "Successfully created a Parent Entry";
	END IF;
END$$


DELIMITER $$
CREATE PROCEDURE add_student_parent_relation(
	IN _studentID VARCHAR(15),
	IN parentFirstName VARCHAR(15),
    IN parentLastName VARCHAR (15),
    IN parentMobilePhone VARCHAR(12),
    IN parentEmailAddress VARCHAR(30)
)
BEGIN
	DECLARE _parentID INT;
    SET _parentID = (
			SELECT parentID From Parents WHERE firstName=parentFirstName 
			AND lastName=parentLastName
            AND mobilePhone=parentMobilePhone
			AND emailAddress=parentEmailAddress
		);
	IF (SELECT studentID FROM Students WHERE studentID=_studentID) IS NULL THEN
		SELECT "ERROR: No student with that student ID is listed";
	ELSEIF _parentID IS NULL THEN
		SELECT "ERROR: No parent with this information is listed";
	ELSEIF (SELECT parentID FROM ParentChild WHERE parentID=_parentID AND studentID=_studentID) IS NOT NULL THEN
		SELECT "ERROR: A student-parent relationship between these two entries has already been made";
	ELSE
		INSERT INTO ParentChild(parentID, studentID)
		VALUES (
			_parentID,  
			_studentID);
		SELECT "Successfully created student-parent Relationship.";
	END IF;
END$$

DELIMITER $$
CREATE PROCEDURE update_parent_details(
	IN _studentID INT,
    IN _firstName VARCHAR(15), 
	IN _lastName VARCHAR(15), 
    IN _mobilePhone VARCHAR (12), 
    IN _emailAddress VARCHAR (30)
)
BEGIN
	DECLARE _parentID INT;
    SET _parentID = (SELECT parentID 
			FROM ParentChild NATURAL JOIN Parents 
			WHERE studentID=_studentID 
			AND firstName=_firstName
            AND lastName=_lastName);
	IF _firstName IS NULL 
		OR _lastName IS NULL THEN
			SELECT "ERROR: Required Parent Name field has not been filled";
	ELSEIF _mobilePhone IS NULL
		OR _emailAddress IS NULL THEN
			SELECT "ERROR: Required Parent Contact fields have not been filled";
	ELSEIF (SELECT COUNT(*) FROM Students WHERE studentID=_studentID) = 0 THEN
		SELECT "ERROR: No student with that student ID is listed";
	ELSEIF (SELECT parentID FROM Parents WHERE 
			firstName=_firstName AND lastName=_lastName AND mobilePhone=_mobilePhone
            AND emailAddress=_emailAddress AND parentID !=_parentID
            ) IS NOT NULL THEN
			SELECT "ERROR: Duplicate Parent Entry Found";
	ELSEIF _parentID IS NULL THEN
		SELECT "ERROR: No parent with this ID/Name is listed";
	ELSE
		UPDATE Parents
		SET mobilePhone=_mobilePhone, emailAddress=_emailAddress
		WHERE parentID=_parentID;
		SELECT "Successfully updated Parent Information";
	END IF;
END$$

DELIMITER $$
CREATE PROCEDURE remove_parent(
	IN _studentID INT,
    IN parentFirstName VARCHAR(15),
	IN parentLastName VARCHAR(15)
)  
BEGIN
	DECLARE _parentID INT;
        SET _parentID = (SELECT parentID 
        FROM ParentChild NATURAL JOIN Parents
        WHERE studentID=_studentID
        AND firstName=parentFirstName
        AND lastName=parentLastName);
    
	IF (SELECT studentID FROM Students WHERE studentID=_studentID) IS NULL THEN
		SELECT "ERROR: No student with this student ID is listed";
	ELSEIF _parentID IS NULL THEN
		SELECT "ERROR: No parent is listed with this Parent ID/Name";
	ELSE
		DELETE FROM Parents
		WHERE parentID=_parentID
		LIMIT 1;
		SELECT "Successfully deleted the Parent information";
	END IF;

END $$


DELIMITER $$
CREATE PROCEDURE remove_parent_relation(
	IN _studentID INT,
    IN parentFirstName VARCHAR(15),
    IN parentLastName VARCHAR(15)
)
BEGIN
	DECLARE _parentID INT;
    SET _parentID=(
		SELECT parentID FROM ParentChild
        NATURAL JOIN Parents
        WHERE firstName=parentFirstName 
        AND lastName= parentLastName
        AND studentID=_studentID
    );
    IF (SELECT studentID FROM Students WHERE studentID=_student) IS NULL THEN
		SELECT "ERROR: No student with this student ID is listed.";
    ELSEIF _parentID IS NULL THEN
		SELECT "ERROR: No relationship between this parent and student is recorded or this parent doesn't exist.";
	ELSE
		DELETE FROM ParentChild
		WHERE studentID=_studentID AND parentID=(
			SELECT parentID FROM Parents
			WHERE firstName=parentFirstName AND
			lastName= parentLastName
		)
		LIMIT 1;
		SELECT "Sucessfully deleted parent child relation entry";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE remove_student(
	IN _studentID INT
)
BEGIN
	IF (SELECT studentID FROM Students WHERE studentID=_studentID) IS NOT NULL THEN
		DELETE FROM Students
		WHERE studentID=_studentID
		LIMIT 1;
		SELECT "Successfully Removed Student Account";
    ELSE
		SELECT "ERROR: There is no student with this student ID";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE change_student_password(
	IN _emailAddress VARCHAR(30),
    IN _pwd VARCHAR(160)
)
BEGIN
	IF _pwd IS NULL THEN
		SELECT "ERROR: The password field is empty";
    ELSEIF (SELECT check_student_email_exists(_emailAddress)) IS TRUE THEN
		UPDATE Students
		SET pwd = SHA1(_pwd)
		WHERE emailAddress=_emailAddress;
        SELECT "Successfully updated password";
	ELSE
		SELECT "Email address is not listed";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_student_id(
	IN _emailAddress VARCHAR(30)
)
BEGIN
	DECLARE _studentID INT;
    
    SET _studentID = (SELECT studentID 
    FROM Students
    WHERE emailAddress=_emailAddress);
    
    IF _studentID IS NULL THEN
		SELECT "ERROR: No Entry Found";
	ELSE
		SELECT _studentID;
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_students_parents(
	IN _studentID INT
)
BEGIN
    IF (SELECT studentID FROM Students WHERE studentID=_studentID) IS NOT NULL THEN
		IF (
			SELECT parentID
			FROM Students
			NATURAL JOIN ParentChild
			WHERE studentID =_studentID
            LIMIT 1
        ) IS NULL THEN
			SELECT "ERROR: This student does not have any parents listed";
		ELSE
			SELECT Parents.* 
			FROM Parents
			NATURAL JOIN ParentChild
			WHERE studentID =_studentID;
		END IF;
	ELSE
		SELECT "ERROR: No student with this student ID is listed";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE update_student_profile_image(
	_studentID INT,
    _profilePicture VARCHAR(5000)
)
BEGIN
	IF (SELECT studentID FROM Students WHERE studentID=_studentID) IS NULL THEN
		SELECT "ERROR: No student is listed with this student ID.";
	ELSEIF _profilePicture IS NULL THEN
		SELECT "ERROR: Not all of the required fields have been filled.";
	ELSE
		UPDATE Students
		SET profilePicture=_profilePicture
		WHERE studentID=_studentID;
        SELECT "Successfully updated profile picture";
	END IF;
END $$

# Functions

DELIMITER //
CREATE FUNCTION check_student_age(
	dob DATE
)
RETURNS INT

BEGIN
	DECLARE age INT;
	SET age = DATEDIFF(CURDATE(), dob) /365.25;
    IF age >= 10 THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END //
DROP FUNCTION check_student_age

DELIMITER //
CREATE FUNCTION check_student_account_exists(
	_emailAddress VARCHAR(30),
    _pwd VARCHAR(160)
)
RETURNS INT
BEGIN
	DECLARE result INT;
    SET result = (
		SELECT COUNT(*)
		FROM Students
		WHERE emailAddress=_emailAddress AND pwd=_pwd
        );
	IF result = 1 THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
    END IF;    
END//

DELIMITER //
CREATE FUNCTION check_student_email_exists(
	_emailAddress VARCHAR(30)
)
RETURNS INT
BEGIN
	DECLARE result INT;
    SET result = (
		SELECT COUNT(*)
		FROM Students
		WHERE emailAddress=_emailAddress
        );
	IF result = 1 THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
    END IF;    
END//





