# Jamf Connect Monitor - Complete Uninstall Guide v2.4.0

## Overview
This guide provides multiple methods to completely remove Jamf Connect Monitor from your fleet, including **enhanced v2.4.0 uninstall capabilities**, silent uninstall via Jamf Pro, and comprehensive system restoration.

## 🗑️ **Enhanced v2.4.0 Uninstall Features**

### **Enterprise-Grade Removal (New in v2.4.0)**
- **✅ Complete System Restoration** - All scripts, daemons, logs, and configurations removed
- **✅ Configuration Backup** - Preserves approved admin lists and settings with timestamped backups
- **✅ Log Archiving** - Complete monitoring history preserved before removal
- **✅ ACL Cleanup** - Extended Attributes and permissions fully restored
- **✅ Package Receipt Management** - All installer receipts cleaned from system database
- **✅ Verification System** - Comprehensive validation of complete removal

### **Jamf Pro Integration (v2.4.0)**
- **✅ Silent Mass Deployment** - Automated uninstall via Jamf Pro policies
- **✅ Inventory Updates** - Automatic Jamf Pro inventory refresh after removal
- **✅ Notification Support** - Uninstall confirmation via configured webhooks
- **✅ Multiple Package ID Support** - Handles all legacy and current installations

## What Gets Removed

### Files and Directories
```bash
# Scripts and Binaries
/usr/local/bin/jamf_connect_monitor.sh                    # Main monitoring script
/usr/local/etc/jamf_ea_admin_violations.sh               # Extension Attribute script
/usr/local/share/jamf_connect_monitor/uninstall_script.sh # Enhanced uninstall script
/usr/local/share/jamf_connect_monitor/                   # Complete application directory

# System Integration
/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist # Daemon configuration
/Library/Preferences/com.macjediwizard.jamfconnectmonitor.plist   # System preferences
/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor.plist # Configuration Profile

# Configuration Files
/usr/local/etc/approved_admins.txt                       # Approved administrator list
/usr/local/etc/jamf_connect_monitor.conf                # Configuration file
/usr/local/etc/approved_admins_template.txt             # Template file

# Log Directory
/var/log/jamf_connect_monitor/                          # All monitoring logs
```

### System Components
- **LaunchDaemon registration and processes** - All background monitoring stopped and unloaded
- **Package receipts from installer** - All package identifiers removed from system database
- **System cache entries** - macOS caches cleared and updated
- **Preference files** - All system and managed preferences cleaned
- **ACL and Extended Attributes** - Complete system state restoration

### What's Preserved (v2.4.0 Feature)

#### **Automatic Backups**
```bash
# Log Archives (Complete History Preserved)
/var/log/jamf_connect_monitor_archive_[timestamp]/
├── monitor.log                    # All monitoring activity
├── admin_violations.log          # Complete violation history  
├── jamf_connect_events.log       # Jamf Connect integration logs
├── realtime_monitor.log          # Real-time monitoring events
└── daemon.log                    # LaunchDaemon execution logs

# Configuration Backups (Settings Preserved)
/usr/local/etc/approved_admins.txt.uninstall_backup.[timestamp]
/usr/local/etc/jamf_connect_monitor.conf.uninstall_backup.[timestamp]
```

#### **What's Preserved**
- **✅ Jamf Connect**: The Jamf Connect application itself remains untouched
- **✅ User Accounts**: No changes to user accounts or admin privileges
- **✅ System Settings**: macOS system configuration unchanged
- **✅ Other Security Tools**: No interference with other monitoring systems

## Uninstall Methods

### Method 1: Enhanced Local Manual Uninstall (v2.4.0)

#### Download and Run Enhanced Uninstall Script
```bash
# Download the enhanced v2.4.0 uninstall script
curl -o uninstall_script.sh https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest/download/uninstall_script.sh

# Make executable
chmod +x uninstall_script.sh

# Run interactive uninstall with enhanced features
sudo ./uninstall_script.sh

# OR run silent uninstall for automation
sudo ./uninstall_script.sh --force
```

#### Enhanced Uninstall Options (v2.4.0)
```bash
# Interactive uninstall with confirmation prompts
sudo ./uninstall_script.sh

# Silent uninstall (perfect for mass deployment)
sudo ./uninstall_script.sh --force

# Verification only (check removal completeness)
sudo ./uninstall_script.sh verify

# Help and usage information
sudo ./uninstall_script.sh help
```

