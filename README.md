# XP Docker Environment

Docker configuration for the distributed **eXPerimental Project (XP)** platform.

This repository provides containerized infrastructure components required for development and testing. The stack includes MariaDB database with automated schema/data initialization, plus the XP microservices.

---

## 🐳 Docker Services

The `docker-compose.yml` defines the following services:

### 1. **MariaDB Database**
- **Image:** `mariadb:latest`
- **Container:** `mariadb`
- **Port:** `3306:3306` (exposed to host)
- **Database:** `xp-users` (created automatically)
- **Credentials:**
  - Root: `root` / `password`
  - User: `user` / `password`
- **Volumes:**
  - `mariadb_data` - Persistent database storage
  - `./sql:/sql` - SQL initialization scripts (mounted)

### 2. **xp-users-service**
- **Image:** `gar2000b/xp-users-service:latest`
- **Container:** `xp-users-service`
- **Port:** `8081:8081`
- **Depends on:** `mariadb`
- **Environment:**
  - `SPRING_DATASOURCE_URL`: `jdbc:mariadb://mariadb:3306/xp-users`
  - `SPRING_DATASOURCE_USERNAME`: `root`
  - `SPRING_DATASOURCE_PASSWORD`: `password`
- **Volumes:**
  - `./logs:/app/logs` - Application logs

### 3. **xp-template-service**
- **Image:** `gar2000b/xp-template-service:latest`
- **Container:** `xp-template-service`
- **Port:** `8080:8080`
- **Depends on:** `mariadb`
- **Environment:**
  - `SPRING_DATASOURCE_URL`: `jdbc:mariadb://mariadb:3306/xp-users`
  - `SPRING_DATASOURCE_USERNAME`: `root`
  - `SPRING_DATASOURCE_PASSWORD`: `password`
- **Volumes:**
  - `./logs:/app/logs` - Application logs

---

## 🚀 Quick Start

### Prerequisites

- **Docker Engine** (20.10+)
- **Docker Compose** (v2.0+)

Verify installation:
```bash
docker --version
docker compose version
```

### Starting the Stack

**Option 1: Fresh start with database initialization**
```bash
./launch.sh
```

This script:
- Stops any running containers
- Removes the MariaDB volume (fresh database)
- Starts all containers
- Waits for MariaDB to be ready
- Runs SQL initialization scripts

**Option 2: Start existing containers**
```bash
./start.sh
```

This simply starts all containers without resetting the database.

### Stopping the Stack

**Stop containers (keeps data):**
```bash
./stop.sh
```

**Stop and remove containers (keeps volumes):**
```bash
docker compose down
```

**Complete cleanup (removes volumes and data):**
```bash
./delete.sh
```

---

## 📊 Database Initialization

The SQL initialization system automatically sets up databases, schemas, and test data when using `launch.sh`.

### SQL Structure

```
sql/
├── 00_init_all.sh              # Main initialization script
├── xp-users/                   # Database: xp-users
│   ├── schema/
│   │   └── 01_users.sql       # Creates users table
│   └── data/
│       ├── insert/
│       │   └── 01_insert_users.sql  # Inserts test users
│       └── update/
│           └── 01_update_users.sql  # Update patches
└── reporting_db/               # Database: reporting_db
    ├── schema/
    │   └── 01_events.sql       # Creates events table
    └── data/
        ├── insert/
        │   └── 01_insert_events.sql
        └── update/
            └── 01_update_events.sql
```

### Initialization Process

The `00_init_all.sh` script runs automatically after MariaDB starts and performs:

1. **Database Creation**
   - Creates `xp-users` database
   - Creates `reporting_db` database
   - Both use `utf8mb4` character set

2. **Schema Application**
   - Executes all `.sql` files in `schema/` directories
   - Files are executed in alphabetical order
   - Example: `xp-users/schema/01_users.sql` creates the `users` table

3. **Data Insertion**
   - Executes all `.sql` files in `data/insert/` directories
   - Populates tables with initial test data
   - Example: `xp-users/data/insert/01_insert_users.sql` inserts 10 test users

