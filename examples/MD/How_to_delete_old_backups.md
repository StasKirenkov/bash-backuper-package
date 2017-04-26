How to delete old backups
-------------------------

 1. If you just need to store the `N` of the last backups, then:

*In the configuration file ./bash-backuper-package/src/1.3/main.conf, set the value of the parameter `MAX_NUMBER_ARCHIVE'*

    ...
    
    # NUMBER OF STORED ARCHIVES (FOR ROTATION BY COUNTER)
    # or set '0', if you haven't limit
    export readonly MAX_NUMBER_ARCHIVES=2;
    
    ...

    2. If you need to take into account the date of the actuality of the backup copies, then:

*In the configuration file ./bash-backuper-package/src/1.3/main.conf, set the value of the parameter `MAX_NUMBER_DAYS'*

        ...
    
    # NUMBER OF DAYS FOR WHICH TO STORE ARCHIVES (FOR ROTATION BY DATE)
    # or set '0', if you haven't limit
    export readonly MAX_NUMBER_DAYS=2
        
        ...

