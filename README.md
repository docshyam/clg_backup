  Purpose - To backup (at short frequncies e.g. 30 minutes) the important and fast growing tables in a database. This script can be used in adjunct to other scripts, those can be copying this data simultaneously to another storage/computer/server. 
In this way, if a server is crashed or data is corrupted, the latest short-term data will be preserved. 
  Modify the chunk size inside updatedpw.sh file according to the requirement.
  Modify the frequency of script running inside systemwide crontab file.
