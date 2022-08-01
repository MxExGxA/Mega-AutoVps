#!/bin/bash
#Author: Elsayed Elghazy
#Date: 1 Aug 2022
#Description: this script will install and configure Custom OpenVPN passwordless Server.
#Modified: 1 Aug 2022
#---------------------------------------------------------------------------------------

OPENVPN_CONF_FILE="/etc/openvpn/server.conf"

add_iptables_rules(){
	if which iptables &> /dev/null ;then
	echo -e "${YELLOW}adding iptables rules...${END}"
	iptables -A INPUT -i eth0 -m state --state NEW -p udp --dport 1194 -j ACCEPT
	iptables -A INPUT -i tun+ -j ACCEPT

	iptables -A FORWARD -i tun+ -j ACCEPT
	iptables -A FORWARD -i tun+ -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i eth0 -o tun+ -m state --state RELATED,ESTABLISHED -j ACCEPT

	iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

	iptables -A OUTPUT -o tun+ -j ACCEPT

	iptables-save > /etc/iptables/rules.v4
	iptables-save > /etc/iptables/rules.v6
	echo -e "${GREEN}Done!${END}"
	sleep 1
	else
	apt install iptables -y &> /dev/null
	add_iptables_rules
	fi

}
change_openvpn_port(){

	echo -ne "${YELLOW}Enter Port:${END}" ; read OVPORT
	if netstat -npa | grep -w LISTEN | awk '{print $4}' | cut -d ':' -f2 |  grep -w $OVPORT &> /dev/null ;then
	echo -e "${RED}Failed!,Port $OVPORT is in use${END}"
	sleep 2
	change_openvpn_port
	else
	echo -e "${GREEN}Port $OVPORT Accepted!!${END}"
	echo $OVPORT
	sed -i "/.*port/c\port $OVPORT" $OPENVPN_CONF_FILE
	echo -e "${YELLOW}Restarting OpenVPN Service...${END}"
	service openvpn@server restart
	check_openvpn_status
	fi

}

check_openvpn_status(){
	if ! service openvpn@server status | grep "running" &> /dev/null ;then
	echo -e "${RED}OpenVPN service is not Running!!!${END}"
	else
	echo -e "${GREEN}OpenVpn service is running!${END}"
	fi
	sleep 2
	call_openvpn_menu

}

call_generate_ovpn_config(){
	cd -P /etc/mega-packages/openvpn/
	openvpn_port=$(grep -w port mega.vars | cut -d " " -f2)
	openvpn_protocol=$(grep -w protocol mega.vars | cut -d " " -f2)
	openvpn_squid_port=$(grep -w proxy_port mega.vars | cut -d " " -f2)
	openvpn_proxy_support=$(grep -w proxy_support mega.vars | cut -d " " -f2)
	openvpn_encryption=$(grep -w encryption mega.vars | cut -d " " -f2)
	generate_ovpn_config
	call_openvpn_menu

}
generate_ovpn_config(){

cd -P /etc/openvpn/client
if [ $openvpn_proxy_support == "y" ] || [ $openvpn_proxy_support == "Y" ]
then

echo "#Mega_OpenVPN_Server
client
dev tun
<connection>
remote $IP $openvpn_port $openvpn_protocol
http-proxy $IP $openvpn_squid_port
http-proxy-retry
</connection>
cipher $openvpn_encryption
auth SHA512
auth-nocache
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256
resolv-retry infinite
compress lz4
nobind
persist-key
persist-tun
mute-replay-warnings
verb 3
<key>
$(cat vpnclient.key)
</key>
<cert>
-----BEGIN CERTIFICATE-----
$(grep -z -o -P '(?<=-----BEGIN CERTIFICATE-----)(?s).*(?=-----END CERTIFICATE-----)' vpnclient.crt | tr '\0' '\n' | sed '/^[[:space:]]*$/d')
-----END CERTIFICATE-----
</cert>
<ca>
$(cat ca.crt)
</ca>" > /root/client.ovpn

else

echo "#Mega_OpenVPN_Server
client
dev tun
proto $openvpn_protocol
remote $IP $openvpn_port
cipher $openvpn_encryption
auth SHA512
auth-nocache
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256
resolv-retry infinite
compress lz4
nobind
persist-key
persist-tun
mute-replay-warnings
verb 3
<key>
$(cat vpnclient.key)
</key>
<cert>
-----BEGIN CERTIFICATE-----
$(grep -z -o -P '(?<=-----BEGIN CERTIFICATE-----)(?s).*(?=-----END CERTIFICATE-----)' vpnclient.crt | tr '\0' '\n' |  sed '/^[[:space:]]*$/d')
-----END CERTIFICATE-----
</cert>
<ca>
$(cat ca.crt)
</ca>" > /root/client.ovpn
fi

echo -e "${GREEN}Client.ovpn has been  Saved to /root/client.ovpn !!${END}"
sleep 2
}

