# Configuration Profile Deployment Guide

## Overview
Jamf Connect Monitor v2.0.0 introduces centralized configuration management via Jamf Pro Configuration Profiles, eliminating hardcoded webhook URLs and email addresses.

## JSON Schema Deployment

### Step 1: Extract Schema
```bash
# From deployed package:
/usr/local/share/jamf_connect_monitor/schema/jamf_connect_monitor_schema.json

# Or from package contents:
pkgutil --expand JamfConnectMonitor-2.0.0.pkg temp
cp temp/Payload/usr/local/share/jamf_connect_monitor/schema/jamf_connect_monitor_schema.json .
```

### Step 2: Create Configuration Profile
1. **Navigate:** Jamf Pro → Computer Management → Configuration Profiles → New
2. **Add Payload:** Application & Custom Settings  
3. **Source:** Custom Schema
4. **Preference Domain:** `com.macjediwizard.jamfconnectmonitor`
5. **Upload Schema:** Select `jamf_connect_monitor_schema.json`

### Step 3: Configure Settings
```json
NotificationSettings:
├── WebhookURL: https://hooks.slack.com/services/YOUR/WEBHOOK
├── EmailRecipient: security@yourcompany.com  
├── NotificationTemplate: security_report
└── NotificationCooldownMinutes: 15

MonitoringBehavior:
├── MonitoringMode: realtime
├── AutoRemediation: true
├── GracePeriodMinutes: 5
└── MonitorJamfConnectOnly: true

JamfProIntegration:
├── CompanyName: Your Company
├── ITContactEmail: ithelp@yourcompany.com
└── UpdateInventoryOnViolation: true
```

### Step 4: Scope and Deploy
- **Target:** Smart Group "Jamf Connect Monitor - Installed"
- **Distribution:** Install Automatically

## Testing Configuration
```bash
# Test configuration reading
sudo jamf_connect_monitor.sh test-config

# Expected output shows configured settings
sudo defaults read com.macjediwizard.jamfconnectmonitor
```

---

**Created with ❤️ by MacJediWizard**