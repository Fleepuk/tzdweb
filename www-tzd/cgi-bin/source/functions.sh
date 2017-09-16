#!/bin/bash

ROOTPATH=/var/www/cgi-bin
GLOBALS=/var/www/cgi-bin/tmp/globals
[[ ! -f $GLOBALS ]] && touch $GLOBALS && chmod 777 $GLOBALS
	

#gets, sets, removes hosts entries for managment hosts

#HOSTS file management

add_rdp(){

	# Adds rdp file to public desktop
	# $1=username $2=host, $3=container name
	HOSTNAME=$(hostname)
	IPADDRESS=$(get_container_ip $3)
	if [[ "$IPADDRESS" != "" ]]
	then
		echo "..\..\bin\amend_rdp.cmd ADD $3 $HOSTNAME" >> $ROOTPATH/tmp/windowshost
	fi
}
remove_rdp(){
	# Removes rdp file from public desktop
	# $1=username, $2=host, $3=container name
	HOSTNAME=$(hostname)
	echo "..\..\bin\amend_rdp.cmd DELETE $3 $HOSTNAME" >> $ROOTPATH/tmp/windowshost
}
purge_rdp(){
	# Purges rdp files from public desktop
	# $1=username, $2=host
	ssh -n $1@$2 "/bin/amend_rdp.cmd PURGE $(hostname)" >/dev/null

}

add_container(){

	# Adds container details to hosts
	# $1=username $2=host, $3=container name
	HOSTNAME=$(hostname)
	IPADDRESS=$(get_container_ip $3)
	if [[ "$IPADDRESS" != "" ]]
	then
		echo "..\..\bin\amend_hosts.cmd ADD $IPADDRESS $3 $HOSTNAME" >> $ROOTPATH/tmp/windowshost
	fi
}
remove_container(){
	# Removes container from hosts
	# $1=username, $2=host, $3=container name
	echo "..\..\bin\amend_hosts.cmd DELETE $3" >> $ROOTPATH/tmp/windowshost
}

get_hosts_linux(){
	[[ -f /var/www/cgi-bin/tmp/hosts ]] && rm -f /var/www/cgi-bin/tmp/hosts
	scp $1@$2:/etc/hosts /var/www/cgi-bin/tmp/hosts
}


put_hosts_linux(){
	scp /var/www/cgi-bin/tmp/hosts $1@$2:/etc/hosts
	rm -rf tmp/hosts
}

add_container_linux(){
	
	HOSTUPDATE=/var/www/cgi-bin/tmp/hosts
	HOSTNAME=$(hostname)
        IPADDRESS=$(get_container_ip $1)
	if [[ $(grep -c "$1" $HOSTUPDATE) -ne 0 ]]
	then
		sed -i "/\t$1\t/d" $HOSTUPDATE
	fi	
	echo -e "${IPADDRESS}\t$1\t#${HOSTNAME}#" >> $HOSTUPDATE

}

delete_container_linux(){

	#$1-username, $2=host, $3=container
	[[ -f tmp/hosts ]] && rm -f tmp/hosts
	ssh -n $1@$2 "cat /etc/hosts" > tmp/hosts
	sed -i "/\t$3\t/d" tmp/hosts	
	cat tmp/hosts|ssh -n $1@$2 "cat > /etc/hosts"
}

get_container_ip(){
	# Get container IP address
	#$1=container name
	echo $(docker inspect $1|grep -A100 "Networks"|grep IPAddress|grep 172|cut -d ":" -f2|tr -d '," ')
}

configure_routing(){
	DOCKERSUBNET=$(docker network inspect tzddocker|grep Subnet|cut -d ":" -f2|cut -d "/" -f1|tr -d " \"")
	HOSTNIC=$(netstat -r|grep default|tr -s " "|cut -d " " -f8)
	HOSTIP=$(ifconfig ${HOSTNIC}|grep "inet "|tr -s " "|cut -d " " -f3)
	if [[ "$3" == "WINDOWS" ]]
	then
		if [[ $(ssh $1@$2 route print|grep -c $DOCKERSUBNET) -eq 0 ]]
		then		
			ssh $1@$2 route add $DOCKERSUBNET mask 255.255.0.0 $HOSTIP > /dev/null
		fi
	else
		if [[ $(ssh $1@$2 /usr/sbin/route|grep -c $DOCKERSUBNET) -eq 0 ]]
		then
			ssh $1@$2 "sudo /usr/sbin/route add -net $DOCKERSUBNET netmask 255.255.0.0 gw $HOSTIP" 2>&1
		fi
	fi
}

