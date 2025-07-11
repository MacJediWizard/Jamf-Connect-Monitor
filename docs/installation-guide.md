# Jamf Connect Monitor - Complete Installation Guide

## Overview
This guide provides comprehensive installation instructions for deploying Jamf Connect Monitor across your macOS fleet.

## Prerequisites

### System Requirements
- **macOS**: 10.14 (Mojave) or later
- **Jamf Connect**: 2.33.0 or later with privilege elevation enabled
- **Jamf Pro**: 10.27 or later (recommended for full integration)
- **Administrative Access**: Required for installation

## Installation Methods

### Method 1: Jamf Pro Deployment (Recommended)

#### Step 1: Download Package
1. Go to [GitHub Releases](https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest)
2. Download `JamfConnectMonitor-1.0.pkg` (20KB)
3. Download `JamfConnectMonitor-1.0.pkg.sha256` for verification

#### Step 2: Verify Package Integrity
```bash
# Verify package checksum
shasum -a 256 -c JamfConnectMonitor-1.0.pkg.sha256
```

#### Step 3: Upload to Jamf Pro
1. **Navigate to Packages:**
   - Settings → Computer Management → Packages
   - Click "New"

2. **Package Configuration:**
   ```
   Display Name: Jamf Connect Monitor
   Category: Security
   Priority: 10
   Description: "Monitors Jamf Connect privilege elevations"
   ```

3. **Upload Package** and save

#### Step 4: Create Extension Attribute
1. **Navigate to Extension Attributes:**
   - Settings → Computer Management → Extension Attributes
   - Click "New"

2. **Configuration:**
   ```
   Display Name: Admin Account Violations
   Description: Monitors unauthorized admin account violations
   Data Type: String
   Input Type: Script
   ```

3. **Script Content:** Copy from `jamf/extension-attribute.sh`

#### Step 5: Create Deployment Policy
1. **General Settings:**
   ```
   Display Name: Deploy Jamf Connect Monitor
   Category: Security
   Trigger: Enrollment Complete, Recurring Check-in
   Execution Frequency: Once per computer
   ```

2. **Packages:** Add "Jamf Connect Monitor"

3. **Scope:** Target Jamf Connect devices

### Method 2: Manual Installation

```bash
# Download package
curl -LO https://github.com/MacJediWizard/jamf-connect-monitor/releases/download/v1.0.0/JamfConnectMonitor-1.0.pkg

# Install package
sudo installer -pkg JamfConnectMonitor-1.0.pkg -target /

# Verify installation
sudo jamf_connect_monitor.sh status
```

### Method 3: One-Click Deployment Script

```bash
# Download deployment script
curl -LO https://github.com/MacJediWizard/jamf-connect-monitor/releases/download/v1.0.0/deployment_script.sh

# Run interactive installation
sudo ./deployment_script.sh interactive
```

## Post-Installation Configuration

### Verify Installation
```bash
# Check installation status
sudo jamf_connect_monitor.sh status

# Verify daemon is running
sudo launchctl list | grep jamfconnectmonitor

# Check log files
ls -la /var/log/jamf_connect_monitor/
```

### Configure Approved Administrators
```bash
# View current approved list
cat /usr/local/etc/approved_admins.txt

# Add approved admin
sudo jamf_connect_monitor.sh add-admin username

# Remove admin from approved list
sudo jamf_connect_monitor.sh remove-admin username
```

## Troubleshooting Installation

### Common Issues

#### Issue: Package Installation Fails
```bash
# Check installer logs
tail -f /var/log/install.log

# Verify package integrity
pkgutil --check-signature JamfConnectMonitor-1.0.pkg
```

#### Issue: Daemon Not Starting
```bash
# Check daemon syntax
plutil -lint /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Load daemon manually
sudo launchctl load /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
```

#### Issue: Extension Attribute Not Populating
```bash
# Test EA script manually
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Force inventory update
sudo jamf recon
```

---

**Created with ❤️ by MacJediWizard**
