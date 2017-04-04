#!/bin/sh

#************************************************#
#                 backup.sh                      #
#           Author: Kirenkov Stas                #
#          Created: April 27, 2012               #
#       Last Updated: February 6, 2017           #
#       https://github.com/StasKirenkov/         #
#                                                #
# Backuping up of selected project and database  #
#                                                #
#************************************************#

# OVERRIDE THE PRIORITY OF THE PROCESS
renice 19 -p $$

# GET THE CURRENT DATE AND TIME IN THE FORMAT: yyyy_mm_dd_hh_mm_ss
dateArchived=`date +%Y_%m_%d_%H_%M_%S`

# REQUIRES FILE SYSTEM BACKUP?
# Default value: 'yes'
# Possible values:
#   'yes' - when you needed backup of filesystem
#   'no' - when you DON'T needed backup of filesystem
filesystemBackup='yes';

# THE PATH TO THE ROOT DIRECTORY FOR STORING BACKUPS
backupRootDirectory='/srv/www/my_project/backup';

# START BACKUP WITH ARGUMENTS FROM THE CONSOLE
# Default value: 'no'
# Possible values:
#   'yes' - when need backup once project from console
#   'no' - Is default value, were get array of projects to backup
once='no';

# NUMBER OF STORED ARCHIVES (FOR ROTATION BY COUNTER)
maximumNumberArchives=5;

# NUMBER OF DAYS FOR WHICH TO STORE ARCHIVES (FOR ROTATION BY DATE)
maximumNumberDays=5

# MINIMUM FREE STORAGE SPACE (IN MEGABYTES)
limitFreeSpace='2048';

# REQUIRES MYSQL DATABASE BACKUP?
# Default value: 'yes'
# Possible values:
#   'yes' - when you needed backup of MySQL DataBase
#   'no' - when you DON'T needed backup of MySQL DataBase
mysqlBackup='yes';

# REQUIRES ALL DATABASE BACKUP? (exclude system bases)
# Default value: 'no'
# Possible values:
#   'yes' - when you needed backup of MySQL DataBase
#   'no' - when you DON'T needed backup of MySQL DataBase
allDataBase='no';

# ARRAY OF DIRECTORIES FOR BACKUP
declare -a backupProjectDir
# ARRAY OF EXCEPTIONS FOR BACKUP
declare -a exclusionList
# ARRAY OF PROJECT NAMES FOR BACKUP
declare -a backupProjectName
# ARRAY OF DATABASE FOR BACKUP
declare -a dataBaseName
# THE ARRAYS OF USER LOGINS AND PASSWORDS FOR MYSQL
declare -a dataBaseLogin
declare -a dataBasePassword

# Counters
backupProjectCounter=0
exclusionListCounter=0
dbUserCounter=0

# PARSING PARAMETERS FROM THE COMMAND LINE
for i in "$@"
do
case $i in
    -p=*|--path=*)
    backupProjectDir[0]="${i#*=}"
    ;;
    -n=*|--nameproject=*)
    backupProjectName[0]="${i#*=}"
    ;;
    -o=*|--once=*)
    once="yes"
    ;;
    -x=*|--path=*)
    exclusionList[0]="${i#*=}"
    ;;
    *)
        echo "Unknown option";
    ;;
esac
done

if [ "${once}" == "no" ]
then
    # Array of directories for backup
    backupProjectDir[0]="/srv/www/my_project";

    # Array of exceptions for backup
    exclusionList[0]="--exclude=*.git*";

    # Array of project names for backup
    backupProjectName[0]="my_project";

    # If you want to back up one database, you must specify its name, and set the 'alldatabase' parameter to 'no'
    dataBaseName[0]="site";

    # The array of user logins and passwords for mysql
    dataBaseLogin[0]="you_login_to_database";
    dataBasePassword[0]="you_password_to_database";
fi;