purge_hosts(){
	 # $1=username, $2=host hostname
	echo "..\..\bin\amend_hosts.cmd PURGE $(hostname)" >> $ROOTPATH/tmp/windowshost
}

purge_hosts_linux(){
	HOSTUPDATE=/var/www/cgi-bin/tmp/hosts
	 # $1=username, $2=host
	HOSTNAME=$(hostname)
	get_hosts_linux $1 $2
	sed -i "/#${HOSTNAME}#/d" $HOSTUPDATE
	put_hosts_linux $1 $2
}

update_managementhosts(){
	# $1=action, $2=container
	DATAPATH=/var/www/cgi-bin/
	source $DATAPATH/source/manage_registry.sh
	while read HOST USERNAME TYPE INTEGRATE STUDIO ATELIER
	do
		if [[ "$INTEGRATE" == "true" ]]
		then
			if [[ "$1" == "amend" ]]
			then
				add_container $USERNAME $HOST $2
			else
				remove_container $USERNAME $HOST $2
			fi
			if [[ "$TYPE" == "WINDOWS" && "$INTEGRATE" == "true" ]]
			then
				if [[ "$1" == "delete" ]]
                		then
					remove_registry $USERNAME $HOST $2
				fi
			fi
		fi
	done < $DATAPATH/tmp/management_clients
}

add_container_host(){
	# $1=container
	local CONTAINERNAME=$1
	[[ "$(grep -e " ${CONTAINERNAME}$" /etc/docker_hosts)" == "" ]] && \
	echo $(get_container_ip ${CONTAINERNAME}) ${CONTAINERNAME} >> /etc/docker_hosts && \
	kill -HUP $(pgrep dnsmasq)
}
remove_container_host(){
 	sed -i "/ $1$/d" /etc/docker_hosts
	kill -HUP $(pgrep dnsmasq)
} 

# REGISTRY MANAGEMENT

add_registry(){

	#$1=username $2=management host $3=container name
	echo "..\..\bin\amend_registry.cmd ADD $3 $(hostname)" >> $ROOTPATH/tmp/windowshost
}

remove_registry(){
	#$1=username $2=management host $3=container name
	echo  "..\..\bin\amend_registry.cmd REMOVE $3" >> $ROOTPATH/tmp/windowshost
}

purge_registry(){

	#$1=username $2=management host 
	ssh -n $1@$2 "/bin/amend_registry.cmd PURGE $(hostname)" >/dev/null
}
# IMAGE information

isHS(){
# Using entrypoint set as /sbin/pseud-init to determine
# %1=container name

local ENTRYPOINT=$(docker inspect --format='{{json .Config.Entrypoint}}' $1|tr -d "[]\"")
if [[ "$ENTRYPOINT" == "/sbin/pseudo-init" ]] 
then
	echo "true"
else
	echo "false"
fi
}

isRDP(){
# Using entrypoint set as /sbin/pseud-init to determine
# %1=container name

local ENTRYPOINT=$(docker inspect --format='{{json .Config.Entrypoint}}' $1|tr -d "[]\"")
if [[ "$ENTRYPOINT" == "/sbin/rdp" ]]
then
        echo "true"
else
        echo "false"
fi
}



write_global(){
#writes fresh global
	if [[ $(grep -c -e "^$1=" $GLOBALS) -eq 0 ]]
	then
		echo "$1=$(eval echo \$$1)" >> $GLOBALS
	else
		if [[ "$(grep -e "^$1=$(eval echo \$$1)" $GLOBALS)" != "$1=$(eval echo \$$1)" ]]
		then
			sed -i "s,$1=.*,$1=$(eval echo \$$1),g" $GLOBALS
		fi
	fi
}

delete_global(){
#deletes whole global
	[[ "$1" != "" ]] && sed -i "/^$1=/d" $GLOBALS
}

append_global(){
#appends to global
	local new
	if [[ "$1" != "" ]] && [[ "$2" != "" ]]
	then
		if  [[ $(grep -c -e "^$1=" $GLOBALS) -eq 0 ]] 
		then
			echo "$1=$2" >> $GLOBALS	
		else
			if [[ $(echo +$(grep -e "^$1=" $GLOBALS|cut -d "=" -f2)+|tr " " "+"|grep -c "+$2+") -eq 0 ]]
			then
				. /var/www/cgi-bin/tmp/globals
				new="$(eval echo \$$1) $2"
				delete_global $1
				echo -e "$1=\"$new\"" >> $GLOBALS
			fi
		fi
	fi
}

