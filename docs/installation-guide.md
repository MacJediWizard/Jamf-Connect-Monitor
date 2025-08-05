# Jamf Connect Monitor v2.x - Complete Installation Guide

## Overview
This guide provides comprehensive installation instructions for deploying Jamf Connect Monitor v2.x with Configuration Profile management and real-time monitoring capabilities across your macOS fleet.

## What's New in v2.x

### Enterprise Configuration Management
- **Configuration Profiles** - Centralized webhook/email management via Jamf Pro
- **JSON Schema** - Easy Application & Custom Settings deployment
- **No Hardcoded Credentials** - All sensitive data managed via encrypted profiles

### Real-time Monitoring
- **Immediate Detection** - Violation response in seconds (like Jamf Protect)
- **Event-driven Architecture** - Continuous monitoring instead of 5-minute polling
- **Performance Options** - Choose periodic, real-time, or hybrid monitoring

### Enhanced Enterprise Features
- **Professional Notifications** - Security report templates with company branding
- **Advanced Smart Groups** - Comprehensive Jamf Pro automation workflows
- **Compliance Reporting** - Detailed audit trails and violation tracking

## Prerequisites

### System Requirements
- **macOS**: 10.14 (Mojave) or later
- **Jamf Connect**: 2.33.0 or later with privilege elevation enabled
- **Jamf Pro**: 10.19 or later (for Configuration Profile JSON Schema support)
- **Administrative Access**: Required for installation

### Pre-Installation Checklist
- [ ] Jamf Connect installed and configured for privilege elevation
- [ ] Jamf Pro environment accessible with admin privileges
- [ ] Network connectivity for webhook notifications (if using)
- [ ] SMTP configuration for email notifications (if using)

## Installation Methods

### Method 1: Jamf Pro Deployment (Recommended for Enterprise)

#### Step 1: Download Release Assets
1. Go to [GitHub Releases](https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest)
2. Download required files:
   - `JamfConnectMonitor-2.0.1.pkg` (or latest 2.x version)
   - `jamf_connect_monitor_schema.json` (Configuration Profile schema)
   - `JamfConnectMonitor-2.0.1.pkg.sha256` (Verification checksum)

#### Step 2: Verify Package Integrity
```bash
# Verify package checksum (adjust version as needed)
shasum -a 256 -c JamfConnectMonitor-2.0.1.pkg.sha256

# Expected output: JamfConnectMonitor-2.0.1.pkg: OK
```

#### Step 3: Upload to Jamf Pro
1. **Navigate to Packages:**
   - Settings → Computer Management → Packages
   - Click "New"

2. **Package Configuration:**
   ```
   Display Name: Jamf Connect Monitor v2.x
   Category: Security
   Priority: 10
   Description: "Enterprise security monitoring with Configuration Profile support"
   ```

3. **Upload Package** and save

#### Step 4: Create Configuration Profile
1. **Navigate to Configuration Profiles:**
   - Computer Management → Configuration Profiles → New

2. **General Settings:**
   ```
   Display Name: Jamf Connect Monitor Configuration
   Description: Centralized security monitoring settings
   Category: Security
   Level: Computer Level
   Distribution Method: Install Automatically
   ```

3. **Add Application & Custom Settings Payload:**
   - Click "Add" → "Application & Custom Settings"
   - Source: "Custom Schema"
   - Preference Domain: `com.macjediwizard.jamfconnectmonitor`
   - Upload Schema: Select `jamf_connect_monitor_schema.json`

4. **Configure Settings via Jamf Pro Interface:**
   ```json
   Notification Settings:
   ├── Webhook URL: https://hooks.slack.com/services/YOUR/WEBHOOK
   ├── Email Recipient: security@yourcompany.com
   ├── Notification Template: security_report
   └── Notification Cooldown: 15 minutes

   Monitoring Behavior:
   ├── Monitoring Mode: realtime
   ├── Auto Remediation: true
   ├── Grace Period: 5 minutes
   └── Monitor Jamf Connect Only: true

   Jamf Pro Integration:
   ├── Company Name: Your Company Name
   ├── IT Contact Email: ithelp@yourcompany.com
   └── Update Inventory on Violation: true
   ```

#### Step 5: Create Extension Attribute
1. **Navigate to Extension Attributes:**
   - Settings → Computer Management → Extension Attributes → New

2. **Configuration:**
   ```
   Display Name: [ Jamf Connect ] - Monitor Status v2.x
   Description: Enhanced monitoring status with Configuration Profile support
   Data Type: String
   Input Type: Script
   ```

3. **Script Content:** Use the enhanced Extension Attribute script from the package

#### Step 6: Create Smart Groups (Flexible v2.x)
**Essential Smart Groups for v2.x:**

