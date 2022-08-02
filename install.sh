#!/bin/bash

initial_check(){

	is_root=`whoami`

}

install_iptables_persistent(){

        echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
        echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
        apt-get -y install iptables-persistent

}

install_other_depends(){

        apt install net-tools -y

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
        cd -P ../
	mv mega-packages/ /etc/mega-packages
	ln /etc/mega-packages/mega_script /bin/mega
	clear
	echo "Installation Complete, Type (mega) then press Enter to Run Mega-AutoScript."
	cd -P ../
	rm -rf Mega-AutoVps/
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
install_other_depends
mega-install
else
echo "permission denied! root access required"
exit 1
fi
