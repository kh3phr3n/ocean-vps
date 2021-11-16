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

# Firewall whitelist
IPS="127.0.0.1/8 ::1"

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
    printf "$1:$2" | chpasswd --crypt-method=SHA512 --sha-rounds=5000 && echo "[OK] Password updated successfully: ${1}"
}

# File editing functions
# ----------------------

# /!\ Append mode
edit_pamd_sshd ()
{
cat << EOF >> /etc/pam.d/sshd

# Custom settings
# ---------------

auth required pam_google_authenticator.so
EOF
}

# /!\ Append mode
edit_sshd_config ()
{
cat << EOF >> /etc/ssh/sshd_config

# Custom settings
# ---------------

AddressFamily inet
X11Forwarding no
PermitRootLogin no
PasswordAuthentication no
EOF
}

# /!\ Append mode
edit_totp_sshd_config ()
{
cat << EOF >> /etc/ssh/sshd_config
ChallengeResponseAuthentication yes

# 2FA TOTP Users
# --------------

Match User root
    AuthenticationMethods publickey,keyboard-interactive

Match User ${USERNAME}
    AuthenticationMethods publickey,keyboard-interactive
EOF
}

# /!\ Create mode
edit_fail2ban_jail_local ()
{
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1d
maxretry = 3
findtime = 10m
banaction = ufw
ignoreip = ${IPS}

[sshd]
enabled = true

[sshd-ddos]
enabled = true

[recidive]
enabled = true
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
        --textbox    "$1" 35 75
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
    fi

    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to install utility packages (git, htop, etc...)?" 8 70

    if [ "$?" -eq 0 ]
    then
        block ":: Install additionnal utility packages"
        apt install --assume-yes --no-install-recommends git htop ranger; pause
    fi

    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to install Docker container runtime?" 8 60

    if [ "$?" -eq 0 ]
    then
        block ":: Install Docker Engine packages"
        apt install --assume-yes --no-install-recommends docker.io docker-compose; pause
    fi

    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to install NodeJS environment?" 8 60

    if [ "$?" -eq 0 ]
    then
        whiptail \
            --separate-output \
            --backtitle "${BACKTITLE}" \
            --title     "Selection [?]" \
            --radiolist "\nChoose which version to install." 20 38 11 \
                "12"      "Node.js v12.x"   OFF \
                "14"      "Node.js v14.x"   OFF \
                "16"      "Node.js v16.x"   OFF \
                "lts"     "Node.js LTS"     ON  \
                "current" "Node.js Current" OFF \
                2>${OUTPUT}

        if [ "$?" -eq 0 ] && [ ! -z "$(<$OUTPUT)" ]
        then
            block ":: Add NodeSource Binary Distribution"
            curl -fsSL https://deb.nodesource.com/setup_$(<$OUTPUT).x | bash - | sed -e "1d;$d"; pause

            block ":: Install NodeJS packages"
            apt install --assume-yes --no-install-recommends nodejs; pause
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
            useradd -m -s /bin/bash ${USERNAME} && echo "[OK] User created successfully: ${USERNAME}" &>> ${LOGFILE}
            usermod -aG $(<$OUTPUT) ${USERNAME} && echo "[OK] Groups added successfully: $(<$OUTPUT)" &>> ${LOGFILE}
            password ${USERNAME} ${USERPASS} &>> ${LOGFILE}

            # Remove user created on Scaleway
            [[ -d "/home/debian" ]] && userdel --force --remove debian &> /dev/null
        fi

        whiptail \
            --backtitle "${BACKTITLE}" \
            --title     "Confirmation [?]" \
            --yesno     "\nDo you want to download custom dotfiles?" 8 60

        if [ "$?" -eq 0 ]
        then
            block ":: Set up custom dotfiles"

            # Clean user's dotfiles
            rm {/root,${USERHOME}}/{.bash*,.profile} && echo "[OK] Original dotfiles deleted successfully" &>> ${LOGFILE}

            # Create Docker configuration
            [[ -x "/bin/docker" ]] && sudo -u ${USERNAME} \
                curl -O -# --create-dirs --output-dir ${USERHOME}/.docker "${MYGITHUB}/.docker/config.json"

            for dotfile in "${DOTFILES[@]}"
            do
                # Get dotfiles to Github
                curl -O -# "${MYGITHUB}/$dotfile"
                # Set ${USERNAME}'s dotfiles
                cp $dotfile ${USERHOME} && chown ${USERNAME}:${USERNAME} ${USERHOME}/$dotfile
                # Process seems to be OK
                [[ "$?" -eq 0 ]] && echo "[OK] Dotfile created successfully: $dotfile" &>> ${LOGFILE}
            done

            # Remove useless dotfiles for root user
            rm -f /root/{.vimrc,.gitconfig,.wget-hsts}; pause
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
        [[ "$?" -eq 0 ]] && echo "[OK] Service SSH activated successfully: ${USERNAME}" &>> ${LOGFILE}

        # Backup original configuration
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.back

        # Restrict SSHD server usage
        sed -i "/AddressFamily/{/^#/b;d}" /etc/ssh/sshd_config
        sed -i "/X11Forwarding/{/^#/b;d}" /etc/ssh/sshd_config
        sed -i "/PermitRootLogin/{/^#/b;d}" /etc/ssh/sshd_config
        sed -i "/PasswordAuthentication/{/^#/b;d}" /etc/ssh/sshd_config

        # Add custom settings
        edit_sshd_config && echo "[OK] Service SSH configured successfully" &>> ${LOGFILE}

        # Add extra layer of security
        set_totp
    fi
}

