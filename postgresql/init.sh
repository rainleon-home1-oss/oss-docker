#!/bin/bash
# init for sonarqube
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE sonar;
    CREATE USER sonar SUPERUSER PASSWORD 'sonar';
    GRANT ALL PRIVILEGES ON DATABASE sonar TO sonar;
EOSQL