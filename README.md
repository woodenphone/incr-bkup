# incr-bkup
A tool for backing up an asagi-style database in incremental batches.
## Features
(The product pitch.)

This tool should work for any asagi-style DB.

Both local and remote database export is supported.

SSH tunnel-based port-forwarding is supported and handled by this script.

Backing up an entire database can be a big task. Backing up a million or less rows can be a much smaller task.

This script takes a huge task that you would do regularly and replaces it with smaller tasks that can be done once each.

Asagi-style databases are almost entirely static, with UPDATEs or DELETEs only occuring for live threads or from administrative actions.

This script assumes that those very few UPDATES that change posts are inconsequential.

This script assumes that those very few DELETES are inconsequential.


## Installation

### Prerequisites:
```
BASH
mysql/mariadb/mysqldump
ssh, sshd
```

Install prerequisites with apt (debian, ubuntu, raspbian, ect):
```
client$ sudo apt update && sudo apt upgrade -y # Bring system and packages up to date
client$ sudo apt install -y ssh sshd !TODO:packagenames!
```


Install prerequisites with yum (CENTOS, Fedora, RHEL):
```
client$ sudo yum update -y # Bring system and packages up to date
client$ sudo yum install !TODO:packagenames!
TODO
```

### incr-bkup itself:
Download the files for incr-bkup into a folder.

Set script as executable:
```
user@client ~/incr-bkup$ chomod +x incr-bkup.sh
```

Do configuration as explained below.


### SSH user setup:
If SSH tunnel portforwarding is to be used, an appropriate username and SSH keyfile must be setup.

To create a SSH keypair:
```
## == Create a SSH key ==
## Generate a RSA4096 private/public keypair:
user@client ~$ ssh-keygen -b4096
TODO FINISH COMMAND EXAMPLE
```

`id_rsa` is your secret key and must not be shared with anyone.

`id_rsa.pub` is your public key and needs to be installed on the remote server.

To install a SSH key on the remote end.
```
## == Add a SSH key ==
## Ensure authorized_keys file exists:
user@server ~$ mkdir -vp ~/.ssh/
user@server ~$ touch ~/.ssh/authorized_keys
## Append your key to a new line in the authorized_keys file:
user@server ~$ cat id_rsa.pub | tee -a ~/.ssh/authorized_keys
## Ensure authorized_keys file and dir have correct permissions:
user@server ~$ chown -R USER ~/.ssh/
user@server ~$ chmod -R 600 ~/.ssh/
## Test ssh configuration before logging out:
TODO
```



### DBMS user setup:
How to set your database up to work with this script.

A user with SELECT priveleges for all appropriate tables; on the domains localhost and $hostname should exist.

For commands to create such a user, see `secondary/add_backup_user.sql`.
These commands can be entered sequentially via the mysql shell or run as a mysql script.
```
## Open a mysql shell as the root (administrative) user:
$ mysql -uroot -p
mysql>
TODO FINISH COMMAND EXAMPLE
```


## Configuration:
### Configfile:
How to setup the config file.

All configuration is done through editing `config.sh`, which is a simple bash script that acts solely to set expected bash variables.

Example for use without SSH portforward:`secondary/nossh-config.example.sh`

Example for use with SSH portforward :`secondary/ssh-config.example.sh`


## Usage:

Running the script:
```
$ ./incr-bkup.sh
OR
$ bash incr-bkup.sh
```


### Automating with cron:
TODO: crontab



## Troubleshooting:
How to figure out what's wrong and then fix it.

### Script exits early
The first step is to read whatever messages the script printed to the console.

The second step is to go into the logs folder and read the logfile, the filename for which is timestamped in UNIX-style seconds-since-epoch format.

This script should have a greater level of diagnostic messages than most other scripts out there. 

Once you have read the last twenty or so lines of log messages from both the logfile and if possible the terminal running the script, you should have an idea of what was being done when the failure occured.

Please copy and search for the last few messages in the log file to find where in the script istelf the failure occured.


### SSH issues
TODO: serverside `~/.ssh` dir permissions
TODO: Check key is installed


### MySQL/MariaDB issues
TODO: User@domain issues and wildcards
TODO: table/DB permissions
TODO: Weird shit.


## Principle of operation
Basically:
1. Load config, prepare output dirs.
2. Setup functions.
3. SSH tunnel setup.
4. Loop over tables.
4.1. Load resumepoint.
4.2. Find latest docid.
4.3. Skip if no work.
4.4. Save table definition.
4.5. Loop over ranges for table.
4.5.1. Range mgmt.
4.5.2. Export range using mysqldump and a WHERE clause.
4.5.3. Record progress.
5. Save progress.
6. End of script, trap calls ssh close function.


## Ideas for future:
* Generalize to support any incremental primarykey mysql DB table.




## Special messages from our sponsors:
```
This machine kills dataloss.
>memories lost like a fart in the fog
Nazi punks fuck off.
Anti-Nazi punks fuck off.
It ain't punk rock 'til the punk rocker says it's punk rock.
Please don't put anything I say in your terrible program.
```