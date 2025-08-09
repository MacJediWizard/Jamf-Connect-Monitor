# Enhanced Uninstall Guide - v2.4.0

## Overview
Jamf Connect Monitor v2.4.0 introduces a comprehensive enterprise-grade uninstall system that provides complete component removal, configuration backup, and system state restoration for production environments.

## 🗑️ **Enhanced Uninstall Features (New in v2.4.0)**

### **Complete System Restoration**
- **✅ Total Component Removal** - All scripts, daemons, logs, and configurations
- **✅ Configuration Backup** - Preserves approved admin lists and settings
- **✅ Log Archiving** - Complete monitoring history preserved before removal
- **✅ ACL Cleanup** - Extended Attributes and permissions fully restored
- **✅ Package Receipt Management** - All installer receipts cleaned from system database
- **✅ Verification System** - Confirm complete removal with detailed validation

### **Enterprise Integration**
- **✅ Jamf Pro Compatibility** - Silent uninstall for mass deployment
- **✅ Inventory Updates** - Automatic Jamf Pro inventory refresh after removal
- **✅ Notification Support** - Uninstall confirmation via configured webhooks
- **✅ Multiple Package ID Support** - Handles all legacy and current installations

## 📋 **What Gets Removed**

### **System Components**
```bash
# Scripts and Binaries
/usr/local/bin/jamf_connect_monitor.sh                    # Main monitoring script
/usr/local/etc/jamf_ea_admin_violations.sh               # Extension Attribute script
/usr/local/share/jamf_connect_monitor/uninstall_script.sh # Uninstall script

# System Integration  
/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist # Daemon configuration
/Library/Preferences/com.macjediwizard.jamfconnectmonitor.plist   # System preferences
/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor.plist # Configuration Profile

# Configuration Files
/usr/local/etc/approved_admins.txt                       # Approved administrator list
/usr/local/etc/jamf_connect_monitor.conf                # Legacy configuration
/usr/local/etc/approved_admins_template.txt             # Template file

# Application Directory
/usr/local/share/jamf_connect_monitor/                  # Complete application directory
```

### **Package Receipts**
```bash
# All package identifiers removed from system database:
com.macjediwizard.jamfconnectmonitor     # Current v2.x package identifier
com.yourcompany.jamfconnectmonitor       # Legacy package identifier  
com.company.jamfconnectmonitor           # Alternative legacy identifier
```

### **System Cache and Processes**
```bash
# LaunchDaemon processes stopped and unloaded
# System cache entries cleared
# Running monitoring processes terminated
# ACL and Extended Attributes cleaned
```

## 💾 **What's Preserved**

### **Automatic Backups**
```bash
# Log Archives (Complete History Preserved)
/var/log/jamf_connect_monitor_archive_[timestamp]/
├── monitor.log                    # All monitoring activity
├── admin_violations.log          # Complete violation history  
├── jamf_connect_events.log       # Jamf Connect integration logs
└── realtime_monitor.log          # Real-time monitoring events

# Configuration Backups (Settings Preserved)
/usr/local/etc/approved_admins.txt.uninstall_backup.[timestamp]
/usr/local/etc/jamf_connect_monitor.conf.uninstall_backup.[timestamp]
```

### **What Remains Untouched**
- **✅ Jamf Connect Application** - Jamf Connect itself remains fully functional
- **✅ User Accounts** - No changes to user accounts or admin privileges
- **✅ System Settings** - macOS system configuration unchanged
- **✅ Other Security Tools** - No interference with other monitoring systems

## 🚀 **Uninstall Methods**

### **Method 1: Interactive Uninstall (Recommended)**
```bash
# Download latest uninstall script
curl -o uninstall_script.sh https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest/download/uninstall_script.sh
sudo chmod +x uninstall_script.sh

# Run interactive uninstall with confirmation prompts
sudo ./uninstall_script.sh

# Interactive prompts guide you through:
# - Component removal confirmation
# - Backup location selection  
# - Verification of removal completeness
```

### **Method 2: Silent Uninstall (Enterprise Mass Deployment)**
```bash
# Silent removal without user prompts
sudo ./uninstall_script.sh --force

# OR using short flag
sudo ./uninstall_script.sh -f

# Perfect for:
# - Mass uninstall via Jamf Pro policies
# - Automated deployment workflows
# - Remote system administration
```

### **Method 3: Local Uninstall (Package Included)**
```bash
# Use uninstall script included with v2.4.0 package
sudo /usr/local/share/jamf_connect_monitor/uninstall_script.sh

# Available options:
sudo /usr/local/share/jamf_connect_monitor/uninstall_script.sh --force
sudo /usr/local/share/jamf_connect_monitor/uninstall_script.sh verify
```

### **Method 4: Verification Only**
```bash
# Check if components are completely removed (no uninstall)
sudo ./uninstall_script.sh verify

# Perfect for:
# - Post-uninstall validation
# - Compliance verification  
# - Troubleshooting removal issues
```

## 📊 **Interactive Uninstall Process**

