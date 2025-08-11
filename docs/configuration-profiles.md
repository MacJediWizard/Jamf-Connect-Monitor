<p align="center">
  <img src="../JamfConnectMonitor-815x1024.png" alt="Jamf Connect Monitor Logo" width="200">
</p>

# Configuration Profile Deployment Guide v2.4.0

## Overview
Jamf Connect Monitor v2.4.0 introduces enhanced Configuration Profile management with centralized administration, improved parsing reliability, and comprehensive troubleshooting capabilities for enterprise environments.

## 🎯 **v2.4.0 Configuration Profile Improvements**

### **Production-Verified Integration (Fixed in v2.4.0)**
- **✅ Standardized Reading Methods** - Uses verified working methods for enterprise environments
- **✅ Company Name Display** - Shows actual company names instead of "Your Company" fallback
- **✅ Enhanced Troubleshooting** - Multiple fallback strategies for reliable configuration reading
- **✅ Production Tested** - All improvements verified in enterprise Jamf Pro environments

### **Enterprise Features**
- **No Hardcoded Credentials** - All sensitive data managed via encrypted Configuration Profiles
- **Real-time Configuration Updates** - Changes apply without script modification
- **Department Flexibility** - Different settings per Smart Group/department
- **Audit Trail** - Complete change history via Jamf Pro logs

## JSON Schema Deployment

### Step 1: Extract Schema
```bash
# From deployed package:
/usr/local/share/jamf_connect_monitor/schema/jamf_connect_monitor_schema.json

# Or from package contents:
pkgutil --expand JamfConnectMonitor-2.4.0.pkg temp
cp temp/Payload/usr/local/share/jamf_connect_monitor/schema/jamf_connect_monitor_schema.json .
```

### Step 2: Create Configuration Profile
1. **Navigate:** Jamf Pro → Computer Management → Configuration Profiles → New
2. **Add Payload:** Application & Custom Settings  
3. **Source:** Custom Schema
4. **Preference Domain:** `com.macjediwizard.jamfconnectmonitor`
5. **Upload Schema:** Select `jamf_connect_monitor_schema.json`

### Step 3: Configure Settings (v2.4.0 Enhanced)
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

SecuritySettings:
├── ViolationReporting: true
├── LogRetentionDays: 30
├── ExcludeSystemAccounts: ["_mbsetupuser", "root", "daemon"]
└── RequireConfirmation: false

JamfProIntegration:
├── CompanyName: Your Company Name (DISPLAYS CORRECTLY in v2.4.0)
├── ITContactEmail: ithelp@yourcompany.com
├── UpdateInventoryOnViolation: true
└── TriggerPolicyOnViolation: security_incident_response

AdvancedSettings:
├── DebugLogging: false
├── MonitoringInterval: 300
├── MaxNotificationsPerHour: 10
└── AutoPopulateApprovedAdmins: true
```

### Step 4: Scope and Deploy
- **Target:** Smart Group "Jamf Connect Monitor - Installed v2.x"
- **Distribution:** Install Automatically

## Configuration Profile Integration Testing (v2.4.0)

### Testing Configuration Reading (Enhanced in v2.4.0)
```bash
# Test v2.4.0 enhanced configuration reading
sudo jamf_connect_monitor.sh test-config

# Expected v2.4.0 output shows actual values:
# === Configuration Profile Test ===
# Profile Status: Deployed
# Webhook: Configured
# Email: your-email@company.com
# Company Name: Your Company Name (NOT "Your Company")
# Monitoring Mode: realtime
# Auto Remediation: true
```

### Manual Configuration Profile Testing
```bash
# Test all configuration reading methods (v2.4.0 uses multiple methods)
echo "=== Configuration Profile Reading Methods Test ==="

echo "Method 1 (Standard):"
defaults read com.macjediwizard.jamfconnectmonitor 2>/dev/null || echo "FAILED"

echo "Method 2 (Managed Preferences - v2.4.0 Preferred):"
defaults read "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor" 2>/dev/null || echo "FAILED"

echo "Method 3 (Sudo Standard):"
sudo defaults read com.macjediwizard.jamfconnectmonitor 2>/dev/null || echo "FAILED"

