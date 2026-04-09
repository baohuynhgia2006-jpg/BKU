#!/bin/bash

ACTION=$1

if [[ $ACTION = "--install" ]]
    then
    echo "Checking dependencies..."
    if ! command -v grep >/dev/null 2>&1 ; then sudo apt-get install grep || { echo "Error: Failed to install packages. Please check your package manager or install them manually." ; exit 1 ; }
    fi
    if ! command -v diff >/dev/null 2>&1 ; then sudo apt-get install diff || { echo "Error: Failed to install packages. Please check your package manager or install them manually." ; exit 1 ; }
    fi
    if ! command -v patch >/dev/null 2>&1 ; then sudo apt-get install patch || { echo "Error: Failed to install packages. Please check your package manager or install them manually." ; exit 1 ; }
    fi
    if ! command -v cron >/dev/null 2>&1 ; then sudo apt-get install cron || { echo "Error: Failed to install packages. Please check your package manager or install them manually." ; exit 1 ; }
    fi
    echo "All dependencies installed."
    sudo cp bku.sh /usr/local/bin/bku
    sudo chmod +rx /usr/local/bin/bku
    echo "BKU installed to /usr/local/bin/bku."
elif [[ $ACTION = "--uninstall" ]]
    then
    echo "Checking BKU installation..."
    if [ ! -f /usr/local/bin/bku ]
        then echo "BKU not installed in /usr/local/bin/bku. Nothing to uninstall."
    else
        echo "Removing BKU from /usr/local/bin/bku..."
        sudo rm -rf /usr/local/bin/bku
        echo "Removing scheduled backups..."
        crontab -u $(whoami) -l | grep -v "bash /usr/local/bin/bku" | crontab -u $(whoami) -
        echo "BKU successfully uninstalled."
    fi
fi