#### Verify Complete Removal
```bash
# Use enhanced verification
sudo ./uninstall_script.sh verify

# Expected output:
# 🔍 Verifying complete removal...
# ✅ Removed: /usr/local/bin/jamf_connect_monitor.sh
# ✅ Removed: /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
# ✅ No monitor processes running
# ✅ LaunchDaemon not registered
# ✅ No package receipts found
# ✅ VERIFICATION PASSED - No components found
```

### Method 2: Jamf Pro Silent Uninstall (Recommended for Enterprise)

#### Step 1: Upload Enhanced Uninstall Script to Jamf Pro

1. **Navigate to Scripts:**
   - Settings → Computer Management → Scripts → New

2. **Script Configuration:**
   ```
   Display Name: Jamf Connect Monitor - Enhanced Uninstall v2.4.0
   Category: Utilities
   Priority: Before
   Script Contents: [Copy entire enhanced uninstall_script.sh content]
   ```

3. **Parameter Configuration:**
   ```
   Parameter 4: Uninstall Mode
   - "interactive" = Show confirmation prompts
   - "force" = Silent removal (recommended for mass deployment)
   - "verify" = Verification only (check removal status)
   ```

#### Step 2: Create Smart Group for Installed Systems

```
Name: Jamf Connect Monitor - Installed (Any Version)
Criteria:
- Extension Attribute "[ Jamf Connect ] - Monitor Status" is not "Not configured"
- OR Extension Attribute "[ Jamf Connect ] - Monitor Status" like "*Version:*"
- OR Computer Group membership is "Previously had Jamf Connect Monitor"
```

#### Step 3: Create Enhanced Uninstall Policy

1. **General Settings:**
   ```
   Display Name: Uninstall Jamf Connect Monitor v2.4.0 (Enhanced)
   Category: Utilities
   Trigger: Custom Event "uninstall_jamf_monitor_v201" OR Manual
   Execution Frequency: Once per computer
   ```

2. **Scripts Configuration:**
   ```
   Script: Jamf Connect Monitor - Enhanced Uninstall v2.4.0
   Priority: Before
   Parameter 4: force
   ```

3. **Scope:**
   ```
   Target: "Jamf Connect Monitor - Installed (Any Version)" smart group
   Exclusions: (none, unless you want to preserve on specific machines)
   ```

4. **Maintenance:**
   ```
   Update Inventory: Enabled
   ```

#### Step 4: Execute Enhanced Mass Uninstall

**Option A: Custom Trigger**
```bash
# On target machines
sudo jamf policy -event uninstall_jamf_monitor_v201
```

**Option B: Manual Execution**
- Select target machines in Jamf Pro
- Execute policy manually for controlled rollout

**Option C: Self Service (Optional)**
- Make policy available in Self Service
- Allow users to uninstall if appropriate
- Include clear description of enhanced uninstall features

### Method 3: Local Package-Included Uninstall (v2.4.0)

```bash
# Use enhanced uninstall script included with v2.4.0 package
sudo /usr/local/share/jamf_connect_monitor/uninstall_script.sh

# Available options:
sudo /usr/local/share/jamf_connect_monitor/uninstall_script.sh --force
sudo /usr/local/share/jamf_connect_monitor/uninstall_script.sh verify
sudo /usr/local/share/jamf_connect_monitor/uninstall_script.sh help
```

## Enhanced Uninstall Process (v2.4.0)

