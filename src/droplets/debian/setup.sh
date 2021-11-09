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

# Installer functions
# -------------------

# Display a log file in a dialog box
# $1: file
show_log()
{
    dialog \
        --backtitle  "${BACKTITLE}" \
        --title      "Journal [*]" \
        --textbox    "$1" 24 62
}

# Don't forget environment variables!
check_env()
{
    if [ -z "${ROOTPASS}" ] || [ -z "${USERPASS}" ] || [ -z "${USERNAME}" ]
    then
        dialog \
            --backtitle "${BACKTITLE}" \
            --title     "Warning [!]" \
            --msgbox    "\nDon't forget to specify environment variables." 8 60

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

# Program entry-point
# -------------------

# Controller and program flow
main()
{
    # Run some checks
    check_env
    check_uid

    # Set basic configuration

    # Display logs
    show_log ${LOGFILE}

    # Clean temporary files
    rm ${LOGFILE} ${OUTPUT}
}

# We start here!
main "@"
