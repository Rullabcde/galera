# Galera Cluster 3 Node + ProxySQL

Ini setup database HA (High Availability) yang dibuat pake **MariaDB Galera Cluster** (3 node) dan **ProxySQL** buat handle query routing (write-read split). Tujuannya biar database bisa tahan banting & scalable.

---

## Konfigurasi Detail

### Galera Node (node-1, node-2, node-3)

Config-nya **hampir sama semua**, bedanya cuma di `wsrep_node_name` & `wsrep_node_address`.

Contoh `node-1` (`db1`):

```ini
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera setup
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so
wsrep_cluster_name="test_cluster"
wsrep_cluster_address="gcomm://db1,db2,db3"
wsrep_sst_method=rsync

# Identitas node ini
wsrep_node_address="db1"
wsrep_node_name="mariadb1"
```

Yang lain tinggal ganti `db1` → `db2` / `db3` dan `mariadb1` → `mariadb2` / `mariadb3`.

---

### ProxySQL

File config utama (`/etc/proxysql.cnf`):

```ini
datadir="/var/lib/proxysql"

admin_variables=
{
    admin_credentials="admin:admin"
}

mysql_variables=
{
    connect_timeout_server=3000
    monitor_username="monitor"
    monitor_password="monitor"
    monitor_connect_timeout=1000
    monitor_ping_timeout=1000
    monitor_read_only_max_timeout_count=5
}
```

---

### init.sql ProxySQL

Script buat setup routing logic di ProxySQL.

```sql
-- Bersihin dulu
DELETE FROM mysql_servers;
DELETE FROM mysql_users;
DELETE FROM mysql_query_rules;

-- Tambah node ke hostgroup
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES
(10, 'db1', 3306),   -- untuk query write
(20, 'db2', 3306),   -- untuk query read
(20, 'db3', 3306);   -- untuk query read

-- User buat aplikasi
INSERT INTO mysql_users (username, password, default_hostgroup) VALUES
('rullabcd', 'rullabcd', 10);

-- User buat monitoring
INSERT INTO mysql_users (username, password, default_hostgroup, transaction_persistent) VALUES
('monitor', 'monitor', 10, 1);

-- Routing rule: SELECT → hostgroup 20
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply) VALUES
(1, 1, '^SELECT .*', 20, 1);

-- Load ke runtime
LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;

-- Save ke disk biar persistent
SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;
```

---

## Testing

1. **Cek Galera**: semua node harus `Synced`

   ```sql
   SHOW STATUS LIKE 'wsrep%';
   ```

2. **Cek ProxySQL**: login ke admin port (6032)

   ```bash
   mysql -u admin -padmin -h 127.0.0.1 -P 6032
   ```

3. **Tes Query Split**:

   - `SELECT` → harus kena `db2` atau `db3`
   - `INSERT` → harus masuk ke `db1`
   - Coba `SHOW PROCESSLIST;` di masing-masing DB

---

## Catatan

- Galera itu multi-master, tapi disarankan nulis ke satu node doang (biar gak conflict)
- `monitor` user wajib ada di semua node Galera (user + pass sama)
- Kalo mau tambah node atau ubah hostgroup, tinggal edit via admin port atau `init.sql`

---
