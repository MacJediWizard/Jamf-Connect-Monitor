# Configuration Guide v2.4.0

## Overview
Jamf Connect Monitor v2.4.0 provides multiple configuration methods, with Configuration Profile being the recommended approach for enterprise deployments.

## Configuration Methods

### 1. Configuration Profile (Recommended)
Deploy centralized settings via Jamf Pro Configuration Profile using the provided JSON schema.

### 2. Script Parameters
Configure via Jamf Pro policy parameters during deployment.

### 3. Local Configuration
Direct configuration via script variables or local files.

## Configuration Profile Settings

### Notification Settings

#### WebhookType
- **Type:** String
- **Options:** `slack`, `teams`, `generic`
- **Description:** Select the webhook platform for notifications
- **Default:** `slack`

#### WebhookURL
- **Type:** String
- **Description:** Full webhook URL for your notification platform
- **Example:** `https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXX`

#### EmailRecipient
- **Type:** String
- **Description:** Email address for security notifications
- **Example:** `security@yourcompany.com`

#### SMTPProvider
- **Type:** String
- **Options:** `office365`, `gmail`, `generic`, `macos`
- **Description:** SMTP provider type for email configuration
- **Default:** `macos`

#### SMTPServer
- **Type:** String
- **Description:** SMTP server address
- **Examples:**
  - Office 365: `smtp.office365.com`
  - Gmail: `smtp.gmail.com`

#### SMTPPort
- **Type:** Integer
- **Description:** SMTP port number
- **Default:** 587 (TLS)
- **Options:** 25, 465 (SSL), 587 (TLS), 2525

#### SMTPUsername
- **Type:** String
- **Description:** SMTP authentication username
- **Note:** Required for authenticated SMTP

#### SMTPPassword
- **Type:** String
- **Description:** SMTP authentication password
- **Note:** Stored securely in Configuration Profile

### Monitoring Settings

#### MonitoringMode
- **Type:** String
- **Options:** `periodic`, `realtime`, `hybrid`
- **Description:** Monitoring mode selection
- **Default:** `periodic`
  - `periodic`: Check every 5 minutes
  - `realtime`: Continuous monitoring
  - `hybrid`: Both periodic and realtime

#### MonitorJamfConnectOnly
- **Type:** Boolean
- **Description:** Only monitor when Jamf Connect elevation events occur
- **Default:** `false`
- **Note:** When true, monitoring is event-driven based on Jamf Connect activity

#### CheckInterval
- **Type:** Integer
- **Description:** Monitoring interval in seconds (periodic mode)
- **Default:** 300 (5 minutes)
- **Range:** 60-3600

#### LogLevel
- **Type:** String
- **Options:** `INFO`, `WARNING`, `ERROR`, `DEBUG`
- **Description:** Logging verbosity level
- **Default:** `INFO`

### Company Settings

#### CompanyName
- **Type:** String
- **Description:** Your organization name for notifications
- **Example:** `Acme Corporation`
- **Note:** Used in email subjects and webhook messages

### Action Settings

#### RemoveAdminPrivileges
- **Type:** Boolean
- **Description:** Automatically remove unauthorized admin privileges (removes from admin group only, does NOT delete user)
- **Default:** `false`
- **Warning:** Test thoroughly before enabling in production
- **Behavior:** 
  - Removes user from admin group
  - Preserves user account and all data
  - Maintains audit trail for forensics
  - Does NOT delete or disable user account
  - See [Forensics Guide](forensics-guide.md) for investigation procedures

#### UpdateJamfInventory
- **Type:** Boolean
- **Description:** Update Jamf Pro inventory after violations
- **Default:** `true`

#### TriggerPolicyID
- **Type:** String
- **Description:** Jamf Pro policy ID to trigger on violations
- **Example:** `42`
- **Note:** Leave empty to disable

## Approved Administrators Configuration

### File Location
`/usr/local/etc/approved_admins.txt`

### Format
```
# One username per line
admin
it_support
helpdesk_admin
```

### Management Commands
```bash
# Add approved admin
sudo jamf_connect_monitor.sh add-admin username

# Remove approved admin
sudo jamf_connect_monitor.sh remove-admin username

# View current list
cat /usr/local/etc/approved_admins.txt
```

## Log Files Configuration

### Log Directory
`/var/log/jamf_connect_monitor/`

### Log Files
- **monitor.log** - Main monitoring activity
- **admin_violations.log** - Unauthorized admin detections
- **legitimate_elevations.log** - Jamf Connect elevation tracking
- **elevation_statistics.json** - Elevation analytics data
- **daemon.log** - LaunchDaemon execution logs
- **realtime_monitor.log** - Real-time monitoring events
- **jamf_connect_events.log** - Jamf Connect integration logs

### Log Rotation
Logs are automatically rotated when reaching 100MB or 30 days old.

## Environment-Specific Configuration

### Development/Testing
```json
{
  "MonitoringMode": "periodic",
  "CheckInterval": 60,
  "LogLevel": "DEBUG",
  "RemoveAdminPrivileges": false,
  "EmailRecipient": "test@company.com"
}
```

### Production
```json
{
  "MonitoringMode": "hybrid",
  "CheckInterval": 300,
  "LogLevel": "INFO",
  "RemoveAdminPrivileges": true,
  "UpdateJamfInventory": true,
  "WebhookURL": "https://hooks.slack.com/services/...",
  "EmailRecipient": "security@company.com"
}
```

### High-Security
```json
{
  "MonitoringMode": "realtime",
  "MonitorJamfConnectOnly": false,
  "RemoveAdminPrivileges": true,
  "UpdateJamfInventory": true,
  "TriggerPolicyID": "42",
  "LogLevel": "WARNING"
}
```

## Testing Configuration

### Verify Settings
```bash
# Test configuration profile parsing
sudo jamf_connect_monitor.sh test-config

# Test email configuration
sudo jamf_connect_monitor.sh test-email

# Test webhook configuration
sudo jamf_connect_monitor.sh test-webhook
```

### Expected Output
```
=== Configuration Test ===
Configuration Profile: Active
Company Name: Acme Corporation
Webhook: Configured (slack)
Email: security@company.com
Monitoring Mode: hybrid
Settings loaded successfully!
```

## Troubleshooting Configuration

### Configuration Profile Not Loading
```bash
# Check profile installation
sudo profiles list | grep jamfconnectmonitor

# Force profile renewal
sudo profiles renew -type=config

# Test manual reading
sudo defaults read /Library/Managed\ Preferences/com.macjediwizard.jamfconnectmonitor
```

### SMTP Authentication Issues
```bash
# Test SMTP connection
sudo jamf_connect_monitor.sh test-email

# Check SMTP settings
grep SMTP /var/log/jamf_connect_monitor/monitor.log
```

### Webhook Delivery Problems
```bash
# Test webhook
sudo jamf_connect_monitor.sh test-webhook

# Check webhook logs
grep webhook /var/log/jamf_connect_monitor/monitor.log
```

## Best Practices

1. **Use Configuration Profiles** for centralized management
2. **Test in staging** before production deployment
3. **Start with periodic monitoring** and gradually enable realtime
4. **Configure both webhook and email** for redundancy
5. **Review logs regularly** during initial deployment
6. **Document approved admins** and maintain the list
7. **Enable MonitorJamfConnectOnly** for event-driven efficiency
8. **Use appropriate LogLevel** (INFO for production, DEBUG for troubleshooting)

---

**Created with ❤️ by MacJediWizard**