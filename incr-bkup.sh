#!/usr/bin/env bash
## dump_board_tables.sh
## Dump a MariaDB / MySQL to two files, a database/table definition file and a table values data file.
## By: Ctrl-S
## Created: 2020-10-31
## Modified: 2020-11-17


## Use 'strict mode' for BASH to avoid bugs that can break something
set -euo pipefail ## WEB: https://devhints.io/bash
IFS=$'\n\t' ## WEB: http://redsymbol.net/articles/unofficial-bash-strict-mode/


## == Load config vars ==
source config.sh
## Sets variables:
# ## == SSH Tunnel ==
# use_portforward=1 # 1 for yes, 0 for no.
# identity_file="${HOME}/.ssh/id_rsa" # Path to SSH private key file.
# remote_username="" # Username on remote host.
# remote_host="" # Address to connect to remote host.
# ssh_port="22" # SSH port on remote host
# remote_sql_port="3306" # Port SQL server is listening on on remote host.
# local_sql_port="13306" # Port to forward to remote host.
# ## == DB Connection ==
# db_host="" # localhost is your own machine
# db_port="" # 3306 is the default 
# db_username="" # mysql -u"${db_username}"
# db_password="" # mysql -p"${db_password}"
# ## == Task ==
# db_name="" # The DB to use.
# table_names=( # The tables to export (MUST have a numeric primary key column).
# 	"boardone"
# 	"boardtwo"
# 	)
# output_dir="" # Dir to save dumps to
# memory_dir="" # Dir to store resume information.
# logs_dir="" # Dir to save logfiles.
# range_size="" # Number to export at a time.


## TODO: move definition of primary key column-name into config file, to generalize for broarder utility.
pkey_name="doc_id" # The name of the PRIMARY KEY (unsigned integer). (Asagi posts table uses "doc_id".)


## == Functions ==
## Echo to stderr isntead of stdout:
errecho(){ >&2 echo $@; }

## Echo to stdout and log to file
# logecho(){ >&2 echo $@  | tee -a "${logfile}" ; }
logecho(){ echo $@ | tee -a "${logfile}" ; }

## Read a numeric value from a file:
readfile_numeric () {
	## Read a numeric value if possible, else use the specified default or else 0.
	##  ${1} filepath
	##  ${2} default_val (optional, defaults to zero.)
	## USAGE: myvar="$(readfile_numeric $filepath 50)"
	local filepath="${1}"
	local val="${2:-0}" ## If not given, default to zero.
	## Does file exist?
	if ! [ -f "${filepath}" ]; then ## File does not exist:
		errecho "error:readfile_numeric: ${filepath} does not exist."
	else ## File exists:
    	## Read file:
    	local read_val=$(cat "${filepath}")
    	# Test if numeric: 
    	local re='^[0-9]+$'
		if ! [[ ${read_val} =~ ${re} ]] ; then
	   		errecho "error:readfile_numeric: read_val is not a number. read_val=${read_val}"
   		else
   			val="${read_val}" ## Use value if numeric.
		fi
	fi
	errecho "debug:readfile_numeric: filepath=${filepath}; val=${val};"
	echo "${val}" ## Pass back out via stdout.
	## Test if only digits: [[ $yournumber =~ ^[0-9]+$ ]]
	## LINK: https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
}

## == /Functions ==

## == Dynamically generated vars ==
## You probably don't need to touch these.
# timestamp="`date -u +%s`" ## Use a single timestamp for all of the dump tasks
started_ts="`date -u +%s`" ## Start-of-run timestamp. This is used for naming things.
logfile="${logs_dir}/incr-bkup.log.ts${started_ts}.txt"
auth_args=( # Login arguments for mysql and mysqldump.
	# Auth:
	--host="${db_host}" 
	--port="${db_port}"
	--user="${db_username}"
	--password="${db_password}"
	)

## Prep dirs
mkdir -vp $(dirname "${logfile}") # Ensure dir exists.
logecho $( mkdir -vp "${output_dir}" ) # Ensure dir exists.
logecho $( mkdir -vp "${memory_dir}" ) # Ensure dir exists.

## Log the more important info about this run:
logecho -e "\n\n"
logecho "## === === RUN START === ==="
logecho "## Starting at date_secs=`date +"%s"`" # Informational purposes only.
logecho "## Starting at long_date=`date`" # Informational purposes only.
logecho "## logfile=${logfile}"
logecho "## started_ts=${started_ts}" # This is used for naming things.
logecho "## output_dir=${output_dir}"
logecho "## pkey_name=${pkey_name}"
logecho "## db_name=${db_name}"
logecho "## table_names[@]=${table_names[@]}"


## == Second guess user ==
## TODO: Impliment warnings messages on suspicious config values.
## Do basic sanity checks on config values here.
## SSH-related, only if use_portforward is nonzero
## Does $local_sql_port match $db_port ?


