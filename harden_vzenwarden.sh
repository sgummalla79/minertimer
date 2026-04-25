#!/bin/zsh

###
# One-shot hardening + repair script for vzenwarden.
# - Restores vzenwarden.sh from this repo (in case the installed copy was wiped or tampered with)
# - Locks ownership to root:wheel and removes world-write so a standard user can't edit it
# - Restarts the daemon so the change takes effect immediately
#
# Run from the repo root with: sudo ./harden_vzenwarden.sh
###

set -e

REPO_DIR="${0:A:h}"
INSTALL_DIR="/Users/Shared/.vzen_warden"
SRC_SCRIPT="${REPO_DIR}/vzenwarden.sh"
DST_SCRIPT="${INSTALL_DIR}/vzenwarden.sh"
PLIST="/Library/LaunchDaemons/com.vzen.warden_routine.plist"
LABEL="com.vzen.warden_routine"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: must be run as root. Try: sudo $0"
    exit 1
fi

if [[ ! -f "$SRC_SCRIPT" ]]; then
    echo "ERROR: source script not found at $SRC_SCRIPT"
    exit 1
fi

if [[ ! -f "$PLIST" ]]; then
    echo "ERROR: $PLIST not found. Run install_vzenwarden.sh first."
    exit 1
fi

echo "==> Restoring script from repo"
mkdir -p "$INSTALL_DIR"
cp "$SRC_SCRIPT" "$DST_SCRIPT"

echo "==> Locking ownership and permissions"
chown -R root:wheel "$INSTALL_DIR"
chmod 755 "$INSTALL_DIR"
chmod 755 "$DST_SCRIPT"

echo "==> Restarting daemon"
launchctl kickstart -k "system/${LABEL}"

echo ""
echo "==> Verification"
ls -la "$INSTALL_DIR"
echo ""
launchctl list | grep "$LABEL" || echo "WARNING: daemon not listed"

echo ""
echo "Done. Expected: vzenwarden.sh ~3.4KB, mode -rwxr-xr-x, owner root:wheel,"
echo "and a launchctl line starting with a numeric PID."