### **Step-by-Step Interactive Experience**
```bash
⚠️  WARNING: This will completely remove Jamf Connect Monitor
This includes:
  • Monitoring scripts and daemon
  • Configuration files and approved admin lists
  • Log files (will be archived)
  • Package receipts

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
✅ Removed: /usr/local/etc/approved_admins.txt (backed up to /usr/local/etc/approved_admins.txt.uninstall_backup.20250805_143022)

📁 Archiving log files...
✅ Archived and removed: /var/log/jamf_connect_monitor
Archive location: /var/log/jamf_connect_monitor_archive_20250805_143022

🗑️  Removing application directories...
✅ Removed directory: /usr/local/share/jamf_connect_monitor

📦 Removing package receipts...
✅ Removed package receipt: com.macjediwizard.jamfconnectmonitor

🧹 Cleaning system caches...
✅ System caches cleaned

📊 Updating Jamf Pro inventory...
✅ Jamf inventory update initiated

🔍 Verifying complete removal...
✅ Removed: /usr/local/bin/jamf_connect_monitor.sh
✅ Removed: /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
✅ No monitor processes running
✅ LaunchDaemon not registered
✅ No package receipts found

=== UNINSTALL COMPLETED ===

Removed Components:
  ✅ Monitoring daemon and scripts
  ✅ Configuration files (backed up)
  ✅ Application directories
  ✅ Package receipts
  ✅ System cache entries

Log Archive:
  📁 /var/log/jamf_connect_monitor_archive_20250805_143022
     (Contains all monitoring logs for historical reference)

Configuration Backups:
  📁 /usr/local/etc/*.uninstall_backup.*
     (Approved admin lists and settings)

✅ Jamf Connect Monitor has been completely removed from this system.
Note: Jamf Connect application itself remains installed and functional.
```

## 🏢 **Enterprise Jamf Pro Deployment**

### **Silent Uninstall via Jamf Pro**

#### **Step 1: Upload Uninstall Script**
1. **Navigate:** Settings → Computer Management → Scripts → New
2. **Configuration:**
   ```
   Display Name: Jamf Connect Monitor - Enhanced Uninstall v2.4.0
   Category: Utilities
   Priority: Before
   ```
3. **Script Content:** Copy entire uninstall_script.sh content
4. **Parameter 4:** Uninstall Mode
   - `interactive` = Show confirmation prompts  
   - `force` = Silent removal (recommended for mass deployment)

#### **Step 2: Create Smart Group for Installed Systems**
```bash
Name: Jamf Connect Monitor - Installed (Any Version)
Criteria: 
  - Extension Attribute "[ Jamf Connect ] - Monitor Status" is not "Not configured"
  OR Computer Group membership is "Previously had Jamf Connect Monitor"
```

#### **Step 3: Create Uninstall Policy**
1. **General Settings:**
   ```
   Display Name: Uninstall Jamf Connect Monitor v2.4.0
   Category: Utilities  
   Trigger: Custom Event "uninstall_jamf_monitor" OR Manual
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
   Exclusions: (none, unless preserving specific systems)
   ```

4. **Maintenance:**
   ```
   Update Inventory: Enabled
   ```

#### **Step 4: Execute Mass Uninstall**

**Option A: Custom Trigger**
```bash
# Execute on target machines
sudo jamf policy -event uninstall_jamf_monitor
```

**Option B: Self Service (Optional)**
- Make policy available in Self Service
- Allow users to uninstall if appropriate
- Include clear description of what gets removed

**Option C: Manual Execution**
- Select target computers in Jamf Pro
- Execute policy manually for controlled rollout

### **Verification and Reporting**
```bash
# Create post-uninstall Smart Group for verification:
Name: Jamf Connect Monitor - Successfully Removed
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status" is "Not configured"
AND Computer Group membership was "Previously had Jamf Connect Monitor"

# This Smart Group should contain all systems where uninstall completed successfully
```

## 🔍 **Verification and Validation**

### **Manual Verification Commands**
```bash
# Verify complete removal manually:
sudo ./uninstall_script.sh verify

# Individual component checks:
ls -la /usr/local/bin/jamf_connect_monitor.sh                    # Should not exist
ls -la /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist # Should not exist
sudo launchctl list | grep jamfconnectmonitor                    # Should return nothing  
pkgutil --pkg-info com.macjediwizard.jamfconnectmonitor         # Should return "No receipt"
```

### **Verification Script Output**
```bash
🔍 Verifying complete removal...

✅ Removed: /usr/local/bin/jamf_connect_monitor.sh
✅ Removed: /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
✅ Removed: /usr/local/etc/approved_admins.txt
✅ Removed: /usr/local/etc/jamf_connect_monitor.conf
✅ Removed: /var/log/jamf_connect_monitor
✅ No monitor processes running
✅ LaunchDaemon not registered  
✅ No package receipts found

✅ VERIFICATION PASSED - No components found
```