```
Jamf Connect Monitor - Installed v2.x
├── Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" contains "Version: 2."
└── Purpose: Track all v2.x installations

Jamf Connect Monitor - Config Profile Active
├── Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" contains "Profile: Deployed"
└── Purpose: Verify Configuration Profile deployment

Jamf Connect Monitor - CRITICAL VIOLATIONS
├── Criteria: Extension Attribute contains "Unauthorized:" AND does not contain "Unauthorized: 0"
└── Purpose: Immediate security incident response (configure alerts!)
```

#### Step 7: Create Deployment Policy
1. **General Settings:**
   ```
   Display Name: Deploy Jamf Connect Monitor v2.x
   Category: Security
   Trigger: Enrollment Complete, Recurring Check-in
   Execution Frequency: Once per computer
   ```

2. **Packages:** Add "Jamf Connect Monitor v2.x"

3. **Scope:** 
   - Target: Computers with Jamf Connect installed
   - Exclusions: "Jamf Connect Monitor - Installed v2.x"

4. **Maintenance:** Enable "Update Inventory"

### Method 2: Manual Installation

#### Single Device Installation
```bash
# Download package (adjust version as needed)
curl -LO https://github.com/MacJediWizard/jamf-connect-monitor/releases/download/v2.0.1/JamfConnectMonitor-2.0.1.pkg

# Install package
sudo installer -pkg JamfConnectMonitor-2.0.1.pkg -target /

# Verify installation
sudo jamf_connect_monitor.sh status
```

#### Manual Configuration (without Configuration Profile)
```bash
# Configure approved admins manually
sudo jamf_connect_monitor.sh add-admin your_username

# Test functionality
sudo jamf_connect_monitor.sh force-check
```

### Method 3: Build from Source

#### Local Build and Deploy
```bash
# Clone repository
git clone https://github.com/MacJediWizard/jamf-connect-monitor.git
cd jamf-connect-monitor

# Build package
sudo ./scripts/package_creation_script.sh build

# Install locally (adjust version as needed)
sudo installer -pkg output/JamfConnectMonitor-2.0.1.pkg -target /
```

## Post-Installation Configuration

### Verify Installation
```bash
# Check version and status
sudo jamf_connect_monitor.sh status

# Expected output for v2.x:
# === Jamf Connect Elevation Monitor Status (v2.x) ===
# Configuration Profile: Active (or Not deployed)
# Company: Your Company Name
# Monitoring Mode: realtime (or periodic)
# ...

# Test Configuration Profile integration
sudo jamf_connect_monitor.sh test-config

# Expected output shows Configuration Profile settings:
# === Configuration Profile Test ===
# Profile Status: Deployed
# Webhook: Configured
# Email: security@yourcompany.com
# ...
```

### Configuration Profile Verification
```bash
# Check Configuration Profile deployment
sudo profiles list | grep jamfconnectmonitor

# Read configuration values
sudo defaults read com.macjediwizard.jamfconnectmonitor

# Should show your configured webhook URLs, email, monitoring mode, etc.
```

### Extension Attribute Testing
```bash
# Test Extension Attribute manually
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Expected output format for v2.x:
# <result>=== JAMF CONNECT MONITOR STATUS v2.0 ===
# Version: 2.x, Periodic: Running, Real-time: Not Running
# Configuration: Profile: Deployed, Webhook: Configured, Email: Configured
# ...
# </result>
```

### Smart Group Validation
1. **Check Smart Group membership** in Jamf Pro computer records
2. **Verify Extension Attribute data** appears in computer inventory
3. **Confirm automated grouping** based on monitoring status

## Configuration Management

### v2.x Configuration Profile Features

#### Centralized Webhook Management
- **No Script Editing:** Webhook URLs managed via Jamf Pro interface
- **Immediate Updates:** Changes apply without script redeployment
- **Secure Storage:** Credentials encrypted via Configuration Profiles
- **Template Options:** Simple, detailed, or security_report formats

#### Advanced Monitoring Options
- **Monitoring Modes:** Choose periodic (5-min), real-time, or hybrid
- **Grace Periods:** Configurable wait time for legitimate elevations
- **Auto-remediation:** Enable/disable automatic admin privilege removal
- **Jamf Connect Focus:** Monitor only Jamf Connect events vs all admin changes

#### Enterprise Branding
- **Company Name:** Appears in all notifications and reports
- **IT Contact:** Included in user-facing security messages
- **Notification Templates:** Professional security incident reporting

### Legacy Configuration (v1.x Compatibility)
```bash
# Manual approved admin management (still supported)
sudo nano /usr/local/etc/approved_admins.txt

# Add/remove admins via CLI
sudo jamf_connect_monitor.sh add-admin username
sudo jamf_connect_monitor.sh remove-admin username
```

## Monitoring Modes Explained

### Periodic Monitoring (Traditional)
- **Interval:** 5-minute checks via LaunchDaemon
- **Resource Usage:** Low - intermittent CPU usage
- **Detection Time:** Up to 5 minutes
- **Best For:** Standard environments, resource-constrained systems

