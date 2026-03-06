#!/bin/zsh

###
# Script to remove the vzenwarden files 
# The script needs to be run from an Administrator account with Administrator privileges using SUDO
# Copyright Soferio Pty Ltd
###

# Step 1: Remove Vzenwarden script w

rm /Users/Shared/.vzen_warden/vzenwarden.sh
rmdir /Users/Shared/.vzen_warden

# Step 2: Remove PLIST file 

rm /Library/LaunchDaemons/com.vzen.warden_routine.plist

# Step 3: Unregister the vzenwarden as a background task

launchctl bootout system/com.vzen.warden_routine

# Step 4: Remove log file
rm /var/lib/.vzen_warden/.vzen_warden.log
rmdir /var/lib/.vzen_warden

# Step 5: Report
echo ""
echo "Script has been run. Assuming there are no errors, to check if the vzenwarden background process is running type the following:"
echo "sudo launchctl list | grep com.vzen.warden_routine"
echo "If you get nothing, it means the background process is no longer running and minecraft is not limited."




# TO CHECK IF SCRIPT IS RUNNING:
# sudo launchctl list | grep soferio

