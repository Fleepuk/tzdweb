#!/bin/bash
#
# Updates docker nginx reverse proxy
# add containers to tzdnginx.conf
# upload this to the nginx container - /etc/nginx/conf.d
# 
# re-write tzdnginx.conf
# copy to nginx
# Reload nginx
# Update hosts.

THISPATH=/var/www/cgi-bin
source $THISPATH/source/functions.sh
[[ -f $THISPATH/tmp/tzdnginx.conf ]] && rm -f $THISPATH/tmp/tzdnginx.conf

while read NGINXTO URL PORTFROM PORTTO
do
	add_nginx_entry $NGINXTO $URL $PORTFROM $PORTTO
done < $THISPATH/tmp/nginx
chmod 777 ${THISPATH}/tmp/tzdnginx.conf
docker cp ${THISPATH}/tmp/tzdnginx.conf nginx:/etc/nginx/conf.d/tzdnginx.conf
docker exec -t nginx sh -c "service nginx reload"
. ${THISPATH}/bin/update-clients.sh