echo "Method 4 (Sudo Managed Preferences - v2.4.0 Preferred):"
sudo defaults read "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor" 2>/dev/null || echo "FAILED"

# v2.4.0 uses Methods 2 & 4 (the ones that work reliably in enterprise environments)
```

### Verify Profile Deployment
```bash
# Check Configuration Profile installation
sudo profiles list | grep jamfconnectmonitor

# Expected output:
# com.macjediwizard.jamfconnectmonitor    [UUID]    Computer Level

# Read specific Configuration Profile values
sudo defaults read com.macjediwizard.jamfconnectmonitor NotificationSettings.WebhookURL
sudo defaults read com.macjediwizard.jamfconnectmonitor JamfProIntegration.CompanyName
sudo defaults read com.macjediwizard.jamfconnectmonitor MonitoringBehavior.MonitoringMode
```

## v2.4.0 Enhanced Configuration Features

### Improved Company Name Display
```json
{
  "JamfProIntegration": {
    "CompanyName": "Acme Corporation",
    "ITContactEmail": "it-support@acme.com"
  }
}
```

**v2.4.0 Result:**
- Extension Attribute shows: `Company: Acme Corporation`
- Main script status shows: `Company: Acme Corporation`
- Notifications include: `Acme Corporation` branding

**Before v2.4.0 (Issue):**
- Extension Attribute showed: `Company: Your Company`
- Fallback values used instead of Configuration Profile

### Enhanced Monitoring Mode Configuration
```json
{
  "MonitoringBehavior": {
    "MonitoringMode": "realtime",
    "AutoRemediation": true,
    "GracePeriodMinutes": 5
  }
}
```

**v2.4.0 Result:**
- Extension Attribute shows: `Mode: realtime`
- Smart Groups populate correctly
- Real-time monitoring activates

**Before v2.4.0 (Issue):**
- Extension Attribute showed: `Mode: ` (empty)
- Smart Groups didn't populate properly

### Advanced Security Configuration
```json
{
  "SecuritySettings": {
    "ViolationReporting": true,
    "LogRetentionDays": 30,
    "ExcludeSystemAccounts": ["_mbsetupuser", "root", "daemon", "_installer"],
    "RequireConfirmation": false
  },
  "AdvancedSettings": {
    "DebugLogging": false,
    "MaxNotificationsPerHour": 10,
    "AutoPopulateApprovedAdmins": true
  }
}
```

## Department-Specific Configuration Profiles

### IT Department Profile (Enhanced Security)
```json
{
  "NotificationSettings": {
    "WebhookURL": "https://hooks.slack.com/services/IT-SECURITY/WEBHOOK",
    "EmailRecipient": "it-security@yourcompany.com",
    "NotificationTemplate": "security_report",
    "NotificationCooldownMinutes": 5
  },
  "MonitoringBehavior": {
    "MonitoringMode": "realtime",
    "AutoRemediation": true,
    "GracePeriodMinutes": 2
  },
  "JamfProIntegration": {
    "CompanyName": "IT Department - Your Company",
    "ITContactEmail": "it-security@yourcompany.com",
    "TriggerPolicyOnViolation": "it_security_incident_response"
  },
  "AdvancedSettings": {
    "DebugLogging": true,
    "MaxNotificationsPerHour": 20
  }
}
```

### Executive/VIP Profile (Balanced Security)
```json
{
  "NotificationSettings": {
    "WebhookURL": "https://hooks.slack.com/services/EXECUTIVE-SECURITY/WEBHOOK",
    "EmailRecipient": "executive-security@yourcompany.com",
    "NotificationTemplate": "detailed",
    "NotificationCooldownMinutes": 10
  },
  "MonitoringBehavior": {
    "MonitoringMode": "hybrid",
    "AutoRemediation": false,
    "GracePeriodMinutes": 15
  },
  "SecuritySettings": {
    "RequireConfirmation": true
  },
  "JamfProIntegration": {
    "CompanyName": "Executive - Your Company"
  }
}
```

### General Staff Profile (Standard Security)
```json
{
  "NotificationSettings": {
    "WebhookURL": "https://hooks.slack.com/services/GENERAL-SECURITY/WEBHOOK",
    "EmailRecipient": "security@yourcompany.com",
    "NotificationTemplate": "simple",
    "NotificationCooldownMinutes": 15
  },
  "MonitoringBehavior": {
    "MonitoringMode": "periodic",
    "AutoRemediation": true,
    "GracePeriodMinutes": 10
  },
  "JamfProIntegration": {
    "CompanyName": "General Staff - Your Company"
  }
}
```

## Troubleshooting Configuration Profiles (v2.4.0 Enhanced)

### Common Configuration Profile Issues

#### Profile Not Applying
```bash
# Check profile installation status
sudo profiles list | grep jamfconnectmonitor

