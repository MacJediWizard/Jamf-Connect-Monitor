# Complete Jamf Pro Silent Deployment Guide

## Overview
This guide provides everything needed to deploy Jamf Connect Monitor silently across your fleet with zero user interaction.

## What You Need to Deploy

### 1. **Required Files** (Create these first)
```
deployment_files/
├── jamf_connect_monitor.sh          # Main monitoring script
├── preinstall_script.sh             # Pre-installation tasks
├── postinstall_script.sh            # Post-installation configuration
├── jamf_ea_admin_violations.sh      # Extension Attribute script
├── package_creation_script.sh       # Package builder
└── README.md                        # This guide
```

### 2. **Package Creation Process**
```bash
# 1. Place all required files in a directory
# 2. Run the package creation script
sudo ./package_creation_script.sh build

# This creates:
# - JamfConnectMonitor-1.0.pkg (main package)
# - JamfConnectMonitor-1.0.pkg.sha256 (checksum)
# - Jamf_Pro_Deployment_Instructions.txt
```

## Jamf Pro Configuration (Step-by-Step)

### Step 1: Upload Package to Jamf Pro

1. **Navigate to Packages:**
   - Settings → Computer Management → Packages
   - Click "New"

2. **Package Upload:**
   - Upload: `JamfConnectMonitor-1.0.pkg`
   - Display Name: "Jamf Connect Monitor"
   - Category: "Security" or "Utilities"
   - Priority: 10
   - Fill in Description, Notes

3. **Save Package**

### Step 2: Create Extension Attribute

1. **Navigate to Extension Attributes:**
   - Settings → Computer Management → Extension Attributes
   - Click "New"

2. **Extension Attribute Settings:**
   ```
   Display Name: Admin Account Violations
   Description: Monitors unauthorized admin account creation and violations
   Data Type: String
   Inventory Display: Extension Attributes
   Input Type: Script
   ```

3. **Script Content:**
   - Copy the entire content from `jamf_ea_admin_violations.sh`
   - Paste into the Script field

4. **Save Extension Attribute**

### Step 3: Create Smart Groups

#### Smart Group 1: Installed Monitoring
```
Name: Jamf Connect Monitor - Installed
Criteria:
- Admin Account Violations | is not | Not configured
- Admin Account Violations | is not | Not monitored
```

#### Smart Group 2: Violations Detected
```
Name: Jamf Connect Monitor - Violations
Criteria:
- Admin Account Violations | contains | Unauthorized Admins:
- Admin Account Violations | does not contain | None
```

#### Smart Group 3: Jamf Connect Users (Target Group)
```
Name: Jamf Connect Devices
Criteria:
- Application Title | is | Jamf Connect.app
- Operating System Version | greater than or equal | 10.14
```

### Step 4: Create Deployment Policy

1. **General Settings:**
   ```
   Display Name: Deploy Jamf Connect Monitor
   Category: Security
   Trigger: Enrollment Complete, Recurring Check-in
   Execution Frequency: Once per computer
   ```

2. **Packages:**
   - Add Package: "Jamf Connect Monitor"
   - Action: Install

3. **Scripts (Optional - for Configuration):**
   If you want to customize settings via parameters:
   ```
   Parameter 4 ($4): Webhook URL (e.g., https://hooks.slack.com/services/...)
   Parameter 5 ($5): Email recipient (e.g., security@company.com)
   Parameter 6 ($6): Monitoring interval in seconds (default: 300)
   Parameter 7 ($7): Company name (e.g., YourCompany)
   ```

4. **Scope:**
   - Target: "Jamf Connect Devices" smart group
   - Exclusions: "Jamf Connect Monitor - Installed" smart group

5. **Maintenance:**
   - Update Inventory: Enabled
   - Fix Permissions: Enabled

### Step 5: Create Monitoring/Response Policies (Optional)

#### Policy 1: Violation Alert Policy
```
Display Name: Admin Violation Response
Trigger: Recurring Check-in
Frequency: Once every day
Scope: "Jamf Connect Monitor - Violations" smart group

Actions:
- Send email alert to IT team
- Run custom script for additional logging
- Force inventory update
```

#### Policy 2: Report Generation Policy
```
Display Name: Weekly Admin Report
Trigger: Recurring Check-in
Frequency: Once every week
Scope: "Jamf Connect Monitor - Installed" smart group

Actions:
- Run script to compile weekly reports
- Email summary to management
```

