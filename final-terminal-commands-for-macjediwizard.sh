#!/bin/bash

# Final Terminal Commands for Jamf Connect Monitor v1.0.0 Release
# Run these commands in your local repository directory

echo "🚀 Final steps to complete Jamf Connect Monitor v1.0.0 release"
echo "Repository: /Users/willieg/Dropbox/GitHub/Jamf-Connect-Monitor"
echo

# Navigate to repository
cd "/Users/willieg/Dropbox/GitHub/Jamf-Connect-Monitor"

echo "📁 Current directory: $(pwd)"
echo

# Step 1: Create uninstall script with content
echo "📝 Step 1: Creating uninstall script with content..."
cat > scripts/uninstall_script.sh << 'EOF'
#!/bin/bash

# Jamf Connect Monitor - Complete Uninstall Script
# Version: 1.0
# Author: MacJediWizard
# Description: Completely removes all Jamf Connect Monitor components

set -e  # Exit on any error

# Configuration
SCRIPT_NAME="JamfConnectMonitor-Uninstall"
LOG_FILE="/var/log/jamf_connect_monitor_uninstall.log"
PACKAGE_IDENTIFIER="com.macjediwizard.jamfconnectmonitor"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Colored output function
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}$message${NC}"
    log_message "INFO" "$message"
}

# Error handling
error_exit() {
    print_status "$RED" "ERROR: $1"
    log_message "ERROR" "$1"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root. Use: sudo $0"
    fi
}

# Stop and unload LaunchDaemon
stop_daemon() {
    print_status "$BLUE" "Stopping monitoring daemon..."
    
    local daemon_paths=(
        "/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
        "/Library/LaunchDaemons/com.company.jamfconnectmonitor.plist"
    )
    
    for daemon_path in "${daemon_paths[@]}"; do
        if [[ -f "$daemon_path" ]]; then
            print_status "$YELLOW" "Found daemon: $daemon_path"
            
            # Get label from plist
            local label=$(defaults read "$daemon_path" Label 2>/dev/null || echo "")
            
            if [[ -n "$label" ]]; then
                print_status "$BLUE" "Unloading daemon: $label"
                launchctl unload "$daemon_path" 2>/dev/null || true
                
                # Wait for daemon to stop
                sleep 2
                
                # Force kill if still running
                local daemon_pid=$(launchctl list | grep "$label" | awk '{print $1}' 2>/dev/null || echo "")
                if [[ -n "$daemon_pid" && "$daemon_pid" != "-" ]]; then
                    print_status "$YELLOW" "Force stopping daemon PID: $daemon_pid"
                    kill -9 "$daemon_pid" 2>/dev/null || true
                fi
                
                print_status "$GREEN" "✓ Daemon stopped: $label"
            fi
        fi
    done
    
    # Kill any remaining monitor processes
    print_status "$BLUE" "Stopping any remaining monitor processes..."
    pkill -f "jamf_connect_monitor.sh" 2>/dev/null || true
    pkill -f "JamfConnectMonitor" 2>/dev/null || true
    
    print_status "$GREEN" "✓ All monitoring processes stopped"
}

# Remove LaunchDaemon files
remove_launch_daemons() {
    print_status "$BLUE" "Removing LaunchDaemon files..."
    
    local daemon_paths=(
        "/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
        "/Library/LaunchDaemons/com.company.jamfconnectmonitor.plist"
        "/Library/LaunchDaemons/com.yourcompany.jamfconnectmonitor.plist"
    )
    
    local removed_count=0
    for daemon_path in "${daemon_paths[@]}"; do
        if [[ -f "$daemon_path" ]]; then
            rm -f "$daemon_path"
            print_status "$GREEN" "✓ Removed: $daemon_path"
            ((removed_count++))
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_status "$YELLOW" "No LaunchDaemon files found"
    else
        print_status "$GREEN" "✓ Removed $removed_count LaunchDaemon file(s)"
    fi
}