### **Jamf Pro Integration Verification**
```bash
# After mass uninstall via Jamf Pro:
1. Check Smart Group "Successfully Removed" for expected membership
2. Verify Extension Attribute shows "Not configured" 
3. Confirm inventory updates completed
4. Validate no monitoring processes running on sample systems
```

## 🚨 **Troubleshooting Uninstall Issues**

### **Common Issues and Solutions**

#### **Permission Denied During Uninstall**
```bash
# Solution: Ensure running with sudo
sudo ./uninstall_script.sh --force

# If still failing, clear ACLs:
sudo xattr -c ./uninstall_script.sh
sudo chmod +x ./uninstall_script.sh
```

#### **LaunchDaemon Won't Unload**
```bash
# Manual daemon removal:
sudo launchctl unload /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
sudo rm -f /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Force kill processes:
sudo pkill -f jamf_connect_monitor
```

#### **Package Receipts Not Removed**
```bash
# Manual package receipt removal:
sudo pkgutil --forget com.macjediwizard.jamfconnectmonitor
sudo pkgutil --forget com.yourcompany.jamfconnectmonitor  
sudo pkgutil --forget com.company.jamfconnectmonitor
```

#### **Configuration Files Remain**
```bash
# Manual configuration cleanup:
sudo rm -f /usr/local/etc/approved_admins.txt
sudo rm -f /usr/local/etc/jamf_connect_monitor.conf
sudo rm -rf /usr/local/share/jamf_connect_monitor
```

#### **Verification Fails After Uninstall**
```bash
# Re-run verification with verbose output:
sudo ./uninstall_script.sh verify --verbose

# Check specific components:
find /usr/local -name "*jamf_connect_monitor*" 2>/dev/null
find /Library -name "*jamfconnectmonitor*" 2>/dev/null
```

### **Log Analysis for Troubleshooting**
```bash
# Check uninstall logs:
tail -f /var/log/jamf_connect_monitor_uninstall.log

# Look for common error patterns:
grep -i "error\|failed\|permission denied" /var/log/jamf_connect_monitor_uninstall.log
```

## 📅 **Backup and Recovery**

### **Restoring from Backups (If Needed)**
```bash
# Restore approved admin list:
sudo cp /usr/local/etc/approved_admins.txt.uninstall_backup.[timestamp] /usr/local/etc/approved_admins.txt

# Restore configuration:
sudo cp /usr/local/etc/jamf_connect_monitor.conf.uninstall_backup.[timestamp] /usr/local/etc/jamf_connect_monitor.conf

# Restore logs from archive:
sudo cp -R /var/log/jamf_connect_monitor_archive_[timestamp]/* /var/log/jamf_connect_monitor/
```

### **Partial Reinstallation (After Uninstall)**
```bash
# If you need to reinstall after uninstall:
1. Download latest package: JamfConnectMonitor-2.4.0.pkg
2. Install package: sudo installer -pkg JamfConnectMonitor-2.4.0.pkg -target /
3. Restore approved admin list from backup (if needed)
4. Verify installation: sudo ./tools/verify_monitoring.sh
```

## 💡 **Best Practices for Enterprise Uninstall**

### **Planning Phase**
- **📋 Document Current State** - Note all approved admins and configurations
- **📊 Identify Target Systems** - Use Smart Groups for precise scoping
- **🧪 Test in Staging** - Validate uninstall process on non-production systems
- **📅 Schedule Maintenance Window** - Plan for brief monitoring interruption

### **Execution Phase**  
- **🎯 Start with Pilot Group** - Test on small subset first
- **📈 Monitor Progress** - Track Smart Group membership changes
- **🔍 Verify Samples** - Manually check random systems for complete removal
- **📊 Update Documentation** - Record systems where monitoring was removed

### **Post-Uninstall Phase**
- **✅ Validate Complete Removal** - Use verification tools
- **📁 Archive Backups** - Store configuration backups for compliance
- **📊 Update Asset Management** - Record uninstall in IT asset database
- **📋 Document Lessons Learned** - Improve process for future uninstalls

### **Compliance and Auditing**
- **📝 Maintain Uninstall Logs** - Keep detailed records of removal process
- **💾 Preserve Configuration Archives** - Retain approved admin lists for auditing
- **📊 Track Inventory Changes** - Monitor Jamf Pro inventory for compliance
- **🔍 Regular Verification** - Periodically verify systems remain clean

---

## 🎯 **Summary**

The v2.4.0 enhanced uninstall system provides enterprise administrators with:

- **✅ Complete System Restoration** - Total removal with no remnants
- **✅ Data Preservation** - Critical configurations and logs backed up
- **✅ Enterprise Scalability** - Silent mass uninstall via Jamf Pro
- **✅ Verification Confidence** - Comprehensive validation of removal
- **✅ Troubleshooting Support** - Detailed diagnostics and error handling

**The enhanced uninstall script ensures clean system state restoration while preserving important historical data for compliance and auditing purposes.**

---

**Created with ❤️ by MacJediWizard**

**Enterprise-grade uninstall with complete system restoration and data preservation.**