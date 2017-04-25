#!/bin/bash
#!/bin/sh
#!/usr/bin/env sh
#!/usr/bin/env bash

#*****************************************************#
#                                                     #
#                    backup.sh                        #
#              Author: Kirenkov Stas                  #
#             Created: April 27, 2012                 #
#      Last functional Updated: April 12, 2017        #
#          https://github.com/StasKirenkov/           #
#                                                     #
#    Backuping up of selected project and database    #
#                                                     #
# Used: https://google.github.io/styleguide/shell.xml #
#                                                     #
#*****************************************************#

# OVERRIDE THE PRIORITY OF THE PROCESS
renice 19 -p $$ >/dev/null 2>&1

# GET THIS SCRIPT NAME
scriptName=$(basename "$0")

message_str='';

# INCLUDE THE MAIN CONFIGURATION FILE
# shellcheck disable=SC1091
source ./main.conf

# INCLUDE THE PRE-TEST FILE
# shellcheck disable=SC1091
source ./bin/pre_start.sh

# PARSING PARAMETERS FROM THE COMMAND LINE
for i in "$@"
do
case $i in
  -p=*|--pathway=*)
  backupProjectDir[0]="${i#*=}"
  ;;
  -n=*|--nameproject=*)
  backupProjectName[0]="${i#*=}"
  ;;
  -o=*|--solitary=*)
  solitary="yes"
  ;;
  -x=*|--exclusion=*)
  exclusionList[0]="${i#*=}"
  ;;
  -v=*|--version)
    echo "${BACKAPER_NAME} v.${VERSION}";
  ;;
  *)
    echo "Unknown parameter, please use the help: ./${scriptName} --help | -h";
  ;;
esac
done

if [ "${solitary}" = "no" ]
then
  # Array of directories for backup
  backupProjectDir[0]="/srv/www/my_project";

  # Array of exceptions for backup
  exclusionList[0]="--exclude=*.git*";

  # Array of project names for backup
  backupProjectName[0]="this_is_my_project";

  # If you want to back up one database, you must specify its name, and set the 'ALL_DATA_BASE' parameter to 'no'
  dataBaseName[0]="site";

  # The array of user logins and passwords for mysql
  dataBaseLogin[0]="you_login_to_database";
  dataBasePassword[0]="you_password_to_database";
fi;

