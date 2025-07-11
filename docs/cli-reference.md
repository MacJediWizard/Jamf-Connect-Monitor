# Jamf Connect Monitor - CLI Reference

## Command Line Interface

The Jamf Connect Monitor provides a comprehensive command-line interface for management and monitoring operations.

### Main Script Location
```bash
/usr/local/bin/jamf_connect_monitor.sh
```

## Available Commands

### monitor (default)
Runs the main monitoring cycle - checks for violations and processes events.

```bash
sudo jamf_connect_monitor.sh monitor
# OR
sudo jamf_connect_monitor.sh  # monitor is default
```

**Returns:**
- Exit code 0: Monitoring completed successfully
- Exit code 1: Errors encountered during monitoring

### status
Displays current system status and configuration.

```bash
sudo jamf_connect_monitor.sh status
```

**Output Example:**
```
=== Jamf Connect Elevation Monitor Status ===
Current Admin Users:
  admin
  it_support
  
Approved Admin Users:
  admin
  it_support
  helpdesk_admin
  
Recent Violations:
  No violations recorded
```

### add-admin
Adds a user to the approved administrator list.

```bash
sudo jamf_connect_monitor.sh add-admin <username>
```

**Parameters:**
- `username` - Username to add to approved list

**Example:**
```bash
sudo jamf_connect_monitor.sh add-admin john.doe
```

### remove-admin
Removes a user from the approved administrator list.

```bash
sudo jamf_connect_monitor.sh remove-admin <username>
```

### force-check
Performs an immediate check for unauthorized admin accounts.

```bash
sudo jamf_connect_monitor.sh force-check
```

### help
Displays usage information and available commands.

```bash
jamf_connect_monitor.sh help
```

## Configuration Files

### Main Configuration
**Location:** `/usr/local/etc/jamf_connect_monitor.conf`

### Approved Administrators
**Location:** `/usr/local/etc/approved_admins.txt`
**Format:** One username per line

## Log Files

### Main Activity Log
**Location:** `/var/log/jamf_connect_monitor/monitor.log`

### Violation Log
**Location:** `/var/log/jamf_connect_monitor/admin_violations.log`

### Jamf Connect Events
**Location:** `/var/log/jamf_connect_monitor/jamf_connect_events.log`

## Extension Attribute Script

### Location
```bash
/usr/local/etc/jamf_ea_admin_violations.sh
```

### Manual Execution
```bash
sudo /usr/local/etc/jamf_ea_admin_violations.sh
```

## LaunchDaemon Management

### Daemon Location
```bash
/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
```

### Manual Control
```bash
# Load daemon
sudo launchctl load /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Unload daemon
sudo launchctl unload /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Check daemon status
sudo launchctl list | grep jamfconnectmonitor
```

## Error Codes

### Main Script Exit Codes
- **0:** Success
- **1:** General error
- **2:** Permission denied
- **3:** Configuration error
- **4:** Jamf Connect not found
- **5:** Lock file exists (already running)

---

**Created with ❤️ by MacJediWizard**
