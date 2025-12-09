#!/bin/sh
set -e

# ============================================
# CONFIG: Add/modify databases here
# ============================================
# Format: "db_name:folder_name"
#   db_name     = MariaDB database name
#   folder_name = subfolder under /sql
#
# Expected structure for each folder:
#   /sql/<folder_name>/
#     schema/*.sql
#     data/insert/*.sql
#     data/update/*.sql
#
DATABASES="xp-users:xp-users reporting_db:reporting_db"

# Root password comes from container env (set in docker-compose)
ROOT_PW="${MARIADB_ROOT_PASSWORD}"

if [ -z "$ROOT_PW" ]; then
  echo "ERROR: MARIADB_ROOT_PASSWORD is not set in the environment."
  exit 1
fi

echo ">>> Initializing MariaDB databases (post-start)..."

# --------------------------------------------
# 1) Create all databases
# --------------------------------------------
DB_CREATE_SQL=""
for entry in $DATABASES; do
  DB_NAME=${entry%%:*}
  DB_CREATE_SQL="$DB_CREATE_SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_uca1400_ai_ci;"
done

echo ">>> Creating databases if not already existing..."
mariadb -uroot -p"$ROOT_PW" <<EOSQL
$DB_CREATE_SQL
EOSQL

# --------------------------------------------
# Helper: run all .sql files in a directory
# --------------------------------------------
run_sql_dir() {
  DB="$1"
  DIR="$2"
  LABEL="$3"

  if [ -d "$DIR" ]; then
    echo ">>> [$DB] Applying: $LABEL ($DIR)..."
    for f in "$DIR"/*.sql; do
      [ -f "$f" ] || continue
      echo "    -> [$DB] Running $(basename "$f")"
      mariadb -uroot -p"$ROOT_PW" "$DB" < "$f"
    done
  fi
}

# --------------------------------------------
# 2) For each DB, apply schema -> insert -> update
# --------------------------------------------
for entry in $DATABASES; do
  DB_NAME=${entry%%:*}
  DB_DIR=${entry#*:}

  BASE_PATH="/sql/$DB_DIR"

  run_sql_dir "$DB_NAME" "$BASE_PATH/schema"        "schema"
  run_sql_dir "$DB_NAME" "$BASE_PATH/data/insert"   "insert data"
  run_sql_dir "$DB_NAME" "$BASE_PATH/data/update"   "update patches"
done

echo ">>> All database initialization completed."