## == Setup SSH tunnel with portforward ==
logecho "## START ssh block"
# ## SSH tunnel values
# use_portforward=1 # 1 for yes, 0 for no.
# identity_file="" # Path to SSH private key file.
# remote_username="" # Username on remote host.
# remote_host="" # Address to connect to remote host.
# ssh_port="" # SSH port on remote host
# remote_sql_port="" # Port SQL server is listening on on remote host.
# local_sql_port="" # Port to forward to remote host.
logecho "## use_portforward=${use_portforward}"
if  [[ $use_portforward -ne 0 ]] ; then
	logecho "## Create SSH tunnel/portforward"
	## === SSH connection management ===
	ssh_socketfile=$(mktemp)
	rm ${ssh_socketfile} # delete socket file so path can be used by ssh
	ssh_cleanup () {
	    # Stop SSH port forwarding process, this function may be
	    # called twice, so only terminate port forwarding if the
	    # socket still exists
	    if [ -S ${ssh_socketfile} ]; then
	        echo
	        echo "Sending exit signal to SSH process" | tee -a "${logfile}"
	        ## -O Valid commands are: ''check'' (check that the master process is running) and ''exit'' (request the master to exit). 
	        ssh -S ${ssh_socketfile} -O exit "${remote_username}@${remote_host}" | tee -a "${logfile}"
	    fi
	    exit ${exit_code:-0}
	}
	trap ssh_cleanup EXIT ERR INT TERM
	## $ ssh admin@server1.example.com -L 8080: server1.example.com:3000
	## $ ssh -L 3336:db001.host:3306 user@pub001.host
	ssh_args=(
		-M -S "${ssh_socketfile}" # Create a socket for controlling tunnel.
		-i "${identity_file}" # Private key file
		## Do not return until after tunnel setup is done: ( https://gist.github.com/scy/6781836 )
		-f ## "fork into background"	
		-N ## "run no command" (Needed to keep ssh in background, omitting makes ssh take over tty.)
		-o ExitOnForwardFailure=yes
		## Port forward:
		-L "${local_sql_port}:${remote_host}:${remote_sql_port}"
		## Remote host:
		-p "${ssh_port}" # Remote host SSH port
		"${remote_username}@${remote_host}" # username@host
		## Keep SSH tunnel alive for 300 seconds of inactivity:
		sleep 300 ## Gives time for port forward to be actually used to persist tunnel.
		)
	logecho "ssh_args=${ssh_args[@]}"
	logecho "## ssh command invoking"
	`ssh "${ssh_args[@]}"` | tee -a "${logfile}"
	logecho "## ssh command returned"
	logecho "## SSH check invoking"
	## -O Valid commands are: ''check'' (check that the master process is running) and ''exit'' (request the master to exit). 
	ssh -S ${ssh_socketfile} -O check "${remote_username}@${remote_host}" | tee -a "${logfile}"
	## "launching a shell here causes the script to not exit and allows you"
	## "to keep the forwarding running for as long as you want."
	## "I also like to customise the prompt to indicate that this isn't a normal shel"
	## FROM https://gist.github.com/scy/6781836#gistcomment-2777535
	logecho "## SSH check done"
	logecho "## SSH tunnel setup done"
else
	logecho "## Not using SSH tunnel." 
fi
logecho "SSH ps check: ` ps -aux | grep "ssh" `"
logecho "## END ssh block"


## == Find what tables the DB has to dump==
## TODO:(MAYBE COPY IN LATER)


