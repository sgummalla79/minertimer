### DEVELOPER NOTES

# TODOS/Next steps
- Maybe expand to cover other Java games?
- Better packaging for less sophisticated users?

## List of directories and their purposes
- Location of .sh script: /Users/Shared/vzenwarden
- Location of .plist: /Library/LaunchDaemons
- Location of error messages etc: std output.
- Location of timekeeping LOG_FILE: /var/lib/vzenwarden/vzenwarden_playtime.log 

## Useful commands:

# To check if script is running (good to check if it is running for other users)
- sudo launchctl list | grep com.vzen.warden_routine

# To stop script:
- sudo launchctl unload /Library/LaunchAgents/com.vzen.warden_routine.plist
