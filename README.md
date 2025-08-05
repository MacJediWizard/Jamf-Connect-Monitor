# Jamf Connect Privilege Monitor v2.0.1

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Jamf Pro Compatible](https://img.shields.io/badge/Jamf%20Pro-10.19%2B-blue.svg)](https://jamf.com)
[![macOS Compatible](https://img.shields.io/badge/macOS-10.14%2B-blue.svg)](https://apple.com/macos)

A comprehensive monitoring and automated remediation system for Jamf Connect privilege elevation events with **enterprise Configuration Profile management** and **real-time detection capabilities**.

## 🚀 **New in v2.0.1**

- **Enhanced Configuration Profile Parsing** - Fixed empty monitoring mode display in Extension Attribute
- **Improved Smart Group Compatibility** - Reliable population with robust plist format handling
- **Better Extension Attribute Data** - Multiple fallback strategies ensure consistent reporting
- **Seamless v2.0.0 Upgrade** - Automatic upgrade preserving all existing configurations

## 🌟 **Features**

- **Real-time & Periodic Monitoring** - Choose immediate or 5-minute interval detection
- **Configuration Profile Management** - No more hardcoded credentials in scripts
- **Automated Remediation** - Instantly removes unauthorized admin privileges
- **Enterprise Notifications** - Slack/Teams webhooks and email with professional templates
- **Comprehensive Logging** - Detailed audit trails of all elevation and violation events
- **Jamf Pro Integration** - Extension Attributes, Smart Groups, and automated policies
- **Zero User Interaction** - Silent deployment and operation across your fleet

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
4. See [Jamf Pro Deployment Guide](docs/jamf-pro-deployment.md) for details

### Option 2: Manual Build and Deploy
```bash
# Clone the repository
git clone https://github.com/MacJediWizard/jamf-connect-monitor.git
cd jamf-connect-monitor

# Build deployment package
sudo ./scripts/package_creation_script.sh build

# Install the generated package
sudo installer -pkg output/JamfConnectMonitor-2.0.1.pkg -target /
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

## 🛠️ **Usage**

### Command Line Interface
```bash
# Check current status with Configuration Profile info
sudo jamf_connect_monitor.sh status

# Test Configuration Profile settings
sudo jamf_connect_monitor.sh test-config

# Manage approved admins
sudo jamf_connect_monitor.sh add-admin username
sudo jamf_connect_monitor.sh remove-admin username

# Force immediate violation check
sudo jamf_connect_monitor.sh force-check
```

### Monitoring Modes
- **Periodic** - Traditional 5-minute interval checking
- **Real-time** - Immediate violation detection using log streaming
- **Hybrid** - Both periodic and real-time monitoring for maximum coverage

## 📊 **Jamf Pro Integration**

### Extension Attribute
Creates comprehensive reporting in Jamf Pro computer records:
- Monitoring status and version
- Configuration Profile deployment status
- Violation history and current unauthorized admins
- Jamf Connect integration status
- System health metrics

### Smart Groups
Automatic device grouping for:
- **Critical Violations** - Immediate security attention required
- **Configuration Status** - Profile deployment tracking
- **Monitoring Modes** - Real-time vs periodic deployment
- **Health Status** - System maintenance requirements

### Automated Workflows
- **Violation Detection** → **Smart Group Membership** → **Policy Triggers** → **Automated Response**
- **Configuration Updates** → **Immediate Application** → **Inventory Updates** → **Reporting**

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
# Manual approved admin management
sudo nano /usr/local/etc/approved_admins.txt
```

## 🔐 **Security Features**

- ✅ **Configuration Profile Encryption** - Secure credential management via Jamf Pro
- ✅ **Real-time Detection** - Immediate response to unauthorized elevations
- ✅ **Audit Trail** - Complete logging of all elevation events and violations
- ✅ **Tamper Resistant** - Root privilege requirement with protected configurations
- ✅ **SIEM Ready** - Structured logging for security information systems
- ✅ **Automated Response** - Zero-touch violation remediation

## 📈 **What Happens During Violations**

1. **Detection** - Real-time or periodic detection of unauthorized admin account
2. **Grace Period** - Configurable wait time for legitimate temporary elevation
3. **Remediation** - Automatic removal of admin privileges (if enabled)
4. **Notification** - Immediate alerts via configured Slack/Teams/email channels
5. **Logging** - Detailed violation report with system context and user information
6. **Jamf Pro Update** - Extension Attribute updates for Smart Group automation
7. **Policy Triggers** - Optional additional policy execution for incident response

## 🗑️ **Uninstallation**

```bash
# Download and run uninstall script
curl -o uninstall_script.sh https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest/download/uninstall_script.sh
sudo chmod +x uninstall_script.sh

# Interactive uninstall with configuration backup
sudo ./uninstall_script.sh

# Silent uninstall for mass deployment
sudo ./uninstall_script.sh --force
```

Complete removal guide: [Uninstall Guide](docs/uninstall-guide.md)

## 📖 **Documentation**

- [Installation Guide](docs/installation-guide.md) - Complete deployment instructions
- [Jamf Pro Deployment Guide](docs/jamf-pro-deployment.md) - Enterprise deployment strategies
- [Configuration Profile Guide](docs/configuration-profiles.md) - Centralized management setup
- [CLI Reference](docs/cli-reference.md) - Command line interface documentation
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions
- [Smart Groups Guide](docs/smart-groups.md) - Jamf Pro automation setup

## 🚀 **Migration from v1.x to v2.0.1**

### Automatic Upgrade
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

## ⭐ **Acknowledgments**

- Jamf Community for Extension Attribute examples and Configuration Profile best practices
- Apple System Administrators community for security monitoring guidance
- Open source contributors and beta testers from the macOS enterprise community

## 🏷️ **Project Status**

![GitHub release (latest by date)](https://img.shields.io/github/v/release/MacJediWizard/jamf-connect-monitor)
![GitHub all releases](https://img.shields.io/github/downloads/MacJediWizard/jamf-connect-monitor/total)
![GitHub issues](https://img.shields.io/github/issues/MacJediWizard/jamf-connect-monitor)
![GitHub stars](https://img.shields.io/github/stars/MacJediWizard/jamf-connect-monitor?style=social)

---

**Made with ❤️ for the macOS Administrator community**

**Enterprise-grade security monitoring with Configuration Profile management and real-time detection capabilities.**

---

Created with ❤️ by MacJediWizard