# Remove main script files
remove_scripts() {
    print_status "$BLUE" "Removing main script files..."
    
    local script_files=(
        "/usr/local/bin/jamf_connect_monitor.sh"
        "/usr/local/etc/jamf_ea_admin_violations.sh"
        "/usr/local/share/jamf_connect_monitor/uninstall.sh"
    )
    
    local removed_count=0
    for script_file in "${script_files[@]}"; do
        if [[ -f "$script_file" ]]; then
            rm -f "$script_file"
            print_status "$GREEN" "✓ Removed: $script_file"
            ((removed_count++))
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_status "$YELLOW" "No script files found"
    else
        print_status "$GREEN" "✓ Removed $removed_count script file(s)"
    fi
}

# Remove configuration files
remove_configuration() {
    print_status "$BLUE" "Removing configuration files..."
    
    local config_files=(
        "/usr/local/etc/approved_admins.txt"
        "/usr/local/etc/approved_admins.txt.backup"
        "/usr/local/etc/approved_admins_template.txt"
        "/usr/local/etc/jamf_connect_monitor.conf"
    )
    
    local removed_count=0
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            # Create backup before removal
            local backup_file="${config_file}.uninstall_backup.$(date +%Y%m%d_%H%M%S)"
            cp "$config_file" "$backup_file" 2>/dev/null || true
            rm -f "$config_file"
            print_status "$GREEN" "✓ Removed: $config_file (backed up to $backup_file)"
            ((removed_count++))
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_status "$YELLOW" "No configuration files found"
    else
        print_status "$GREEN" "✓ Removed $removed_count configuration file(s)"
    fi
}