# If not listed, check Jamf Pro scope and deployment
# Computer Management → Configuration Profiles → [Your Profile] → Scope

# Force profile renewal
sudo profiles renew -type=config

# Check for profile conflicts
sudo profiles list | grep -E "(jamf|monitor)"
```

#### Configuration Values Not Reading (Fixed in v2.4.0)
```bash
# Test v2.4.0 configuration reading
sudo jamf_connect_monitor.sh test-config

# If showing fallback values, test individual methods:
echo "Testing Configuration Profile reading methods..."

# Method 2 (v2.4.0 preferred):
defaults read "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor" JamfProIntegration.CompanyName 2>/dev/null

# Method 4 (v2.4.0 preferred):
sudo defaults read "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor" JamfProIntegration.CompanyName 2>/dev/null

# If both fail, check profile deployment in Jamf Pro
```

#### Company Name Shows "Your Company" Instead of Actual Name
```bash
# This was a v2.0.0 issue, fixed in v2.0.1+
# Verify v2.4.0 installation:
sudo jamf_connect_monitor.sh status | grep "v2.4.0"

# Test Configuration Profile company name:
sudo defaults read "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor" JamfProIntegration.CompanyName

# If still shows "Your Company", check Configuration Profile deployment:
# Jamf Pro → Computer Management → Configuration Profiles → Deployment status
```

#### Monitoring Mode Empty in Extension Attribute
```bash
# This was a v2.0.0 issue, fixed in v2.0.1+
# Update Extension Attribute script in Jamf Pro (CRITICAL):
# Settings → Extension Attributes → Replace with v2.4.0 script

# Test Extension Attribute:
sudo /usr/local/etc/jamf_ea_admin_violations.sh | grep "Mode:"
# Expected v2.4.0: Mode: periodic (or realtime/hybrid)

# Force inventory update:
sudo jamf recon
```

### JSON Schema Validation
```bash
# Validate JSON schema syntax
python3 -m json.tool jamf_connect_monitor_schema.json

# Check schema version
grep '"title"' jamf_connect_monitor_schema.json
# Should show: "Jamf Connect Monitor Configuration"

# Verify schema properties
python3 -c "
import json
with open('jamf_connect_monitor_schema.json') as f:
    schema = json.load(f)
    print('Schema properties:', list(schema['properties'].keys()))
"
```

### Configuration Profile Deployment Validation
```bash
# Comprehensive Configuration Profile validation
echo "=== Configuration Profile Deployment Validation ==="

# 1. Check profile installation
echo "Profile Installation:"
sudo profiles list | grep jamfconnectmonitor && echo "✅ Installed" || echo "❌ Not Installed"

# 2. Test configuration reading
echo "Configuration Reading:"
sudo jamf_connect_monitor.sh test-config | grep -q "Profile Status: Deployed" && echo "✅ Reading Successfully" || echo "❌ Reading Failed"

# 3. Check company name (v2.4.0 improvement)
echo "Company Name Display:"
company_name=$(sudo jamf_connect_monitor.sh test-config | grep "Company Name:" | cut -d':' -f2 | xargs)
if [[ "$company_name" != "Your Company" ]]; then
    echo "✅ Shows actual company name: $company_name"
else
    echo "❌ Shows fallback value (Configuration Profile issue)"
fi

# 4. Verify monitoring mode
echo "Monitoring Mode:"
sudo jamf_connect_monitor.sh test-config | grep -q "Mode:" && echo "✅ Mode Configured" || echo "❌ Mode Not Set"

