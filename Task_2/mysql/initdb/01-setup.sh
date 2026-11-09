#!/bin/bash
# Runs ONCE, the first time the container starts with an empty data directory.
# The official MySQL entrypoint sources this file, so docker_process_sql and
# mysql_note are available here.
#
# Creates the application database, the application user, the tables
# and the default data.

mysql_note "Creating database '${APP_DB_NAME}', user '${APP_DB_USER}' and tables"
docker_process_sql <<EOSQL
CREATE DATABASE IF NOT EXISTS \`${APP_DB_NAME}\`;
CREATE USER IF NOT EXISTS '${APP_DB_USER}'@'%' IDENTIFIED BY '${APP_DB_PASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE ON \`${APP_DB_NAME}\`.* TO '${APP_DB_USER}'@'%';
EOSQL
docker_process_sql --database="${APP_DB_NAME}" < /opt/webapp/schema.sql
