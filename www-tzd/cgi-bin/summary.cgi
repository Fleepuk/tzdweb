#!/bin/bash
[[ ! -f /tmp/management_hosts ]] && touch tmp/management_hosts
source source/functions.sh
ADDHOST=false
cat base/header 
. source/client.sh 2>&1
[[ $(grep -c "$MANHOST" tmp/management_clients) -eq 0 ]] && ADDHOST=true
cat base/nav|sed "s/screen1/green/g"
if [[ "$ADDHOST" == "true" ]]
then
	echo "<table align=\"center\"><tr><td class=\"instruction\">Add $MANHOSTUC to Management Clients?"
	echo "<td><form action="./add-host.cgi" method=\"POST\"><input type=\"submit\" name=\"ADDHOST\" value=\"Yes\" class=\"button\"></td><td><input type=\"submit\" name=\"ADDHOST\" value=\"No\" class=\"button\"></td></tr></table><br>"
fi
echo "<table align=\"center\"><tr><td class=\"p\" colspan=\"3\">Summary</td></tr>"
echo "<tr></tr>"
echo "<tr><td class=\"p light\" colspan=\"3\">Local Images</td></tr>"
echo "<tr></tr>"
echo "<tr><td class=\"label label2 yellow\">Repository</td><td class=\"label label2 yellow\">Tag</td><td class=\"label label2 yellow\">Size</td></tr>"
while read REP TAG SIZE 
do
	echo "<tr><td class=\"label label2\">$REP</td><td class=\"label label2\">$TAG</td><td class=\"label label2\">$SIZE</td></tr>"
done < <( docker images --format "{{.Repository}} {{.Tag}} {{.Size}}" 2>&1)

echo "<tr><td class=\"p light\" colspan=\"3\">Remote Images</td></tr>"
echo "<tr></tr>"
echo "<tr><td class=\"label label2 yellow\">Repository</td><td class=\"label label2 yellow\">Tag</td><td class=\"label label2 yellow\">Size</td></tr>"

while read TAG SIZE DATE 
do
	echo "<tr><td class=\"label label2\">tzdsystems/docker</td><td class=\"label label2\">$TAG</td><td class=\"label label2\">$SIZE</td></tr>"
done < tmp/dockerhub

echo "<tr><td class=\"p light\" colspan=\"3\">Containers</td></tr>"
echo "<tr></tr>"
echo "<tr><td class=\"label label2 yellow\">Name</td><td class=\"label label2 yellow\">Repository</td><td class=\"label label2 yellow\">Status</td></tr>"
while read NAME IMAGE STATUS
do
	echo "<tr><td class=\"label label2\">$NAME</td><td class=\"label label2\">$IMAGE</td><td class=\"label label2\">"$STATUS"</td></tr>"
done < <(docker ps -a --format "{{.Names}} ({{.Image}}) {{.Status}}")
echo "<tr></tr>"
echo "</table>"
cat base/footer
echo "dockerhub.sh" > tmp/trigger
