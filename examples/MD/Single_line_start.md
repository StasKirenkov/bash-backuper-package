# Single line start

----------
Below is an example, running a single line on cron

----------
    * * * * * /bin/sh /your/path/to/backup.sh -p=root_directory_backups -n=your_project_name -o=yes
    - - - - -
    | | | | |
    | | | | ----- Day of week (0 - 7) (Sunday=0 or 7)
    | | | ------- Month (1 - 12)
    | | --------- Day of month (1 - 31)
    | ----------- Hour (0 - 23)
    ------------- Minute (0 - 59)