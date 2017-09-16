#!/bin/bash
source source/functions.sh
. source/client.sh
ADDHOST=false
[[ $(grep -c "$MANHOST" tmp/management_hosts) -eq 0 ]] && ADDHOST=true
cat base/header 
cat base/nav|sed "s/screen1/green/g"
if [[ "$ADDHOST" == "true" ]]
then
	echo "<table align=\"center\"><tr><td class=\"instruction\">Add $MANHOST as Management Client?</td>"
	echo "<td><form action="./add-host.cgi" method=\"get\"><input type=\"submit\" value=\"Yes\"></td></tr></table><br>"
fi
echo "<table align=\"center\"><tr><td class=\"p\" colspan=\"3\">Summary</td></tr>"
echo "<tr></tr>"
echo "<tr><td class=\"p\" colspan=\"3\">Local Images</td></tr>"
echo "<tr></tr>"
echo "<tr><td class=\"label label2 yellow\">Repository</td><td class=\"label label2 yellow\">Tag</td><td class=\"label label2 yellow\">Size</td></tr>"
while read REP TAG SIZE 
do
	echo "<tr><td class=\"label label2 light\">$REP</td><td class=\"label label2\">$TAG</td><td class=\"label label2 light\">$SIZE</td></tr>"
done < <( docker images --format "{{.Repository}} {{.Tag}} {{.Size}}" 2>&1)

echo "<tr><td class=\"p\" colspan=\"3\">Remote Images</td></tr>"
echo "<tr></tr>"
echo "<tr><td class=\"label label2 yellow\">Repository</td><td class=\"label label2 yellow\">Tag</td><td class=\"label label2 yellow\">Size</td></tr>"

while read TAG SIZE DATE 
do
	echo "<tr><td class=\"label label2\">tzdsystems/docker</td><td class=\"label label2\">$TAG</td><td class=\"label label2\">$SIZE</td></tr>"
done < tmp/dockerhub

echo "<tr><td class=\"p\" colspan=\"3\">Containers</td></tr>"
echo "<tr></tr>"
echo "<tr><td class=\"label label2 yellow\">Name</td><td class=\"label label2 yellow\">Repository</td><td class=\"label label2 yellow\">Status</td></tr>"

while read NAME IMAGE STATUS
do
	echo "<tr><td class=\"label label2\">$NAME</td><td class=\"label label2\">$IMAGE</td><td class=\"label label2\">"$STATUS"</td></tr>"
done < <(docker ps -a --format "{{.Names}} ({{.Image}}) {{.Status}}")
echo "<tr></tr>"
echo "</table>"
cat base/footer
