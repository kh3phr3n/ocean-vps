#!/usr/bin/bash

# Environment variables
# ---------------------

# Dialog settings
OUTPUT=$(mktemp)
LOGFILE=$(mktemp)
BACKTITLE="Debian Post-installation Setup"

# User settings
ROOTPASS=""
USERPASS=""
USERNAME=""
USERHOME="/home/${USERNAME}"
USERGROUPS="sudo,systemd-journal"

# Utility functions
# -----------------

# Update user's password
# $1: username
# $2: password
password () {
    printf "$1:$2" | chpasswd --crypt-method=SHA512 --sha-rounds=5000 && echo ":: ${1}'s password updated successfully"
}

# Installer functions
# -------------------

# Display a log file in a dialog box
# $1: file
show_log()
{
    whiptail \
        --backtitle  "${BACKTITLE}" \
        --title      "Journal [*]" \
        --textbox    "$1" 24 62
}

# Don't forget environment variables!
check_env()
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
check_uid()
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

# Update package dependencies
sys_upgrade()
{
    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to upgrade package dependencies?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        # Package maintenance
        apt update && apt upgrade && apt autoremove
    fi
}

# Install package dependencies
sys_packages()
{
    whiptail \
        --separate-output \
        --backtitle "${BACKTITLE}" \
        --title     "Selection [?]" \
        --checklist "\nChoose which packages to install." 15 55 5 \
            "1" "Utils: vim htop ranger ripgrep curl" ON \
            "2" "Docker: docker.io docker-compose" ON \
            "3" "Manpages: man-db manpages" ON \
            "4" "Firewall: ufw netcat" ON \
            2>${OUTPUT}

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        for item in $(<$OUTPUT)
        do
            case $item in
                "1") apt install vim htop ranger ripgrep curl;;
                "2") apt install docker.io docker-compose;;
                "3") apt install man-db manpages;;
                "4") apt install ufw netcat;;
            esac
        done
    fi
}

# Update root password to SHA512
set_root()
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
set_user()
{
    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to create a new  user (${USERNAME})?" 8 60

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
            adduser ${USERNAME} && usermod -aG $(<$OUTPUT) ${USERNAME}
        fi
    fi
}

# Program entry-point
# -------------------

# Controller and program flow
main()
{
    clear
    # Run some checks
    check_env
    check_uid

    # System actions
    sys_upgrade
    sys_packages

    # Set basic configuration
    set_root
    set_user

    # Display logs
    show_log ${LOGFILE}

    # Clean temporary files
    rm ${LOGFILE} ${OUTPUT}

    # File auto-destruction
    shred --zero --verbose --iterations=10 --remove=wipesync ${0}
}

# We start here!
main "@"
