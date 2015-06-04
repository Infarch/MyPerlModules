# --------------------------------------------------------
# Host:                         127.0.0.1
# Database:                     whois
# Server version:               5.1.47-community
# Server OS:                    Win32
# HeidiSQL version:             5.0.0.3272
# Date/time:                    2010-11-27 00:25:00
# --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
# Dumping database structure for whois
CREATE DATABASE IF NOT EXISTS `whois` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `whois`;


# Dumping structure for table whois.domain
DROP TABLE IF EXISTS `domain`;
CREATE TABLE IF NOT EXISTS `domain` (
  `ID` int(10) NOT NULL AUTO_INCREMENT,
  `Name` varchar(100) NOT NULL,
  `Delegated` tinyint(2) DEFAULT NULL,
  `CreatedDate` date DEFAULT NULL,
  `IP` varchar(15) DEFAULT NULL,
  `YandexPages` int(10) DEFAULT NULL,
  `LoadedDate` date DEFAULT NULL,
  `CY` int(3) DEFAULT NULL,
  `Mirror` int(3) DEFAULT NULL,
  /*`RegisterDate` date DEFAULT NULL,*/
  `Owner` varchar(500) DEFAULT NULL,
  `Email` varchar(200) DEFAULT NULL,
  `Raw` text,
  `Done` TINYINT(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

# Dumping data for table whois.domain: 0 rows
/*!40000 ALTER TABLE `domain` DISABLE KEYS */;
/*!40000 ALTER TABLE `domain` ENABLE KEYS */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
