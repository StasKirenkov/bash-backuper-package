#!/bin/sh

#Занизим приоритет выполнения, что бы не 'жрать лишние' ресурсы
renice 19 -p $$

#************************************************#
#                 backup.sh                      #
#           Author: Kirenkov Stas                #
#               April 27, 2012                   #
#                                                #
#       Backuping up of selected project         #
#************************************************#

# Получаем текущие дату и время в формате: yyyy_mm_dd_hh_mm_ss
archDate=`date +%Y_%m_%d_%H_%M_%S`

# Бэкап файлов? yes || no
fileBackup="yes";

# Корневая дирректория для хранения резервных копий
backupPath='/srv/www/htdocs/backup';

#Признак одиночного запуска с передачей параметров
ONCE="no";

# Кол-во актуальных архивов (для ротации по кол-ву)
total=5;

# Кол-во дней за которые хранить архивы (для ротации по дате)
days=5

# Минимально кол-во свободного места на НЖМД для хранения архивов (задается в МегаБайтах)
minfreespace="2048";

# Бэкап MySQL баз? yes || no
mysqlBackup="no";

#Разбор параметров из коммандной строки
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
    ONCE="yes"
    ;;
    -x=*|--path=*)
    exclude_list[0]="${i#*=}"
    ;;
    *)
        echo "Unknown option";
    ;;
esac
done
#echo PATH = ${arch_Path[0]}
#echo NAME PROJECT = ${arch_Name[0]}
#echo ONCE = ${ONCE}
#
#exit;

if [ "${ONCE}" == "no" ]
then
    # Массив дирректорий для архивации
    arch_Path[0]="/srv/www/htdocs";
    arch_Path[1]="/srv/www/htdocs/denklienta";
    arch_Path[2]="/srv/www/htdocs/index_new";

    # Массив исключений
    exclude_list[0]="--exclude=*.svn* --exclude=*.git* --exclude=/srv/www/htdocs/backup/* --exclude=/srv/www/htdocs/bitrix/backup/* --exclude=/srv/www/htdocs/backup/* --exclude=/srv/www/htdocs/upload/* --exclude=/srv/www/htdocs/php_my_adm_1038/* --exclude=/srv/www/htdocs/video/* --exclude=/srv/www/htdocs/denklienta/* --exclude=/srv/www/htdocs/index_new/* --exclude=/srv/www/htdocs/bitrix/managed_cache/MYSQL/*";
    exclude_list[1]="--exclude=*.svn* --exclude=*.git* --exclude=/srv/www/htdocs/denklienta/backup/* --exclude=/srv/www/htdocs/denklienta/upload/* --exclude=/srv/www/htdocs/denklienta/bitrix/backup/* --exclude=/srv/www/htdocs/denklienta/upload/* --exclude=/srv/www/htdocs/denklienta/bitrix/managed_cache/MYSQL/*";
    exclude_list[2]="";

    # Массив наименований проектов
    arch_Name[0]="etm_corp_site";
    arch_Name[1]="etm_electroforum";
    arch_Name[2]="index_page";

    # Бэкап MySQL баз? yes || no
    mysqlBackup="yes";

    # Архивировать все базы? yes || no
    allbases="no";

    # Если необходимо архивировать конкретную базу необходимо задать ее имя, а параметру 'allbases' задать значение 'no'
    dbName[0]="site";
    dbName[1]="denkl";

    # Массив пар пользователей и паролей от MySQL
    arch_base_login[0]="site";
    arch_base_pass[0]="WYMmeWXMq";

    arch_base_login[1]="denkl";
    arch_base_pass[1]="frfe43s";
fi;

# Непосредственно функция архивации заданной(ых) дирректории(й)
function arch ()
{
        # Проверяем сущестование дирректории бэкапа
        if [ ! -d "${backupPath}" ]
        then
                #Создаем дирректорию для архива
                mkdir -p ${backupPath}
        fi;

        # Проверяем кол-во свободного места на НЖМД
        freespace=`df -m ${backupPath} | grep dev | awk '{print $4}'`; # Работает для локальных директорий
        #freespace=`df -m ${backupPath} | grep 4 | awk '{print $3}'`; # Работает для примонтированной директории

        # Проверяем достаточность свободного места на НЖМД
        if [ "${minfreespace}" -ge "${freespace}" ]; then
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
                                path=${backupPath}"/"${arch_Name[$i]}"/"${archDate};

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
        sqlUserLen=${#arch_base_login[@]}

        # Проверяем нужен ли бэкап MySQL баз
        if [ "${mysqlBackup}" == "yes" ]
        then
                for ((u=0; u<=${sqlUserLen}; ++u));
                do
                        if [ -n "${arch_base_login[$u]}" ] && [ -n ${arch_base_pass[$u]} ]
                        then
                                dbs=$(mysql -u${arch_base_login[$u]} -p${arch_base_pass[$u]} -e "show databases;" | grep [[:alnum:]])

                                # Дирректория бэкапа
                                path=${backupPath}"/"${arch_Name[$u]}"/"${archDate};

                                # Проверяем сущестование дирректории бэкапа
                                if [ ! -d "${path}" ]
                                then
                                        #Создаем дирректорию для архива
                                        mkdir -p ${path}
                                fi;

                                if [ "${allbases}" == "yes" ]
                                then
                                        for l in $dbs
                                        do
                                                # Исключаем системные базы
                                                if [ "$l" == "Database" ] || [ "$l" == "information_schema" ] || [ "$l" == "mysql" ]
                                                then
                                                        continue
                                                fi;

                                                file=$l.sql
                                                mysqldump -u${arch_base_login[$u]} -p${arch_base_pass[$u]} --databases $l > /tmp/${file}
                                                mkdir -p ${path}"/sql/"
                                                mv /tmp/$file ${path}"/sql/"${file}
                                        done
                                elif [ "${allbases}" == "no" ]
                                then
                                        file=${dbName[$u]}.sql
                                        mysqldump -u${arch_base_login[$u]} -p${arch_base_pass[$u]} --databases ${dbName[$u]} > /tmp/${file}
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
                path=${backupPath}"/"${arch_Name[$k]}"/";

                # Получаем вложенные дирректории с отдельными архивами
                inDir=$(ls ${path} -l -1t | grep '^d' |awk '{print $8}');

                # Счетчик
                count=0;

                # Раскладываем вложенные дирректории
                for i in `ls ${path} -l -1t | grep '^d' |awk '{print $8}'`;
                do
                        find ${path}${i} -mtime +${days} -type d -exec rm -rf {} \;
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
                path=${backupPath}"/"${arch_Name[$k]}"/";

                # Получаем вложенные дирректории с отдельными архивами
                inDir=$(ls ${path} -l -1t | grep '^d' |awk '{print $9}');

                # Счетчик
                count=0;

                preCount=$((total-1));

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