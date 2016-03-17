select '----------- INNODB_ENGINE -------------';

show engine innodb status;

select '----------- PROCESSLIST -------------';

select * from information_schema.PROCESSLIST;

select '------------ INNODB_LOCKS -----------';

select * from information_schema.INNODB_LOCKS;

select '------------ INNODB_TRX -----------------';

select * from information_schema.INNODB_TRX;

select '----------- OPEN TABLES -------------';

show open tables;

select '----------------------------------------------';