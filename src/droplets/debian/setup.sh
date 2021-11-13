#!/usr/bin/bash

# Environment variables
# ---------------------

# Root settings
ROOTPASS=""

# User settings
USERNAME=""
USERPASS=""
USERHOME="/home/${USERNAME}"
USERGROUPS="sudo,systemd-journal"

# Dialog settings
OUTPUT=$(mktemp)
LOGFILE=$(mktemp)
BACKTITLE="Tekin Server Installer"

# User dotfiles
MYGITHUB="https://raw.githubusercontent.com/kh3phr3n/ocean-vps/master/src/dotfiles"
DOTFILES=('.vimrc' '.gitconfig' '.bashrc' '.bash_logout' '.bash_profile' '.bash_aliases')

# Utility functions
# -----------------

# Initialize colors
init_colors ()
{
    PURPLE='\e[0;35m'
    YELLOW='\e[1;33m'
    GREEN='\e[0;32m'
    CYAN='\e[0;36m'
    BLUE='\e[1;34m'
    RED='\e[0;31m'
    OFF='\e[0m'
}

block () {
    clear; echo -e "${BLUE}$1\n${OFF}"
}

pause () {
    echo -e "${YELLOW}\n:: Press any key to continue...${OFF}"; read
}

# Reboot machine
# $1: shutdown seconds
restart () {
    block ":: Reboot Debian system"

    for (( i=$1 ; i>0 ; i-- ))
    do
        echo -n "$i " && sleep 1
    done; reboot
}

# Update user's password
# $1: username
# $2: password
password () {
    printf "$1:$2" | chpasswd --crypt-method=SHA512 --sha-rounds=5000 && echo ":: ${1}'s password updated successfully"
}

# File editing functions
# ----------------------

# /!\ Append mode
edit_sshd_config ()
{
cat << EOF >> /etc/ssh/sshd_config

# Custom settings
# ---------------

X11Forwarding no
PermitRootLogin no
PasswordAuthentication no
EOF
}

# Installer functions
# -------------------

# Display a log file in a dialog box
# $1: file
show_log ()
{
    whiptail \
        --backtitle  "${BACKTITLE}" \
        --title      "Journal [*]" \
        --textbox    "$1" 25 85
}

# Don't forget environment variables!
check_env ()
{
    if [ -z "${ROOTPASS}" ] || [ -z "${USERPASS}" ] || [ -z "${USERNAME}" ] || [ $(pwd) != "/root" ]
    then
        whiptail \
            --backtitle "${BACKTITLE}" \
            --title     "Warning [!]" \
            --msgbox    "\nDon't forget to set env variables and run this script from /root directory." 8 85

        # Quit installer
        exit 0
    fi
}

# Root privileges are required
check_uid ()
{
    if [ "${UID}" -ne 0 ]
    then
        whiptail \
            --backtitle "${BACKTITLE}" \
            --title     "Warning [!]" \
            --msgbox    "\nRoot privileges are required for run this installer." 8 60

        # Quit installer
        exit 0
    fi
}

# Update and install package dependencies
set_pkgs ()
{
    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to upgrade package dependencies?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        block ":: Synchronize and upgrade packages"
        apt update && apt upgrade --assume-yes && apt autoremove; pause

        block ":: Install additionnal packages"
        apt install --assume-yes --no-install-recommends curl htop ranger; pause

        whiptail \
            --backtitle "${BACKTITLE}" \
            --title     "Confirmation [?]" \
            --yesno     "\nDo you want to install Docker container runtime?" 8 60

        if [ "$?" -eq 0 ]
        then
            block ":: Install Docker Engine packages"
            apt install --assume-yes --no-install-recommends docker.io docker-compose; pause
        fi
    fi
}

# Update root password to SHA512
set_root ()
{
    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to upgrade root's password?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        password root ${ROOTPASS} &>> ${LOGFILE}
    fi
}