### Interactive Uninstall Experience
```bash
⚠️  WARNING: This will completely remove Jamf Connect Monitor v2.4.0
This includes:
  • Monitoring scripts and daemon
  • Configuration files and approved admin lists (will be backed up)
  • Log files (will be archived with timestamp)
  • Package receipts and system cache entries

Jamf Connect application will NOT be affected.

Are you sure you want to proceed? (yes/no): yes

🔄 Stopping monitoring daemon...
✅ Monitoring daemon stopped successfully

📧 Sending uninstall notification...
✅ Uninstall notification sent via webhook

🗑️  Removing LaunchDaemon files...
✅ Removed: /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

🗑️  Removing main script files...
✅ Removed: /usr/local/bin/jamf_connect_monitor.sh
✅ Removed: /usr/local/etc/jamf_ea_admin_violations.sh

💾 Archiving configuration files...
✅ Removed: /usr/local/etc/approved_admins.txt 
   (backed up to /usr/local/etc/approved_admins.txt.uninstall_backup.20250805_143022)

📁 Archiving log files...
✅ Archived and removed: /var/log/jamf_connect_monitor
   Archive location: /var/log/jamf_connect_monitor_archive_20250805_143022

🗑️  Removing application directories...
✅ Removed directory: /usr/local/share/jamf_connect_monitor

📦 Removing package receipts...
✅ Removed package receipt: com.macjediwizard.jamfconnectmonitor

🧹 Cleaning system caches and ACLs...
✅ System caches cleaned
✅ Extended Attributes and ACLs cleared

📊 Updating Jamf Pro inventory...
✅ Jamf inventory update initiated

🔍 Verifying complete removal...
✅ Removed: /usr/local/bin/jamf_connect_monitor.sh
✅ Removed: /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
✅ No monitor processes running
✅ LaunchDaemon not registered
✅ No package receipts found

=== ENHANCED UNINSTALL COMPLETED ===

Removed Components:
  ✅ Monitoring daemon and scripts
  ✅ Configuration files (backed up with timestamps)
  ✅ Application directories
  ✅ Package receipts and system cache entries
  ✅ ACL and Extended Attributes

Archive Locations:
  📁 /var/log/jamf_connect_monitor_archive_20250805_143022
     (Contains all monitoring logs for historical reference)

Configuration Backups:
  📁 /usr/local/etc/*.uninstall_backup.20250805_143022
     (Approved admin lists and settings preserved)

Cleanup Complete:
  • All monitoring stopped and unloaded
  • All files removed with comprehensive backup
  • System caches and ACLs cleared
  • Jamf Pro inventory updated

✅ Jamf Connect Monitor has been completely removed from this system.
Note: Jamf Connect application itself remains installed and functional.
```

## Verification and Validation (Enhanced v2.4.0)

### Comprehensive Verification
```bash
# Use enhanced verification command
sudo ./uninstall_script.sh verify

# Manual verification checks
echo "=== Manual Verification Checklist ==="

# 1. Check for remaining files
echo "Checking for remaining files..."
find /usr/local -name "*jamf_connect_monitor*" 2>/dev/null || echo "✅ No files found"
find /Library -name "*jamfconnectmonitor*" 2>/dev/null || echo "✅ No files found"

# 2. Check for running processes
echo "Checking for running processes..."
pgrep -f jamf_connect_monitor && echo "❌ Processes still running" || echo "✅ No processes running"

# 3. Check LaunchDaemon registration
echo "Checking LaunchDaemon registration..."
launchctl list | grep jamfconnectmonitor && echo "❌ Still registered" || echo "✅ Not registered"

# 4. Check package receipts
echo "Checking package receipts..."
pkgutil --pkg-info com.macjediwizard.jamfconnectmonitor 2>/dev/null && echo "❌ Receipt found" || echo "✅ No receipts"

# 5. Verify backup creation
echo "Checking backup creation..."
ls -la /var/log/jamf_connect_monitor_archive_* 2>/dev/null && echo "✅ Logs archived" || echo "⚠️ No archive found"
ls -la /usr/local/etc/*.uninstall_backup.* 2>/dev/null && echo "✅ Configs backed up" || echo "⚠️ No backups found"
```

### Jamf Pro Integration Verification
```bash
# After mass uninstall via Jamf Pro:
# 1. Check Smart Group "Successfully Removed" for expected membership
# 2. Verify Extension Attribute shows "Not configured" 
# 3. Confirm inventory updates completed
# 4. Validate no monitoring processes running on sample systems
```

## Troubleshooting Enhanced Uninstall (v2.4.0)

### Common Issues and Solutions

#### Permission Denied During Uninstall
```bash
# Solution: Ensure running with sudo and clear ACLs
sudo xattr -c ./uninstall_script.sh
sudo chmod +x ./uninstall_script.sh
sudo ./uninstall_script.sh --force
```

#### LaunchDaemon Won't Unload
```bash
# Enhanced v2.4.0 uninstall handles this automatically, but manual fix:
sudo launchctl unload /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
sudo rm -f /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Force kill processes if needed:
sudo pkill -f jamf_connect_monitor
```

