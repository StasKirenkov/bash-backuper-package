How to disable delete old backups
-------------------------

*In the configuration file ./bash-backuper-package/src/1.3/main.conf, set the value **`0`** of the parameter `MAX_NUMBER_ARCHIVE' and  'MAX_NUMBER_DAYS'*

    ...
    
    # NUMBER OF STORED ARCHIVES (FOR ROTATION BY COUNTER)
    # or set '0', if you haven't limit
    export readonly MAX_NUMBER_ARCHIVES=0;
    
    ...
    ...
    
    # NUMBER OF DAYS FOR WHICH TO STORE ARCHIVES (FOR ROTATION BY DATE)
    # or set '0', if you haven't limit
    export readonly MAX_NUMBER_DAYS=0
        
    ...

