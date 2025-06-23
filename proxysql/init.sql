DELETE FROM mysql_servers;
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES
(10, 'db1', 3306),
(10, 'db2', 3306),
(10, 'db3', 3306);

DELETE FROM mysql_users;
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES
('rullabcd', 'siswa123', 10);

LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;

SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;