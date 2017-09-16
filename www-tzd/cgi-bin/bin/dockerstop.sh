#!/bin/bash
#
# Stops an images 

BASEDIR=/var/www/cgi-bin
HOSTNAME=$(hostname)
source $BASEDIR/source/functions.sh
source $BASEDIR/source/functions.sh
cd $BASEDIR
. tmp/globals
#	Stop
	delete_global JOBSTATUS
 	echo "docker stop $STOPCONTAINER" >> tmp/joblog
	docker stop $STOPCONTAINER 2>&1 >> tmp/joblog
	. bin/update-clients.sh
	JOBSTATUS="complete"
	write_global JOBSTATUS
	delete_global STOPCONTAINER

