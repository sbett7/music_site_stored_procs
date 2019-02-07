USE sbett7_music_school1;


CREATE TABLE Instruments (
	instrumentName VARCHAR (30),
	instrumentType ENUM('Percussion','Brass','Woodwind','Strings','Keyboard'),
	image VARCHAR(5000),
	
	PRIMARY KEY (instrumentName)
)CHARACTER SET utf8, ENGINE=MyISAM;


CREATE TABLE InstrumentStock (
	instrumentID INT AUTO_INCREMENT,
	studentID INT DEFAULT NULL,
	instrumentName VARCHAR(30) NOT NULL,
	instrumentCondition ENUM('New', 'Excellent', 'Good', 'Repair', 'Discard') NOT NULL,
	costPerHour DECIMAL(5,2) DEFAULT 10.00,
	lessonCost DECIMAL(5,2) DEFAULT 32.50,
	startDate DATETIME DEFAULT NULL,
	endDate DATETIME DEFAULT NULL,

	PRIMARY KEY (instrumentID),
	CONSTRAINT listed_instrument FOREIGN KEY (instrumentName) REFERENCES Instruments(instrumentName),
	CONSTRAINT hired_by_student FOREIGN KEY (studentID) REFERENCES Students(studentID)
)CHARACTER SET utf8, ENGINE=MyISAM;

DELIMITER $$
CREATE PROCEDURE add_instrument_stock_entry(
	_instrumentName VARCHAR(30),
    _instrumentCondition ENUM('New', 'Excellent', 'Good', 'Repair', 'Discard')
)
BEGIN
	IF _instrumentName OR _instrumentCondition IS NULL THEN
		SELECT "ERROR: Not all of the required fields have been filled";
	ELSEIF (SELECT COUNT(*) FROM Instruments WHERE instrumentName=_instrumentName) = 0 THEN
		SELECT "ERROR: No Instruments with that name have been listed";
	ELSE
		INSERT INTO InstrumentStock(instrumentName, instrumentCondition)
		VALUES (_instrumentName, _instrumentCondition); 
        SELECT "Successfully added an instrument to stock";
	END IF;
    
END $$

DELIMITER $$
CREATE PROCEDURE update_instrument_condition(
	_instrumentID INT,
    _instrumentCondition ENUM('New', 'Excellent', 'Good', 'Repair', 'Discard')
)
BEGIN
	IF (SELECT COUNT(*) FROM InstrumentStock WHERE instrumentID=_instrumentID) = 0 THEN
		SELECT "ERROR: No instruments with that ID are listed";
	ELSEIF _instrumentID IS NULL OR _instrumentCondition IS NULL THEN
		SELECT "ERROR: Not all of the required fields have been filled";
	ELSE
		UPDATE InstrumentStock
		SET instrumentCondition=_instrumentCondition
		WHERE instrumentID=_instrumentID;
        SELECT "Successfully updated instrument condition";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE update_instrument_entry_with_student_hire(
	_instrumentID INT,
    _studentID INT,
    daysHiredFor INT
)
BEGIN
	IF (SELECT COUNT(*) FROM Students WHERE studentID = _studentID) = 0 THEN
		SELECT "ERROR: No students with that ID are listed";
	ELSEIF (SELECT COUNT(*) FROM InstrumentStock WHERE instrumentID=_instrumentID) = 0 THEN
		SELECT "ERROR: No instruments with that ID are listed";
	ELSEIF daysHiredFor IS NULL THEN
		SELECT "ERROR: Not all of the required fields have been filled";
	ELSE
		UPDATE InstrumentStock
		SET 
			studentID=_studentID,
			startdate=CURDATE(),
			endDate=DATE_ADD(CURDATE(), INTERVAL daysHiredFor DAY)
		WHERE instrumentID = _instrumentID;
        SELECT "Successfully loaned instrument to student";
	END IF;
    
END $$

DELIMITER $$
CREATE PROCEDURE remove_student_from_instrument_entry(
	_instrumentID INT
)
BEGIN
	IF (SELECT COUNT(*) FROM InstrumentStock WHERE instrumentID=_instrumentID) = 0 THEN
		SELECT "ERROR: No instruments with that ID are listed";
	ELSE
		UPDATE InstrumentStock
		SET
			studentID=NULL,
			startdate=NULL,
			endDate=NULL
		WHERE instrumentID = _instrumentID;
        SELECT "Successfully restocked instrument";
	END IF;
END $$


