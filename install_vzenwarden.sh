#!/bin/zsh

###
# Script to place the vzenwarden files where they belong and to give appropriate permissions etc
# The script needs to be run from an Administrator account with Administrator privileges
# Copyright Soferio Pty Ltd
###

# Step 1: Place Vzenwarden script where it belongs (and create directory if necessary)

mkdir -p /Users/Shared/.vzen_warden
cp vzenwarden.sh /Users/Shared/.vzen_warden/
chmod +x /Users/Shared/.vzen_warden/vzenwarden.sh

# Step 2: Place the PLIST file where it belongs

cp com.vzen.warden_routine.plist /Library/LaunchDaemons/
chown root:wheel /Library/LaunchDaemons/com.vzen.warden_routine.plist
chmod 644 /Library/LaunchDaemons/com.vzen.warden_routine.plist

# Step 3: Register the vzenwarden as a background task

launchctl load -w /Library/LaunchDaemons/com.vzen.warden_routine.plist

# Step 4: Post Script report
echo ""
echo "Script has been run. Assuming there are no errors, to check if the vzenwarden background process is running type the following:"
echo "sudo launchctl list | grep com.vzen.warden_routine"
echo "If you get a line of text commencing with a process number, it means the script is running."

# NOTES POST INSTALLATION

# TO STOP SCRIPT RUNNING, you use this command:
# sudo launchctl unload /Library/LaunchDaemons/com.vzen.warden_routine.plist

# TO CHECK IF SCRIPT IS RUNNING:
# sudo launchctl list | grep com.vzen.warden_routine


