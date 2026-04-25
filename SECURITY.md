# Security & Hardening Notes

This document captures the threat model, defense layers, verification tests, and residual risks for vzenwarden / MinerTimer. Goal: a **standard (non-admin) user on the same Mac cannot disable, kill, or tamper with the timer**.

Last verified: 2026-04-25 on macOS 26.4 (Apple Silicon M4).

---

## Threat model

**In scope:**
- A logged-in standard (non-admin) user attempting to stop, edit, kill, or remove the timer using only their own account, with no admin password.

**Out of scope:**
- Anyone who knows an admin password.
- Physical attacks (disk removal, swapping the SSD).
- Detection-bypass attacks where the kid runs Minecraft under a different process name. See [Residual risks](#residual-risks).

---

## Defense layers

1. **POSIX file permissions.** The script, plist, and log file are all `root:wheel`. The install directory `/Users/Shared/.vzen_warden/` is mode 755. A non-root user cannot write, delete, or replace any of them.
2. **System-domain LaunchDaemon (not LaunchAgent).** The daemon lives in `/Library/LaunchDaemons/` and runs as root. Stopping it requires root via `launchctl bootout`/`unload`/`disable`. User-domain `launchctl` operations cannot affect it.
3. **Sticky bit on `/Users/Shared`.** `/Users/Shared` is mode 1777. The sticky bit (`t`) means a non-owner cannot rename or delete subdirs they don't own — so the kid cannot `mv` or `rmdir` the install directory even though `/Users/Shared` itself is world-writable.
4. **FileVault.** Disk is encrypted at rest. Booting from external media or attaching the disk to another Mac yields an unreadable volume without the FileVault password.
5. **Apple Silicon Recovery gating.** Entering macOS Recovery on Apple Silicon requires a local **admin** password. Without an admin password, Recovery, Reduced Security mode, and external boot are unreachable.
6. **System Integrity Protection (SIP).** Enabled by default. Disabling SIP itself requires Recovery, which is gated above.

---

## What's locked down (current install state)

| Path | Owner | Mode | Notes |
|---|---|---|---|
| `/Library/LaunchDaemons/com.vzen.warden_routine.plist` | `root:wheel` | `644` | Daemon definition |
| `/Users/Shared/.vzen_warden/` | `root:wheel` | `755` | Install dir |
| `/Users/Shared/.vzen_warden/vzenwarden.sh` | `root:wheel` | `755` | The script |
| `/var/lib/.vzen_warden/` | `root:wheel` | `755` | Log dir |
| `/var/lib/.vzen_warden/.vzen_warden.log` | `root:wheel` | `644` | Daily playtime counter |

The daemon runs as **root** (verified via `ps -axo user,pid,command | grep vzen`).

---

## Verification tests (2026-04-25)

24 attack attempts run as a non-root user. **All blocked.** Each test was followed by re-checking the daemon PID and file state to confirm no effect.

### Filesystem tampering

| # | Attack | Result |
|---|---|---|
| A1 | Overwrite `/Library/LaunchDaemons/com.vzen.warden_routine.plist` | `permission denied` |
| A2 | Overwrite `/Users/Shared/.vzen_warden/vzenwarden.sh` | `permission denied` |
| A3 | Delete the script | `permission denied` |
| A4 | `mv /Users/Shared/.vzen_warden /tmp/` (sticky-bit test) | `permission denied` |
| A5 | Create new file inside install dir | `permission denied` |
| A6 | `rmdir` the install dir | `permission denied` |
| A7 | Tamper with the log file (rewind the counter) | `permission denied` |

### Process and launchd control

| # | Attack | Result |
|---|---|---|
| B1 | `kill <pid>` | `operation not permitted` |
| B2 | `kill -9 <pid>` | `operation not permitted` |
| B3 | `launchctl bootout system/com.vzen.warden_routine` | `Operation not permitted` |
| B4 | `launchctl unload …LaunchDaemons/…plist` | `Input/output error` (no effect) |
| B5 | `launchctl kill SIGKILL system/com.vzen.warden_routine` | `Not privileged to signal service` |
| B6 | `launchctl disable system/com.vzen.warden_routine` | `Operation not permitted` |
| B7 | `launchctl stop com.vzen.warden_routine` | exit 3, no effect |

### Domain hijack / indirect attacks

| # | Attack | Result |
|---|---|---|
| C1 | Drop a same-label LaunchAgent in the user domain | Loaded in user domain, **system daemon untouched** (PIDs in different domains are independent) |
| C2 | Per-user `~/Library/LaunchDaemons` | Not a thing on macOS — only LaunchAgents are user-scoped |
| C3 | PATH override | Not applicable — plist hardcodes the absolute script path |
| C4 | Symlink replacement on `/var/lib/.vzen_warden` | `permission denied` |
| C5 | Crontab / `/etc/periodic` / `/etc/rc.*` hooks | All require root |

---

## How to re-verify hardening

Run as a non-admin (no `sudo`):

```sh
# Should ALL fail with permission denied / operation not permitted:
echo x > /Library/LaunchDaemons/com.vzen.warden_routine.plist
echo x > /Users/Shared/.vzen_warden/vzenwarden.sh
rm /Users/Shared/.vzen_warden/vzenwarden.sh
launchctl bootout system/com.vzen.warden_routine
kill $(pgrep -f vzenwarden.sh)

# Should show daemon still running as root:
ps -axo user,pid,command | grep vzenwarden | grep -v grep
launchctl list | grep com.vzen.warden_routine
```

If any tampering command succeeds, re-run [harden_vzenwarden.sh](harden_vzenwarden.sh):

```sh
sudo ./harden_vzenwarden.sh
```

---

## Residual risks

### 1. Admin password compromise (operational, highest real-world risk)
If the kid learns an admin password, every defense above is bypassed. Mitigations:
- Don't reuse the admin password elsewhere.
- Never enter it where the kid can see (shoulder-surfing).
- Don't store it in their account's Keychain or shared notes.
- Consider a dedicated admin account used only for admin actions, with no auto-login and no Touch ID enrolled for the kid's fingerprint.

### 2. Detection bypass (different problem from "disable")
The script at [vzenwarden.sh:44](vzenwarden.sh#L44) greps `ps aux` for the literal word `Minecraft`. The timer keeps running, but Minecraft is never killed if it doesn't show up in `ps`. Known bypasses:
- Renaming `Minecraft.app` so the bundle path no longer contains "Minecraft".
- Alternate launchers (Prism Launcher, MultiMC, TLauncher) that may invoke Java with argv that doesn't contain "Minecraft".
- **Minecraft Bedrock Edition** — script is Java-only by design.
- Browser-based Minecraft Classic (`classic.minecraft.net`) — no local process.

Mitigations to consider: match `java` processes that load Minecraft `.jar` files, or replace this script with macOS **Screen Time** per-app limits (Apple-supported, harder to bypass, covers Bedrock).

### 3. Physical attack
Removing the SSD or disassembling the Mac. Apple Silicon + FileVault makes this very hard, but it's not zero.

### 4. Reboot / state reset
Confirmed not exploitable. The log persists across reboots (root-owned in `/var/lib`); the kid cannot delete or rewind it.

### 5. Time manipulation
Standard users cannot change the system clock on macOS without admin. Confirmed not exploitable.

---

## Hardening history

- **2026-04-25:** Discovered installed `vzenwarden.sh` had been wiped to 0 bytes and was world-writable (mode 777). Root cause: original [install_vzenwarden.sh](install_vzenwarden.sh) didn't `chown` or restrict perms after copy, leaving the script writable by any user — a privilege escalation since the daemon runs as root.
  - Fixed `install_vzenwarden.sh` to `chown -R root:wheel` and `chmod 755` the install dir and script.
  - Added [harden_vzenwarden.sh](harden_vzenwarden.sh) for one-shot repair of existing installs.
  - Tightened [uninstall_vzenwarden.sh](uninstall_vzenwarden.sh): root check, correct teardown order (`bootout` before file removal), tolerance for missing files, and verification at the end.
  - Ran the 24-attack battery above; all blocked.
