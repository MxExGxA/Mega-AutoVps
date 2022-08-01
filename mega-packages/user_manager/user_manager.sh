#!/bin/bash
#Author: Elsayed Elghazy
#Date: 1 Aug 2022
#Description: this script will add/remove System users 
#Modified: 1 Aug 2022
#---------------------------------------------------------------------------------------


add_user(){
	echo -ne "${YELLOW}Enter Username to create: ${END}" ; read username

#check if user is already exists
	if cat /etc/passwd | awk '{print $1}' | grep -w $username &> /dev/null ;then
	#user already exists
	echo -e "${RED}The User $usermame is Already exists!${END}"
	else
	echo -ne "${YELLOW}Enter Password: ${END}" ; read password
	useradd $username -p $password
	echo -e "${GREEN}User $username Created Successfully!${END}"
	fi
	sleep 2
	user_manager_menu

}

remove_user(){
	USERS=`cat /etc/passwd | egrep "/bin/bash|/bin/sh" | cut -d ':' -f1`
	echo -e "$USERS"
	echo -ne "${YELLOW}Enter Username remove: ${END}" ; read username
	if userdel $username &> /dev/null ;then
	echo -e "${GREEN}User $username has been deleted Successfully!${END}"
	else
	echo -e "${RED}Could not Delete User $username${END}"
	fi
	sleep 2
	user_manager_menu

}


view_all_users(){
	USERS=`cat /etc/passwd | egrep "/bin/bash|/bin/sh" | cut -d ':' -f1`
	for u in $USERS
	do
		if [ $u == $CURRENT_USER ]
		then
		echo -e "${BACK_GREEN}$u${END}"
		else
		echo -e "$u"
		fi
	done
	echo 4
	sleep 0.5
	echo 3
	sleep 0.5
	echo 2
	sleep 0.5
	echo 1
	sleep 0.5
	user_manager_menu
}




user_manager_menu(){
	show_header
        echo -e "${BACK_CYAN}              -[User Manager]-                ${END}"
	echo -e "0-Go Back"
	echo -e "1-View All Users"
	echo -e	"2-Add User"
	echo -e "3-Remove User"
	echo $SEP
	echo -ne "Enter Number(0-3):"; read CHOICE

	case $CHOICE in
	0)mega;;
	1)view_all_users;;
	2)add_user;;
	3)remove_user;;
	*)user_manager_menu;;
	esac


}



user_manager_menu
