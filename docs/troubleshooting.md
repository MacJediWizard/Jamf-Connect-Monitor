# Troubleshooting Guide

## Common Issues

### Extension Attribute Not Populating
**Symptoms**: Empty or "Not configured" in Jamf Pro
**Solutions**:
1. Check script permissions: `ls -la /usr/local/etc/jamf_ea_admin_violations.sh`
2. Test manually: `sudo /usr/local/etc/jamf_ea_admin_violations.sh`
3. Force inventory update: `sudo jamf recon`

### Monitoring Not Running
**Symptoms**: No log entries, violations not detected
**Solutions**:
1. Check daemon status: `sudo launchctl list | grep jamfconnectmonitor`
2. Load daemon: `sudo launchctl load /Library/LaunchDaemons/com.company.jamfconnectmonitor.plist`
3. Check logs: `tail -f /var/log/jamf_connect_monitor/monitor.log`

### False Violation Alerts
**Symptoms**: Approved admins being flagged
**Solutions**:
1. Check approved list: `cat /usr/local/etc/approved_admins.txt`
2. Add user: `sudo /usr/local/bin/jamf_connect_monitor.sh add-admin username`
3. Verify admin group: `dscl . -read /Groups/admin GroupMembership`

## Log Analysis

### Key Log Locations
- Installation: `/var/log/jamf_connect_monitor_install.log`
- Activity: `/var/log/jamf_connect_monitor/monitor.log`
- Violations: `/var/log/jamf_connect_monitor/admin_violations.log`
- Daemon: `/var/log/jamf_connect_monitor/daemon.log`

### Performance Tuning
- Increase monitoring interval for large environments
- Implement log rotation for disk space management
- Consider network bandwidth for notifications
