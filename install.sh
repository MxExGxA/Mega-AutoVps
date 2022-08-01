#!/bin/bash

initial_check(){

	is_root=`whoami`

}

download_mega_packages(){

        wget https://github.com/MxExGxA/Mega-AutoVps/tree/master/mega-packages

}

install_iptables_persistent(){

        echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
        echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
        apt-get -y install iptables-persistent

}

update_vps(){
        rm /var/lib/dpkg/lock-frontend
        dpkg --configure -a

        echo -e "${YELLOW}Updating and Upgrading vps...${END}"
        apt update -y
        apt upgrade -y
        echo -e "${GREEN}Updating & Upgrading  completed!${END}"
        sleep 1
        first_run=0
}

#install dependencies
install_depends(){
        for d in $@
        do
        which $d &> /dev/null
                if [ $? != 0 ]
                then
                echo -e "${RED}$d is not installed, ${YELLOW}installing...${END}"
                apt install $d -y &> /dev/null
                echo -e "${GREEN}$d has installed Successfully!!${END}"
                sleep 1
                fi
        done
}


mega-install(){
	cd -P mega-packages/
	chmod +x mega_script
	chmod +x openvpn/openvpn.sh
	chmod +x squid/squid.sh
	chmod +x user_manager/user_manager.sh
	cd -P /root/mega_script/
	cp -r mega-packages /etc/mega-packages
	ln /etc/mega-packages/mega_script /bin/mega
        cd -P ../
        rm -r mega-packages/
}



initial_check
if [ $is_root == "root" ]
then
clear
echo "root permission checked!"
echo ""
sleep 2
update_vps
install_depends lsof curl iptables wget
install_iptables_persistent
download_mega_packages
mega-install
mega
else
echo "permission denied! root access required"
exit 1
fi
