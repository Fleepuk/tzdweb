#!/bin/bash
[[ ! -f /tmp/management_clients ]] && touch tmp/management_clients
source source/functions.sh
. tmp/globals
cat base/header 
cat base/nav|sed "s/calm screen4/dcalm/g"
cat base/advanced|sed "s/green build/yellow build/g"
if [[ "$REQUEST_METHOD" == "POST" ]]
then
	read INFO
#	echo $INFO
	. bin/manage-client-array.sh $INFO > /dev/null
	if [[ "$ADDUSER" != "" ]] 
	then
		delete_global $ADDUSER
		echo "<meta http-equiv="refresh" content=\"1;./add-host.cgi\">"
	fi
fi
#Advanced
#Disk usage
THISCOLOR=blue
echo "<table align=\"center\">"
echo "<tr><td class=\"information\" colspan=\"6\">Disk Usage</td></tr>"
#echo "<tr class=\"information blue\"><td>HOST</td><td>USERNAME</td><td>OS</td><td>INTEGRATED</td><td>STUDIO</td><td>ATELIER</td></tr>"
while read FS SIZE USED AVAIL USE MOUNT
do
echo "<tr class=\"filelisting $THISCOLOR\">" 
echo "<td>$FS</td><td>$SIZE</td><td>$USED</td><td>$AVAIL</td><td>$USE</td><td>$MOUNT</td>"
echo "</tr>"
[[ "$THISCOLOR" == "blue" ]] && THISCOLOR=light
done < <(df|grep -v loop)
echo "</table>"
echo "<table width=\"100%\"><tr><td width=\"100%\" height=\"3px\" class=\"build\"></td></tr></table>"

#ZFS usage
echo "<table width=\"100%\"><tr><td width=\"100%\" height=\"3px\" class=\"yellow build\"></td></tr></table>"
echo "<table align=\"center\">"
echo "<tr><td class=\"information\" colspan=\"5\">ZFS Usage</td></tr>"
echo "<tr class=\"filelisting blue\"><td>Volume</td><td>Size (bytes)</td>"
REFERENCED=0
while read NAME USED
do
	if [[ "$NAME" == "(Reference-volume)" ]]
	then 
		REFERENCED=$(($REFERENCED + USED))
	else
		echo "<tr class=\"filelisting light\">"
		echo "<td>$NAME</td><td>$USED</td>"
		echo "</tr>"
	fi
done < tmp/zfsusage
echo "<tr class=\"filelisting light\"><td>(Reference volumes)</td><td>${REFERENCED}</td>"
echo "</table>"
echo "<table width=\"100%\"><tr><td width=\"100%\" height=\"3px\" class=\"build\"></td></tr></table>"

THISCOLOR=blue
echo "<table align=\"center\">"
echo "<tr><td class=\"information\" colspan=\"5\">ZFS Status</td></tr>"
#echo "<tr class=\"information blue\"><td>HOST</td><td>USERNAME</td><td>OS</td><td>INTEGRATED</td><td>STUDIO</td><td>ATELIER</td></tr>"

while read NAME SIZE ALLOC FREE EXPANDSZ FRAG CAP DEDUP HEALTH ALTROOT
do
echo "<tr class=\"filelisting $THISCOLOR\">"
echo "<td>$NAME</td><td>$SIZE</td><td>$FREE</td><td>$ALLOC</td><td>$HEALTH</td>"
echo "</tr>"
[[ "$THISCOLOR" == "blue" ]] && THISCOLOR=light
done < tmp/zfspools
echo "</table>"

#status message
echo "<table width=\"100%\"><tr><td width=\"100%\" height=\"3px\" class=\"yellow build\"></td></tr></table>"
echo "<table align=\"center\"><tr><td class=\"information\">Status: "
cat tmp/status
echo "</td></tr></table>"

#Management Clients
echo "<table width=\"100%\"><tr><td width=\"100%\" height=\"3px\" class=\"blue build\"></td></tr></table>"
echo "<table align=\"center\"><tr><td class=\"label\" colspan=\"7\">Registered Management Clients</td></tr>"
echo "<table align=\"center\"><tr class=\"information blue\"><td>HOST</td><td>USERNAME</td><td>OS</td><td>INTEGRATED</td><td>STUDIO</td><td>ATELIER</td></tr>"
while read HOST USERNAME TYPE INTEGRATED STUDIO ATELIER
do
	if [[ "$INTEGRATED" == "true" ]]
	then
		DIS=""
		THEME="yellow"
	else
		THEME="light tblack"
		DIS="disabled"
	fi
	echo "<tr class=\"information $THEME\">" 
	echo "<form action=\"./system.cgi\" method=\"POST\">"
	echo "<td><input type=\"hidden\" name=\"HOST\" value=\"$HOST\">$HOST</td>"
	echo "<td>$USERNAME</td><td>$TYPE</td>"
	echo "<td><input type=\"submit\" name=\"INTEGRATED\" value=\"$INTEGRATED\" class=\"button information $THEME\"></td>"
	if [[ "$TYPE" == "WINDOWS" ]]
	then
		echo "<td><input type=\"submit\" name=\"STUDIO\" value=\"$STUDIO\" class=\"button information $THEME\" $DIS></td>"
	else
		echo "<td><input type=\"submit\" name=\"STUDIO\" value=\"$STUDIO\" class=\"button information $THEME\" disabled></td>"
	fi
	echo "<td><input type=\"submit\" name=\"ATELIER\" value=\"$ATELIER\" class=\"button information $THEME\" $DIS></td>"
	echo "<td><input type=\"submit\" name=\"DELETE\" value=\"Delete\" class=\"button red\"></td>"
	echo "</form></tr>"
done < tmp/management_clients
echo "</table>"
echo "<table width=\"100%\"><tr><td width=\"100%\" height=\"3px\" class=\"blue build\"></td></tr></table>"

echo "<table align=\"center\">"
echo "<tr><td><form action=\"./terminal.cgi\" method=\"POST\"><input type=\"submit\" name=\"TERMINAL\" value=\"Terminal\" class=\"button green\"></td></tr>"
echo "</table>"
echo "<table width=\"100%\"><tr><td width=\"100%\" height=\"3px\" class=\"yellow build\"></td></tr></table>"
cat base/footer
echo "zfs-status.sh" > tmp/trigger


