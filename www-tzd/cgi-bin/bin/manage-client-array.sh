#!/bin/bash
#
# Creates list of images on docker hub
# $1=POST string
source /var/www/cgi-bin/source/functions.sh

THISHOST=$(echo $1|cut -d "&" -f1|cut -d "=" -f2)
THISCHANGE=$(echo $1|cut -d "&" -f2|cut -d "=" -f1)
CURRENTVALUE=$(echo $1|cut -d "&" -f2|cut -d "=" -f2)
case $CURRENTVALUE in
	"Delete")
		sed -i "/$THISHOST/d" tmp/management_clients	
		;;
	*)
		if [[ "$CURRENTVALUE" == "true" ]]
		then 
			NEWVALUE=false
		else
			NEWVALUE=true
		fi
		while read HOST USERNAME TYPE INTEGRATED STUDIO ATELIER
		do
			if [[ "$THISHOST" == "$HOST" ]]
			then
				if [[ "$USERNAME" != "unknown" ]]
				then 
					if [[ "$THISCHANGE" == "INTEGRATED" ]]
					then
						if [[ "$NEWVALUE" == "true" ]] 
						then
							sed -i "s/$HOST $USERNAME $TYPE $INTEGRATED $STUDIO $ATELIER/$HOST $USERNAME $TYPE true false false/g" tmp/management_clients
							echo "update-clients.sh" > /var/www/cgi-bin/tmp/trigger
						else
							sed -i "s/$HOST $USERNAME $TYPE $INTEGRATED $STUDIO $ATELIER/$HOST $USERNAME $TYPE false false false/g" tmp/management_clients
							if  [[ "$TYPE" == "WINDOWS" ]]
							then
								purge_hosts $USERNAME $HOST
								[[ "$STUDIO" == "true" ]] && purge_registry $USERNAME $HOST
							else
								purge_hosts_linux $USERNAME $HOST
							fi
						fi
					else
						if [[ "$INTEGRATED" == "true" ]]
						then
							if [[ "$THISCHANGE" == "STUDIO" ]]
							then
								sed -i "s/$HOST $USERNAME $TYPE $INTEGRATED $STUDIO $ATELIER/$HOST $USERNAME $TYPE true $NEWVALUE $ATELIER/g" tmp/management_clients
							else
								sed -i "s/$HOST $USERNAME $TYPE $INTEGRATED $STUDIO $ATELIER/$HOST $USERNAME $TYPE true $STUDIO $NEWVALUE/g" tmp/management_clients
							fi
						fi
					fi
				else
					append_global ADDUSER $THISHOST
				fi
			fi
		done < tmp/management_clients
		;;
esac
