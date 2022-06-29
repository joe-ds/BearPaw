# BearPaw
A pure PowerShell-based git backup system.

# Install
 - Install the PSM1 file as a module.
 - Edit the first three lines as desired. You'll need a repo to back up to and restore from.
 - Run `Initialize-Backup` the first time.

# Use
Run `Add-Backup <fileorfolder>` to add files and `Remove-Backup <fileorfolder>` to remove files.
Note that if a folder is given, all children will be backed up.
`Show-Backup` will list all files and folders marked for backup.
Run `Update-Backup` to backup all marked files and folders to GitHub. For automated regular backups, this command can be set as a scheduled task.

# Restoring Backups
Run the `Deploy-Backup` command to restore all backed up files. The contents of the backed up repo will have to be copied over first.

# Limitations
This is meant to be a simple script for ensuring dotfiles and the like aren't lost. There's no granular restoring of individual files (yet?!), and it's not really meant to be used to synchronise across a number of systems.
