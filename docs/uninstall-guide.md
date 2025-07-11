# Jamf Connect Monitor - Complete Uninstall Guide

## Overview
This guide provides multiple methods to completely remove Jamf Connect Monitor from your fleet, including silent uninstall via Jamf Pro.

## What Gets Removed

### Files and Directories
- `/usr/local/bin/jamf_connect_monitor.sh` - Main monitoring script
- `/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist` - Daemon configuration
- `/usr/local/etc/approved_admins.txt` - Approved administrator list
- `/usr/local/etc/jamf_connect_monitor.conf` - Configuration file
- `/var/log/jamf_connect_monitor/` - All log files (archived before removal)
- `/usr/local/share/jamf_connect_monitor/` - Application directory

### System Components
- LaunchDaemon registration and processes
- Package receipts from installer
- System cache entries
- Preference files

### What's Preserved
- **Log Archives**: All logs are archived to `/var/log/jamf_connect_monitor_archive_[timestamp]/`
- **Configuration Backups**: Approved admin lists backed up with `.uninstall_backup` suffix
- **Jamf Connect**: The Jamf Connect application itself remains untouched

## Uninstall Methods

### Method 1: Local Manual Uninstall

#### Download and Run Uninstall Script
```bash
# Download the uninstall script
curl -o uninstall_script.sh https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest/download/uninstall_script.sh

# Make executable
chmod +x uninstall_script.sh

# Run interactive uninstall
sudo ./uninstall_script.sh

# OR run silent uninstall
sudo ./uninstall_script.sh --force
```

#### Verify Removal
```bash
# Check that components are removed
sudo ./uninstall_script.sh verify
```

### Method 2: Jamf Pro Silent Uninstall (Recommended)

#### Step 1: Upload Uninstall Script to Jamf Pro

1. **Navigate to Scripts:**
   - Settings → Computer Management → Scripts → New

2. **Script Configuration:**
   ```
   Display Name: Jamf Connect Monitor - Uninstall
   Category: Utilities
   Priority: After
   Script Contents: [Copy entire uninstall_script.sh content]
   ```

3. **Parameter Configuration:**
   ```
   Parameter 4: Uninstall Mode
   - "interactive" = Show confirmation prompts
   - "force" = Silent removal (recommended for mass deployment)
   ```

#### Step 2: Create Smart Group for Installed Systems

```
Name: Jamf Connect Monitor - Installed
Criteria:
- Admin Account Violations | is not | Not configured
- Admin Account Violations | is not | Not monitored
```

#### Step 3: Create Uninstall Policy

1. **General Settings:**
   ```
   Display Name: Uninstall Jamf Connect Monitor
   Category: Utilities
   Trigger: Custom Event "uninstall_jamf_monitor" OR Manual
   Execution Frequency: Once per computer
   ```

2. **Scripts Configuration:**
   ```
   Script: Jamf Connect Monitor - Uninstall
   Priority: Before
   Parameter 4: force
   ```

3. **Scope:**
   ```
   Target: "Jamf Connect Monitor - Installed" smart group
   Exclusions: (none, unless you want to preserve on specific machines)
   ```

4. **Maintenance:**
   ```
   Update Inventory: Enabled
   ```

#### Step 4: Execute Uninstall

**Option A: Custom Trigger**
```bash
# On target machines
sudo jamf policy -event uninstall_jamf_monitor
```

**Option B: Manual Execution**
- Select target machines in Jamf Pro
- Execute policy manually

---

**Created with ❤️ by MacJediWizard**