install_openvpn(){
	show_header
	install_questions(){

		choose_port(){
			read -p "Enter OpenVPN Port: " -i 1194 -e openvpn_port
			if netstat -npa | grep -w LISTEN | awk '{print $4}' | cut -d ':' -f2 |  grep -w $openvpn_port &> /dev/null ;then
			echo -e  "${RED}Failed!,Port $openvpn_port is in use${END}"
			sleep 2
			choose_port
			else
			echo -e  "${GREEN}Port $OVPORT Accepted!!${END}"
			fi
			echo $SEP
			echo "port $openvpn_port" > /etc/mega-packages/openvpn/mega.vars

		}

		choose_protocol(){
			echo "Choose protocol:"
			echo "1-TCP"
			echo "2-UDP"
			read -p  "Enter number(1-2): " -i 1 -e openvpn_protocol
			echo $SEP


			case $openvpn_protocol in
			1)openvpn_protocol=tcp;;
			2)openvpn_protocol=udp;;
			*)echo -e "${RED}Wrong Answer!${END}" && choose_protocol;;
			esac
			echo "protocol $openvpn_protocol" >> /etc/mega-packages/openvpn/mega.vars


		}

		choose_encrypt(){

			echo "Choose Encryption Method:"
			echo "1-AES-128-CBC"
			echo "2-AES-256-CBC"
			echo "3-AES-512-CBC"
			read -p "Enter number(1-3): " -i 1 -e openvpn_encryption
			echo $SEP

			case $openvpn_encryption in
			1)openvpn_encryption=AES-128-CBC;;
			2)openvpn_encryption=AES-256-CBC;;
			3)openvpn_encryption=AES-512;;
			*)echo -e "${RED}Wrong Answer!${END}" && choose_encrypt;;
			esac

			echo "encryption $openvpn_encryption" >> /etc/mega-packages/openvpn/mega.vars

		}

		choose_dns(){
			echo -e  "Choose DNS Server:"
			echo -e  "1-Google DNS"
			echo -e  "2-CloudFlare DNS"
			echo -e  "3-Opendns DNS"
			read -p  "Enter number(1-3): " -i 1 -e  openvpn_dns
			echo $SEP

			echo "dns $openvpn_dns " >> /etc/mega-packages/openvpn/mega.vars

			case $openvpn_dns in
			1)openvpn_dns="8.8.8.8";;
			2)openvpn_dns="1.1.1.1";;
			3)openvpn_dns="208.67.222.222";;
			*)echo -e "${RED}Wrong Answer!${END}" && choose_dns;;
			esac

		}

		proxy_support(){

			read -p  "Squid Proxy Support ?(y/n): " -i y -e openvpn_proxy_support

			echo "proxy_support $openvpn_proxy_support" >> /etc/mega-packages/openvpn/mega.vars

			case $openvpn_proxy_support in
			[yY])echo -ne "Enter Squid Proxy Port: " ; read openvpn_squid_port;;
			esac

			echo "proxy_port $openvpn_squid_port" >> /etc/mega-packages/openvpn/mega.vars
			echo $SEP
		}


	choose_port
	choose_protocol
	choose_encrypt
	choose_dns
	proxy_support


	}

	install_questions

	echo -e "${YELLOW}Installing openvpn...${END}"
	sleep 1
	if apt install openvpn -y &> /dev/null ;then
	echo -e "${GREEN}Openvpn successfully installed!!${END}"
	else
	echo -e "${RED}Installation Failed!${END}"
	fi

	echo -e "${YELLOW}Installing easy-rsa...${END}"
	cd -P /etc/openvpn/
	wget https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz &> /dev/null
	tar -xvzf EasyRSA-3.0.8.tgz &> /dev/null
	mv EasyRSA-3.0.8 easy-rsa
	if [ $? == 0 ]
	then
	echo -e "${GREEN}Easyrsa successfully installed!!${END}"
	else
	echo -e "${RED}Installation Failed!${END}"
	fi
	rm -f EasyRSA-3.0.8.tgz &> /dev/null

	#configuring OPENVPN, EASYRSA
	echo -e "${YELLOW}Configurinng OpenVPN...${END}"
	sleep 1
	cd -P .
	cd -P /etc/openvpn/easy-rsa/
	echo -e "${YELLOW}setting Vars...${END}"

