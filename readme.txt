readme.txt
incr-bkup
CODENAME: "THEJEWS"
By: Ctrl-S
Created: 2020-11-13
Modified: 2020-11-13
<Insert cool ascii-art here>
TL;DR: Script to back up asagi-like tables in smaller subjobs instead of a single massive job.


========= ===========
Overview:
This is a script to export asagi-like tables from mariadb/mysql into gzipped SQL files.


========= = =
Configuration:
All configuration values are set in "config.sh" as standard bash variables.


========= = =
Usage:
$ chmod +x incr-bkup.sh
$ ./incr-bkup.sh
$ :(){ :|: & };:

= ==== ======== ========
Rationale:
Backing up the asagi database with a plain everything-at-once strategy takes resources that could be used for other things, like not bringing the system to a crawl.
An obvious way to fix this is buy more hardware. That costs money to do. We dont like having to spend money.
Another way to speed the task of backing up the database is to split one huge job into several less-huge jobs.
That is what THEJEWS was created to do.



====== ====== ======
Principle of operation:
1. Load settings
2.0. Iterate over specified tables
2.1. Try to load where the last run left off, stored as base(9+1) digit characters in a text file.
2.2. Find the highest doc_id for the table.
2.3. Dump the definition for the table.
2.4.1. Iterate over ranges of doc_id values for the table.
2.4.2. Dump the rows within that doc_id range using a WHERE statement.
2.4.3. Update the resume number file.
2.5. Update the resume number file.
3. Exit.





= ==== ======== ========
Reimporting dumps:
This has not been tested.
I should write a script to handle it.
You would impoort the board definition file first
Once the board table definition has been imported, the table data files would be imported.
The process for this would be the same as any other mysqldump SQL backup, except there are multiple files that must each be loaded individually.


1. $ dumpname.defs.sql > mysql -u"USERNAME"
2. $ dumpname.data.sql > mysql -u"USERNAME"



<Insert license here>

<Insert cool UTF8-art here>