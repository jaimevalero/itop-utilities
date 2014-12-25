-- Create test data, to to the synch.sh script
--

CREATE DATABASE IF NOT EXISTS DBName

DROP TABLE IF EXISTS `orgs`;

-- Create Organization table
CREATE TABLE `orgs` (
  `Org_Name` varchar(250) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `orgs` VALUES ('My orgazation name'),('Other org');

DROP TABLE IF EXISTS `servers`;

-- Create Servers table
CREATE TABLE `servers` (
  `Name` varchar(250) DEFAULT NULL,
  `IP` varchar(250) DEFAULT NULL,
  `Notes` varchar(250) DEFAULT NULL,
  `CPU` varchar(250) DEFAULT NULL,
  `Memory` varchar(250) DEFAULT NULL,
  `Initial_Date` varchar(250) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `servers` VALUES ('Google Dns','8.8.8.8','DNS Servers','','','2012-01-01'),('Raspberry PI','192.168.1.1','I am so glad I bought it','1','8 MB','2013-06-02');