4. **Update Patches**
   - Executes all `.sql` files in `data/update/` directories
   - Used for data migrations or corrections

### Adding New Databases

To add a new database, edit `sql/00_init_all.sh`:

```bash
DATABASES="xp-users:xp-users reporting_db:reporting_db newdb:newdb"
```

Then create the folder structure:
```
sql/newdb/
├── schema/
│   └── 01_tables.sql
└── data/
    ├── insert/
    │   └── 01_insert_data.sql
    └── update/
```

---

## 🗄️ Database Schemas

### xp-users Database

**Table: `users`**
- `id` - BIGINT UNSIGNED (AUTO_INCREMENT, PRIMARY KEY)
- `username` - VARCHAR(50) (UNIQUE, NOT NULL)
- `first_name` - VARCHAR(100) (NOT NULL)
- `last_name` - VARCHAR(100) (NOT NULL)
- `email` - VARCHAR(255) (UNIQUE, NOT NULL)
- `created_at` - DATETIME (DEFAULT CURRENT_TIMESTAMP)
- `updated_at` - DATETIME (DEFAULT CURRENT_TIMESTAMP ON UPDATE)

**Test Data:** 10 sample users (alice.wonder, bob.stone, etc.)

### reporting_db Database

**Table: `events`**
- `EventId` - INT (AUTO_INCREMENT, PRIMARY KEY)
- `EventName` - VARCHAR(100) (NOT NULL)
- `EventDate` - DATE
- `Location` - VARCHAR(100)

---

## 🔧 Manual Operations

### Access MariaDB Container

```bash
docker exec -it mariadb bash
```

### Run SQL Manually

```bash
# Connect to MariaDB
docker exec -it mariadb mariadb -uroot -ppassword

# Or run a SQL file
docker exec -i mariadb mariadb -uroot -ppassword xp-users < your_script.sql
```

### Re-run Initialization

```bash
docker exec -i mariadb sh /sql/00_init_all.sh
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f mariadb
docker compose logs -f xp-users-service
docker compose logs -f xp-template-service
```

### Check Container Status

```bash
docker compose ps
```

---

## 📝 Available Scripts

| Script | Purpose |
|--------|---------|
| `launch.sh` | Fresh start: stops containers, removes volume, starts fresh, runs SQL init |
| `start.sh` | Start existing containers (no data reset) |
| `stop.sh` | Stop all containers (preserves data) |
| `delete.sh` | Stop containers and remove MariaDB volume (deletes all data) |

---

## 🔌 Connection Details

### From Host Machine

- **MariaDB:** `localhost:3306`
- **xp-users-service:** `http://localhost:8081`
- **xp-template-service:** `http://localhost:8080`

### From Containers

- **MariaDB:** `mariadb:3306`
- **Database:** `xp-users` or `reporting_db`
- **Username:** `root`
- **Password:** `password`

### JDBC Connection String

```
jdbc:mariadb://mariadb:3306/xp-users
```

---

## 💾 Data Persistence

- **MariaDB data** is stored in Docker volume `xp-docker_mariadb_data`
- **Logs** are written to `./logs/` directory (mounted from containers)
- **SQL scripts** are mounted from `./sql/` directory

To completely reset:
```bash
./delete.sh  # Removes volume and all data
./launch.sh  # Fresh start with initialization
```

---

## ⚠️ Notes

- **Root password** is set to `password` (change for production!)
- **Data persistence** relies on Docker volumes - data survives container restarts
- **SQL initialization** only runs when using `launch.sh` (which removes the volume)
- **Container restart policy:** `unless-stopped` (auto-restart on failure)

---

## 📌 Status

This is a **development/testing** environment. For production deployments, ensure:
- Strong database passwords
- Proper network security
- Backup strategies
- Environment-specific configuration

---

## 🔗 Related

- [xp-users-service](https://github.com/gar2000b/xp-users-service)
- [xp-template-service](https://github.com/gar2000b/xp-template-service)
