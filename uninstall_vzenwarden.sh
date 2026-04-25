#!/bin/zsh

###
# Script to remove the vzenwarden files
# The script needs to be run from an Administrator account with Administrator privileges using SUDO
# Copyright Soferio Pty Ltd
###

set -u

LABEL="com.vzen.warden_routine"
PLIST="/Library/LaunchDaemons/${LABEL}.plist"
INSTALL_DIR="/Users/Shared/.vzen_warden"
LOG_DIR="/var/lib/.vzen_warden"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must be run as root. Try: sudo $0"
    exit 1
fi

# Step 1: Unregister the daemon first so it stops cleanly before its files disappear
launchctl bootout "system/${LABEL}" 2>/dev/null || true

# Step 2: Remove the plist
rm -f "$PLIST"

# Step 3: Remove the installed script and its directory
rm -f "${INSTALL_DIR}/vzenwarden.sh"
rmdir "$INSTALL_DIR" 2>/dev/null || true

# Step 4: Remove log file and its directory
rm -f "${LOG_DIR}/.vzen_warden.log"
rmdir "$LOG_DIR" 2>/dev/null || true

# Step 5: Verify
echo ""
if launchctl list | grep -q "$LABEL"; then
    echo "WARNING: ${LABEL} still appears in launchctl list — uninstall did not fully complete."
    exit 1
fi
if [[ -e "$PLIST" || -e "${INSTALL_DIR}/vzenwarden.sh" ]]; then
    echo "WARNING: leftover files remain. Check $PLIST and $INSTALL_DIR."
    exit 1
fi
echo "Uninstall complete. vzenwarden is no longer running and Minecraft is not limited."
