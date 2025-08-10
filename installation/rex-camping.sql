CREATE TABLE IF NOT EXISTS `rex_camping` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `campsiteid` varchar(50) DEFAULT NULL,
  `propid` varchar(50) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  `propdata` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;