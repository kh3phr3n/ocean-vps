#!/usr/local/bin/bash

# Shell options
shopt -s dotglob

# System settings
SWAPFILE="/usr/swap0"

# Dialog settings
OUTPUT=$(mktemp)
LOGFILE=$(mktemp)
BACKTITLE="FreeBSD DigitalOcean Setup"

# User settings
ROOTPASS=""
USERPASS=""
USERNAME="freebsd"
USERHOME="/usr/home/${USERNAME}"
# User dotfiles
DOTFILES=('.vimrc' '.bashrc' '.bash_logout' '.bash_profile' '.bash_aliases')
MYGITHUB="https://raw.githubusercontent.com/kh3phr3n/freebsd-ocean/master/src/dotfiles"

# Display a log file in a dialog box
# $1: file
show_log()
{
    dialog \
        --backtitle  "${BACKTITLE}" \
        --title      "Journal [*]" \
        --textbox    "$1" 24 62
}

# Don't forget passwords!
check_pass()
{
    if [ -z "${ROOTPASS}" ] || [ -z "${USERPASS}" ]
    then
        dialog \
            --backtitle "${BACKTITLE}" \
            --title     "Warning [!]" \
            --msgbox    "\nDon't forget to specify root or freebsd passwords." 8 60

        # Quit installer
        exit 0
    fi
}

# Root privileges are required
check_uid()
{
    if [ "${UID}" -ne 0 ]
    then
        dialog \
            --backtitle "${BACKTITLE}" \
            --title     "Warning [!]" \
            --msgbox    "\nRoot privileges are required for run this installer." 8 60

        # Quit installer
        exit 0
    fi
}

# Check working directory
check_dir()
{
    if [ "${PWD}" != "${USERHOME}" ]
    then
        dialog \
            --backtitle "${BACKTITLE}" \
            --title     "Warning [!]" \
            --msgbox    "\nThis installer must be run from ${USERHOME}." 8 60

        # Quit installer
        exit 0
    fi
}

# Configure NTP Timezone
set_ntp()
{
    dialog \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to configure your Timezone (NTP)?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        # Choose timezone
        tzsetup

        # Enable services?
        dialog \
            --backtitle "${BACKTITLE}" \
            --title     "Confirmation [?]" \
            --yesno     "\nDo you want to enable ntpd* services?" 8 60

        # 0 means user hit [yes] button
        if [ "$?" -eq 0 ]
        then
            sysrc ntpd_enable="YES"        &>> ${LOGFILE}
            sysrc ntpd_sync_on_start="YES" &>> ${LOGFILE}
        fi
    fi
}

# Configure basic firewall
set_ipfw()
{
    dialog \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to enable the firewall (IPFW)?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        # Enable services
        sysrc firewall_quiet="YES"   &>> ${LOGFILE}
        sysrc firewall_enable="YES"  &>> ${LOGFILE}
        sysrc firewall_logdeny="YES" &>> ${LOGFILE}

        # Basic configuration
        sysrc firewall_type="workstation"          &>> ${LOGFILE}
        sysrc firewall_allowservices="any"         &>> ${LOGFILE}
        sysrc firewall_myservices="ssh http https" &>> ${LOGFILE}

        # Denials limit log?
        dialog \
            --backtitle "${BACKTITLE}" \
            --title     "Question [?]" \
            --inputbox  "\nHow many denials per IP address you'll log?" 8 60 0 2>${OUTPUT}

        # Update /etc/sysctl.conf
        [[ "$?" -eq 0 ]] && echo "net.inet.ip.fw.verbose_limit=$(<$OUTPUT)" >> /etc/sysctl.conf
        [[ "$?" -eq 0 ]] && echo "sysctl.conf: denials limit updated to $(<$OUTPUT)" &>> ${LOGFILE}
    fi
}

# No root login
set_sshd()
{
    dialog \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to disable root login (SSHD)?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        sed -i '' '/^PermitRootLogin/s/without-password/no/' /etc/ssh/sshd_config
        [[ "$?" -eq 0 ]] && echo "sshd_config: root login disabled" &>> ${LOGFILE}
    fi
}

# Add optional swap file
set_swap()
{
    dialog \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to add an optional swap?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        # What size?
        dialog \
            --backtitle "${BACKTITLE}" \
            --title     "Question [?]" \
            --inputbox  "\nWhat size do you want to allow (M,G,T)?" 8 60 1G 2>${OUTPUT}

        if [ "$?" -eq 0 ]
        then
            # Create new swap file
            truncate -s $(<$OUTPUT) ${SWAPFILE} && chmod 0600 ${SWAPFILE}
            [[ "$?" -eq 0 ]] && echo "swap: ${SWAPFILE} file created" &>> ${LOGFILE}

            # Mount swap files
            echo "md99 none swap sw,file=${SWAPFILE},late 0 0" >> /etc/fstab
            [[ "$?" -eq 0 ]] && echo "swap: ${SWAPFILE} added to /etc/fstab" &>> ${LOGFILE}
        fi
    fi
}

# Set root and freebsd passwords
set_pass()
{
    dialog \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to update user passwords (SHA512)?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        # Update users' passwords
        chpass -p $(openssl passwd -6 ${ROOTPASS}) root        &>> ${LOGFILE}
        chpass -p $(openssl passwd -6 ${USERPASS}) ${USERNAME} &>> ${LOGFILE}
    fi
}

# Get bash configuration
set_dot()
{
    dialog \
        --backtitle "${BACKTITLE}" \
        --title     "Confirmation [?]" \
        --yesno     "\nDo you want to download custom dotfiles?" 8 60

    # 0 means user hit [yes] button
    if [ "$?" -eq 0 ]
    then
        # Delete users' dotfiles
        rm -rf /root/* && rm {.mail*,.login*,.*shrc,.profile,.viminfo,.wget-hsts}
        [[ "$?" -eq 0 ]] && echo "dotfiles: all files deleted" &>> ${LOGFILE}

        # Get dotfiles to Github
        for dotfile in "${DOTFILES[@]}"
        do
            curl -sO "${MYGITHUB}/$dotfile" && chown freebsd:freebsd $dotfile
            [[ "$?" -eq 0 ]] && echo "dotfiles: $dotfile file created" &>> ${LOGFILE}
        done
    fi
}

# Controller and program flow
main()
{
    # Run some checks
    check_pass
    check_uid
    check_dir

    # Set basic configuration
    set_ntp
    set_ipfw
    set_sshd
    set_swap
    set_pass
    set_dot

    # Display logs
    show_log ${LOGFILE}

    # Clean temporary files
    rm ${LOGFILE} ${OUTPUT}
}

# We start here!
main "@"

