CREATE TABLE `User` (
	`ID` INT(11) NOT NULL AUTO_INCREMENT,
	`URL` VARCHAR(500) NOT NULL,
	`Alias` VARCHAR(500) NOT NULL,
	`Status` TINYINT(1) NOT NULL DEFAULT '1',
	`Errors` TINYINT(1) NOT NULL DEFAULT '0',
	PRIMARY KEY (`ID`)
)
ENGINE=InnoDB
ROW_FORMAT=DEFAULT;

CREATE TABLE `Album` (
	`ID` INT(11) NOT NULL AUTO_INCREMENT,
	`URL` VARCHAR(500) NOT NULL,
	`Status` TINYINT(1) NOT NULL DEFAULT '1',
	`Errors` TINYINT(1) NOT NULL DEFAULT '0',
	`User_ID` INT(11) NOT NULL,
	`Name` VARCHAR(250) NULL DEFAULT NULL,
	PRIMARY KEY (`ID`),
	INDEX `FK_Category_User` (`User_ID`),
	CONSTRAINT `FK_Category_User` FOREIGN KEY (`User_ID`) REFERENCES `User` (`ID`)
)
ENGINE=InnoDB
ROW_FORMAT=DEFAULT;

CREATE TABLE `photo` (
	`ID` INT(11) NOT NULL AUTO_INCREMENT,
	`Album_ID` INT(11) NOT NULL,
	`URL` VARCHAR(500) NOT NULL,
	`Status` TINYINT(1) NOT NULL DEFAULT '1',
	`Errors` TINYINT(1) NOT NULL DEFAULT '0',
	`GoogleID` VARCHAR(50) NOT NULL,
	`Description` TEXT NULL,
	`IsNew` TINYINT(1) NOT NULL DEFAULT '0',
	`FileName` VARCHAR(500) NULL,
	PRIMARY KEY (`ID`),
	INDEX `FK_Photo_Album` (`Album_ID`),
	CONSTRAINT `FK_Photo_Album` FOREIGN KEY (`Album_ID`) REFERENCES `album` (`ID`)
)
ENGINE=InnoDB
ROW_FORMAT=DEFAULT;

