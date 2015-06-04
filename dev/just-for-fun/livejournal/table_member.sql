CREATE TABLE `member` (
	`ID` INT(10) NOT NULL AUTO_INCREMENT COMMENT 'primary key',
	`Member_ID` INT(10) NULL DEFAULT NULL COMMENT 'parent member id',
	`URL` VARCHAR(250) NULL DEFAULT NULL COMMENT 'url of the member',
	`NextURL` VARCHAR(250) NULL DEFAULT NULL COMMENT 'url of the next page. makes sense when page number is greater than 1',
	`Type` TINYINT(1) NOT NULL COMMENT 'type of the member (category, product, image, etc.)',
	`Status` TINYINT(1) NOT NULL COMMENT 'status of the member (ready, processing, done)',
	`Level` TINYINT(3) NOT NULL DEFAULT '0' COMMENT 'level of the category. root category has level 0',
	`Page` SMALLINT(5) NOT NULL DEFAULT '1' COMMENT 'number of page. makes sense when the member\'s children takes more than one web page',
	`ShortDescription` TEXT NULL,
	`FullDescription` TEXT NULL,
	`Name` VARCHAR(250) NULL COMMENT 'name of the member',
	`InternalID` VARCHAR(50) NULL DEFAULT NULL COMMENT 'it might be article or some like that',
	`Vendor` VARCHAR(150) NULL DEFAULT NULL COMMENT 'Makes sense if the member is a product',
	`Price` FLOAT(11,2) NULL DEFAULT NULL COMMENT 'Makes sense if the member is a product',
	`Errors` TINYINT(2) NOT NULL DEFAULT '0' COMMENT 'Number of errors happening during processing this member',
	/*
	`CustomText1` TEXT NULL,
	`CustomText2` TEXT NULL,
	`CustomText3` TEXT NULL,
	`CustomVarc1` VARCHAR(200) NULL,
	`CustomVarc2` VARCHAR(200) NULL,
	`CustomVarc3` VARCHAR(200) NULL,
	*/
	PRIMARY KEY (`ID`),
	UNIQUE INDEX `URL` (`URL`),
	INDEX `FK_Member_Member` (`Member_ID`),
	CONSTRAINT `FK_Member_Member` FOREIGN KEY (`Member_ID`) REFERENCES `member` (`ID`)
)
ENGINE=InnoDB
ROW_FORMAT=DEFAULT
AUTO_INCREMENT=1