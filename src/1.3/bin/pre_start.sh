#*****************************************************#
#                                                     #
# Pre-start check, for critical params and dependency #
#                                                     #
#*****************************************************#

error_str='';

if [ -z "$FILESYSTEM_BACKUP" ];
then
    error_str="$error_str\r'FILESYSTEM_BACKUP' can not be empty. Please set the value to "yes" or "no" in the file $(dirname $(pwd))/name.conf"
fi;

if [ -z "$MIN_FREE_SPACE" ];
then
    error_str="$error_str\r'MIN_FREE_SPACE' can not be empty. Please set the limited value in the file $(dirname $(pwd))/name.conf or set value 0, if you haven't limit"
fi;

if [ -z "$MYSQL_BACKUP" ];
then
    error_str="$error_str\r'MYSQL_BACKUP' can not be empty. Please set the value to "yes" or "no" in the file $(dirname $(pwd))/name.conf"
fi;

if [ -z "$ALL_DATA_BASE" ];
then
    error_str="$error_str\r'ALL_DATA_BASE' can not be empty. Please set the value to "yes" or "no" in the file $(dirname $(pwd))/name.conf"
fi;