DELIMITER $$
CREATE PROCEDURE get_instrument_images_by_type(
	_instrumentType enum('Percussion','Brass','Woodwind','Strings','Keyboard')
)
BEGIN
	IF _instrumentType IS NULL THEN
		SELECT "ERROR: Not all of the required fields have been filled.";
	ELSEIF (SELECT COUNT(*) FROM Instruments WHERE instrumentType=_instrumentType) IS NULL THEN
		SELECT "ERROR: No instruments in this category are listed.";
	ELSE
		SELECT instrumentName, image
		FROM Instruments
        WHERE instrumentType=_instrumentType;
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_instrument_image_by_name(
	_instrumentName VARCHAR(30)
)
BEGIN
	IF _instrumentName IS NULL THEN
		SELECT "ERROR: Not all of the required fields have been filled.";
	ELSEIF (SELECT COUNT(*) FROM Instruments WHERE instrumentName=_instrumentName) IS NULL THEN
		SELECT "ERROR: There is no instrument by this name.";
	ELSE
		SELECT image
		FROM Instruments
        WHERE instrumentName=_instrumentName;
	END IF;
END $$


DELIMITER $$
CREATE PROCEDURE get_list_of_available_instruments(
	
)
BEGIN
	SELECT InstrumentStock.instrumentName, Instruments.instrumentType,
		InstrumentStock.lessonCost, InstrumentStock.costPerHour,
        COUNT(InstrumentStock.instrumentID) AS instrumentStock
	FROM InstrumentStock LEFT JOIN Instruments
		ON InstrumentStock.instrumentName=Instruments.InstrumentName
	WHERE InstrumentStock.studentID IS NULL
    GROUP BY InstrumentStock.instrumentName
    ORDER BY InstrumentStock.instrumentName;
END $$

DELIMITER $$
CREATE PROCEDURE get_instrument_details_from_grouped_instruments(
	_instrumentName VARCHAR(30)
)
BEGIN
	SELECT *
    FROM InstrumentStock
    WHERE instrumentName=_instrumentName
    AND instrumentCondition != 'Discard'
    AND instrumentCondition != 'Repair'
    AND studentID = NULL
    ORDER BY instrumentCondition, instrumentID ASC
    LIMIT 1;
END $$

DELIMITER $$
CREATE PROCEDURE add_student_id_to_instrument_from_group_instruments(
	_instrumentName VARCHAR (30),
    _studentID INT,
    daysHiredFor INT
)
BEGIN
	DECLARE _instrumentID INT;
	SET _instrumentID = (
		SELECT *
		FROM InstrumentStock
		WHERE instrumentName=_instrumentName
		AND instrumentCondition != 'Discard'
		AND instrumentCondition != 'Repair'
		AND studentID = NULL
		ORDER BY instrumentCondition, instrumentID ASC
		LIMIT 1
	);
	
	IF (SELECT COUNT(*) FROM Students WHERE studentID = _studentID) = 0 THEN
		SELECT "ERROR: No students with that ID are listed";
	ELSEIF (SELECT COUNT(*) FROM InstrumentStock WHERE instrumentName=_instrumentName AND studentID IS NULL) = 0 THEN
		SELECT "ERROR: No available instruments with that name";
	ELSEIF daysHiredFor IS NULL THEN
		SELECT "ERROR: Not all of the required fields have been filled";
	ELSE
		UPDATE InstrumentStock
		SET 
			studentID=_studentID,
			startdate=CURDATE(),
			endDate=DATE_ADD(CURDATE(), INTERVAL daysHiredFor DAY)
		WHERE instrumentID = _instrumentID;
        SELECT "Successfully loaned instrument to student";
	END IF;
END $$

DELIMITER $$
CREATE PROCEDURE get_students_hired_instruments(
	_studentID INT
)
BEGIN
	SELECT *
    FROM InstrumentStock
    WHERE studentID=_studentID
    ORDER BY endDate ASC;
END $$

DELIMITER $$
CREATE PROCEDURE search_instrument_stock(
	filterByType VARCHAR(30),
    filterByString VARCHAR(30)

)
BEGIN
	SELECT DISTINCT instrumentName, costPerHour, lessonCost
    FROM InstrumentStock
    WHERE
    CASE filterByType
		WHEN 'Instrument Type' THEN
			instrumentName IN (
				SELECT instrumentName
                FROM Instruments
                WHERE instrumentType=filterByString
		)
	END;
END$$