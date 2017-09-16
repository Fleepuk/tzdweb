#!/bin/bash
#Checks docker internal network and sets it to maintain uniqueness to local environment.

BASEDIR=/var/www/cgi-bin/
source $BASEDIR/source/functions.sh
unset OLDTZDDOCKERSN
DOCKNET=tzddocker
HOST=tzd-iscinternal
ID=tzd
HOSTNIC=$(netstat -r|grep default|tr -s " "|cut -d " " -f8)
HOSTIP=$(ifconfig ${HOSTNIC}|grep "inet "|tr -s " "|cut -d " " -f3)
while [[ "$HOSTIP" == "" ]]
do 
	HOSTIP=$(ifconfig ${HOSTNIC}|grep "inet "|tr -s " "|cut -d " " -f3)
	sleep 1
done

write_global HOSTIP
HOSTOCT=$(echo $HOSTIP|cut -d "." -f4)
write_global HOSTOCT

#check for existing entry in globals.  If so, record it as old for updating hosts and routing

[[ "$TZDDOCKERSN" == "" ]] && TZDDOCKERSN=172.$HOSTOCT.0.0 && write_global TZDDOCKERSN
[[ "$(docker network ls|grep -c $DOCKNET)" == "0" ]] && docker network create tzddocker --subnet $TZDDOCKERSN/16

if [[ "$TZDDOCKERSN" != "172.$HOSTOCT.0.0" ]]
then
	OLDTZDDOCKERSN=$TZDDOCKERSN
	write_global OLDTZDDOCKERSN
fi 
TZDDOCKERSN=172.$HOSTOCT.0.0
write_global TZDDOCKERSN

. $BASEDIR/tmp/globals
if [[ "$OLDTZDDOCKERSN" != ""  ]]
then
	#IP address has changed.
	#Get list of containers attached to the old network
	#Detach containers from that net

	for CONTAINER in $(docker network inspect $DOCKNET|grep "Containers" -A 100|grep Name|cut -d ":" -f2|tr -d "\" ,") 
	do
		append_global CONTAINERMV $CONTAINER
		docker network disconnect $DOCKNET $CONTAINER
	done
	docker network rm $DOCKNET
	docker network create $DOCKNET --subnet $TZDDOCKERSN/16
	#Attach containers
	. $BASEDIR/tmp/globals
	for CONTAINER in $CONTAINERMV
	do
		docker network connect $DOCKNET $CONTAINER
	done
	#Update hosts and routing
	. $BASEDIR/bin/update-clients.sh
	delete_global CONTAINERMV
	delete_global OLDTZDDOCKERSN
fi



