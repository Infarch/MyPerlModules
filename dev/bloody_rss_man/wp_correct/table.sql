# --------------------------------------------------------
# Host:                         127.0.0.1
# Database:                     wptest
# Server version:               5.1.47-community
# Server OS:                    Win64
# HeidiSQL version:             5.0.0.3272
# Date/time:                    2010-11-17 15:53:29
# --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
# Dumping database structure for wptest
CREATE DATABASE IF NOT EXISTS `wptest` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `wptest`;


# Dumping structure for table wptest.wp_posts
DROP TABLE IF EXISTS `wp_posts`;
CREATE TABLE IF NOT EXISTS `wp_posts` (
  `ID` int(10) NOT NULL AUTO_INCREMENT,
  `post_content` varchar(500) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

# Dumping data for table wptest.wp_posts: 8 rows
/*!40000 ALTER TABLE `wp_posts` DISABLE KEYS */;
INSERT INTO `wp_posts` (`ID`, `post_content`) VALUES (1, '<Being the nice <a href="http://www.icecreaang.com?wm_login=hгrenska&amp;cf=y"  manner="colour:#0000ff;font-weight:bold;">eading</a>ujhore'), (2, '<Being the nice <a href="http://www.icecreaang.com?wm_login=hгrenska&amp;cf=y"  manner="colour:#0000ff;font-weight:bold;">eading</a>ujhore'), (3, '<a href=\'http://www.icec.com?wm_login=henska&amp;cf=y\' ><img src="http://www.excussy.com/rss/ICB105000329/l_h_rss001.jpg" border></a></centre><br /><centre><font ><a href="http://www.iceang.com?wm_login=hdenska&amp;cf=y"  manner="colour:#0000ff;font-weight:bold;">T'), (4, '<a href=\'http://www.icec.com?wm_login=henska&amp;cf=y\' ><img src="http://www.excussy.com/rss/ICB105000329/l_h_rss001.jpg" border></a></centre><br /><centre><font ><a href="http://www.iceang.com?wm_login=hdenska&amp;cf=y"  manner="colour:#0000ff;font-weight:bold;">T'), (5, '<a href=\'http://www.icec.com?wm_login=henska&amp;cf=y\' ><img src="http://www.excussy.com/rss/ICB105000329/l_h_rss001.jpg" border></a></centre><br /><centre><font ><a href="http://www.iceang.com?wm_login=hdenska&amp;cf=y"  manner="colour:#0000ff;font-weight:bold;">T'), (6, '<a href = \'http:\\google.com\'  >Gogel</a>'), (7, '<a href = \'http:\\google.com\'  >Gogel</a>'), (8, '<a href = \'http:\\google.com\'  >Gogel</a>');
/*!40000 ALTER TABLE `wp_posts` ENABLE KEYS */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