# Update root password to SHA512
set_user ()
{
    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to create a new user (${USERNAME})?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        whiptail \
            --backtitle "${BACKTITLE}" \
            --title     "Question [?]" \
            --inputbox  "\nEnter user groups separated by commas" 8 60 ${USERGROUPS} \
            2>${OUTPUT}

        if [ "$?" -eq 0 ]
        then
            # Create user/groups and define password
            useradd -m -s /bin/bash ${USERNAME} && echo ":: ${USERNAME} user created successfully." &>> ${LOGFILE}
            usermod -aG $(<$OUTPUT) ${USERNAME} && echo ":: $(<$OUTPUT) groups added successfully." &>> ${LOGFILE}
            password ${USERNAME} ${USERPASS} &>> ${LOGFILE}
        fi

        whiptail \
            --backtitle "${BACKTITLE}" \
            --title     "Confirmation [?]" \
            --yesno     "\nDo you want to download custom dotfiles?" 8 60

        if [ "$?" -eq 0 ]
        then
            block ":: Set up custom dotfiles"

            # Clean user's dotfiles
            rm {/root,${USERHOME}}/{.bash*,.profile} && echo ":: user's dotfiles deleted successfully." &>> ${LOGFILE}

            for dotfile in "${DOTFILES[@]}"
            do
                # Get dotfiles to Github
                curl -O -# "${MYGITHUB}/$dotfile"
                # Set ${USERNAME}'s dotfiles
                cp $dotfile ${USERHOME} && chown ${USERNAME}:${USERNAME} ${USERHOME}/$dotfile
                # Process seems to be OK
                [[ "$?" -eq 0 ]] && echo ":: $dotfile file created successfully." &>> ${LOGFILE}
            done; pause
        fi
    fi
}

# Configure user's key and SSHD server
set_sshd ()
{
    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to configure SSH connection?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        # Copy SSH authorized key for ${USERNAME}
        mv .ssh ${USERHOME} && chown -R ${USERNAME}:${USERNAME} ${USERHOME}/.ssh
        [[ "$?" -eq 0 ]] && echo ":: ${USERNAME}'s ssh configured successfully." &>> ${LOGFILE}

        # Backup original configuration
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.back

        # Restrict SSHD server usage
        sed -i "/X11Forwarding/d" /etc/ssh/sshd_config
        sed -i "/PermitRootLogin/d" /etc/ssh/sshd_config
        sed -i "/PasswordAuthentication/d" /etc/ssh/sshd_config

        # Add custom settings
        edit_sshd_config && echo ":: sshd_config file edited successfully." &>> ${LOGFILE}
    fi
}

# Configure firewall (UFW)
set_wall ()
{
    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to enable Uncomplicated Firewall (UFW)?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        block ":: Install additionnal packages"
        apt install --assume-yes --no-install-recommends ufw netcat; pause

        # Disable UFW IPV6 support
        cp /etc/default/ufw /etc/default/ufw.back && sed -i "/^IPV6/s/yes/no/" /etc/default/ufw
        [[ "$?" -eq 0 ]] && echo ":: ufw IPV6 support disabled successfully." &>> ${LOGFILE}

        block ":: Deny all incoming connections"
        ufw default allow outgoing && ufw default deny incoming; pause

        whiptail \
            --separate-output \
            --backtitle "${BACKTITLE}" \
            --title     "Selection [?]" \
            --checklist "\nChoose which ports to open." 20 38 11 \
                "22"    "SSH" ON \
                "80"    "HTTP" ON \
                "443"   "HTTPS" ON \
                "3306"  "MySQL" OFF \
                "5432"  "PostgreSQL" OFF \
                "8080"  "Adminer" OFF \
                "8083"  "MQTT" OFF \
                "5672"  "AMQP" OFF \
                "8081"  "Redis (Admin)" OFF \
                "18083" "EMQX (Admin)" OFF \
                "15672" "RabbitMQ (Admin)" OFF \
                2>${OUTPUT}

        # 0 means user hit [yes] button
        if [ "$?" -eq 0 ]
        then
            block ":: Allow UFW specific ports"

            for port in $(<$OUTPUT)
            do
                # Create new UFW rule
                ufw allow $port && echo ":: port $port opened successfully." &>> ${LOGFILE}
                # Restrict usage on port 22
                [ "$port" == "22" ] && ufw limit $port
            done

            # We can now enable UFW!
            ufw enable && echo ":: ufw enabled successfully." &>> ${LOGFILE}; pause
        fi
    fi
}

del_setup ()
{
    # Display logs
    show_log ${LOGFILE}

    block ":: Clean up setup environment"

    # Clean all files
    rm ${LOGFILE} ${OUTPUT} && shred --zero --verbose --iterations=10 --remove=wipesync ${0}; pause
}

# Program entrypoint
# ------------------

# Controller and program flow
main ()
{
    clear
    # Initialization
    init_colors

    # Run some checks
    check_env
    check_uid

    # System actions
    set_pkgs

    # Set basic confs
    set_root
    set_user
    set_sshd
    set_wall

    # Clean up
    del_setup

    # Let's finish!
    restart 5
}

# We start here!
main "@"
