#!/usr/bin/bash

# Dialog settings
OUTPUT=$(mktemp)
LOGFILE=$(mktemp)
BACKTITLE="Debian DigitalOcean Setup"

# User settings
ROOTPASS=""
USERPASS=""
USERNAME="debian"
USERHOME="/home/${USERNAME}"

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
            --msgbox    "\nDon't forget to specify root or ${USERNAME} passwords." 8 60

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

# Controller and program flow
main()
{
    # Run some checks
    check_pass
    check_uid

    # Set basic configuration

    # Display logs
    show_log ${LOGFILE}

    # Clean temporary files
    rm ${LOGFILE} ${OUTPUT}
}

# We start here!
main "@"
