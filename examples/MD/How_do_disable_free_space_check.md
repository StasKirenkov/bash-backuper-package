How do I disable the free space check
-------------------------

*In the configuration file ./bash-backuper-package/src/1.3/main.conf, set the value **`0`** of the parameter `MIN_FREE_SPACE'*

    ...
    # MINIMUM FREE STORAGE SPACE (MB or GB)
	# or set '0', if you haven't limit
	export readonly MIN_FREE_SPACE='0';
    ...
