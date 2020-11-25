#!/usr/bin/env bash
## incr-rest.sh
## Import a dump created by incr-bkup.sh.
## By: Ctrl-S
## Created: 2020-11-20
## Modified: 2020-11-20

## Use 'strict mode' for BASH to avoid bugs that can break something
set -euo pipefail ## WEB: https://devhints.io/bash
IFS=$'\n\t' ## WEB: http://redsymbol.net/articles/unofficial-bash-strict-mode/

started_ts="`date -u +%s`" ## Start-of-run timestamp.

## == Config ==

## == /Config ==
logfile="${logs_dir}/incr-bkup.log.${started_ts}.txt"


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




## Prep dirs
mkdir -vp $(dirname "${logfile}") # Ensure dir exists.



## == Start work ==



## 1. $ dumpname.defs.sql > mysql -u"USERNAME"
## 2. $ dumpname.data.sql > mysql -u"USERNAME"















## == End of script ==
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
##
##
##
## "Ceterum autem censeo Carthaginem esse delendam"