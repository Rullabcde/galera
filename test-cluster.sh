#!/bin/bash

APP_USER="rullabcd"
APP_PASS="rullabcd"
APP_PORT=6033
PROXYSQL_ADMIN_USER="admin"
PROXYSQL_ADMIN_PASS="admin"
ADMIN_PORT=6032
HOST="127.0.0.1"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${GREEN}Testing koneksi ke ProxySQL sebagai app user...${NC}"
mysql -u$APP_USER -p$APP_PASS -h$HOST -P$APP_PORT <<EOF
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50));
INSERT INTO users (name) VALUES ('Alpha'), ('Bravo'), ('Charlie');
SELECT * FROM users;
EOF

echo -e "\n${GREEN}Mengambil info query digest dari ProxySQL Admin...${NC}"
docker exec -i proxysql mysql -u$PROXYSQL_ADMIN_USER -p$PROXYSQL_ADMIN_PASS -h$HOST -P$ADMIN_PORT -e "
SELECT hostgroup, username, digest_text, count_star, first_seen, last_seen
FROM stats_mysql_query_digest
ORDER BY last_seen DESC
LIMIT 10;
"

echo -e "\n${YELLOW}Note:${NC} Coba matikan salah satu DB node (db2 atau db3), lalu jalankan ulang script ini untuk lihat efek failover."