## == Loop over each specified table ==
logecho "Now dumping database tables..."
logecho "## table_names[@]=${table_names[@]}"
tables_iterarion=0
for table_name in ${table_names[@]}
do
	tables_iterarion=$((tables_iterarion+1))
	logecho "## Now processing table_name=${table_name}"
	logecho "## tables_iterarion=${tables_iterarion}"
	## == Resume ==
	resume_pkey_num_file="${memory_dir}/${table_name}.resume_pkey_num.txt"
	logecho "## Reading: resume_pkey_num_file=${resume_pkey_num_file}"
	## Read a numeric value if possible, else use default of 0.
	min_pkey="$(readfile_numeric $resume_pkey_num_file 0)"
	logecho "## Loaded min_pkey=${min_pkey}"

	# == Find stop point ==
	## Find highest vale for the primary key from table
	logecho "## Find highest value for PRIMARY KEY column ${pkey_name}..."
	max_args=( # Use array for better commenting of args
		# Options:
		--batch # No border, implies --silent.
		--skip-column-names # Prevent showing "Tables_in_torako-03b" messages.
		# Query:
		--execute="SELECT max(${pkey_name}) FROM ${table_name};"
		# Database:
		"${db_name}"
		)
	logecho "max_args=${max_args[@]}" # Store args to file.
	max_res=` mysql "${auth_args[@]}" "${max_args[@]}" `
	logecho "max_res=${max_res}" # Store result var to file.
	# logecho -e "\n" # Seperator for readability
	max_pkey="${max_res}" # seperate var to permit intermediate data processing of SQL query result.

	## == Handle case where no new posts ==
	logecho "## Comparing: min_pkey=${min_pkey} ; with max_pkey=${max_pkey} ; using PRIMARY KEY ${pkey_name}"
	if [[ $min_pkey == $max_pkey ]]; then
		logecho "Nothing to dump!"
		continue # This table has nothing to do.
	else
		logecho "There is at least 1 row to dump"
	fi
	## At this point it is garunteed that at least one post needs saving.

	## == Dump defs (Once per table) ==
	## Dump the DB and table definitions:
	defs_filepath="${output_dir}/ts${started_ts}.${db_name}.${table_name}.defs.sql.gz" # Filepath to store table definitions to.
	logecho "## defs_filepath=${defs_filepath}"
	logecho "Now dumping table definition ..."
	defs_args=( # Use array for better commenting of args.
		--tz-utc # Convert to UTC for export so that timstamps are preserved across timezones.
		--quick # Fetch and dump one row at a time sequentially, for large databses.
		--opt 
		--single-transaction  # Use a transaction for consistent DB state in dump. (Needs InnoDB to do much.)
		--no-data # Do not store any rows.
		--skip-lock-tables # Prevent locking tables during dump process. (To prevent breaking asagi)
		# Normally, mysqldump treats the first name argument on the command line as a database name and following names as table names. 
		"${db_name}" # Database name
		# Table name(s) (optional)
		"${table_name}"
		)
	logecho "defs_args=${defs_args[@]}" # Store args to file.
	mysqldump "${auth_args[@]}" "${defs_args[@]}"  | gzip > "${defs_filepath}"
	logecho $( ls -lah "${defs_filepath}" ) # Ensure dir exists.

	## == Work over ranges ==
	logecho "## Dumping ranges of ${range_size} rows from ${min_pkey} to ${max_pkey} using PRIMARY KEY ${pkey_name}..."
	## (2-value for loop)
	## <Loop management>
	cycle_n=0 # First cycle is 1.
	for ((i = $min_pkey ; i < $max_pkey ; i=${i}+${range_size} )); do
		let cycle_n=cycle_n+1 # Increment by one.
		logecho "## Cycle start. cycle_n=${cycle_n}; i=${i};" 
		low_num="${i}" # Generate high and low values.
		let high_num=${i}+${range_size}
		logecho "Comparing high_num with max_pkey"
		if [ $high_num -gt $max_pkey ]; then
			logecho "Lowering high_num to max_pkey"
			let high_num=$max_pkey # Prevent high value going past the maximum.
		fi
		logecho "## low_num=${low_num}"
		logecho "## high_num=${high_num}"
		## </Loop management>
		
		low_pkey="${low_num}"
		high_pkey="${high_num}"

		## Record info for this range:
		logecho "## === Info for current range ==="
		logecho "## db_host=${db_host}"
		logecho "## db_name=${db_name}"
		logecho "## table_name=${table_name}"
		logecho "## cycle_n=${cycle_n}"
		logecho "## low_pkey=${low_pkey}"
		logecho "## high_pkey=${high_pkey}"
		logecho "## pkey_name=${pkey_name}"
		logecho "## current time (epoch): t=`date +"%s"`"
		logecho "## current time (longform): `date`"
		logecho "## output_dir=${output_dir}"

		## == Dump data ==
		## Dump the table data:
		logecho "Now dumping data..."
		data_filepath="${output_dir}/ts${started_ts}.${db_name}.${table_name}.pkey_${low_pkey}_to_${high_pkey}.data.sql.gz" # Filepath to store actual data to.
		logecho "## data_filepath=${data_filepath}"
		data_where_stmt="( (${pkey_name} >= ${low_pkey}) AND (${pkey_name} <= ${high_pkey}) )"
		logecho "## data_where_stmt=${data_where_stmt}"
		data_args=( # Use array for better commenting of args
			--tz-utc # Convert to UTC for export so that timstamps are preserved across timezones.
			--quick # Fetch and dump one row at a time sequentially, for large databses.
			--opt 
			--single-transaction # Use a transaction for consistent DB state in dump. (Needs InnoDB to do much.)
			--no-create-db # This option suppresses the CREATE DATABASE ... IF EXISTS statement...
			--no-create-info # Do not write CREATE TABLE statements which re-create each dumped table.
			--skip-lock-tables # Prevent locking tables during dump process. (To prevent breaking asagi)
			--where="${data_where_stmt}"
			# Normally, mysqldump treats the first name argument on the command line as a database name and following names as table names. 
			"${db_name}" # Database name
			# Table name(s) (optional)
			"${table_name}"
			)
		logecho "data_args=${data_args[@]}" # Store args to file.
		mysqldump "${auth_args[@]}" "${data_args[@]}"  | gzip > "${data_filepath}"
		logecho $( ls -lah "${data_filepath}" )

		## == Remember progress (mid-run) ==
		logecho "Saving resume point high_pkey=${high_pkey} to resume_pkey_num_file=${resume_pkey_num_file}"
		newdir="`dirname "${resume_pkey_num_file}"`"
		logecho ` mkdir -vp "${newdir}" ` # Ensure dir exists.
		echo "${high_pkey}" > "${resume_pkey_num_file}" # Save data (overwrite).

		logecho "## Done with range: low_pkey=${low_pkey} to high_pkey=${high_pkey}"
	done # Finished looping over rows for this table.
	## Finished working over ranges
	logecho "## Finished working with ranges of range_size=${range_size} rows from min_pkey=${min_pkey} to max_pkey=${max_pkey} using PRIMARY KEY ${pkey_name}"
	# logecho -e "\n" # Seperator for readability

	## == Remember progress (post-run) ==
	logecho "Saving resume point pkey of max_pkey=${max_pkey} to file resume_pkey_num_file=${resume_pkey_num_file}"
	logecho $( mkdir -vp $(dirname "${resume_pkey_num_file}") ) # Ensure dir exists.
	echo -n "${max_pkey}" > "${resume_pkey_num_file}"

	logecho "Done with table_name=table_name"
