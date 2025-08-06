# Jamf Connect Privilege Monitor v2.0.1

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Jamf Pro Compatible](https://img.shields.io/badge/Jamf%20Pro-10.19%2B-blue.svg)](https://jamf.com)
[![macOS Compatible](https://img.shields.io/badge/macOS-10.14%2B-blue.svg)](https://apple.com/macos)
[![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-green.svg)](https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest)

A comprehensive monitoring and automated remediation system for Jamf Connect privilege elevation events with **enterprise Configuration Profile management** and **real-time detection capabilities**.

## 🎯 **v2.0.1 Production Ready - All Critical Fixes Verified**

**✅ ENTERPRISE TESTED:** All critical issues resolved and verified working in Success Academies production environment  
**✅ ACL CLEARING:** Fixed script execution permissions with comprehensive Extended Attribute cleanup  
**✅ CONFIGURATION PROFILE:** Standardized reading methods - shows actual company names instead of "Your Company"  
**✅ AUTO-VERSION DETECTION:** Future-proof version management - works automatically with all v2.x+ releases  
**✅ VERIFICATION TOOLS:** New production validation script for enterprise deployment confidence  

## 🚀 **What's Fixed in v2.0.1**

### **Critical Production Fixes**
- **✅ ACL Clearing** - Eliminates `@` symbols in file permissions preventing script execution
- **✅ Configuration Profile Integration** - Company names display correctly (e.g., "Success Academies" not "Your Company")  
- **✅ Extension Attribute Auto-Detection** - Version displays as "Version: 2.0.1" automatically
- **✅ Smart Group Compatibility** - Enhanced data format ensures proper population
- **✅ Future-Proof Architecture** - Works automatically with v2.0.2, v2.1.0, v3.0.0+ without updates

### **New Production Tools**
- **🔧 tools/verify_monitoring.sh** - Comprehensive deployment verification script
- **🗑️ Enhanced Uninstall Script** - Complete system removal with configuration backup
- **📊 Production Validation** - All fixes verified in enterprise Jamf Pro environment

## 🌟 **Features**

- **Real-time & Periodic Monitoring** - Choose immediate or 5-minute interval detection
- **Configuration Profile Management** - No more hardcoded credentials in scripts
- **Automated Remediation** - Instantly removes unauthorized admin privileges
- **Enterprise Notifications** - Slack/Teams webhooks and email with professional templates
- **Comprehensive Logging** - Detailed audit trails of all elevation and violation events
- **Jamf Pro Integration** - Extension Attributes, Smart Groups, and automated policies
- **Zero User Interaction** - Silent deployment and operation across your fleet
- **Production Verification** - Built-in tools to validate deployment success

## 📋 **Requirements**

- macOS 10.14 or later
- Jamf Connect 2.33.0 or later with privilege elevation enabled
- Jamf Pro 10.19 or later (for Configuration Profile JSON Schema support)
- Root/administrator access for installation

## 🔧 **Quick Installation**

### Option 1: Package for Jamf Pro (Recommended)
1. Download the latest `.pkg` from [Releases](https://github.com/MacJediWizard/jamf-connect-monitor/releases)
2. Upload to Jamf Pro and deploy via policy
3. Deploy Configuration Profile using included JSON Schema
4. **CRITICAL:** Update Extension Attribute script in Jamf Pro for v2.0.1 features
5. Verify deployment with included verification script
6. See [Jamf Pro Deployment Guide](docs/jamf-pro-deployment.md) for details

### Option 2: Manual Build and Deploy
```bash
# Clone the repository
git clone https://github.com/MacJediWizard/jamf-connect-monitor.git
cd jamf-connect-monitor

# Build deployment package
sudo ./scripts/package_creation_script.sh build

# Install the generated package
sudo installer -pkg output/JamfConnectMonitor-2.0.1.pkg -target /

# Verify installation
sudo ./tools/verify_monitoring.sh
```

### Post-Installation Verification
```bash
# Verify all components are working correctly
sudo ./tools/verify_monitoring.sh

# Expected output includes:
# ✅ Main script installed: Version 2.0.1
# ✅ Permissions correct: -rwxr-xr-x (no @ symbols)
# ✅ Extension Attribute runs successfully
# ✅ Version detected: Version: 2.0.1, Periodic: Running
# ✅ Company name: [Your Company Name] (from Configuration Profile)
```

## 📱 **Configuration Profile Deployment**

### Jamf Pro Application & Custom Settings
1. **Navigate:** Computer Management → Configuration Profiles → New
2. **Add Payload:** Application & Custom Settings
3. **Source:** Custom Schema
4. **Preference Domain:** `com.macjediwizard.jamfconnectmonitor`
5. **Upload Schema:** Use `jamf_connect_monitor_schema.json` from package
6. **Configure Settings:** Webhook URLs, email recipients, monitoring modes

### Example Configuration
```json
{
  "NotificationSettings": {
    "WebhookURL": "https://hooks.slack.com/services/YOUR/WEBHOOK",
    "EmailRecipient": "security@yourcompany.com",
    "NotificationTemplate": "security_report"
  },
  "MonitoringBehavior": {
    "MonitoringMode": "realtime",
    "AutoRemediation": true,
    "GracePeriodMinutes": 5
  },
  "JamfProIntegration": {
    "CompanyName": "Your Company",
    "ITContactEmail": "ithelp@yourcompany.com"
  }
}
```

### Configuration Profile Verification
```bash
# Test Configuration Profile integration
sudo jamf_connect_monitor.sh test-config

# Expected output shows your actual settings:
# Company Name: Your Company (not "Your Company" fallback)
# Webhook: Configured
# Email: yourcompany@domain.com
# Monitoring Mode: realtime
```

## 🛠️ **Usage**

### Command Line Interface
```bash
# Check current status with Configuration Profile info
sudo jamf_connect_monitor.sh status

# Test Configuration Profile settings (v2.0.1 feature)
sudo jamf_connect_monitor.sh test-config

# Manage approved admins
sudo jamf_connect_monitor.sh add-admin username
sudo jamf_connect_monitor.sh remove-admin username

# Force immediate violation check
sudo jamf_connect_monitor.sh force-check

# Verify all components (v2.0.1 tool)
sudo ./tools/verify_monitoring.sh
```

### Monitoring Modes
- **Periodic** - Traditional 5-minute interval checking
- **Real-time** - Immediate violation detection using log streaming
- **Hybrid** - Both periodic and real-time monitoring for maximum coverage

## 📊 **Jamf Pro Integration**

### Extension Attribute (Enhanced in v2.0.1)
Creates comprehensive reporting in Jamf Pro computer records:
- **Auto-Version Detection** - Shows "Version: 2.0.1" automatically
- **Configuration Profile Status** - "Profile: Deployed" with actual company names
- **Monitoring Mode Display** - "Mode: periodic" (fixed in v2.0.1)
- **Violation History** - Current unauthorized admins with detailed tracking
- **Jamf Connect Integration** - Status monitoring and health metrics
- **System Health** - ACL clearing verification and permission validation

### Smart Groups (Future-Proof Design)
Automatic device grouping with flexible criteria:
- **Critical Violations** - `Extension Attribute like "*Unauthorized:*" AND not like "*Unauthorized: 0*"`
- **v2.x Installations** - `Extension Attribute like "*Version: 2.*"` (catches all v2.x versions)
- **Configuration Status** - `Extension Attribute like "*Profile: Deployed*"`
- **Real-time Monitoring** - `Extension Attribute like "*Mode: realtime*"`
- **Health Status** - `Extension Attribute like "*Daemon: Healthy*"`

### Automated Workflows
- **Violation Detection** → **Smart Group Membership** → **Policy Triggers** → **Automated Response**
- **Configuration Updates** → **Immediate Application** → **Inventory Updates** → **Reporting**
- **Version Updates** → **Automatic Smart Group Population** → **Zero Maintenance Required**

## 📈 **Monitoring**

### Log Locations
- **Main Activity**: `/var/log/jamf_connect_monitor/monitor.log`
- **Violations**: `/var/log/jamf_connect_monitor/admin_violations.log`
- **Real-time Events**: `/var/log/jamf_connect_monitor/realtime_monitor.log`
- **Jamf Connect Events**: `/var/log/jamf_connect_monitor/jamf_connect_events.log`

### Real-time Monitoring
```bash
# Watch main activity
tail -f /var/log/jamf_connect_monitor/monitor.log

# Monitor real-time violations
tail -f /var/log/jamf_connect_monitor/realtime_monitor.log

# Check Extension Attribute output
sudo /usr/local/etc/jamf_ea_admin_violations.sh
```

## ⚙️ **Configuration**

### Configuration Profile Management (v2.0.0+)
All settings managed centrally via Jamf Pro Configuration Profiles:
- **Notification Settings** - Webhook URLs, email recipients, templates
- **Monitoring Behavior** - Real-time vs periodic, auto-remediation, grace periods
- **Security Settings** - Violation reporting, log retention, excluded accounts
- **Jamf Pro Integration** - Company branding, inventory updates, policy triggers

### Legacy Configuration (v1.x compatibility)
```bash
# Manual approved admin management (still supported)
sudo nano /usr/local/etc/approved_admins.txt
```

## 🔐 **Security Features**

- ✅ **Configuration Profile Encryption** - Secure credential management via Jamf Pro
- ✅ **Real-time Detection** - Immediate response to unauthorized elevations
- ✅ **Audit Trail** - Complete logging of all elevation events and violations
- ✅ **Tamper Resistant** - Root privilege requirement with protected configurations
- ✅ **SIEM Ready** - Structured logging for security information systems
- ✅ **Automated Response** - Zero-touch violation remediation
- ✅ **ACL Security** - Extended Attribute clearing prevents permission bypass

## 📈 **What Happens During Violations**

1. **Detection** - Real-time or periodic detection of unauthorized admin account
2. **Grace Period** - Configurable wait time for legitimate temporary elevation
3. **Remediation** - Automatic removal of admin privileges (if enabled)
4. **Notification** - Immediate alerts via configured Slack/Teams/email channels
5. **Logging** - Detailed violation report with system context and user information
6. **Jamf Pro Update** - Extension Attribute updates for Smart Group automation
7. **Policy Triggers** - Optional additional policy execution for incident response

## 🔧 **Production Verification Tools (New in v2.0.1)**

### Comprehensive Deployment Validation
```bash
# Run complete verification after installation
sudo ./tools/verify_monitoring.sh

# What it tests:
✅ Main script installation and version detection
✅ Extension Attribute script execution and permissions  
✅ ACL clearing verification (no @ symbols in permissions)
✅ Configuration Profile integration and company name display
✅ Version auto-detection functionality
✅ Monitoring mode detection accuracy
```

### Verification Output Example
```bash
🔍 JAMF CONNECT MONITOR VERIFICATION v2.0.1
✅ Main script installed: Version 2.0.1
✅ Permissions correct: -rwxr-xr-x
✅ Extension Attribute script installed: Version 2.0.1
✅ EA permissions correct: -rwxr-xr-x (no @ symbols)
✅ Extension Attribute runs successfully
✅ Version detected: Version: 2.0.1, Periodic: Running
✅ Monitoring mode detected: Mode: periodic
✅ Company name: Success Academies (from Configuration Profile)
🎉 MONITORING APPEARS TO BE WORKING CORRECTLY
```

## 🗑️ **Complete Uninstallation (Enhanced in v2.0.1)**

### Quick Uninstall
```bash
# Download and run enhanced uninstall script
curl -o uninstall_script.sh https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest/download/uninstall_script.sh
sudo chmod +x uninstall_script.sh

# Interactive uninstall with configuration backup
sudo ./uninstall_script.sh

# Silent uninstall for mass deployment
sudo ./uninstall_script.sh --force

# Verify complete removal
sudo ./uninstall_script.sh verify
```

### Enhanced Uninstall Features
- **✅ Complete Component Removal** - All scripts, daemons, logs, and configurations
- **✅ Configuration Backup** - Approved admin lists preserved with `.uninstall_backup` suffix
- **✅ Log Archiving** - All monitoring logs archived before removal
- **✅ ACL Cleanup** - Extended Attributes and permissions fully restored
- **✅ Package Receipt Cleanup** - All installer receipts removed from system database
- **✅ Jamf Pro Integration** - Inventory update triggered after removal
- **✅ Verification Mode** - Confirm complete removal with detailed validation

Complete removal guide: [Uninstall Guide](docs/uninstall-guide.md)

## 📖 **Documentation**

- [Installation Guide](docs/installation-guide.md) - Complete deployment instructions with v2.0.1 verification
- [Jamf Pro Deployment Guide](docs/jamf-pro-deployment.md) - Enterprise deployment strategies
- [Configuration Profile Guide](docs/configuration-profiles.md) - Centralized management setup
- [CLI Reference](docs/cli-reference.md) - Command line interface documentation
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions including ACL problems
- [Smart Groups Guide](docs/smart-groups.md) - Jamf Pro automation setup with future-proof criteria
- [Migration Guide](docs/migration-guide.md) - v1.x to v2.x upgrade instructions

## 🚀 **Migration to v2.0.1**

### From v2.0.0 (Seamless Upgrade)
```bash
# 1. Upload v2.0.1 package to Jamf Pro
# 2. Update Extension Attribute script (CRITICAL for version display)
# 3. Deploy to existing v2.0.0 systems
# 4. Run verification: sudo ./tools/verify_monitoring.sh
# 5. Verify Smart Groups populate with enhanced data
```

### From v1.x (Recommended Path)
The v2.0.1 package automatically migrates existing v1.x installations while preserving:
- Approved administrator lists
- Historical violation logs  
- Monitoring configuration preferences

### New Configuration Profile Features
After upgrade, deploy Configuration Profile to enable:
- Centralized webhook/email management
- Real-time monitoring capabilities
- Enhanced notification templates
- Advanced security settings

See [Migration Guide](docs/migration-guide.md) for detailed upgrade instructions.

## 🎯 **Enterprise Deployment Checklist**

### Critical Steps for v2.0.1 Production Deployment
- [ ] **Upload Package** - Deploy JamfConnectMonitor-2.0.1.pkg to Jamf Pro
- [ ] **Update Extension Attribute** - MOST CRITICAL: Apply v2.0.1 script for proper version display
- [ ] **Deploy Configuration Profile** - Use included JSON Schema for centralized management
- [ ] **Create Smart Groups** - Use future-proof criteria: `Extension Attribute like "*Version: 2.*"`
- [ ] **Test on Pilot Group** - Deploy to 2-3 test systems first
- [ ] **Run Verification** - Use `sudo ./tools/verify_monitoring.sh` on pilot systems
- [ ] **Force Inventory Update** - Run `sudo jamf recon` on pilot systems
- [ ] **Verify Extension Attribute** - Check Jamf Pro computer records show correct v2.0.1 data
- [ ] **Full Fleet Deployment** - Deploy to production after pilot validation

### Expected Results After Deployment
```bash
# Extension Attribute Data in Jamf Pro:
Version: 2.0.1, Periodic: Running, Real-time: Not Running
Configuration: Profile: Deployed, Webhook: [Configured/Not Configured], Email: [your-email], Mode: periodic, Company: [Your Company Name]
Violations: Total: 0, Recent: 0, Last: None, Unauthorized: 0
Admin Status: Current: [admin,user1], Approved: [admin,user1]
Jamf Connect: Installed: Yes, Elevation: Yes, Monitoring: Yes
Health: Last Check: [timestamp], Daemon: Healthy, Logs: [size], Config Test: OK
```

## 🤝 **Contributing**

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 **Changelog**

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes and upgrade notes.

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 **Support**

- **Issues**: [GitHub Issues](https://github.com/MacJediWizard/jamf-connect-monitor/issues)
- **Documentation**: [Complete Guides](https://github.com/MacJediWizard/jamf-connect-monitor/tree/main/docs)
- **Discussions**: [GitHub Discussions](https://github.com/MacJediWizard/jamf-connect-monitor/discussions)
- **Production Support**: Use included `tools/verify_monitoring.sh` for immediate diagnostics

## ⭐ **Acknowledgments**

- Jamf Community for Extension Attribute examples and Configuration Profile best practices
- Apple System Administrators community for security monitoring guidance
- Open source contributors and beta testers from the macOS enterprise community
- **Success Academies** for enterprise environment testing and validation

## 🏷️ **Project Status**

![GitHub release (latest by date)](https://img.shields.io/github/v/release/MacJediWizard/jamf-connect-monitor)
![GitHub all releases](https://img.shields.io/github/downloads/MacJediWizard/jamf-connect-monitor/total)
![GitHub issues](https://img.shields.io/github/issues/MacJediWizard/jamf-connect-monitor)
![GitHub stars](https://img.shields.io/github/stars/MacJediWizard/jamf-connect-monitor?style=social)

## 🎉 **Production Ready Status**

**✅ v2.0.1 VERIFIED WORKING IN ENTERPRISE ENVIRONMENT**

- **Enterprise Tested:** Success Academies production environment
- **All Critical Fixes Applied:** ACL clearing, Configuration Profile integration, auto-version detection
- **Verification Tools Included:** Complete diagnostic and validation scripts
- **Future-Proof Design:** Works automatically with all future v2.x+ versions
- **Zero Maintenance:** Smart Groups and Extension Attributes update automatically

---

**Made with ❤️ for the macOS Administrator community**

**Enterprise-grade security monitoring with Configuration Profile management, real-time detection capabilities, and production-verified reliability.**

---

Created with ❤️ by MacJediWizard