## Silent Deployment Parameters

### Configuration via Jamf Pro Parameters

The package accepts these parameters for silent configuration:

| Parameter | Purpose | Example | Default |
|-----------|---------|---------|---------|
| $4 | Webhook URL | `https://hooks.slack.com/...` | None |
| $5 | Email recipient | `security@company.com` | None |
| $6 | Monitoring interval | `180` (3 minutes) | `300` |
| $7 | Company name | `AcmeCorp` | `YourCompany` |

### Example Policy Script Configuration:
```bash
# In the policy's Script payload, configure:
# Parameter 4: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
# Parameter 5: security@yourcompany.com
# Parameter 6: 300
# Parameter 7: YourCompany
```

## What Happens During Silent Installation

### Pre-Installation (Automatic):
1. ✅ Stops any existing monitoring
2. ✅ Creates necessary directories
3. ✅ Captures current admin users
4. ✅ Backs up existing configuration
5. ✅ Verifies system requirements

### Installation (Automatic):
1. ✅ Installs monitoring script
2. ✅ Installs LaunchDaemon
3. ✅ Creates default configuration
4. ✅ Sets proper permissions

### Post-Installation (Automatic):
1. ✅ Configures monitoring with provided parameters
2. ✅ Creates approved admin list from current users
3. ✅ Starts monitoring daemon
4. ✅ Runs initial monitoring check
5. ✅ Sends installation notification (if configured)
6. ✅ Updates Jamf inventory

## Verification & Monitoring

### Immediate Verification (After Deployment):
```bash
# On target machines, verify installation:
sudo /usr/local/bin/jamf_connect_monitor.sh status

# Check if daemon is running:
sudo launchctl list | grep jamfconnectmonitor

# View installation logs:
tail -f /var/log/jamf_connect_monitor_install.log
```

### Ongoing Monitoring in Jamf Pro:

1. **Extension Attribute Reporting:**
   - View in Computer inventory
   - Create Advanced Searches
   - Monitor Smart Group membership

2. **Smart Group Monitoring:**
   - "Jamf Connect Monitor - Installed" (deployment success)
   - "Jamf Connect Monitor - Violations" (security alerts)

3. **Log Collection:**
   - Use Files and Processes to collect logs
   - Automate with policies for investigation

## Troubleshooting Silent Deployment

### Common Issues:

#### Installation Fails:
```bash
# Check installation logs:
tail -50 /var/log/jamf_connect_monitor_install.log

# Verify package integrity:
pkgutil --check-signature /path/to/JamfConnectMonitor-1.0.pkg
```

#### Monitoring Not Starting:
```bash
# Check daemon status:
sudo launchctl list | grep jamfconnectmonitor

# Manual start:
sudo launchctl load /Library/LaunchDaemons/com.company.jamfconnectmonitor.plist

# Check permissions:
ls -la /usr/local/bin/jamf_connect_monitor.sh
```

#### Extension Attribute Not Populating:
```bash
# Test EA script manually:
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Force inventory update:
sudo jamf recon
```

### Log Locations for Troubleshooting:
- Installation: `/var/log/jamf_connect_monitor_install.log`
- Monitoring: `/var/log/jamf_connect_monitor/monitor.log`
- Violations: `/var/log/jamf_connect_monitor/admin_violations.log`
- Daemon: `/var/log/jamf_connect_monitor/daemon.log`

## Deployment Rollout Strategy

### Phase 1: Pilot Testing (1-2 weeks)
- Deploy to 5-10 test machines
- Monitor for issues
- Verify all functionality
- Adjust configuration as needed

### Phase 2: Department Rollout (2-3 weeks)
- Deploy to one department at a time
- Monitor violation reports
- Train IT staff on responses
- Refine approved admin lists

### Phase 3: Full Deployment (1-2 weeks)
- Deploy to remaining devices
- Full monitoring active
- Automated response policies
- Regular reporting established

## Maintenance & Updates

### Regular Tasks:
- **Weekly:** Review violation reports
- **Monthly:** Update approved admin lists
- **Quarterly:** Review and update configuration
- **As needed:** Package updates for new features

### Update Process:
1. Create new package version
2. Upload to Jamf Pro
3. Update deployment policy
4. Test on pilot group
5. Deploy to production

This guide ensures completely silent deployment with zero user interaction while maintaining full monitoring and security capabilities.