done # Finished working with this database.
logecho "Finished dumping DB"

logecho "## Finished at t=`date +"%s"`" # Last command.
# echo -e "\n\n\n\n" | tee -a "${logfile}" # Seperator for readability
## == Verbose notes==
##
## I believe that MariaDB and MySQL command should behave about the same.
## LINK: https://mariadb.com/kb/en/mysqldump/
## LINK: https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html
## A seconds-since-epoch name prevents accidental clobbering, and makes it trivial to tell when the dump was produced.
##
##
## To import a dump produced by this script: 
## !!! UNTESTED !!!
##  ( May be destructive if you have a DB with the same name! Use caution. )
## 1. $ dumpname.defs.sql > mysql -u"USERNAME"
## 2. $ dumpname.data.sql > mysql -u"USERNAME"
##
## Basically the table definitions must be imported before the table values data can be imported.
##
##
##
##
## According to POSIX: "foo//bar" means the same as "foo/bar"
## LINK: https://stackoverflow.com/questions/11226322/how-to-concatenate-two-strings-to-build-a-complete-path#24026057
## LINK: https://en.wikibooks.org/wiki/Bourne_Shell_Scripting/Variable_Expansion
##
## How to find the tables matching a column name:
## LINK: https://remarkablemark.org/blog/2020/08/25/mysql-find-table-with-column-name/
##
## Check if file exists:
## LINK: https://linuxize.com/post/bash-check-if-file-exists/
##
## Read value from file
## LINK: https://askubuntu.com/questions/367136/how-do-i-read-a-variable-from-a-file
##
## LINK: https://www.shell-tips.com/bash/functions/
##
## Writing text to stderr instead of stdout:
## LINK: https://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr#23550347
##
## BASH loops
## LINK: https://ryanstutorials.net/bash-scripting-tutorial/bash-loops.php
##
## SSH port forwarding:
## https://www.tecmint.com/create-ssh-tunneling-port-forwarding-in-linux/
## https://www.man7.org/linux/man-pages/man1/ssh.1.html
## https://linux.die.net/man/1/ssh
## https://stackoverflow.com/questions/7085429/terminating-ssh-session-executed-by-bash-script
## https://gist.github.com/scy/6781836
## https://www.g-loaded.eu/2006/11/24/auto-closing-ssh-tunnels/
##
## https://stackoverflow.com/questions/2241063/bash-script-to-set-up-a-temporary-ssh-tunnel/15198031#15198031
##
## == TROUBLESHOOTING ==
## === SQL host address gotcha with SSH portforwarding ===
## SQL host address gotcha with SSH portforwarding.
## 
## Symptoms:
## Message: "ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)"
## This message may be missed in logfiles because stderr isntead of stdout.
## Failure to connect to remote DB via SSH port forwarding.
##
## Cause:
## You may have used "--host=localhost"
## When mysql is given host "localhost" it tries to use a UNIX socket 
## instead of the network stack and specified host:port to connect to the DB server. 
## This means port forwarding has no interaction with your mysql command.
##
## Soluntion:
## Specify a localhost IP address instead of passing the value "localhost" to mysql
## e.g. "--host=127.0.0.1"
##
##
##
## "Ceterum autem censeo Carthaginem esse delendam"