# Jamf Connect Privilege Monitor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Jamf Pro Compatible](https://img.shields.io/badge/Jamf%20Pro-10.27%2B-blue.svg)](https://jamf.com)
[![macOS Compatible](https://img.shields.io/badge/macOS-10.14%2B-blue.svg)](https://apple.com/macos)

A comprehensive monitoring and automated remediation system for Jamf Connect privilege elevation events. Automatically detects and removes unauthorized admin accounts while maintaining detailed audit trails.

## 🚀 Features

- **Real-time Monitoring**: Continuously monitors Jamf Connect elevation events
- **Automated Remediation**: Automatically removes unauthorized admin privileges
- **Comprehensive Logging**: Detailed audit trails of all elevation and violation events
- **Jamf Pro Integration**: Extension Attribute for reporting and Smart Group automation
- **Zero User Interaction**: Silent deployment and operation
- **Notification Support**: Slack/Teams webhook and email notifications
- **Whitelist Management**: Configurable approved administrator list

## 📋 Requirements

- macOS 10.14 or later
- Jamf Connect 2.33.0 or later with privilege elevation enabled
- Jamf Pro 10.27 or later (recommended)
- Root/administrator access for installation

## 🔧 Quick Installation

### Option 1: One-Click Deployment (Recommended)
```bash
# Download and run the deployment script
curl -o deployment_script.sh https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest/download/deployment_script.sh
sudo chmod +x deployment_script.sh
sudo ./deployment_script.sh interactive
```

### Option 2: Package for Jamf Pro
1. Download the latest `.pkg` from [Releases](https://github.com/MacJediWizard/jamf-connect-monitor/releases)
2. Upload to Jamf Pro
3. Deploy via policy (see [Jamf Pro Deployment Guide](docs/jamf-pro-deployment.md))

### Option 3: Manual Installation
```bash
# Clone the repository
git clone https://github.com/MacJediWizard/jamf-connect-monitor.git
cd jamf-connect-monitor

# Build deployment package
sudo ./scripts/package_creation_script.sh build

# Install the generated package
sudo installer -pkg output/JamfConnectMonitor-1.0.1.pkg -target /
```

## 📖 Documentation

- [Complete Installation Guide](docs/installation-guide.md)
- [Jamf Pro Deployment Guide](docs/jamf-pro-deployment.md)
- [Configuration Options](docs/configuration.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Uninstall Guide](docs/uninstall-guide.md)
- [CLI Reference](docs/cli-reference.md)

## 🛠️ Usage

### Command Line Interface
```bash
# Check current status
sudo jamf_connect_monitor.sh status

# Add approved admin
sudo jamf_connect_monitor.sh add-admin username

# Remove approved admin
sudo jamf_connect_monitor.sh remove-admin username

# Force immediate check
sudo jamf_connect_monitor.sh force-check
```

### Jamf Pro Integration

Create an Extension Attribute with the provided script:
- Navigate to Settings → Computer Management → Extension Attributes
- Use the script from `jamf/extension-attribute.sh`
- Create Smart Groups based on violation status

## 📊 Monitoring

### Log Locations
- **Main Activity**: `/var/log/jamf_connect_monitor/monitor.log`
- **Violations**: `/var/log/jamf_connect_monitor/admin_violations.log`
- **Jamf Connect Events**: `/var/log/jamf_connect_monitor/jamf_connect_events.log`

### Real-time Monitoring
```bash
# Watch main activity
tail -f /var/log/jamf_connect_monitor/monitor.log

# Watch for violations
tail -f /var/log/jamf_connect_monitor/admin_violations.log
```

## ⚙️ Configuration

### Basic Configuration
```bash
# Edit approved admin list
sudo nano /usr/local/etc/approved_admins.txt

# Configure notifications (optional)
sudo nano /usr/local/etc/jamf_connect_monitor.conf
```

### Advanced Configuration
- **Monitoring Interval**: Modify LaunchDaemon (default: 5 minutes)
- **Webhook Notifications**: Add Slack/Teams webhook URL
- **Email Alerts**: Configure SMTP settings
- **Company Branding**: Customize company name and settings

## 🔐 Security Features

- ✅ **Whitelisting**: Only pre-approved users can have admin rights
- ✅ **Audit Trail**: Complete logging of all elevation events and violations
- ✅ **Real-time Response**: Immediate detection and remediation
- ✅ **SIEM Ready**: Structured logging for security information systems
- ✅ **Tamper Resistant**: Runs as root with proper permission controls

## 📈 What Happens When Violations Occur

1. **Detection**: Script detects unauthorized admin account
2. **Logging**: Creates detailed violation report with timestamps
3. **Notification**: Sends alerts via configured channels (Slack/Email)
4. **Remediation**: Automatically removes admin privileges
5. **Reporting**: Updates Jamf Pro Extension Attribute for visibility

## 🗑️ Uninstallation

```bash
# Download uninstall script
curl -o uninstall_script.sh https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest/download/uninstall_script.sh
sudo chmod +x uninstall_script.sh

# Interactive uninstall
sudo ./uninstall_script.sh

# OR use included uninstaller
sudo /usr/local/share/jamf_connect_monitor/uninstall_script.sh --force
```

Complete removal guide: [Uninstall Guide](docs/uninstall-guide.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/MacJediWizard/jamf-connect-monitor/issues)
- **Documentation**: [Complete Guides](https://github.com/MacJediWizard/jamf-connect-monitor/tree/main/docs)

## ⭐ Acknowledgments

- Jamf Community for Extension Attribute examples
- Apple System Administrators community
- Open source contributors and testers

## 🏷️ Badges

![GitHub release (latest by date)](https://img.shields.io/github/v/release/MacJediWizard/jamf-connect-monitor)
![GitHub all releases](https://img.shields.io/github/downloads/MacJediWizard/jamf-connect-monitor/total)
![GitHub issues](https://img.shields.io/github/issues/MacJediWizard/jamf-connect-monitor)
![GitHub stars](https://img.shields.io/github/stars/MacJediWizard/jamf-connect-monitor?style=social)

---

**Made with ❤️ for the macOS Administrator community**
---

Created with ❤️ by MacJediWizard
