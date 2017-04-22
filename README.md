![](http://edgarallenmarketing.com/wp-content/uploads/2016/01/Data-Loss-Sticky-Notes.gif)
#### <a name="simple-description"></a> Simple-description
Backuper-package is a admin tools to create a backup of file system and MySQL databases, example, your web projects.

##### Table of Contents
* [Simple description](#simple-description)
* [Preamble](#preamble)
  * [Credits / Contributors](#credits-contributors)
  * [Feedback](#feedback)
* [Main Features](#main-features)

---
[![Code Climate](https://codeclimate.com/github/StasKirenkov/bash-backuper-package/badges/gpa.svg)](https://codeclimate.com/github/StasKirenkov/bash-backuper-package) [![Test Coverage](https://codeclimate.com/github/StasKirenkov/bash-backuper-package/badges/coverage.svg)](https://codeclimate.com/github/StasKirenkov/bash-backuper-package/coverage) [![Issue Count](https://codeclimate.com/github/StasKirenkov/bash-backuper-package/badges/issue_count.svg)](https://codeclimate.com/github/StasKirenkov/bash-backuper-package)

----------
#### <a name="preamble"></a> Preamble
The Backuper-package was originally designed to provide a file-based backup system. After there was a need to save and dump MySQL database.
Subsequently, many extensions of functionality are planned.
Details will be later ...

#### <a name="credits-contributors"></a> Credits / Contributors
The Backuper-package is the original product of many hours of work by Stas Kirenkov, the primary author of the code.

#### <a name="feedback"></a> Feedback
Feedback is most certainly welcome for this document. Send your additions, comments and criticisms to the itmnewsru@gmail.com


----------


----------
#### <a name="main-features"></a> Main Features (v1.3)

v1.3
 - The procedure of pre-start checking of required parameters is added. ./bash-backuper-package/src/1.3/bin/pre_start.sh
 - All settings are now taken in a separate configuration file ./bash-backuper-package/src/1.3/main.conf
 - Start used Google code style
 - Added system messages during the execution, for subsequent logging to a file or to mail
 - You can specify a limit for limiting the space for saving backups, not only in megabytes, but also in gigabytes
 - If you do not have problems with the place to store backups, you can turn off the restrictions for the following parameters MAX_NUMBER_ARCHIVES, MAX_NUMBER_DAYS, MIN_FREE_SPACE

v1.2
 - Structuring of archival copies by catalogs with the name of the Project and the date of reservation;

>![enter image description here](https://lh3.googleusercontent.com/-tvLbpUaozkU/WO3f8NoCkdI/AAAAAAAAfGo/ioHMjSk0sU884kp-kFLcddEl6pmnsIUfACLcB/s0/Image.png "Image.png")

 - Storage as an archive, so far only ZIP. In the future there will be an expanded choice.;
 - 2 types of rotation of obsolete copies, by number or by date / time;
 - Backup of MySQL databases as a * .sql;

---
Author: Stas Kirenkov
Update: 04/05/2017
Contacts email: itmnewsru@gmail.com