# THE ARCHIVING FUNCTION OF THE SPECIFIED DIRECTORY (S)
create_backup()
{
  if [ -z "$error_str" ];
  then
    # Check the existence of the backup directory
    if [ ! -d "${BACKUP_ROOT_DIR}" ]
    then
      # Create a directory for the archive, if not created
      mkdir -p "${BACKUP_ROOT_DIR}"

      message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Dir ${BACKUP_ROOT_DIR} isn't exist and was created.";
    fi;
    #
    if echo "${MIN_FREE_SPACE}" | awk 'match($0, /[0-9]+MB/) { print substr( $0, RSTART, RLENGTH )}';
    then
      MIN_FREE_SPACE=${MIN_FREE_SPACE//MB}
    fi;
    #
    if echo "${MIN_FREE_SPACE}" | awk 'match($0, /[0-9]+GB/) { print substr( $0, RSTART, RLENGTH )}';
    then
      MIN_FREE_SPACEClear=${MIN_FREE_SPACE//GB}
      MIN_FREE_SPACE=$((${MIN_FREE_SPACEClear//GB}*1024));
    fi;
    #
    if [ "${MIN_FREE_SPACE}" -gt "0" ];
    then
      message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Check the amount of free space on the HDD";

      # Check the amount of free space on the HDD
      freespace=$(df -m "${BACKUP_ROOT_DIR}" | grep dev | awk '{print $4}');

      # Check for free space on the HDD
      if [ "${MIN_FREE_SPACE}" -lt "${freespace}" ];
      then
      	message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - The free space on the hard drive is over. Clear old archives.";

        #echo "The free space on the hard drive is over. Clear old archives."

        # Delete old archives, with minimum quantity verification
        message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Delete old archives, with minimum quantity verification";

        clean_by_count

        message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Continue to backup";
        #echo "Continue to backup"
      fi;
    fi;

    # Count the number of directories for archiving
    projects_counter=${#backupProjectDir[@]}

    # Count the number of exemptions for archiving
    exclusions_counter=${#exclusionList[@]}

    # Create a backup of the specified directory in the directory with the archive
    if [ "${projects_counter}" -gt "0" ]
    then
      message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Check whether you need to back up the file system";

      # Check whether you need to back up the file system
      if [ "${FILESYSTEM_BACKUP}" = "yes" ]
      then
        while [[ "$i" -lt "${projects_counter}" ]];
        do
          if [ -n "${backupProjectName[$i]}" ];
          then
            # The full path of the backup directory
            pathway="$BACKUP_ROOT_DIR/${backupProjectName[$i]}/$date_archived";

            # Check the existence of the backup directory
            message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Check the existence of the backup directory";

            if [ ! -d "${pathway}" ]
            then
              # Create a directory for the archive, if it was not created earlier
              message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Create a directory for the archive, if it was not created earlier";
              mkdir -p "${pathway}"
            fi;

            # Check if we have any exceptions for archiving
            message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Check if we have any exceptions for archiving";

            if [ "${exclusions_counter}" -gt "0" ]
            then
              zip -9 -r "$pathway/${backupProjectName[$i]}".zip "${backupProjectDir[$i]}" "${exclusionList[$i]}"
            elif [ "${exclusions_counter}" -eq "0" ]
            then
              zip -9 -r "$pathway/${backupProjectName[$i]}".zip "${backupProjectDir[$i]}"
            fi;

            message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Project archiving ${backupProjectName[$i]} is completed";

            i=$(( i + 1 ))
          fi;
        done
      fi;
    fi;

    # Count the number of MySQL users to back up the database
    db_user_counter=${#dataBaseLogin[@]}

    # Check whether MySQL databases are needed
    message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Check whether MySQL databases are needed";

    if [ "${MYSQL_BACKUP}" = "yes" ]
    then
      while [ "$u" != "${db_user_counter}" ]; do
        if [ -n "${dataBaseLogin[$u]}" ] && [ -n "${dataBasePassword[$u]}" ] && [ -n "${backupProjectName[$u]}" ]
        then
          dbs=$(mysql -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} -e "show databases;" | grep [[:alnum:]])

          # The full path of the backup directory
          pathway="$BACKUP_ROOT_DIR/${backupProjectName[$u]}/$date_archived";

          # Check the existence of the backup directory
          message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Check the existence of the backup directory for MySQL backup";

          if [ ! -d "${pathway}" ]
          then
            # Create a directory for the archive, if it was not created earlier
            message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Create a directory for the archive, if it was not created earlier";

            mkdir -p "${pathway}"
          fi;

          # Check if you need to archive all databases
          message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Check if you need to archive all databases";

          if [ "${ALL_DATA_BASE}" = "yes" ]
          then
            for l in $dbs
            do
              # Exclude system databases
              if [ "$l" = "Database" ] || [ "$l" = "information_schema" ] || [ "$l" = "mysql" ]
              then
                continue
              fi;

              file="${l}".sql
              mysqldump -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} --databases $l > /tmp/"${file}"
              mkdir -p "${pathway}/sql/"
              mv /tmp/"$file" "${pathway}/sql/${file}"
            done
          elif [ "${ALL_DATA_BASE}" = "no" ]
          then
            file="${dataBaseName[$u]}".sql
            mysqldump -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} --databases ${dataBaseName[$u]} > /tmp/"${file}"
            mkdir -p "${pathway}/sql/"
            mv /tmp/"$file" "${pathway}/sql/${file}"
          fi;

          message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Databases archiving is completed";
        fi;

        u=$(( u + 1 ))
      done
    fi;
  fi;
}

# ROTATION OF OLD COPIES, BY DATE / TIME
clean_by_date ()
{
  if [ -z "$error_str" ];
  then
    if [ "${MAX_NUMBER_DAYS}" -gt "0" ];
    then
      message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Start rotation of old copies, by date / time";

      # Check the project directories in turn
      while [ "$k" != "${projects_counter}" ];
      do
        if [ -n "${backupProjectName[$k]}" ];
        then
          # Backup directory
          pathway="$BACKUP_ROOT_DIR/${backupProjectName[$k]}/";

          # Checking the nested directories
          message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Checking the nested directories";

          for i in $(ls "${pathway}" -l -1t -q |awk '{print $9}');
          do
            find "${pathway}${i}" -mtime +"${MAX_NUMBER_DAYS}" -type d -exec rm -rf {} \;
          done

          k=$(( k + 1 ))
        fi;
      done

      message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Finish rotation of old copies, by date / time";
    fi;
  fi;
}

# ROTATION OF OLD COPIES, BY NUMBER
clean_by_count ()
{
  if [ -z "$error_str" ];
  then
    if [ "${MAX_NUMBER_ARCHIVES}" -gt "0" ];
    then
      message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Start rotation of old copies, by number";

      # Check the project directories in turn
      while [ "$k" != "${projects_counter}" ];
      do
        if [ -n "${backupProjectName[$k]}" ];
        then
          # Backup directory
          pathway="$BACKUP_ROOT_DIR/${backupProjectName[$k]}/";

          preCount=$((MAX_NUMBER_ARCHIVES-1));

          # Checking the nested directories
          message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Checking the nested directories";

          for i in $(ls "${pathway}" -l -1t -q |awk '{print $9}');
          do
            if [ "${subdir_counter}" -ge "${preCount}" ]
            then
              rm -rf "${pathway}${i}";
            fi;

            let subdir_counter=$(($subdir_counter + 1));
          done

          k=$(( k + 1 ))
        fi;
      done

      message_str="$message_str\r\r$(date +%Y_%m_%d_%H_%M_%S) - Finish rotation of old copies, by number";
    fi;
  fi;
}

sendMail ()
{
  # IF HAVE ONE OR ANY ERROR, LET'S DO PRINT
  if [ -n "$message_str" ] || [ -n "$error_str" ];
  then
    mail -s "${BACKAPER_NAME} v.${VERSION} - log result" "$MAIL_ADDRESS" <<< $(echo -e "$(date +%Y_%m_%d_%H_%M_%S) - ###\r$error_str\r###########\r$message_str")
    exit 0
  fi;
}

# Run the backup
create_backup

# We call the function of cleaning the non-actual archives by:
# - date
#clean_by_date

# - number of
clean_by_count

# IF HAVE ONE OR ANY ERROR OR MESSAGE, LET'S DO SEND
sendMail

exit 0