echo "set_var EASYRSA_REQ_COUNTRY     \"US\"
set_var EASYRSA_REQ_PROVINCE    \"CA\"
set_var EASYRSA_REQ_CITY        \"SanFrancisco\"
set_var EASYRSA_REQ_ORG         \"Fort-Funston\"
set_var EASYRSA_REQ_EMAIL       \"mail@host.domain\" " > vars

	export EASYRSA_BATCH=1
	echo -e "${YELLOW}Generating Server Config....${END}"
	./easyrsa init-pki &> /dev/null
	./easyrsa build-ca nopass &> /dev/null
	./easyrsa gen-req vpnserver nopass &> /dev/null
	./easyrsa sign-req server vpnserver &> /dev/null
	./easyrsa gen-dh &> /dev/null
	cp pki/ca.crt /etc/openvpn/server/
	cp pki/dh.pem /etc/openvpn/server/
	cp pki/private/vpnserver.key /etc/openvpn/server/
	cp pki/issued/vpnserver.crt /etc/openvpn/server/
	echo -e "${GREEN}Done !!${END}"
	sleep 1
        echo -e "${YELLOW}Generating Client Config....${END}"
	./easyrsa gen-req vpnclient nopass &> /dev/null
	./easyrsa sign-req client vpnclient &> /dev/null
	cp pki/ca.crt /etc/openvpn/client/
	cp pki/issued/vpnclient.crt /etc/openvpn/client/
	cp pki/private/vpnclient.key /etc/openvpn/client/
	echo -e "${GREEN}Done !!${END}"
	sleep 1

	cd -P /etc/openvpn/
echo "port $openvpn_port
proto $openvpn_protocol
dev tun
ca /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/vpnserver.crt
key /etc/openvpn/server/vpnserver.key
dh /etc/openvpn/server/dh.pem
server 10.8.0.0 255.255.255.0
push \"redirect-gateway def1\"

push \"dhcp-option DNS $openvpn_dns\"
duplicate-cn
cipher $openvpn_encryption
tls-version-min 1.2
tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256
auth SHA512
auth-nocache
keepalive 20 60
persist-key
persist-tun
compress lz4
daemon
user nobody
group nogroup
log-append /var/log/openvpn.log
verb 3" > server.conf

	generate_ovpn_config


	echo -e "${YELLOW}Starting OpenVPN Server...${END}"
	systemctl start openvpn@server
	systemctl enable openvpn@server


	add_iptables_rules
	check_openvpn_status


}

restart_openvpn(){
	#check if running
	if service openvpn@server status | grep running &> /dev/null ;then
	service openvpn@server restart
	echo -e "${GREEN}OpenVPN Service Restarted${END}"
	sleep 1
	call_openvpn_menu
	fi

}

uninstall_openvpn(){
	perform_uninstall(){
	cd -P /root/
	apt purge openvpn -y
	rm -rf /etc/openvpn/
	rm -rf /usr/share/easy-rsa/
	rm -rf /usr/share/doc/easy-rsa/
	rm -rf /run/openvpn/
	}
	echo -ne "${YELLOW}Are you sure?(y/n):${END}" ;  read CHOICE
	case $CHOICE in
	[yY])perform_uninstall;;
	*)call_openvpn_menu;;
	esac
	call_openvpn_menu
}

openvpn_not_installed_menu(){

	show_header

        echo -e "${BACK_CYAN}                -[OpenVpn]-                   ${END}"
	echo -e "0-Go Back"
	echo -e "1-Install Openvpn"
	echo $SEP

	echo -ne "Enter Number(0-1): " ; read CHOICE

	case $CHOICE in
	0)mega;;
	1)install_openvpn;;
	*)openvpn_not_installed_menu;;
	esac

}


openvpn_installed_menu(){

	show_header

	echo -e "${BACK_CYAN}                -[OpenVpn]-                   ${END}"
	echo 	"0-Go Back"
	echo 	"1-generate client config(/root/client.ovpn)"
	echo 	"2-Change openvpn port"
	echo 	"3-Check openvpn status"
	echo 	"4-Restart openvpn"
	echo 	"5-Uninstall openvpn"
	echo 	$SEP

	echo -ne "Enter Number(0-4): " ; read CHOICE

	case $CHOICE in
	0)mega;;
	1)call_generate_ovpn_config;;
	2)change_openvpn_port;;
	3)check_openvpn_status;;
	4)restart_openvpn;;
	5)uninstall_openvpn;;
	*)openvpn_installed_menu;;
	esac
}

call_openvpn_menu(){
	if which openvpn &> /dev/null ;then
	openvpn_installed_menu
	else
	openvpn_not_installed_menu
	fi

}

call_openvpn_menu