# THE ARCHIVING FUNCTION OF THE SPECIFIED DIRECTORY (S)
function create_backup()
{
        # Check the existence of the backup directory
        if [ ! -d "${backupRootDirectory}" ]
        then
                # Create a directory for the archive, if not created
                mkdir -p ${backupRootDirectory}
        fi;

        # Check the amount of free space on the HDD
        freespace=`df -m ${backupRootDirectory} | grep dev | awk '{print $4}'`; # For local directories
        #freespace=`df -m ${backupRootDirectory} | grep 4 | awk '{print $3}'`; # For the mounted directory

        # Check for free space on the HDD
        if [ "${limitFreeSpace}" -ge "${freespace}" ]; then
            echo "The free space on the hard drive is over. Clear old archives."
            # Delete old archives, with minimum quantity verification
            clean_by_count
            echo "Continue to backup"
            #exit
        fi

        # Count the number of directories for archiving
        backupProjectCounter=${#backupProjectDir[@]}

        # Count the number of exemptions for archiving
        exclusionListCounter=${#exclusionList[@]}

        # Create a backup of the specified directory in the directory with the archive
        if [ "${backupProjectCounter}" -gt "0" ]
        then
                # Check whether you need to back up the file system
                if [ "${filesystemBackup}" == "yes" ]
                then
                        for ((i=0; i<${backupProjectCounter}; i++));
                        do
                                # The full path of the backup directory
                                path=${backupRootDirectory}"/"${backupProjectName[$i]}"/"${dateArchived};

                                # Check the existence of the backup directory
                                if [ ! -d "${path}" ]
                                then
                                        # Create a directory for the archive, if it was not created earlier
                                        mkdir -p ${path}
                                fi;

                                # Check if we have any exceptions for archiving
                                if [ "${exclusionListCounter}" -gt "0" ]
                                then
                                        zip -9 -r ${path}"/"${backupProjectName[$i]}.zip ${backupProjectDir[$i]} ${exclusionList[$i]}
                                elif [ "${exclusionListCounter}" -eq "0" ]
                                then
                                        zip -9 -r ${path}"/"${backupProjectName[$i]}.zip ${backupProjectDir[$i]}
                                fi;
                        done
                fi;
        fi;

        # Count the number of MySQL users to back up the database
        dbUserCounter=${#dataBaseLogin[@]}

        # Check whether MySQL databases are needed
        if [ "${mysqlBackup}" == "yes" ]
        then
                for ((u=0; u<=${dbUserCounter}; ++u));
                do
                        if [ -n "${dataBaseLogin[$u]}" ] && [ -n ${dataBasePassword[$u]} ]
                        then
                                dbs=$(mysql -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} -e "show databases;" | grep [[:alnum:]])

                                # The full path of the backup directory
                                path=${backupRootDirectory}"/"${backupProjectName[$i]}"/"${dateArchived};

                                # Check the existence of the backup directory
                                if [ ! -d "${path}" ]
                                then
                                        # Create a directory for the archive, if it was not created earlier
                                        mkdir -p ${path}
                                fi;

                                # Check if you need to archive all databases
                                if [ "${allDataBase}" == "yes" ]
                                then
                                        for l in $dbs
                                        do
                                                # Exclude system databases
                                                if [ "$l" == "Database" ] || [ "$l" == "information_schema" ] || [ "$l" == "mysql" ]
                                                then
                                                        continue
                                                fi;

                                                file=$l.sql
                                                mysqldump -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} --databases $l > /tmp/${file}
                                                mkdir -p ${path}"/sql/"
                                                mv /tmp/$file ${path}"/sql/"${file}
                                        done
                                elif [ "${allDataBase}" == "no" ]
                                then
                                        file=${dataBaseName[$u]}.sql
                                        mysqldump -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} --databases ${dataBaseName[$u]} > /tmp/${file}
                                        mkdir -p ${path}"/sql/"
                                        mv /tmp/$file ${path}"/sql/"${file}
                                fi;
                        fi;
                done
        fi;
}

function clean_by_date ()
{
        # Check the project directories in turn
        for ((k=0; k<${backupProjectCounter}; ++k));
        do
                # Backup directory
                path=${backupRootDirectory}"/"${backupProjectName[$k]}"/";

                # Checking the nested directories
                for i in `ls ${path} -l -1t | grep '^d' |awk '{print $8}'`;
                do
                        find ${path}${i} -mtime +${maximumNumberDays} -type d -exec rm -rf {} \;
                done
        done
}

function clean_by_count ()
{
        # Check the project directories in turn
        for ((k=0; k<${backupProjectCounter}; k++));
        do
                # Backup directory
                path=${backupRootDirectory}"/"${backupProjectName[$k]}"/";

                # Counter
                count=0;

                preCount=$((maximumNumberArchives-1));

                # Checking the nested directories
                for i in `ls ${path} -l -1t | grep '^d' |awk '{print $9}'`;
                do
                        if [ "${count}" -ge "${preCount}" ]
                        then
                                rm -rf ${path}${i};
                        fi;

                        let count=$((${count} + 1));
                done
        done
}

# Run the backup
create_backup

# We call the function of cleaning the non-actual archives by:
# - date
#clean_by_date

# - number of
clean_by_count

exit 0
