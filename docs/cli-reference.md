<p align="center">
  <img src="../JamfConnectMonitor-815x1024.png" alt="Jamf Connect Monitor Logo" width="200">
</p>

# Jamf Connect Monitor v2.4.0 - CLI Reference

## Command Line Interface

The Jamf Connect Monitor provides a comprehensive command-line interface for management, monitoring operations, and elevation tracking.

### Main Script Location
```bash
/usr/local/bin/jamf_connect_monitor.sh
```

## Available Commands

### monitor (default)
Runs the main monitoring cycle - checks for violations, processes elevation events, and tracks legitimate elevations.

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
=== Jamf Connect Elevation Monitor Status (v2.4.0) ===
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

### elevation-report
Displays comprehensive legitimate elevation statistics and history.

```bash
sudo jamf_connect_monitor.sh elevation-report
```

**Output Example:**
```
=== Legitimate Elevation Report ===

Total Elevations: 15 | Today: 3 | Unique Users: 5 | Top Reasons: [8] software update; [4] printer driver; [3] testing;

Recent Legitimate Elevations:
  2025-08-09 10:15:23 | LEGITIMATE_ELEVATION | john.doe | software update | MAC001
  2025-08-09 09:45:12 | LEGITIMATE_DEMOTION | jane.smith | Duration: 15m

Current Elevation Statistics:
  Total Elevations: 15
  Today's Elevations: 3

Top Users (by elevation count):
  john.doe: 8 elevations
  jane.smith: 4 elevations
  bob.jones: 3 elevations
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

### test-config
Tests Configuration Profile integration and displays all current settings.

```bash
sudo jamf_connect_monitor.sh test-config
```

**Output Example:**
```
=== Configuration Profile Test ===
Profile Status: Deployed

Notification Settings:
  Webhook: Configured
  Email: security@company.com
  SMTP Provider: gmail
  SMTP Server: smtp.gmail.com:587
  SMTP Auth: Configured (user@gmail.com)
  From Address: notifications@company.com
  Template: detailed
  Cooldown: 15 minutes

Monitoring Behavior:
  Mode: realtime
  Auto Remediation: true
  Grace Period: 5 minutes
  Jamf Connect Only: true
```

### test-email
Sends a test email to verify SMTP configuration and delivery.

```bash
sudo jamf_connect_monitor.sh test-email [recipient@domain.com]
```

**Parameters:**
- `recipient@domain.com` (optional) - Override default email recipient

**Example:**
```bash
# Test with configured recipient
sudo jamf_connect_monitor.sh test-email

# Test with specific recipient  
sudo jamf_connect_monitor.sh test-email admin@company.com
```

### test-webhook
Sends a test webhook notification to verify Slack/Teams integration.

```bash
sudo jamf_connect_monitor.sh test-webhook
```

**Output Example:**
```
Testing webhook notification...
Platform: teams
URL: https://outlook.office.com/webhook/...
Template: detailed

✅ Test webhook sent successfully!
Check your Teams channel for the test message.
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

### Check Daemon Status
```bash
# Method 1: Using monitor script (recommended)
sudo /usr/local/bin/jamf_connect_monitor.sh status

# Method 2: Check LaunchDaemon registration
sudo launchctl list | grep jamfconnectmonitor
# Output: PID Status Label
# Example: 56024  0  com.macjediwizard.jamfconnectmonitor

# Method 3: Check running processes
ps aux | grep jamf_connect_monitor | grep -v grep
# Should show 1-2 monitor processes if running

# Method 4: Check recent activity
tail -n 10 /var/log/jamf_connect_monitor/monitor.log
```

### Manual Control
```bash
# Load daemon
sudo launchctl load /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Unload daemon
sudo launchctl unload /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Restart daemon
sudo launchctl unload /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
sleep 2
sudo launchctl load /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
```

## Log Files

### Log Locations
All logs are stored in `/var/log/jamf_connect_monitor/`

| Log File | Purpose | New in v2.4.0 |
|----------|---------|---------------|
| `monitor.log` | Main monitoring activity log | |
| `admin_violations.log` | Detailed violation reports | |
| `elevation_history.log` | All elevation events with reasons | Enhanced |
| `legitimate_elevations.log` | Audit trail of authorized elevations | ✅ New |
| `elevation_statistics.json` | Elevation analytics data | ✅ New |
| `.stats_*` | Statistics counter files | ✅ New |
| `.current_elevation_*` | Active elevation tracking | ✅ New |
| `daemon.log` | LaunchDaemon output | |
| `daemon_error.log` | LaunchDaemon errors | |

### New Elevation Tracking Logs (v2.4.0)

#### legitimate_elevations.log
Comprehensive audit trail of all legitimate Jamf Connect elevations:
```
2025-08-09 10:15:23.123 | LEGITIMATE_ELEVATION | john.doe | software update | MAC001
2025-08-09 10:30:45.456 | LEGITIMATE_DEMOTION | john.doe | Duration: 15m 22s
```

#### elevation_history.log
Complete elevation lifecycle tracking:
```
2025-08-09 10:15:23.123 | ELEVATED | john.doe | Awaiting reason...
2025-08-09 10:15:23.125 | REASON | john.doe | software update
2025-08-09 10:30:45.456 | DEMOTED | john.doe | Duration: 15m 22s
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