#### Package Receipts Not Removed
```bash
# Enhanced v2.4.0 uninstall handles multiple package IDs, but manual cleanup:
sudo pkgutil --forget com.macjediwizard.jamfconnectmonitor
sudo pkgutil --forget com.yourcompany.jamfconnectmonitor  
sudo pkgutil --forget com.company.jamfconnectmonitor
```

#### Incomplete Removal
```bash
# Use enhanced verification and cleanup
sudo ./uninstall_script.sh verify

# If issues found, re-run enhanced uninstall:
sudo ./uninstall_script.sh --force

# Check specific components manually:
sudo find /usr/local -name "*jamf_connect_monitor*" -exec rm -rf {} \;
sudo find /Library -name "*jamfconnectmonitor*" -exec rm -rf {} \;
```

#### Backup and Archive Issues
```bash
# Check backup creation
ls -la /var/log/jamf_connect_monitor_archive_*
ls -la /usr/local/etc/*.uninstall_backup.*

# If backups missing, check disk space:
df -h /var/log
df -h /usr/local

# Manually create backup if needed before uninstall:
sudo cp -R /var/log/jamf_connect_monitor /var/log/jamf_connect_monitor_manual_backup_$(date +%Y%m%d_%H%M%S)
```

## Backup and Recovery (v2.4.0 Feature)

### Restoring from Enhanced Backups
```bash
# List available backups
ls -la /var/log/jamf_connect_monitor_archive_*
ls -la /usr/local/etc/*.uninstall_backup.*

# Restore approved admin list:
sudo cp /usr/local/etc/approved_admins.txt.uninstall_backup.[timestamp] /usr/local/etc/approved_admins.txt

# Restore configuration:
sudo cp /usr/local/etc/jamf_connect_monitor.conf.uninstall_backup.[timestamp] /usr/local/etc/jamf_connect_monitor.conf

# Restore logs from archive:
sudo cp -R /var/log/jamf_connect_monitor_archive_[timestamp]/* /var/log/jamf_connect_monitor/
```

### Partial Reinstallation (After Enhanced Uninstall)
```bash
# If you need to reinstall after enhanced uninstall:
# 1. Download latest package
curl -LO https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest/download/JamfConnectMonitor-2.4.0.pkg

# 2. Install package
sudo installer -pkg JamfConnectMonitor-2.4.0.pkg -target /

# 3. Restore approved admin list from backup (if needed)
sudo cp /usr/local/etc/approved_admins.txt.uninstall_backup.[timestamp] /usr/local/etc/approved_admins.txt

# 4. Verify installation with v2.4.0 tools
sudo ./tools/verify_monitoring.sh
```

## Enterprise Best Practices (v2.4.0)

### Planning Phase for Mass Uninstall
- **📋 Document Current State** - Note all approved admins and configurations
- **📊 Identify Target Systems** - Use Smart Groups for precise scoping
- **🧪 Test Enhanced Uninstall** - Validate process on non-production systems
- **📅 Schedule Maintenance Window** - Plan for brief monitoring interruption
- **💾 Verify Backup Locations** - Ensure adequate disk space for archives

### Execution Phase  
- **🎯 Start with Pilot Group** - Test enhanced uninstall on small subset first
- **📈 Monitor Progress** - Track Smart Group membership changes
- **🔍 Verify Samples** - Manually check random systems for complete removal
- **📊 Update Documentation** - Record systems where monitoring was removed
- **💾 Validate Backups** - Confirm archives and configuration backups created

### Post-Uninstall Phase
- **✅ Validate Complete Removal** - Use enhanced verification tools
- **📁 Archive Backups** - Store configuration backups for compliance
- **📊 Update Asset Management** - Record uninstall in IT asset database
- **📋 Document Lessons Learned** - Improve process for future uninstalls
- **🔍 Regular Verification** - Periodically verify systems remain clean

### Compliance and Auditing
- **📝 Maintain Uninstall Logs** - Keep detailed records of enhanced removal process
- **💾 Preserve Configuration Archives** - Retain approved admin lists for auditing
- **📊 Track Inventory Changes** - Monitor Jamf Pro inventory for compliance
- **🔍 Regular Verification** - Use verification tools to confirm clean state

---

**Created with ❤️ by MacJediWizard**

**Enhanced enterprise-grade uninstall with complete system restoration, comprehensive backup, and production-verified reliability.**