# 5. Test notifications
echo "Notification Configuration:"
sudo jamf_connect_monitor.sh test-config | grep -q "Webhook: Configured" && echo "✅ Webhook Configured" || echo "⚠️ Webhook Not Configured"
```

## Performance and Scalability

### Configuration Profile Performance
- **Reading Overhead:** v2.4.0 uses optimized methods reducing lookup time
- **Cache Utilization:** Configuration Profiles cached by macOS for fast access
- **Network Impact:** Minimal - profiles downloaded once, cached locally
- **Update Speed:** Changes apply within seconds of profile deployment

### Large-Scale Deployment
```bash
# Monitor Configuration Profile deployment progress
# Create Smart Group: "Configuration Profile Deployed"
# Criteria: Extension Attribute like "*Profile: Deployed*"

# Track deployment percentage:
# Deployed Systems / Total Target Systems * 100
```

### Resource Usage
```bash
# Monitor Configuration Profile reading performance
time sudo jamf_connect_monitor.sh test-config

# Typical v2.4.0 performance: < 2 seconds
# If slower, check Configuration Profile deployment status
```

## Advanced Configuration Scenarios

### Multi-Tenant Environments
```json
{
  "JamfProIntegration": {
    "CompanyName": "Client ABC - MSP Provider",
    "ITContactEmail": "support-abc@msp.com"
  },
  "NotificationSettings": {
    "WebhookURL": "https://hooks.slack.com/services/CLIENT-ABC/SECURITY",
    "EmailRecipient": "security-abc@msp.com"
  }
}
```

### Compliance and Audit Environments
```json
{
  "SecuritySettings": {
    "ViolationReporting": true,
    "LogRetentionDays": 365,
    "RequireConfirmation": false
  },
  "AdvancedSettings": {
    "DebugLogging": true,
    "MaxNotificationsPerHour": 50
  },
  "NotificationSettings": {
    "NotificationTemplate": "security_report",
    "NotificationCooldownMinutes": 5
  }
}
```

### Development/Testing Environments
```json
{
  "MonitoringBehavior": {
    "MonitoringMode": "periodic",
    "AutoRemediation": false,
    "GracePeriodMinutes": 30
  },
  "SecuritySettings": {
    "RequireConfirmation": true,
    "ViolationReporting": false
  },
  "JamfProIntegration": {
    "CompanyName": "Development Environment - Your Company"
  }
}
```

## Configuration Profile Maintenance

### Regular Validation Schedule
- **Daily:** Automated Configuration Profile compliance monitoring
- **Weekly:** Review Configuration Profile deployment success rates
- **Monthly:** Analyze configuration effectiveness and optimization opportunities
- **Quarterly:** Update Configuration Profile settings based on security requirements

### Monitoring Configuration Drift
```bash
# Create Smart Group: "Configuration Profile Compliance"
# Criteria: Extension Attribute like "*Profile: Deployed*" 
# AND Extension Attribute like "*Config Test: OK*"

# Track compliance percentage over time
# Alert on configuration drift or deployment failures
```

### Configuration Profile Updates
```bash
# When updating Configuration Profile settings:
# 1. Update Configuration Profile in Jamf Pro
# 2. Settings apply automatically (no script updates needed)
# 3. Force profile renewal on test systems:
sudo profiles renew -type=config

# 4. Verify new settings:
sudo jamf_connect_monitor.sh test-config

# 5. Monitor Smart Group membership changes
```

## Best Practices

### Security Recommendations
- **Use encrypted Configuration Profiles** for sensitive webhook URLs
- **Implement least privilege** with minimal required permissions
- **Regular audit** of Configuration Profile settings and scopes
- **Department-specific configurations** for tailored security policies

### Operational Excellence
- **Monitor Configuration Profile compliance** via Smart Groups
- **Automate validation** with built-in test commands
- **Document configuration changes** for audit trails
- **Use production verification tools** for deployment validation

### Scalability Guidelines
- **Start with simple configurations** and add complexity gradually
- **Test Configuration Profile changes** on pilot groups first
- **Monitor performance impact** of configuration complexity
- **Use Smart Group scoping** for targeted Configuration Profile deployment

---

**Created with ❤️ by MacJediWizard**

**Production-verified Configuration Profile management with v2.4.0 integration improvements and comprehensive troubleshooting.**