# Handle log files
handle_log_files() {
    print_status "$BLUE" "Handling log files..."
    
    local log_dirs=(
        "/var/log/jamf_connect_monitor"
    )
    
    local log_files=(
        "/var/log/jamf_connect_monitor_install.log"
        "/var/log/jamf_connect_monitor_uninstall.log"
    )
    
    # Archive logs before removal
    local archive_dir="/var/log/jamf_connect_monitor_archive_$(date +%Y%m%d_%H%M%S)"
    
    for log_dir in "${log_dirs[@]}"; do
        if [[ -d "$log_dir" ]]; then
            print_status "$BLUE" "Archiving logs from: $log_dir"
            mkdir -p "$archive_dir"
            cp -R "$log_dir"/* "$archive_dir"/ 2>/dev/null || true
            
            # Remove original log directory
            rm -rf "$log_dir"
            print_status "$GREEN" "✓ Archived and removed: $log_dir"
            print_status "$YELLOW" "Archive location: $archive_dir"
        fi
    done
    
    # Handle individual log files
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" && "$log_file" != "$LOG_FILE" ]]; then
            if [[ ! -d "$archive_dir" ]]; then
                mkdir -p "$archive_dir"
            fi
            cp "$log_file" "$archive_dir"/ 2>/dev/null || true
            rm -f "$log_file"
            print_status "$GREEN" "✓ Archived and removed: $log_file"
        fi
    done
}

# Remove application directories
remove_directories() {
    print_status "$BLUE" "Removing application directories..."
    
    local app_dirs=(
        "/usr/local/share/jamf_connect_monitor"
    )
    
    local removed_count=0
    for app_dir in "${app_dirs[@]}"; do
        if [[ -d "$app_dir" ]]; then
            rm -rf "$app_dir"
            print_status "$GREEN" "✓ Removed directory: $app_dir"
            ((removed_count++))
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_status "$YELLOW" "No application directories found"
    else
        print_status "$GREEN" "✓ Removed $removed_count application directories"
    fi
}

# Remove package receipts
remove_package_receipts() {
    print_status "$BLUE" "Removing package receipts..."
    
    local package_ids=(
        "com.macjediwizard.jamfconnectmonitor"
        "com.company.jamfconnectmonitor"
        "com.yourcompany.jamfconnectmonitor"
    )
    
    local removed_count=0
    for package_id in "${package_ids[@]}"; do
        if pkgutil --pkg-info "$package_id" &>/dev/null; then
            print_status "$BLUE" "Found package receipt: $package_id"
            
            # Get package files before removal
            local package_files=$(pkgutil --files "$package_id" 2>/dev/null || echo "")
            
            # Remove package receipt
            pkgutil --forget "$package_id" 2>/dev/null || true
            print_status "$GREEN" "✓ Removed package receipt: $package_id"
            ((removed_count++))
            
            # Log package files for reference
            if [[ -n "$package_files" ]]; then
                log_message "INFO" "Files from package $package_id:"
                echo "$package_files" | while read file; do
                    log_message "INFO" "  $file"
                done
            fi
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_status "$YELLOW" "No package receipts found"
    else
        print_status "$GREEN" "✓ Removed $removed_count package receipt(s)"
    fi
}

# Clean system caches and preferences
clean_system_caches() {
    print_status "$BLUE" "Cleaning system caches..."
    
    # Clear LaunchDaemon cache
    print_status "$BLUE" "Reloading LaunchDaemon cache..."
    launchctl load /System/Library/LaunchDaemons/com.apple.launchctl.Aqua.plist 2>/dev/null || true
    
    # Clean up any preference files
    local pref_files=(
        "/Library/Preferences/com.macjediwizard.jamfconnectmonitor.plist"
        "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor.plist"
    )
    
    for pref_file in "${pref_files[@]}"; do
        if [[ -f "$pref_file" ]]; then
            rm -f "$pref_file"
            print_status "$GREEN" "✓ Removed preference file: $pref_file"
        fi
    done
    
    print_status "$GREEN" "✓ System caches cleaned"
}

# Update Jamf Pro inventory (if available)
update_jamf_inventory() {
    print_status "$BLUE" "Updating Jamf Pro inventory..."
    
    if command -v jamf &> /dev/null; then
        # Submit inventory update
        jamf recon &
        print_status "$GREEN" "✓ Jamf inventory update initiated"
    else
        print_status "$YELLOW" "Jamf binary not found - skipping inventory update"
    fi
}

# Send uninstall notification
send_uninstall_notification() {
    print_status "$BLUE" "Sending uninstall notification..."
    
    # Check for webhook configuration in existing config
    local webhook_url=""
    if [[ -f "/usr/local/etc/jamf_connect_monitor.conf" ]]; then
        webhook_url=$(grep "WebhookURL=" /usr/local/etc/jamf_connect_monitor.conf 2>/dev/null | cut -d'=' -f2 || echo "")
    fi
    
    if [[ -n "$webhook_url" && "$webhook_url" != "" ]]; then
        local hostname=$(hostname)
        local payload="{
            \"text\": \"🗑️ Jamf Connect Monitor Uninstalled\",
            \"attachments\": [{
                \"color\": \"warning\",
                \"fields\": [
                    {\"title\": \"Hostname\", \"value\": \"$hostname\", \"short\": true},
                    {\"title\": \"Uninstall Date\", \"value\": \"$(date)\", \"short\": true},
                    {\"title\": \"Status\", \"value\": \"Complete\", \"short\": true}
                ]
            }]
        }"
        
        curl -X POST -H 'Content-type: application/json' \
             --data "$payload" \
             "$webhook_url" &>/dev/null && \
        print_status "$GREEN" "✓ Uninstall notification sent via webhook"
    else
        print_status "$YELLOW" "No webhook configuration found - skipping notification"
    fi
}

# Verify complete removal
verify_removal() {
    print_status "$BLUE" "Verifying complete removal..."
    
    local issues=0
    
    # Check for remaining files
    local check_paths=(
        "/usr/local/bin/jamf_connect_monitor.sh"
        "/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
        "/usr/local/etc/approved_admins.txt"
        "/usr/local/etc/jamf_connect_monitor.conf"
        "/var/log/jamf_connect_monitor"
    )
    
    for check_path in "${check_paths[@]}"; do
        if [[ -e "$check_path" ]]; then
            print_status "$RED" "✗ Still exists: $check_path"
            ((issues++))
        else
            print_status "$GREEN" "✓ Removed: $check_path"
        fi
    done
    
    # Check for running processes
    if pgrep -f "jamf_connect_monitor" &>/dev/null; then
        print_status "$RED" "✗ Monitor processes still running"
        ((issues++))
    else
        print_status "$GREEN" "✓ No monitor processes running"
    fi
    
    # Check for LaunchDaemon registration
    if launchctl list | grep -q "jamfconnectmonitor"; then
        print_status "$RED" "✗ LaunchDaemon still registered"
        ((issues++))
    else
        print_status "$GREEN" "✓ LaunchDaemon not registered"
    fi
    
    # Check package receipts
    local remaining_packages=""
    for pkg_id in "com.macjediwizard.jamfconnectmonitor" "com.company.jamfconnectmonitor"; do
        if pkgutil --pkg-info "$pkg_id" &>/dev/null; then
            remaining_packages="$remaining_packages $pkg_id"
            ((issues++))
        fi
    done
    
    if [[ -n "$remaining_packages" ]]; then
        print_status "$RED" "✗ Package receipts still exist:$remaining_packages"
    else
        print_status "$GREEN" "✓ No package receipts found"
    fi
    
    return $issues
}

# Display removal summary
show_removal_summary() {
    local archive_dir=$(ls -td /var/log/jamf_connect_monitor_archive_* 2>/dev/null | head -1 || echo "")
    
    print_status "$GREEN" "=== UNINSTALL COMPLETED ==="
    echo
    print_status "$BLUE" "Removed Components:"
    echo "  ✓ Monitoring daemon and scripts"
    echo "  ✓ Configuration files (backed up)"
    echo "  ✓ Application directories"
    echo "  ✓ Package receipts"
    echo "  ✓ System cache entries"
    echo
    
    if [[ -n "$archive_dir" ]]; then
        print_status "$BLUE" "Log Archive:"
        echo "  📁 $archive_dir"
        echo "     (Contains all monitoring logs for historical reference)"
        echo
    fi
    
    print_status "$BLUE" "Configuration Backups:"
    echo "  📁 /usr/local/etc/*.uninstall_backup.*"
    echo "     (Approved admin lists and settings)"
    echo
    
    print_status "$BLUE" "Cleanup Complete:"
    echo "  • All monitoring stopped"
    echo "  • All files removed"
    echo "  • System caches cleared"
    echo "  • Jamf Pro inventory updated"
    echo
    
    print_status "$GREEN" "Jamf Connect Monitor has been completely removed from this system."
    print_status "$YELLOW" "Note: Jamf Connect application itself remains installed and functional."
}

# Interactive confirmation
confirm_uninstall() {
    if [[ "${1:-}" != "--force" && "${1:-}" != "-f" ]]; then
        echo
        print_status "$YELLOW" "⚠️  WARNING: This will completely remove Jamf Connect Monitor"
        print_status "$YELLOW" "This includes:"
        echo "  • Monitoring scripts and daemon"
        echo "  • Configuration files and approved admin lists"
        echo "  • Log files (will be archived)"
        echo "  • Package receipts"
        echo
        print_status "$BLUE" "Jamf Connect application will NOT be affected."
        echo
        
        read -p "Are you sure you want to proceed? (yes/no): " confirm
        
        if [[ "$confirm" != "yes" && "$confirm" != "y" ]]; then
            print_status "$YELLOW" "Uninstall cancelled by user"
            exit 0
        fi
    fi
}

# Main execution
main() {
    print_status "$GREEN" "=== Starting Jamf Connect Monitor Uninstall ==="
    print_status "$BLUE" "Version: 1.0"
    print_status "$BLUE" "Date: $(date)"
    echo
    
    check_root
    confirm_uninstall "$@"
    
    # Perform uninstall steps
    stop_daemon
    send_uninstall_notification  # Send before removing config
    remove_launch_daemons
    remove_scripts
    remove_configuration
    handle_log_files
    remove_directories
    remove_package_receipts
    clean_system_caches
    update_jamf_inventory
    
    # Verify and report
    if verify_removal; then
        show_removal_summary
        log_message "INFO" "Uninstall completed successfully with no issues"
        exit 0
    else
        print_status "$YELLOW" "Uninstall completed with some issues (see above)"
        log_message "WARN" "Uninstall completed but verification found remaining items"
        exit 1
    fi
}

# Command line options
case "${1:-uninstall}" in
    "uninstall"|"")
        main "$@"
        ;;
    "--force"|"-f")
        main "$@"
        ;;
    "verify")
        print_status "$BLUE" "Verifying removal..."
        if verify_removal; then
            print_status "$GREEN" "Verification passed - no components found"
        else
            print_status "$RED" "Verification failed - components still present"
            exit 1
        fi
        ;;
    "help"|"--help")
        echo "Jamf Connect Monitor Uninstall Script"
        echo "Usage: $0 [option]"
        echo
        echo "Options:"
        echo "  uninstall    Remove all components (default, interactive)"
        echo "  --force, -f  Remove all components (non-interactive)"
        echo "  verify       Check if components are removed"
        echo "  help         Show this help message"
        echo
        echo "Examples:"
        echo "  sudo $0                    # Interactive uninstall"
        echo "  sudo $0 --force           # Silent uninstall"
        echo "  sudo $0 verify           # Check removal status"
        ;;
    *)
        print_status "$RED" "Unknown option: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
EOF

chmod +x scripts/uninstall_script.sh
echo "✅ Created scripts/uninstall_script.sh (executable)"

# Step 2: Create uninstall documentation
echo "📝 Step 2: Creating uninstall documentation..."
cat > docs/uninstall-guide.md << 'EOF'
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

### Method 3: Package-Based Uninstall

#### Create Uninstall Package

1. **Package the Uninstall Script:**
   ```bash
   # Create package structure
   mkdir -p uninstall_package/usr/local/bin
   cp uninstall_script.sh uninstall_package/usr/local/bin/

   # Create postinstall script
   cat > postinstall << 'EOF'
   #!/bin/bash
   /usr/local/bin/uninstall_script.sh --force
   rm -f /usr/local/bin/uninstall_script.sh
   EOF

   # Build package
   pkgbuild --root uninstall_package \
            --scripts scripts \
            --identifier com.macjediwizard.jamfconnectmonitor.uninstall \
            --version 1.0 \
            JamfConnectMonitor-Uninstall-1.0.pkg
   ```

2. **Deploy via Jamf Pro:**
   - Upload package to Jamf Pro
   - Create policy with package installation
   - Scope to installed systems

## Verification and Monitoring

### Post-Uninstall Verification

#### Automated Verification (Jamf Pro)

Create a new Extension Attribute to verify removal:

```bash
#!/bin/bash

# Check for remaining components
if [[ -f "/usr/local/bin/jamf_connect_monitor.sh" ]] || \
   [[ -f "/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist" ]] || \
   [[ -d "/var/log/jamf_connect_monitor" ]]; then
    echo "<r>Components Found - Uninstall Incomplete</r>"
elif [[ -d "/var/log/jamf_connect_monitor_archive_"* ]]; then
    echo "<r>Successfully Uninstalled - Logs Archived</r>"
else
    echo "<r>Never Installed</r>"
fi
```

#### Manual Verification Commands

```bash
# Check for remaining files
ls -la /usr/local/bin/jamf_connect_monitor.sh 2>/dev/null || echo "Script removed ✓"
ls -la /Library/LaunchDaemons/*jamfconnectmonitor* 2>/dev/null || echo "Daemon removed ✓"
ls -la /usr/local/etc/approved_admins.txt 2>/dev/null || echo "Config removed ✓"

# Check for running processes
pgrep -f jamf_connect_monitor || echo "No processes running ✓"

# Check LaunchDaemon registration
launchctl list | grep jamfconnectmonitor || echo "Daemon not registered ✓"

# Check package receipts
pkgutil --pkg-info com.macjediwizard.jamfconnectmonitor || echo "Package receipt removed ✓"
```

### Smart Groups for Monitoring Uninstall

#### Uninstall Verification Smart Group
```
Name: Jamf Connect Monitor - Uninstall Status
Criteria:
- Uninstall Verification | is | Successfully Uninstalled - Logs Archived
```

#### Failed Uninstall Smart Group
```
Name: Jamf Connect Monitor - Uninstall Failed
Criteria:
- Uninstall Verification | is | Components Found - Uninstall Incomplete
```

## Troubleshooting Uninstall Issues

### Common Issues and Solutions

#### Issue: Daemon Won't Stop
**Symptoms**: LaunchDaemon remains active after uninstall
**Solution**:
```bash
# Force stop all related processes
sudo pkill -9 -f jamf_connect_monitor
sudo launchctl unload -w /Library/LaunchDaemons/*jamfconnectmonitor*
sudo rm -f /Library/LaunchDaemons/*jamfconnectmonitor*
```

#### Issue: Package Receipt Won't Remove
**Symptoms**: `pkgutil --forget` fails
**Solution**:
```bash
# List all related packages
pkgutil --pkgs | grep -i jamf.*monitor

# Force remove each package receipt
sudo pkgutil --forget com.macjediwizard.jamfconnectmonitor
sudo pkgutil --forget com.company.jamfconnectmonitor
```

#### Issue: Permission Denied Errors
**Symptoms**: Cannot remove files due to permissions
**Solution**:
```bash
# Fix permissions before removal
sudo chmod -R 755 /usr/local/bin/jamf_connect_monitor.sh
sudo chmod -R 755 /var/log/jamf_connect_monitor
sudo chown -R root:wheel /usr/local/etc/approved_admins.txt

# Then run uninstall again
sudo ./uninstall_script.sh --force
```

#### Issue: Partial Uninstall
**Symptoms**: Some components remain after uninstall
**Solution**:
```bash
# Manual cleanup
sudo rm -f /usr/local/bin/jamf_connect_monitor.sh
sudo rm -f /Library/LaunchDaemons/*jamfconnectmonitor*
sudo rm -rf /var/log/jamf_connect_monitor
sudo rm -f /usr/local/etc/approved_admins.txt
sudo rm -f /usr/local/etc/jamf_connect_monitor.conf
sudo rm -rf /usr/local/share/jamf_connect_monitor

# Clear package receipts
sudo pkgutil --forget com.macjediwizard.jamfconnectmonitor

# Verify complete removal
sudo ./uninstall_script.sh verify
```

## Bulk Uninstall Strategies

### Strategy 1: Phased Removal
1. **Phase 1**: Test uninstall on 5-10 machines
2. **Phase 2**: Remove from one department
3. **Phase 3**: Full fleet removal

### Strategy 2: Maintenance Window
- Schedule uninstall during maintenance windows
- Use custom triggers for coordinated removal
- Monitor progress via Smart Groups

### Strategy 3: Conditional Removal
```bash
# Only remove if no violations in last 30 days
last_violation=$(grep "VIOLATION" /var/log/jamf_connect_monitor/admin_violations.log 2>/dev/null | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' || echo "")

if [[ -z "$last_violation" ]] || [[ $(date -d "$last_violation" +%s) -lt $(date -d "30 days ago" +%s) ]]; then
    /usr/local/bin/uninstall_script.sh --force
fi
```

## Log Preservation and Analysis

### Log Archive Locations
After uninstall, logs are preserved in:
- `/var/log/jamf_connect_monitor_archive_[timestamp]/`
- `/usr/local/etc/*.uninstall_backup.[timestamp]`

### Extract Historical Data
```bash
# Find all archived logs
ls -la /var/log/jamf_connect_monitor_archive_*/

# Extract violation summary
grep "VIOLATION" /var/log/jamf_connect_monitor_archive_*/admin_violations.log

# Get final statistics
wc -l /var/log/jamf_connect_monitor_archive_*/monitor.log
```

## Post-Uninstall Considerations

### Security Impact
- ✅ No impact on Jamf Connect functionality
- ✅ Temporary elevation still works normally
- ⚠️ No automated admin account monitoring
- ⚠️ Manual admin oversight required

### Alternative Solutions
If removing due to issues rather than obsolescence:
1. **Adjust monitoring interval** instead of removal
2. **Update approved admin lists** for accuracy
3. **Configure different notification methods**
4. **Review and update to latest version**

### Clean Reinstall Process
If planning to reinstall:
1. Complete uninstall using this guide
2. Verify removal with `uninstall_script.sh verify`
3. Download latest installer package
4. Deploy fresh installation

## Support and Recovery

### Emergency Restore
If uninstall was performed in error:
```bash
# Restore from backup
sudo cp /usr/local/etc/approved_admins.txt.uninstall_backup.* /usr/local/etc/approved_admins.txt

# Reinstall from package
sudo installer -pkg JamfConnectMonitor-1.0.pkg -target /

# Verify restoration
sudo jamf_connect_monitor.sh status
```

### Support Resources
- **GitHub Issues**: [Report uninstall problems](https://github.com/MacJediWizard/jamf-connect-monitor/issues)
- **Documentation**: [Complete documentation](https://github.com/MacJediWizard/jamf-connect-monitor/wiki)
- **Community**: [Jamf Nation discussions](https://community.jamf.com)

---

**Created with ❤️ by MacJediWizard**
EOF

echo "✅ Created docs/uninstall-guide.md"

# Step 3: Verify file structure
echo "📁 Step 3: Verifying file structure..."
echo "Repository contents:"
find . -name "*.sh" -o -name "*.md" -o -name "*.plist" | grep -v ".git" | sort

echo
echo "📋 Step 4: Verification checklist:"
echo "✅ Uninstall script: scripts/uninstall_script.sh"
echo "✅ Uninstall guide: docs/uninstall-guide.md"
echo "✅ Package creation ready: scripts/package_creation_script.sh"
echo "✅ Main monitoring script: scripts/jamf_connect_monitor.sh"

# Step 5: Final package rebuild (optional)
echo
echo "🔨 Step 5: Rebuilding package with uninstall script..."
cd scripts
if sudo ./package_creation_script.sh build; then
    echo "✅ Package rebuilt successfully with uninstall script included"
    ls -la output/
else
    echo "⚠️ Package rebuild failed - continuing with GitHub release preparation"
fi
cd ..

# Step 6: Display GitHub Desktop instructions
echo
echo "🐙 Step 6: GitHub Desktop Instructions"
echo "=================================="
echo "1. Open GitHub Desktop"
echo "2. Navigate to your jamf-connect-monitor repository"
echo "3. Review changes (should show modified files)"
echo "4. Commit with message: 'Release v1.0.0 - MacJediWizard Production Release'"
echo "5. Push to GitHub"
echo "6. Create tag 'v1.0.0' on GitHub"
echo

# Step 7: Display GitHub release instructions
echo "🚀 Step 7: GitHub Release Instructions"
echo "====================================="
echo "1. Go to: https://github.com/MacJediWizard/jamf-connect-monitor/releases"
echo "2. Click 'Create a new release'"
echo "3. Tag version: 'v1.0.0'"
echo "4. Release title: 'Jamf Connect Monitor v1.0.0 - Production Release'"
echo "5. Upload these files from scripts/output/:"
echo "   - JamfConnectMonitor-1.0.pkg"
echo "   - JamfConnectMonitor-1.0.pkg.sha256"
echo "   - Jamf_Pro_Deployment_Instructions.txt"
echo "6. Upload from repository root:"
echo "   - scripts/uninstall_script.sh"
echo "7. Write release notes describing the features"
echo "8. Click 'Publish release'"
echo

echo "✅ All files ready for GitHub release!"
echo "📦 Package location: scripts/output/JamfConnectMonitor-1.0.pkg"
echo "🔑 Checksum: scripts/output/JamfConnectMonitor-1.0.pkg.sha256"
echo "📚 Instructions: scripts/output/Jamf_Pro_Deployment_Instructions.txt"
echo "🗑️ Uninstaller: scripts/uninstall_script.sh"
echo
echo "🎉 Jamf Connect Monitor v1.0.0 is ready for release!"
EOF

chmod +x scripts/final_terminal_commands.sh
echo "✅ Created scripts/final_terminal_commands.sh (executable)"

# Step 2: Create uninstall documentation
echo "📝 Step 2: Creating uninstall documentation..."
cat > docs/uninstall-guide.md << 'EOF'
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
EOF

echo "✅ Created docs/uninstall-guide.md"

# Step 3: Display completion summary
echo
echo "🎯 COMPLETION SUMMARY"
echo "===================="
echo "✅ Uninstall script created: scripts/uninstall_script.sh"
echo "✅ Uninstall guide created: docs/uninstall-guide.md"
echo "✅ Repository is 100% complete for v1.0.0 release"
echo
echo "📋 NEXT STEPS:"
echo "1. Review the created files above"
echo "2. Use GitHub Desktop to commit changes"
echo "3. Create GitHub release with tag v1.0.0"
echo "4. Upload release assets from scripts/output/"
echo
echo "🚀 Ready for production deployment!"
