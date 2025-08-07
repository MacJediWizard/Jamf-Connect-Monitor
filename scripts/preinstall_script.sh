#!/bin/bash

# Jamf Pro Pre-installation Script
# This script prepares the system for Jamf Connect Monitor installation

# Set script timeout to prevent hanging
set -o pipefail

# Variables
SCRIPT_NAME="JamfConnectMonitor-PreInstall"
LOG_FILE="/var/log/jamf_connect_monitor_install.log"

# Logging function
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [PREINSTALL] $1" | tee -a "$LOG_FILE"
}

log_message "Starting pre-installation tasks"

# Clean up old installation files to ensure clean upgrade
log_message "Cleaning up previous installation files"

# Remove old script locations (if they exist from previous versions)
old_files=(
    "/usr/local/bin/jamf_connect_monitor.sh"
    "/usr/local/etc/jamf_ea_admin_violations.sh"
    "/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
    "/usr/local/share/jamf_connect_monitor/uninstall_script.sh"
)

for file in "${old_files[@]}"; do
    if [[ -f "$file" ]]; then
        # Clear any ACLs before removal
        xattr -c "$file" 2>/dev/null || true
        rm -f "$file"
        log_message "Removed old file: $file"
    fi
done

# Clean up old directories (but preserve logs and config)
if [[ -d "/usr/local/share/jamf_connect_monitor" ]]; then
    # Remove old uninstall script specifically
    rm -f "/usr/local/share/jamf_connect_monitor/uninstall_script.sh" 2>/dev/null || true
    log_message "Cleaned up old application directory"
fi

# Stop existing monitoring if running
if launchctl list 2>/dev/null | grep -q "com.macjediwizard.jamfconnectmonitor"; then
    log_message "Stopping existing monitoring daemon"
    launchctl unload /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist 2>/dev/null || true
    # Shorter sleep to avoid hanging
    sleep 1
fi

# Kill any running monitor processes
pkill -f "jamf_connect_monitor.sh" 2>/dev/null || true

# Create necessary directories with proper permissions
log_message "Creating directory structure"

directories=(
    "/usr/local/bin"
    "/usr/local/etc"
    "/var/log/jamf_connect_monitor"
    "/usr/local/share/jamf_connect_monitor"
)

for dir in "${directories[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_message "Created directory: $dir"
    fi
    chmod 755 "$dir"
    chown root:wheel "$dir"
done

# Backup existing configuration if it exists
if [[ -f "/usr/local/etc/approved_admins.txt" ]]; then
    cp "/usr/local/etc/approved_admins.txt" "/usr/local/etc/approved_admins.txt.backup.$(date +%Y%m%d_%H%M%S)"
    log_message "Backed up existing approved admin list"
fi

# Get current admin users for initial whitelist (excluding system accounts)
log_message "Capturing current admin users for whitelist"
current_admins=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | \
    sed 's/GroupMembership: //' | \
    tr ' ' '\n' | \
    grep -v '^_' | \
    grep -v '^root$' | \
    grep -v '^daemon$' | \
    sort)

# Save current admins to temporary file for post-install
echo "$current_admins" > "/tmp/jamf_monitor_current_admins.txt"
log_message "Saved current admin list with $(echo "$current_admins" | wc -l | tr -d ' ') users"

# Check Jamf Connect status
if [[ -f "/Applications/Jamf Connect.app/Contents/Info.plist" ]]; then
    jc_version=$(defaults read "/Applications/Jamf Connect.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown")
    log_message "Jamf Connect detected: Version $jc_version"
    
    # Check if privilege elevation is configured
    elevation_enabled=$(defaults read /Library/Managed\ Preferences/com.jamf.connect.plist TemporaryUserPromotion 2>/dev/null || echo "0")
    if [[ "$elevation_enabled" == "1" ]]; then
        log_message "Jamf Connect privilege elevation is enabled"
    else
        log_message "WARNING: Jamf Connect privilege elevation not enabled"
    fi
else
    log_message "WARNING: Jamf Connect not installed"
fi

# Set up log rotation for monitoring logs
log_message "Configuring log rotation"
cat > "/etc/newsyslog.d/jamf_connect_monitor.conf" << 'EOF'
# Jamf Connect Monitor log rotation
/var/log/jamf_connect_monitor/*.log    644  5  10240  *  GZ
EOF

# Check system requirements
macos_version=$(sw_vers -productVersion)
log_message "System check: macOS $macos_version"

# Verify script will have necessary permissions
if [[ $EUID -eq 0 ]]; then
    log_message "Running with root privileges - OK"
else
    log_message "ERROR: Not running as root"
    exit 1
fi

# Check available disk space (need at least 100MB)
available_space=$(df -m /var/log | awk 'NR==2 {print $4}')
if [[ $available_space -gt 100 ]]; then
    log_message "Disk space check: ${available_space}MB available - OK"
else
    log_message "WARNING: Low disk space: ${available_space}MB available"
fi

# Pre-create configuration file with current environment settings
log_message "Creating default configuration"
cat > "/tmp/jamf_monitor_config.env" << EOF
# Jamf Connect Monitor Configuration
# Generated during installation on $(date)

# System Information
HOSTNAME=$(hostname)
MACOS_VERSION=$macos_version
INSTALL_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Default Settings
MONITORING_INTERVAL=300
LOG_RETENTION_DAYS=30
AUTO_REMEDIATION=true
VIOLATION_REPORTING=true

# Installation Context
JAMF_CONNECT_VERSION=${jc_version:-"Not Installed"}
ELEVATION_ENABLED=${elevation_enabled:-"0"}
CURRENT_ADMIN_COUNT=$(echo "$current_admins" | wc -l | tr -d ' ')
EOF

log_message "Pre-installation tasks completed successfully"
exit 0