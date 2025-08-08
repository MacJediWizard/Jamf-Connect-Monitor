# Jamf Connect Monitor v2.3.0 - Complete Installation Guide

## Overview
This guide provides comprehensive installation instructions for deploying Jamf Connect Monitor v2.3.0 with enhanced Configuration Profile management, automatic ACL clearing, and future-proof version detection across your macOS fleet.

## What's New in v2.3.0

### Critical Production Fixes
- **Automatic ACL Clearing** - Eliminates Extended Attribute script execution issues
- **Enhanced Configuration Profile Integration** - Shows actual company names instead of fallback values
- **Future-Proof Version Detection** - Automatic identification of all v2.x+ versions
- **Improved Smart Group Compatibility** - Reliable Extension Attribute data format

### Enterprise Configuration Management
- **Configuration Profiles** - Centralized webhook/email management via Jamf Pro
- **JSON Schema** - Easy Application & Custom Settings deployment
- **No Hardcoded Credentials** - All sensitive data managed via encrypted profiles

### Real-time Monitoring
- **Immediate Detection** - Violation response in seconds
- **Event-driven Architecture** - Continuous monitoring instead of 5-minute polling
- **Performance Options** - Choose periodic, real-time, or hybrid monitoring

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
   - `JamfConnectMonitor-2.3.0.pkg` (or latest 2.x version)
   - `jamf_connect_monitor_schema.json` (Configuration Profile schema)
   - `JamfConnectMonitor-2.3.0.pkg.sha256` (Verification checksum)

#### Step 2: Verify Package Integrity
```bash
# Verify package checksum
shasum -a 256 -c JamfConnectMonitor-2.3.0.pkg.sha256

# Expected output: JamfConnectMonitor-2.3.0.pkg: OK
```

#### Step 3: Upload to Jamf Pro
1. **Navigate to Packages:**
   - Settings → Computer Management → Packages
   - Click "New"

2. **Package Configuration:**
   ```
   Display Name: Jamf Connect Monitor v2.3.0
   Category: Security
   Priority: 10
   Description: "Enterprise security monitoring with enhanced Configuration Profile support and automatic ACL clearing"
   ```

3. **Upload Package** and save

#### Step 4: Create Configuration Profile
1. **Navigate to Configuration Profiles:**
   - Computer Management → Configuration Profiles → New

2. **General Settings:**
   ```
   Display Name: Jamf Connect Monitor Configuration
   Description: Centralized security monitoring settings with v2.3.0 enhancements
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

#### Step 5: Create/Update Extension Attribute (CRITICAL for v2.3.0)
1. **Navigate to Extension Attributes:**
   - Settings → Computer Management → Extension Attributes → New (or Edit existing)

2. **Configuration:**
   ```
   Display Name: [ Jamf Connect ] - Monitor Status v2.x
   Description: Enhanced monitoring status with v2.3.0 Configuration Profile support
   Data Type: String
   Input Type: Script
   ```

3. **Script Content:** Use the v2.3.0 Enhanced Extension Attribute script from the package

#### Step 6: Create Smart Groups (Future-Proof v2.x)
**Essential Smart Groups for v2.3.0:**

```
Jamf Connect Monitor - Installed v2.x
├── Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" contains "Version: 2."
└── Purpose: Track all v2.x installations (automatically includes v2.3.0+)

Jamf Connect Monitor - Latest v2.3.0+
├── Criteria: Extension Attribute contains "Version: 2.3.0" OR contains "Version: 2.0.2"
└── Purpose: Track systems with latest production fixes

Jamf Connect Monitor - Config Profile Active
├── Criteria: Extension Attribute contains "Profile: Deployed"
└── Purpose: Verify Configuration Profile deployment

Jamf Connect Monitor - CRITICAL VIOLATIONS
├── Criteria: Extension Attribute contains "Unauthorized:" AND does not contain "Unauthorized: 0"
└── Purpose: Immediate security incident response (configure alerts!)
```

#### Step 7: Create Deployment Policy
1. **General Settings:**
   ```
   Display Name: Deploy Jamf Connect Monitor v2.3.0
   Category: Security
   Trigger: Enrollment Complete, Recurring Check-in
   Execution Frequency: Once per computer
   ```

2. **Packages:** Add "Jamf Connect Monitor v2.3.0"

3. **Scope:** 
   - Target: Computers with Jamf Connect installed
   - Exclusions: "Jamf Connect Monitor - Installed v2.x"

4. **Maintenance:** Enable "Update Inventory"

### Method 2: Manual Installation

#### Single Device Installation
```bash
# Download package
curl -LO https://github.com/MacJediWizard/jamf-connect-monitor/releases/download/v2.3.0/JamfConnectMonitor-2.3.0.pkg

# Install package
sudo installer -pkg JamfConnectMonitor-2.3.0.pkg -target /

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

# Install locally
sudo installer -pkg output/JamfConnectMonitor-2.3.0.pkg -target /
```

## Post-Installation Configuration

### Verify v2.3.0 Installation
```bash
# Check version and status
sudo jamf_connect_monitor.sh status

# Expected output for v2.3.0:
# === Jamf Connect Elevation Monitor Status (v2.3.0) ===
# Configuration Profile: Active (or Not deployed)
# Company: [Your Actual Company Name] (not "Your Company" fallback)
# Monitoring Mode: periodic (or realtime/hybrid)
# ...

# Test Configuration Profile integration
sudo jamf_connect_monitor.sh test-config

