#!/bin/bash

# Jamf Connect Monitor - Complete Uninstall Script
# Version: 1.0.1
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
    print_status "$BLUE" "Version: 1.0.1"
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
