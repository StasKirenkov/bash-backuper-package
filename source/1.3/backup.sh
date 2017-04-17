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

# INCLUDE THE MAIN CONFIGURATION FILE
source ./main.conf

# INCLUDE THE PRE-TEST FILE
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
  backupProjectName[0]="my_project";

  # If you want to back up one database, you must specify its name, and set the 'ALL_DATA_BASE' parameter to 'no'
  dataBaseName[0]="site";

  # The array of user logins and passwords for mysql
  dataBaseLogin[0]="you_login_to_database";
  dataBasePassword[0]="you_password_to_database";
fi;

# THE ARCHIVING FUNCTION OF THE SPECIFIED DIRECTORY (S)
create_backup()
{
  # Check the existence of the backup directory
  if [ ! -d "${BACKUP_ROOT_DIR}" ]
  then
    # Create a directory for the archive, if not created
    mkdir -p ${BACKUP_ROOT_DIR}
  fi;
#  #
#  # TODO (Stas Kirenkov): необходима проверка наличия bc (basic calculator - apt-get install bc)
#  #
#  #
#  if echo ${MIN_FREE_SPACE} | awk 'match($0, /[0-9]+MB/) { print substr( $0, RSTART, RLENGTH )}';
#  then
#    $MIN_FREE_SPACE=${MIN_FREE_SPACE//MB}
#  fi
#  #
#  if echo ${MIN_FREE_SPACE} | awk 'match($0, /[0-9]+GB/) { print substr( $0, RSTART, RLENGTH )}';
#  then
#    MIN_FREE_SPACEClear=${MIN_FREE_SPACE//GB}
#    #echo `${MIN_FREE_SPACE//GB}*1024`
#    #echo $(${MIN_FREE_SPACEClear//GB}*1024);
#  fi
##  echo "${MIN_FREE_SPACE}";
#exit;

  if [ "${MIN_FREE_SPACE}" -ne "0" ];
  then
    # Check the amount of free space on the HDD
    freespace=$(df -m ${BACKUP_ROOT_DIR} | grep dev | awk '{print $4}');

    # Check for free space on the HDD
    if [ "${MIN_FREE_SPACE}" -ge "${freespace}" ];
    then
      echo "The free space on the hard drive is over. Clear old archives."
      # Delete old archives, with minimum quantity verification
      clean_by_count
      echo "Continue to backup"
    fi
  fi

  # Count the number of directories for archiving
  projects_counter=${#backupProjectDir[@]}

  # Count the number of exemptions for archiving
  exclusions_counter=${#exclusionList[@]}

  # Create a backup of the specified directory in the directory with the archive
  if [ "${projects_counter}" -gt "0" ]
  then
    # Check whether you need to back up the file system
    if [ "${FILESYSTEM_BACKUP}" = "yes" ]
    then
      while [ "$i" != "${projects_counter}" ]; do
        # The full path of the backup directory
        pathway=${BACKUP_ROOT_DIR}"/"${backupProjectName[$i]}"/"${date_archived};

        # Check the existence of the backup directory
        if [ ! -d "${pathway}" ]
        then
          # Create a directory for the archive, if it was not created earlier
          mkdir -p ${pathway}
        fi;

        # Check if we have any exceptions for archiving
        if [ "${exclusions_counter}" -gt "0" ]
        then
          zip -9 -r ${pathway}"/"${backupProjectName[$i]}.zip ${backupProjectDir[$i]} ${exclusionList[$i]}
        elif [ "${exclusions_counter}" -eq "0" ]
        then
          zip -9 -r ${pathway}"/"${backupProjectName[$i]}.zip ${backupProjectDir[$i]}
        fi;

        i=$(( i + 1 ))
      done
    fi;
  fi;

  # Count the number of MySQL users to back up the database
  db_user_counter=${#dataBaseLogin[@]}

  # Check whether MySQL databases are needed
  if [ "${MYSQL_BACKUP}" = "yes" ]
  then
    while [ "$u" != "${db_user_counter}" ]; do
      if [ -n "${dataBaseLogin[$u]}" ] && [ -n ${dataBasePassword[$u]} ]
      then
        dbs=$(mysql -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} -e "show databases;" | grep [[:alnum:]])

        # The full path of the backup directory
        pathway=${BACKUP_ROOT_DIR}"/"${backupProjectName[$i]}"/"${date_archived};

        # Check the existence of the backup directory
        if [ ! -d "${pathway}" ]
        then
          # Create a directory for the archive, if it was not created earlier
          mkdir -p ${pathway}
        fi;

        # Check if you need to archive all databases
        if [ "${ALL_DATA_BASE}" = "yes" ]
        then
          for l in $dbs
          do
            # Exclude system databases
            if [ "$l" = "Database" ] || [ "$l" = "information_schema" ] || [ "$l" = "mysql" ]
            then
              continue
            fi;

            file=$l.sql
            mysqldump -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} --databases $l > /tmp/${file}
            mkdir -p ${pathway}"/sql/"
            mv /tmp/$file ${pathway}"/sql/"${file}
          done
        elif [ "${ALL_DATA_BASE}" = "no" ]
        then
          file=${dataBaseName[$u]}.sql
          mysqldump -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} --databases ${dataBaseName[$u]} > /tmp/${file}
          mkdir -p ${pathway}"/sql/"
          mv /tmp/$file ${pathway}"/sql/"${file}
        fi;
      fi;

      u=$(( u + 1 ))
    done
  fi;
}

# ROTATION OF OLD COPIES, BY DATE / TIME
clean_by_date ()
{
  if [ "${MAX_NUMBER_DAYS}" -ne "0" ];
  then
    # Check the project directories in turn
    while [ "$k" != "${projects_counter}" ]; do
      # Backup directory
      pathway=${BACKUP_ROOT_DIR}"/"${backupProjectName[$k]}"/";

      # Checking the nested directories
      for i in `ls ${pathway} -l -1t | grep '^d' |awk '{print $8}'`;
      do
        find ${pathway}${i} -mtime +${MAX_NUMBER_DAYS} -type d -exec rm -rf {} \;
      done

      k=$(( k + 1 ))
    done
  fi
}

# ROTATION OF OLD COPIES, BY NUMBER
clean_by_count ()
{
  if [ "${MAX_NUMBER_ARCHIVES}" -ne "0" ];
  then
    # Check the project directories in turn
    while [ "$k" != "${projects_counter}" ]; do
      # Backup directory
      pathway=${BACKUP_ROOT_DIR}"/"${backupProjectName[$k]}"/";

      preCount=$((MAX_NUMBER_ARCHIVES-1));

      # Checking the nested directories
      for i in $(ls ${pathway} -l -1t | grep '^d' |awk '{print $9}');
      do
        if [ "${subdir_counter}" -ge "${preCount}" ]
        then
          rm -rf ${pathway}${i};
        fi;

        let subdir_counter=$((${subdir_counter} + 1));
      done

      k=$(( k + 1 ))
    done
  fi
}

sendMail ()
{
	mail -s "$(date +%Y %m %d %H:%M:%S) - ###" "$MAIL_ADDRESS"
}

# Run the backup
create_backup

# We call the function of cleaning the non-actual archives by:
# - date
#clean_by_date

# - number of
clean_by_count

exit 0