### Real-time Monitoring (v2.x Feature)
- **Detection:** Immediate via log streaming
- **Resource Usage:** Moderate - continuous background monitoring
- **Detection Time:** Seconds
- **Best For:** High-security environments, immediate response requirements

### Hybrid Monitoring
- **Combination:** Both periodic and real-time monitoring active
- **Resource Usage:** Higher - maximum coverage with redundancy
- **Detection Time:** Immediate with backup checks
- **Best For:** Critical systems requiring maximum security coverage

## Version-Specific Installation Notes

### v2.0.1 Updates
- Enhanced Configuration Profile parsing for monitoring modes
- Fixed empty monitoring mode display in Extension Attribute
- Improved Smart Group compatibility and reliability
- Better handling of different plist formats

### v2.0.0 Introduction
- Initial Configuration Profile support
- Real-time monitoring capabilities
- JSON Schema for Jamf Pro deployment
- Enhanced notification templates

## Troubleshooting Installation

### Common Installation Issues

#### Package Installation Fails
```bash
# Check installer logs
tail -f /var/log/install.log

# Verify package signature (adjust version as needed)
pkgutil --check-signature JamfConnectMonitor-2.0.1.pkg

# Check disk space
df -h /usr/local
```

#### Configuration Profile Not Applying
```bash
# Force profile renewal
sudo profiles renew -type=config

# Check profile installation status
sudo profiles list | grep jamfconnectmonitor

# Validate JSON schema syntax
python3 -m json.tool jamf_connect_monitor_schema.json
```

#### Extension Attribute Not Populating
```bash
# Test Extension Attribute script manually
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Check script permissions
ls -la /usr/local/etc/jamf_ea_admin_violations.sh
# Should be: -rwxr-xr-x root wheel

# Force inventory update
sudo jamf recon
```

#### Daemon Not Starting
```bash
# Check LaunchDaemon syntax
plutil -lint /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Load daemon manually
sudo launchctl load /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Check daemon status
sudo launchctl list | grep jamfconnectmonitor
```

### Performance Troubleshooting

#### Real-time Monitoring Impact
```bash
# Monitor CPU usage
top -p $(pgrep -f jamf_connect_monitor)

# Check memory usage
ps aux | grep jamf_connect_monitor

# Monitor log growth
du -sh /var/log/jamf_connect_monitor/
```

#### Network Connectivity Issues
```bash
# Test webhook connectivity
curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"Test from Jamf Connect Monitor"}' \
     "YOUR_WEBHOOK_URL"

# Test email configuration
echo "Test email from Jamf Connect Monitor" | mail -s "Test Subject" "your-email@company.com"
```

## Migration from v1.x to v2.x

### Automatic Migration Process
v2.x automatically preserves existing v1.x configurations:
- **Approved Admin Lists** - Maintained during upgrade
- **Historical Logs** - Preserved with new v2.x logging enhancements
- **LaunchDaemon Settings** - Updated with backward compatibility

### Enhanced Features After Migration
After upgrading to v2.x, deploy Configuration Profile to enable:
- **Centralized webhook/email management**
- **Real-time monitoring capabilities**
- **Enhanced notification templates**
- **Advanced Smart Group integration**

### Migration Validation
```bash
# Verify v1.x settings preserved
cat /usr/local/etc/approved_admins.txt

# Check upgrade status
sudo jamf_connect_monitor.sh status | grep "Version: 2."

# Test Configuration Profile integration
sudo jamf_connect_monitor.sh test-config
```

## Best Practices

### Security Recommendations
- **Deploy Configuration Profiles** immediately after package installation
- **Configure webhook notifications** for immediate violation alerts
- **Create Smart Groups** for automated incident response
- **Monitor "CRITICAL VIOLATIONS"** Smart Group daily (should be 0)

### Performance Optimization
- **Start with periodic monitoring** for baseline performance
- **Gradually enable real-time monitoring** for high-security systems
- **Monitor resource usage** via Smart Groups and system metrics
- **Adjust grace periods** based on legitimate elevation patterns

### Operational Excellence
- **Regular Smart Group review** for deployment progress
- **Weekly violation trend analysis** for security improvements
- **Configuration Profile compliance monitoring** for centralized management
- **Documentation updates** for approved admin list changes

---

## Next Steps After Installation

1. **Verify Smart Group Population** - Check Extension Attribute data in Jamf Pro
2. **Test Notification Delivery** - Configure and test webhook/email alerts
3. **Monitor System Performance** - Track resource usage with real-time monitoring
4. **Plan Fleet Rollout** - Expand from pilot to full deployment
5. **Configure Advanced Features** - Enable department-specific settings

---

**Installation Complete!** 

You now have enterprise-grade security monitoring with Configuration Profile management, real-time detection capabilities, and comprehensive Jamf Pro integration.

---

**Created with ❤️ by MacJediWizard**