FROM postgres:15.3-alpine

COPY init.sql /docker-entrypoint-initdb.d/
#COPY dev_init.sql /docker-entrypoint-initdb.d/
#Uncomment the above line when etting up docker during development.
