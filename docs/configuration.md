# Configuration Guide

## Monitoring Settings

### Monitoring Interval
Default: 300 seconds (5 minutes)
Configure via Jamf Pro policy parameter 6 or LaunchDaemon StartInterval

### Approved Administrators
File: `/usr/local/etc/approved_admins.txt`
- One username per line
- Automatically populated with current admins during installation
- Manage via command line or manual editing

## Notification Configuration

### Slack/Teams Webhooks
Configure via Jamf Pro policy parameter 4 or script variable:
```bash
WEBHOOK_URL="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXX"
```

### Email Notifications  
Configure via Jamf Pro policy parameter 5 or script variable:
```bash
EMAIL_RECIPIENT="security@yourcompany.com"
```

## Company Customization

### Branding
Configure via Jamf Pro policy parameter 7:
```bash
COMPANY_NAME="YourCompany"
```

### Package Identifier
Update in package_creation_script.sh:
```bash
PACKAGE_IDENTIFIER="com.yourcompany.jamfconnectmonitor"
```

---

**Created with ❤️ by MacJediWizard**
