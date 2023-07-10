FROM postgres:15.3-alpine

COPY init.sql /docker-entrypoint-initdb.d/
