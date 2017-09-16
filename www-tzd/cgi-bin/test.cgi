#!/bin/bash
read CREDENTIALS
USERNAME=$(echo $CREDENTIALS|cut -d "&" -f1|cut -d "=" -f2|tr -d " ")
PASSWORD=$(echo $CREDENTIALS|cut -d "&" -f2|cut -d "=" -f2|tr -d " ")
[[ -f tmp/authorized_keys ]] && rm -f tmp/authorized_keys
echo "Content-type: text/html"
echo ""
. source/client.sh
echo "<table align="centre">"
echo "<tr><td align="center">Add integrated host.</td</tr>"
echo "<tr><td> This will add an RSA certificate to the \"authorized_keys\" file in the users .ssh directory on $MANHOST.</td></tr><br>"

if [[ $(sshpass -p $PASSWORD ssh $USERNAME@$MANHOST) ]] 
then
	echo "<tr>Login succeeded.  Checking for authorized keys.</tr><br>"
	if [[ "$(sshpass -p $PASSWORD ssh $USERNAME@$MANHOST ls .ssh)" == "" ]]
	then
		echo "<tr>Adding .ssh directory and setting permissions</tr><br>"
		sshpass -p $PASSWORD ssh $USERNAME@$MANHOST "mkdir .ssh;chmod 700 .ssh"
	 
	else
		echo "<tr>Retrieving authorized_keys</tr><br>"
		sshpass -p $PASSWORD scp $USERNAME@$MANHOST:.ssh/authorized_keys tmp/authorized_keys
	fi
	cat /usr/share/httpd/.ssh/id_rsa.pub >> tmp/authorized_keys
	echo "<tr>Transferring authorized keys</tr><br>"
	sshpass -p $PASSWORD scp tmp/authorized_keys $USERNAME@$MANHOST:.ssh/authorized_keys 2>&1
	echo "<tr>Keys in place.  Testing certified logon.</tr><br>"
	if [[ $(ssh $USERNAME@$MANHOST) ]]
	then
		echo "<tr>Success.</tr>"
		echo "<tr>Adding $MANHOST to integrated clients list</tr><br>"
		echo -e "$MANHOST $USERNAME $MANHOSTTYPE true" >> tmp/management_hosts
		
###copy reg scripts  for windows	

		echo "<tr>Redirecting to summary page</tr><br>"
 
		echo "<meta http-equiv="refresh" content=\"5;url=http://tzddocker/cgi-bin/summary.cgi\""
		
	else
		echo "<tr>Certificate copy failed to achieve.</tr><br>"
	fi
	
else
	echo "Login failed.  It sucks to be you."
fi
echo "</table>"
rm -rf tmp/authorized_keys