set_totp ()
{
    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to enable SSH 2FA (Two-Factor Authentication)?" 8 70

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        block ":: Install additionnal packages"
        apt install --assume-yes --no-install-recommends libpam-google-authenticator; pause

        block ":: Generate new QR code"
        sudo -u ${USERNAME} google-authenticator \
            --force --time-based --disallow-reuse --rate-time=30 --window-size=3 --rate-limit=3; pause

        # Backup original configuration
        cp /etc/pam.d/sshd /etc/pam.d/sshd.back

        # Set up PAM and SSHD
        sed -i "/@include common-auth/s/^/# &/g" /etc/pam.d/sshd
        sed -i "/ChallengeResponseAuthentication/{/^#/b;d}" /etc/ssh/sshd_config
        edit_pamd_sshd && edit_totp_sshd_config && echo "[OK] Service SSH 2FA configured successfully: ${USERNAME}" &>> ${LOGFILE}
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

        # Backup original configurations
        cp /etc/default/ufw /etc/default/ufw.back
        cp /etc/ufw/before.rules /etc/ufw/before.rules.back

        # Disable UFW IPV6 support + ping
        sed -i "/^IPV6/s/yes/no/" /etc/default/ufw && \
        sed -i "/input -p icmp --icmp-type echo/s/ACCEPT/DROP/" /etc/ufw/before.rules
        [[ "$?" -eq 0 ]] && echo "[OK] Service UFW configured successfully" &>> ${LOGFILE}

        block ":: Deny all incoming connections"
        ufw default allow outgoing && ufw default deny incoming; pause

        whiptail \
            --separate-output \
            --backtitle "${BACKTITLE}" \
            --title     "Selection [?]" \
            --checklist "\nChoose which ports to open." 20 38 11 \
                "22"    "SSH"              ON \
                "80"    "HTTP"             ON \
                "443"   "HTTPS"            ON \
                "3306"  "MySQL"            OFF \
                "5432"  "PostgreSQL"       OFF \
                "8080"  "Adminer"          OFF \
                "8083"  "MQTT"             OFF \
                "5672"  "AMQP"             OFF \
                "8081"  "Redis (Admin)"    OFF \
                "18083" "EMQX (Admin)"     OFF \
                "15672" "RabbitMQ (Admin)" OFF \
                2>${OUTPUT}

        # 0 means user hit [yes] button
        if [ "$?" -eq 0 ]
        then
            block ":: Allow UFW specific ports"

            for port in $(<$OUTPUT)
            do
                # Create new UFW rule
                ufw allow $port && echo "[OK] Port allowed successfully: $port" &>> ${LOGFILE}
                # Restrict usage on port 22
                [ "$port" == "22" ] && ufw limit $port
            done

            # We can now enable UFW!
            ufw enable && echo "[OK] Service UFW enabled successfully" &>> ${LOGFILE}; pause
        fi
    fi
}

# Security tools
set_secu ()
{
    whiptail \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to install security tools?" 8 60

    if [ "$?" -eq 0 ]
    then
        block ":: Install additionnal packages"
        apt install --assume-yes --no-install-recommends rkhunter; pause

        block ":: Rootkit Hunter system check"
        rkhunter --check; pause

        whiptail \
            --backtitle "${BACKTITLE}" \
            --title     "Confirmation [?]" \
            --yesno     "\nDo you want to install Fail2ban?" 8 60

        if [ "$?" -eq 0 ]
        then
            block ":: Install additionnal packages"
            apt install --assume-yes --no-install-recommends fail2ban

            # Add custom settings
            edit_fail2ban_jail_local && echo "[OK] Service Fail2ban configured successfully" &>> ${LOGFILE}; pause
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
    set_root
    set_user
    set_sshd
    set_wall
    set_secu

    # Clean up
    del_setup

    # Let's finish!
    restart 5
}

# We start here!
main "@"
