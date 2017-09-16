#!/bin/bash
#
ROOTPATH=/var/www/cgi-bin
TRIGGER=$ROOTPATH/tmp/trigger
SCRIPTPATH=$ROOTPATH/bin
source $ROOTPATH/source/functions.sh
. $ROOTPATH/bin/tzddocker-init.sh
delete_global JOBSTATUS

while : 
do
	while :
	do
		unset COMMAND
		while [[ ! -f $TRIGGER ]]
		do
			sleep 1
		done
		DOTHIS=$(cat $TRIGGER)
		. $SCRIPTPATH/$DOTHIS
		echo $DOTHIS >> $ROOTPATH/tmp/jobtrigger
		rm -f $TRIGGER
	done
done

