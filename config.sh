#!/usr/bin/env bash
## config.sh
## Define variables for incr-bkup.sh.
echo "config.sh START"

## == SSH Tunnel ==
use_portforward=1 # 1 for yes, 0 for no.
identity_file="${HOME}/.ssh/id_rsa" # Path to SSH private key file.
remote_username="" # Username on remote host.
remote_host="" # Address to connect to remote host.
ssh_port="22" # SSH port on remote host
remote_sql_port="3306" # Port SQL server is listening on on remote host.
local_sql_port="13306" # Port to forward to remote host.
## == DB Connection ==
db_host="" # localhost is your own machine
db_port="" # 3306 is the default
db_username="" # mysql -u"${db_username}" (dbuser from dbuser@hostname)
db_password="" # mysql -p"${db_password}"
## == Task ==
db_name="" # The DB to use.
table_names=( # The tables to export (MUST have a primary key doc_id column).
	"boardone"
	"boardtwo"
	)
output_dir="" # Dir to save dumps to
memory_dir="" # Dir to store resume information.
logs_dir="" # Dir to save logfiles.
range_size="" # Number to export at a time.

echo "config.sh END"