/* add_backup_user.sql
 * Description: Create user for backups.
 * By: Ctrl-S
 * Created: 2020-11-17
 * Updated: 2020-11-18
 */

/* Create backup user */
CREATE USER 'incr-bkup'@'localhost' IDENTIFIED BY 'passwordhere';
CREATE USER 'incr-bkup'@'myserver-hostname' IDENTIFIED BY 'passwordhere';

/* Grant priveleges to backup user */
GRANT SELECT, LOCK TABLES ON *.* to 'incr-bkup'@'localhost'; -- plain "$ mysql" command ($USER@localhost)
GRANT SELECT, LOCK TABLES  ON *.* to 'incr-bkup'@'myserver-hostname'; -- SSH portforwards ($USER@$HOSTNAME)
FLUSH PRIVILEGES;