remove_entry_global(){
#removes entry from global
	if [[ "$1" != "" ]] && [[ "$2" != "" ]]
	then
		local REMOVE
		REMOVE=$(echo "+$(grep -e "^$1=" $GLOBALS|cut -d "=" -f2)+"|tr -d "\""|tr " " "+"|sed "s/+$2+/+/"|tr "+" " "|sed "s/^\ //"|sed "s/\ $//")
		delete_global $1
		if [[ "$REMOVE" != "" ]]
		then
			if [[ $(echo $REMOVE|grep -c " ") -eq 0 ]]
			then
				echo "$1=$REMOVE">>$GLOBALS
			else 
				echo -e "$1=\"$REMOVE\"" >>$GLOBALS
			fi
		fi
	fi
}

status() {
#writes a status message for system page
	echo $1 > tmp/status

}

client_status() {

	unset PINGCOUNT
	PINGCOUNT=$(ping -c 2 -w 1 $1 |grep -c "ttl")
	if [[ $PINGCOUNT -eq 0 ]]
	then
		echo "offline"
	else
		echo "online"
	fi
}


######## NGINX

remove_nginx_entry() {
	local NGINXCONF=/var/www/cgi-bin/tmp/tzdnginx.conf
        # $1=container
        local CONTAINER=$1
        local THISHOST=$(hostname)
        CONTAINERLINE=$(grep -n "${CONTAINER}.${THISHOST}.lan" $NGINXCONF|cut -d ":" -f1)
        STARTDELETE=$((${CONTAINERLINE}-2))
        ENDDELETE=$((${CONTAINERLINE}+4))
        sed -i "${STARTDELETE},${ENDDELETE}d" $NGINXCONF
}
add_nginx_entry() {
        # $1=container, $2=url $3=listenport $4=destination port
        local NGINXCONF=/var/www/cgi-bin/tmp/tzdnginx.conf
        local THISHOST=$(hostname)
        local CONTAINER=$1
        [[ -f $NGINXCONF ]] && [[ $(grep -c "${CONTAINER}.${THISHOST}.lan" $NGINXCONF) -ne 0 ]] && remove_nginx_entry $1
        echo "server {" >> $NGINXCONF
        echo -e "\tlisten  $3;" >> $NGINXCONF
        echo -e "\tserver_name  $2;" >> $NGINXCONF
        echo -e "\tlocation  / {"  >> $NGINXCONF
        echo -e "\tproxy_pass\thttp://$1:$4/;"  >> $NGINXCONF
        echo -e "\t}" >> $NGINXCONF
        echo "}" >> $NGINXCONF
}
hosts_add_nginx() {
	# $1=type (Windows, Linux....)
	[[ "$1" == "" ]] && return 1
	TMPPATH=/var/www/cgi-bin/tmp
	THISIP=$(get_container_ip nginx)
	HOSTNAME=$(hostname)
	#echo $TMPPATH,$THISIP,$HOSTNAME
	if [[ -f $TMPPATH/tzdnginx.conf ]]
	then
		for ADDHOST in $(grep "$(hostname).lan" $TMPPATH/tzdnginx.conf|tr -s " "|cut -d " " -f2|tr -d ";")
		do
			#echo $TMPPATH/tzdnginx.conf,$1,$THISIP,$ADDHOST
			if [[ "$1" == "WINDOWS" && "$THISIP" != "" ]]
			then
				echo "..\..\bin\amend_hosts.cmd ADD $THISIP $ADDHOST $HOSTNAME" >> $ROOTPATH/tmp/windowshost
			fi
		done
	fi
	if [[ -f $TMPPATH/nginxlb ]]
	then
		while read THISHOST other
		do
			ADDHOST=$(echo $THISHOST|cut -d ":" -f1)
			#echo $TMPPATH/tzdnginx.conf,$1,$THISIP,$ADDHOST
			if [[ "$1" == "WINDOWS" && "$THISIP" != "" ]]
			then
				echo "..\..\bin\amend_hosts.cmd ADD $THISIP $ADDHOST $HOSTNAME" >> $ROOTPATH/tmp/windowshost
			fi
		done < $TMPPATH/nginxlb
	fi
	unset TMPPATH

}
dockerlogin() {
	. /var/www/cgi-bin/tmp/globals
	docker login -u $TZDUSER -p $TZDPASS
}
dockerlogout() {
	docker logout > /dev/null
}

imagelocation() {
	#$1=full image name, eg tzdsystems/docker:test
	echo $(grep "$(echo $1|tr ":" " ")" /var/www/cgi-bin/tmp/images|cut -d " " -f3)
}

