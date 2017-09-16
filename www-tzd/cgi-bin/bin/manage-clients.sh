#!/bin/bash
#
# Script to add rsa pub key to client and update tmp/management-clients
ROOTPATH=/var/www/cgi-bin
cd $ROOTPATH
source source/functions.sh
. tmp/globals
# open_terminal
echo "Add integrated client."
echo "This will add an RSA certificate to the \"authorized_keys\" file"
echo "in the users .ssh directory on $MANHOST."
if [[ $(sshpass -o StrictHostKeyChecking=no -p $PASSWORD ssh-copy-id $USERNAME@$MANHOST) ]] 
then
	echo "Login succeeded.  Checking for authorized keys."
	if [[ "$(sshpass -p $PASSWORD ssh  -o StrictHostKeyChecking=no $USERNAME@$MANHOST ls .ssh)" == "" ]]
	then
		echo "Adding .ssh directory and setting permissions."
		sshpass -p $PASSWORD ssh  -o StrictHostKeyChecking=no $USERNAME@$MANHOST "mkdir .ssh;chmod 700 .ssh"
	 
	else
		echo "Retrieving authorized_keys"
		sshpass -p $PASSWORD scp -o StrictHostKeyChecking=no $USERNAME@$MANHOST:.ssh/authorized_keys tmp/authorized_keys
	fi
	cat /root/.ssh/id_rsa.pub > tmp/authorized_keys
	cat /usr/share/httpd/.ssh/id_rsa.pub >> tmp/authorized_keys
	echo "Transferring authorized keys back to client."
	sshpass -p $PASSWORD rsync tmp/authorized_keys $USERNAME@$MANHOST:.ssh/authorized_keys 2>&1
	echo "Keys in place.  Testing logon."|tee $ROOTPATH/tmp/addclient
	if [[ $(ssh -o StrictHostKeyChecking=no $USERNAME@$MANHOST echo 0) ]]
	then
		echo "Success."
		echo "Adding $MANHOST to integrated clients list."|tee $ROOTPATH/tmp/addclient
		sed  -i "/$MANHOST/d" tmp/management_clients 
		echo "$MANHOST $USERNAME $MANHOSTTYPE true $STUDIO $ATELIER" >> tmp/management_clients
		echo "Updating clients...."
		. $ROOTPATH/bin/update-clients.sh
		echo "...done."
	else
		echo "Certificate copy failed to achieve."|tee $ROOTPATH/tmp/addclient
	fi
	
else
	echo "Login failed.  It is probably the username and password supplied."|tee $ROOTPATH/tmp/addclient
fi
echo "SCRIPT END"
rm -rf tmp/authorized_keys
delete_global USERNAME
delete_global PASSWORD
delete_global TERMGARGET
