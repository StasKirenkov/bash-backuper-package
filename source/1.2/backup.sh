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
fileBackup='yes';

# THE PATH TO THE ROOT DIRECTORY FOR STORING BACKUPS
backupRootDirectory='/srv/www/my_project/backup';

# START BACKUP WITH ARGUMENTS FROM THE CONSOLE
# Default value: 'no'
# Possible values:
#   'yes' - when need backup once project from console
#   'no' - Is default value, were get array of projects to backup
once="no";

# NUMBER OF STORED ARCHIVES (FOR ROTATION BY COUNTER)
maximumNumberArchives=5;

# Кол-во дней за которые хранить архивы (для ротации по дате)
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
allDataBase="no";

# PARSING PARAMETERS FROM THE COMMAND LINE
for i in "$@"
do
case $i in
    -p=*|--path=*)
    arch_Path[0]="${i#*=}"
    ;;
    -n=*|--nameproject=*)
    arch_Name[0]="${i#*=}"
    ;;
    -o=*|--once=*)
    once="yes"
    ;;
    -x=*|--path=*)
    exclude_list[0]="${i#*=}"
    ;;
    *)
        echo "Unknown option";
    ;;
esac
done

if [ "${once}" == "no" ]
then
    # ARRAY OF DIRECTORIES FOR BACKUP
    arch_Path[0]="/srv/www/my_project";

    # ARRAY OF EXCEPTIONS FOR BACKUP
    exclude_list[0]="--exclude=*.git*";

    # ARRAY OF PROJECT NAMES FOR BACKUP
    arch_Name[0]="my_project";

    # IF YOU WANT TO BACK UP ONE DATABASE, YOU MUST SPECIFY ITS NAME, AND SET THE 'ALLDATABASE' PARAMETER TO 'NO'
    dataBaseName[0]="site";

    # THE ARRAY OF USER PAIRS AND PASSWORDS FOR MYSQL
    dataBaseLogin[0]="you_login_to_database";
    dataBasePassword[0]="you_password_to_database";
fi;

# Непосредственно функция архивации заданной(ых) дирректории(й)
function arch ()
{
        # Проверяем сущестование дирректории бэкапа
        if [ ! -d "${backupRootDirectory}" ]
        then
                #Создаем дирректорию для архива
                mkdir -p ${backupRootDirectory}
        fi;

        # Проверяем кол-во свободного места на НЖМД
        freespace=`df -m ${backupRootDirectory} | grep dev | awk '{print $4}'`; # Работает для локальных директорий
        #freespace=`df -m ${backupRootDirectory} | grep 4 | awk '{print $3}'`; # Работает для примонтированной директории

        # Проверяем достаточность свободного места на НЖМД
        if [ "${limitFreeSpace}" -ge "${freespace}" ]; then
            echo "Свободное место на жестком диске закончилось. Очищаем старые архивы."
            #Проводим очистку архивов, по их актуальному кол-ву
            clean_by_count
            echo "Продолжаем резервное копирование"
            #exit
        fi

        #Считаем кол-во дирректорий для архивации
        elLen=${#arch_Path[@]}

        #Проверяем, есть ли у нас исключения для архивации
        exLen=${#exclude_list[@]}

        #Производим архивацию заданной дирректории в дирректорию с архивом
        if [ "${elLen}" -gt "0" ]
        then
                # Проверяем нужен ли бэкап файлов
                if [ "${fileBackup}" == "yes" ]
                then
                        for ((i=0; i<${elLen}; i++));
                        do
                                # Дирректория бэкапа
                                path=${backupRootDirectory}"/"${arch_Name[$i]}"/"${dateArchived};

                                # Проверяем сущестование дирректории архивации
                                if [ ! -d "${path}" ]
                                then
                                        #Создаем дирректорию для архива
                                        mkdir -p ${path}
                                fi;

                                if [ "${exLen}" -gt "0" ]
                                then
                                        zip -9 -r ${path}"/"${arch_Name[$i]}.zip ${arch_Path[$i]} ${exclude_list[$i]}
                                elif [ "${exLen}" -eq "0" ]
                                then
                                        zip -9 -r ${path}"/"${arch_Name[$i]}.zip ${arch_Path[$i]}
                                fi;
                        done
                fi;
        fi;

        #Считаем кол-во MySQL пользователей для архивации БД
        sqlUserLen=${#dataBaseLogin[@]}

        # Проверяем нужен ли бэкап MySQL баз
        if [ "${mysqlBackup}" == "yes" ]
        then
                for ((u=0; u<=${sqlUserLen}; ++u));
                do
                        if [ -n "${dataBaseLogin[$u]}" ] && [ -n ${dataBasePassword[$u]} ]
                        then
                                dbs=$(mysql -u${dataBaseLogin[$u]} -p${dataBasePassword[$u]} -e "show databases;" | grep [[:alnum:]])

                                # Дирректория бэкапа
                                path=${backupRootDirectory}"/"${arch_Name[$u]}"/"${dateArchived};

                                # Проверяем сущестование дирректории бэкапа
                                if [ ! -d "${path}" ]
                                then
                                        #Создаем дирректорию для архива
                                        mkdir -p ${path}
                                fi;

                                if [ "${allDataBase}" == "yes" ]
                                then
                                        for l in $dbs
                                        do
                                                # Исключаем системные базы
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
        # Считаем кол-во дирректорий для архивации
        elLen=${#arch_Path[@]}

        # Раскладываем дирректории проектов
        for ((k=0; k<${elLen}; ++k));
        do
                # Дирректория бэкапа
                path=${backupRootDirectory}"/"${arch_Name[$k]}"/";

                # Получаем вложенные дирректории с отдельными архивами
                inDir=$(ls ${path} -l -1t | grep '^d' |awk '{print $8}');

                # Счетчик
                count=0;

                # Раскладываем вложенные дирректории
                for i in `ls ${path} -l -1t | grep '^d' |awk '{print $8}'`;
                do
                        find ${path}${i} -mtime +${maximumNumberDays} -type d -exec rm -rf {} \;
                done
        done
}

function clean_by_count ()
{
        # Считаем кол-во дирректорий для архивации
        elLen=${#arch_Path[@]}

        # Раскладываем дирректории проектов
        for ((k=0; k<${elLen}; k++));
        do
                # Дирректория бэкапа
                path=${backupRootDirectory}"/"${arch_Name[$k]}"/";

                # Получаем вложенные дирректории с отдельными архивами
                inDir=$(ls ${path} -l -1t | grep '^d' |awk '{print $9}');

                # Счетчик
                count=0;

                preCount=$((maximumNumberArchives-1));

                # Раскладываем вложенные дирректории
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

arch # Вызываем функцию архивации

# Вызываем функцию очистки НЕ актуальных архивов по:
# - дате
#clean_by_date

# - колличеству
clean_by_count

exit 0
