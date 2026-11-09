FROM mysql:8.4

# Default database and application user.
# Override any of them with environment variables at runtime.
# MYSQL_ROOT_PASSWORD has no default: it must be given at runtime.
ENV APP_DB_NAME=webapp \
    APP_DB_USER=webapp \
    APP_DB_PASSWORD=webapp123 \
    MYSQL_INITDB_SKIP_TZINFO=1

# Server settings
COPY conf/mysql.cnf /etc/mysql/conf.d/mysql.cnf

# Tables and default data used by the app
COPY schema/schema.sql /opt/webapp/schema.sql

# Runs once, on the first start with an empty data directory
COPY initdb/01-setup.sh /docker-entrypoint-initdb.d/01-setup.sh
