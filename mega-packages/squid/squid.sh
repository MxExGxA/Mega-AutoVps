#!/bin/bash
#Author: Elsayed Elghazy
#Date: 1 Aug 2022
#Description: this script will install and configure Squid Proxy Server
#Modified: 1 Aug 2022
#---------------------------------------------------------------------------------------

SQUID_CONF_FILE="/etc/squid/squid.conf"
is_num='^[0-9]+$'
cd 
cd -
#-------------------Install-and-configure-Squid-proxy---------------------#

change_squid_port(){

	echo -ne "${YELLOW}Enter Squid Port:${END}"; read PORT
	if [[ $PORT =~ $is_num ]] && (( $PORT >= 1 )) && (( $PORT <= 65000 ))
	then
		#check if port is in use
		netstat -npa | awk '{print $4}' | cut -d ':' -f2 |  grep $PORT &> /dev/null
		if [ $? == 0 ]
		then
			echo -e "${RED}port $PORT is used by another process !${END}"
			change_squid_port
		else
			echo -e "${GREEN}Port $PORT Accepted!${END}"
			sed -i "/http_port/c\http_port 0.0.0.0:$PORT" $SQUID_CONF_FILE
			echo -e "${YELLOW}Restarting Squid Service...${END}"
			service squid restart
		fi
	else
	echo -e "${RED}Wrong Port Number${END}"
	change_squid_port
	fi

}

install_squid(){
	echo -e "${YELLOW}Installing Squid...${END}"
	apt install squid -y &> /dev/null
	echo -e "${GREEN}Squid has installed!!${END}"

#squid.conf

echo "
#allowed dstdomains
$IP
127.0.0.1
localhost" > /etc/squid/allowed_dstdomains

echo "
#Squid_Configuration
acl allowed_dst dstdomain '/etc/squid/allowed_dstdomains'
acl url3 url_regex -i '/etc/payloads'
acl all src 0.0.0.0/0
http_access allow allowed_dst
http_access allow url3
http_access allow all
#port
http_port $PORT

#name
visible_hostname Mega-autoscript

via off
forwarded_for off
pipeline_prefetch off" > $SQUID_CONF_FILE


	change_squid_port
	echo -e "${YELLOW}Configuring...${END}"


	sleep 1
	cp /etc/mega-packages/squid/payloads /etc/payloads


	echo -e "${YELLOW}Checking squid status... ${END}"
	sleep 1
	if service squid status &> /dev/null ;then
		echo -e "${GREEN}RUNNING!!${END}"
	else
		echo -e "${RED}ERROR!${END}"
	fi
	sleep 2
	call_squid_menu
}

check_squid_status(){
	if service squid status | grep "active (running)" &> /dev/null ;then
	echo -e "${GREEN}Squid service is Running.${END}"
	else
	echo -e "${RED}Squid service is not running!${END}"
	fi
	sleep 1
	call_squid_menu
}

restart_squid_service(){
	echo -e "${YELLOW}Restarting...${END}"
	if service squid restart &> /dev/null ;then
	echo -e "${GREEN}Squid service has restarted.${END}"
	else
	echo -e "${RED}Failed to Restart Squid service${END}"
	fi
	sleep 2
	call_squid_menu

}

uninstall_squid(){

	perform_uninstall(){

		echo -e "${YELLOW}Uninstalling...${END}"
		apt remove squid -y &> /dev/null
		if rm /etc/squid/squid.conf ;then
		echo -e "${GREEN}Squid has uninstalled.${END}"
		else
		echo -e "${RED}Failed to uninstall squid!${END}"
		fi
		sleep 2
		call_squid_menu

	}

	echo -ne "${YELLOW}Are You Sure?(y/n)" ; read CHOICE
	case $CHOICE in
	[yY])perform_uninstall;;
	*)call_squid_menu;;
	esac




}

squid_not_installed_menu(){
	show_header
	echo -e "${BACK_CYAN}                 -[SQUID]-                    ${END}"
	echo -e "0-Go Back"
	echo -e "1-Install squid"
	echo $SEP
	echo -ne "Enter Number(0-1):"; read CHOICE

	case $CHOICE in
	0)mega;;
	1)install_squid;;
	*)squid_not_installed_menu;;
	esac


}
squid_installed_menu(){
	show_header
	echo -e "${BACK_CYAN}${WHITE}                  -[SQUID]-                   ${END}"
	echo -e "0-Go Back"
	echo -e "1-Change squid port"
	echo -e "2-Check squid status"
	echo -e "3-Restart squid"
	echo -e "4-Uninstall Squid"
	echo $SEP
	echo -ne "Enter Number(0-4):${END}"; read CHOICE

	case $CHOICE in
	0)mega;;
	1)change_squid_port && squid_installed_menu;;
	2)check_squid_status;;
	3)restart_squid_service;;
	4)uninstall_squid;;
	*)squid_installed_menu;;
	esac
}
#check if squid is installed
call_squid_menu(){
	if ! which squid &> /dev/null ;then
		squid_not_installed_menu
	else
		squid_installed_menu
	fi

}
call_squid_menu