# Expected output shows Configuration Profile settings:
# === Configuration Profile Test ===
# Profile Status: Deployed
# Webhook: Configured
# Email: security@yourcompany.com
# Company Name: [Your Actual Company Name]
# ...
```

### ACL and Permission Verification
```bash
# Verify no ACLs remain (v2.3.0 automatically clears these)
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
ls -la@ /usr/local/etc/jamf_ea_admin_violations.sh

# Should show: -rwxr-xr-x (no @ symbol)
# If @ symbols appear, ACLs need manual clearing
```

### Configuration Profile Verification
```bash
# Check Configuration Profile deployment
sudo profiles list | grep jamfconnectmonitor

# Read configuration values
sudo defaults read com.macjediwizard.jamfconnectmonitor

# Should show your configured webhook URLs, email, monitoring mode, actual company name, etc.
```

### Extension Attribute Testing
```bash
# Test Extension Attribute manually
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Expected output format for v2.3.0:
# <result>=== JAMF CONNECT MONITOR STATUS v2.0 ===
# Version: 2.3.0, Periodic: Running, Real-time: Not Running
# Configuration: Profile: Deployed, Webhook: Configured, Email: Configured, Mode: periodic, Company: [Your Actual Company Name]
# ...
# </result>
```

### Smart Group Validation
1. **Check Smart Group membership** in Jamf Pro computer records
2. **Verify Extension Attribute data** appears in computer inventory
3. **Confirm automated grouping** based on monitoring status
4. **Validate version detection** shows "Version: 2.3.0"

## Configuration Management

### v2.3.0 Configuration Profile Features

#### Enhanced Company Name Integration
- **Actual Company Names:** Extension Attribute displays configured company name instead of "Your Company" fallback
- **Immediate Updates:** Changes apply without script redeployment
- **Secure Storage:** Credentials encrypted via Configuration Profiles
- **Template Options:** Simple, detailed, or security_report formats

#### Advanced Monitoring Options
- **Monitoring Modes:** Choose periodic (5-min), real-time, or hybrid
- **Grace Periods:** Configurable wait time for legitimate elevations
- **Auto-remediation:** Enable/disable automatic admin privilege removal
- **Jamf Connect Focus:** Monitor only Jamf Connect events vs all admin changes

#### Enterprise Branding
- **Company Name:** Appears in all notifications and reports with actual configured values
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

### v2.3.0 Critical Fixes
- **Automatic ACL clearing** - No more script execution permission issues
- **Enhanced Configuration Profile parsing** - Actual company names displayed
- **Future-proof version detection** - Automatic compatibility with all v2.x+ versions
- **Improved Smart Group data format** - Reliable population and automation

### v2.3.0 Foundation Features
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

# Verify package signature
pkgutil --check-signature JamfConnectMonitor-2.3.0.pkg

# Check disk space
df -h /usr/local
```

#### ACL Permission Issues (Fixed automatically in v2.3.0)
```bash
# Manual fix if automated clearing fails:
sudo xattr -c /usr/local/bin/jamf_connect_monitor.sh
sudo xattr -c /usr/local/etc/jamf_ea_admin_violations.sh

# Verify no ACLs remain:
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
# Should show: -rwxr-xr-x (no @ symbol)
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
ls -la@ /usr/local/etc/jamf_ea_admin_violations.sh
# Should be: -rwxr-xr-x root wheel (no @ symbol)

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

## Migration from v1.x to v2.3.0

### Automatic Migration Process
v2.3.0 automatically preserves existing v1.x configurations:
- **Approved Admin Lists** - Maintained during upgrade
- **Historical Logs** - Preserved with new v2.x logging enhancements
- **LaunchDaemon Settings** - Updated with backward compatibility

### Enhanced Features After Migration
After upgrading to v2.3.0, deploy Configuration Profile to enable:
- **Centralized webhook/email management**
- **Real-time monitoring capabilities**
- **Enhanced notification templates**
- **Advanced Smart Group integration**
- **Automatic ACL clearing**
- **Enhanced Configuration Profile parsing**

### Migration Validation
```bash
# Verify v1.x settings preserved
cat /usr/local/etc/approved_admins.txt

# Check upgrade status
sudo jamf_connect_monitor.sh status | grep "Version: 2.3.0"

# Test Configuration Profile integration
sudo jamf_connect_monitor.sh test-config

# Verify ACL clearing worked
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
# Should show no @ symbol
```

## Best Practices

### Security Recommendations
- **Deploy Configuration Profiles** immediately after package installation
- **Configure webhook notifications** for immediate violation alerts
- **Create Smart Groups** for automated incident response
- **Monitor "CRITICAL VIOLATIONS"** Smart Group daily (should be 0)
- **Use flexible Smart Group criteria** ("Version: 2.") for future compatibility

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
- **Future-proof Smart Group criteria** to automatically include newer versions

---

## Next Steps After Installation

1. **Verify Smart Group Population** - Check Extension Attribute data in Jamf Pro shows "Version: 2.3.0"
2. **Test Notification Delivery** - Configure and test webhook/email alerts
3. **Validate Configuration Profile Integration** - Ensure actual company names display
4. **Monitor System Performance** - Track resource usage with real-time monitoring
5. **Plan Fleet Rollout** - Expand from pilot to full deployment
6. **Configure Advanced Features** - Enable department-specific settings

---

**Installation Complete!** 

You now have enterprise-grade security monitoring with enhanced Configuration Profile management, automatic ACL clearing, future-proof version detection, and comprehensive Jamf Pro integration.

---

**Created with ❤️ by MacJediWizard**