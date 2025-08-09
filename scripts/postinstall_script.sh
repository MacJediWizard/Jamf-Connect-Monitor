#!/bin/bash

# Jamf Pro Post-installation Script
# This script completes the Jamf Connect Monitor setup after package installation

# Variables
SCRIPT_NAME="JamfConnectMonitor-PostInstall"
LOG_FILE="/var/log/jamf_connect_monitor_install.log"
CONFIG_FILE="/usr/local/etc/jamf_connect_monitor.conf"
MONITOR_SCRIPT="/usr/local/bin/jamf_connect_monitor.sh"
LAUNCH_DAEMON="/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
APPROVED_ADMINS="/usr/local/etc/approved_admins.txt"

# Centralized version management - auto-extract from main script
if [[ -f "/usr/local/bin/jamf_connect_monitor.sh" ]]; then
    PACKAGE_VERSION=$(grep "^VERSION=" "/usr/local/bin/jamf_connect_monitor.sh" | cut -d'"' -f2)
    if [[ -z "$PACKAGE_VERSION" ]]; then
        PACKAGE_VERSION=$(head -10 "/usr/local/bin/jamf_connect_monitor.sh" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    fi
fi
[[ -z "$PACKAGE_VERSION" ]] && PACKAGE_VERSION="2.4.0"  # Fallback

# Configuration from Jamf Pro Parameters (if provided)
WEBHOOK_URL="${4:-}"          # Parameter 4
EMAIL_RECIPIENT="${5:-}"      # Parameter 5
MONITORING_INTERVAL="${6:-300}" # Parameter 6
COMPANY_NAME="${7:-YourCompany}" # Parameter 7

# Logging function
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [POSTINSTALL] $1" | tee -a "$LOG_FILE"
}

log_message "Starting post-installation configuration for v$PACKAGE_VERSION"

# Verify package installation
verify_installation() {
    local errors=0
    
    if [[ ! -f "$MONITOR_SCRIPT" ]]; then
        log_message "ERROR: Monitor script not found at $MONITOR_SCRIPT"
        ((errors++))
    fi
    
    if [[ ! -f "$LAUNCH_DAEMON" ]]; then
        log_message "ERROR: LaunchDaemon not found at $LAUNCH_DAEMON"
        ((errors++))
    fi
    
    return $errors
}

# Configure the monitoring script with environment-specific settings
configure_monitoring_script() {
    log_message "Configuring monitoring script"
    
    if [[ ! -f "$MONITOR_SCRIPT" ]]; then
        log_message "ERROR: Monitor script not found"
        return 1
    fi
    
    # Update configuration variables in the script (for legacy compatibility)
    if [[ -n "$WEBHOOK_URL" ]]; then
        sed -i '' "s|^WEBHOOK_URL=.*|WEBHOOK_URL=\"$WEBHOOK_URL\"|" "$MONITOR_SCRIPT"
        log_message "Configured webhook URL (legacy method)"
    fi
    
    if [[ -n "$EMAIL_RECIPIENT" ]]; then
        sed -i '' "s|^EMAIL_RECIPIENT=.*|EMAIL_RECIPIENT=\"$EMAIL_RECIPIENT\"|" "$MONITOR_SCRIPT"
        log_message "Configured email recipient (legacy method): $EMAIL_RECIPIENT"
    fi
    
    # Set permissions
    chmod +x "$MONITOR_SCRIPT"
    chown root:wheel "$MONITOR_SCRIPT"
    
    # FIX: Set permissions for Extension Attribute script and clear ACLs
    if [[ -f "/usr/local/etc/jamf_ea_admin_violations.sh" ]]; then
        chmod +x "/usr/local/etc/jamf_ea_admin_violations.sh"
        chown root:wheel "/usr/local/etc/jamf_ea_admin_violations.sh"
        # Clear any extended attributes/ACLs that may cause execution issues
        xattr -c "/usr/local/etc/jamf_ea_admin_violations.sh" 2>/dev/null || true
        log_message "Set permissions and cleared ACLs for Extension Attribute script"
    fi
    
    # FIX: Set permissions for uninstall script and clear ACLs
    if [[ -f "/usr/local/share/jamf_connect_monitor/uninstall_script.sh" ]]; then
        chmod +x "/usr/local/share/jamf_connect_monitor/uninstall_script.sh"
        chown root:wheel "/usr/local/share/jamf_connect_monitor/uninstall_script.sh"
        # Clear any extended attributes/ACLs that may cause execution issues
        xattr -c "/usr/local/share/jamf_connect_monitor/uninstall_script.sh" 2>/dev/null || true
        log_message "Set permissions and cleared ACLs for uninstall script"
    fi
    
    log_message "Monitor script configuration completed"
}

# Create approved admin list from current admins or template
create_approved_admin_list() {
    log_message "Creating approved admin list"
    
    # Use current admins from pre-install if available
    if [[ -f "/tmp/jamf_monitor_current_admins.txt" ]]; then
        cp "/tmp/jamf_monitor_current_admins.txt" "$APPROVED_ADMINS"
        log_message "Used current admin list from pre-install"
    elif [[ -f "/usr/local/etc/approved_admins_template.txt" ]]; then
        cp "/usr/local/etc/approved_admins_template.txt" "$APPROVED_ADMINS"
        log_message "Used template admin list"
    else
        # Get current admins directly
        dscl . -read /Groups/admin GroupMembership 2>/dev/null | \
        sed 's/GroupMembership: //' | \
        tr ' ' '\n' | \
        grep -v '^_' | \
        grep -v '^root$' | \
        grep -v '^daemon$' | \
        sort > "$APPROVED_ADMINS"
        log_message "Generated admin list from current system"
    fi
    
    # Set permissions and clear ACLs
    chmod 644 "$APPROVED_ADMINS"
    chown root:wheel "$APPROVED_ADMINS"
    xattr -c "$APPROVED_ADMINS" 2>/dev/null || true
    
    local admin_count=$(wc -l < "$APPROVED_ADMINS" | tr -d ' ')
    log_message "Approved admin list created with $admin_count users"
    
    # Log the admins for audit purposes (first 3 for security)
    local admin_preview=$(head -3 "$APPROVED_ADMINS" | tr '\n' ',' | sed 's/,$//')
    [[ $admin_count -gt 3 ]] && admin_preview="$admin_preview... (+$((admin_count-3)) more)"
    log_message "Approved admins preview: $admin_preview"
}

# Configure LaunchDaemon with custom settings
configure_launch_daemon() {
    log_message "Configuring LaunchDaemon"
    
    if [[ ! -f "$LAUNCH_DAEMON" ]]; then
        log_message "ERROR: LaunchDaemon not found"
        return 1
    fi
    
    # Update monitoring interval if specified
    if [[ "$MONITORING_INTERVAL" != "300" ]]; then
        /usr/libexec/PlistBuddy -c "Set :StartInterval $MONITORING_INTERVAL" "$LAUNCH_DAEMON" 2>/dev/null || {
            log_message "WARNING: Could not update monitoring interval"
        }
        log_message "Set monitoring interval to $MONITORING_INTERVAL seconds"
    fi
    
    # Update company name in label if specified (for legacy compatibility)
    if [[ "$COMPANY_NAME" != "YourCompany" ]]; then
        local new_label="com.${COMPANY_NAME,,}.jamfconnectmonitor"
        /usr/libexec/PlistBuddy -c "Set :Label $new_label" "$LAUNCH_DAEMON" 2>/dev/null || {
            log_message "WARNING: Could not update daemon label"
        }
        log_message "Updated daemon label to $new_label"
    fi
    
    # Set permissions and clear ACLs
    chown root:wheel "$LAUNCH_DAEMON"
    chmod 644 "$LAUNCH_DAEMON"
    xattr -c "$LAUNCH_DAEMON" 2>/dev/null || true
    
    log_message "LaunchDaemon configuration completed"
}

# Create configuration file for runtime settings
create_config_file() {
    log_message "Creating configuration file"
    
    cat > "$CONFIG_FILE" << EOF
# Jamf Connect Monitor Configuration
# Generated on $(date)

[Settings]
MonitoringInterval=$MONITORING_INTERVAL
LogRetentionDays=30
AutoRemediation=true
ViolationReporting=true

[Notifications]
WebhookURL=$WEBHOOK_URL
EmailRecipient=$EMAIL_RECIPIENT

[System]
CompanyName=$COMPANY_NAME
InstallDate=$(date '+%Y-%m-%d %H:%M:%S')
Version=$PACKAGE_VERSION

[Paths]
ApprovedAdminsList=$APPROVED_ADMINS
LogDirectory=/var/log/jamf_connect_monitor
ScriptPath=$MONITOR_SCRIPT
EOF
    
    chmod 644 "$CONFIG_FILE"
    chown root:wheel "$CONFIG_FILE"
    xattr -c "$CONFIG_FILE" 2>/dev/null || true
    
    log_message "Configuration file created"
}

# Initialize monitoring with first run
initialize_monitoring() {
    log_message "Initializing monitoring system"
    
    # Run initial monitoring to ensure everything works
    if "$MONITOR_SCRIPT" monitor; then
        log_message "Initial monitoring run successful"
    else
        log_message "WARNING: Initial monitoring run failed"
    fi
    
    # Display current status (first 5 lines to avoid log spam)
    "$MONITOR_SCRIPT" status | head -5 | while read line; do
        log_message "STATUS: $line"
    done
}

# Load and start the LaunchDaemon
start_monitoring_daemon() {
    log_message "Starting monitoring daemon"
    
    # Unload if already loaded (for upgrades)
    launchctl unload "$LAUNCH_DAEMON" 2>/dev/null || true
    
    # Load the daemon
    if launchctl load "$LAUNCH_DAEMON"; then
        log_message "LaunchDaemon loaded successfully"
        
        # Wait a moment and verify it's running
        sleep 2
        if launchctl list | grep -q "jamfconnectmonitor"; then
            log_message "Monitoring daemon is running"
        else
            log_message "WARNING: Monitoring daemon may not be running properly"
        fi
    else
        log_message "ERROR: Failed to load LaunchDaemon"
        return 1
    fi
}

# Create Jamf Pro inventory record
update_jamf_inventory() {
    log_message "Updating Jamf Pro inventory"
    
    # Create a receipt file for Jamf Pro to track installation
    cat > "/usr/local/share/jamf_connect_monitor/install_receipt.txt" << EOF
Installation Date: $(date)
Version: $PACKAGE_VERSION
Monitoring Interval: $MONITORING_INTERVAL
Approved Admins: $(wc -l < "$APPROVED_ADMINS" | tr -d ' ')
Webhook Configured: $([[ -n "$WEBHOOK_URL" ]] && echo "Yes" || echo "No")
Email Configured: $([[ -n "$EMAIL_RECIPIENT" ]] && echo "Yes" || echo "No")
EOF
    
    # Clear ACLs on receipt file
    xattr -c "/usr/local/share/jamf_connect_monitor/install_receipt.txt" 2>/dev/null || true
    
    # Update inventory if jamf binary exists
    if command -v jamf &> /dev/null; then
        jamf recon &
        log_message "Jamf inventory update initiated"
    else
        log_message "Jamf binary not found - skipping inventory update"
    fi
}

# Cleanup temporary files
cleanup_temp_files() {
    log_message "Cleaning up temporary files"
    
    rm -f "/tmp/jamf_monitor_current_admins.txt"
    rm -f "/tmp/jamf_monitor_config.env"
    
    log_message "Temporary files cleaned up"
}

# Send installation notification (generic, no customer info)
send_installation_notification() {
    if [[ -n "$WEBHOOK_URL" ]]; then
        local hostname=$(hostname)
        local payload="{
            \"text\": \"✅ Jamf Connect Monitor Installed\",
            \"attachments\": [{
                \"color\": \"good\",
                \"fields\": [
                    {\"title\": \"Hostname\", \"value\": \"$hostname\", \"short\": true},
                    {\"title\": \"Version\", \"value\": \"$PACKAGE_VERSION\", \"short\": true},
                    {\"title\": \"Monitoring Interval\", \"value\": \"$MONITORING_INTERVAL seconds\", \"short\": true},
                    {\"title\": \"Install Date\", \"value\": \"$(date)\", \"short\": true}
                ]
            }]
        }"
        
        curl -X POST -H 'Content-type: application/json' \
             --data "$payload" \
             "$WEBHOOK_URL" &>/dev/null && \
        log_message "Installation notification sent via webhook"
    fi
}

# Main execution
main() {
    log_message "=== Starting Jamf Connect Monitor Post-Installation ==="
    log_message "Parameters - Webhook: $([[ -n "$WEBHOOK_URL" ]] && echo "Configured" || echo "None"), Email: $([[ -n "$EMAIL_RECIPIENT" ]] && echo "Configured" || echo "None"), Interval: $MONITORING_INTERVAL"
    
    # Verify package installation
    if ! verify_installation; then
        log_message "ERROR: Package verification failed"
        exit 1
    fi
    
    # Configure components
    configure_monitoring_script
    create_approved_admin_list
    configure_launch_daemon
    create_config_file
    
    # Initialize and start monitoring
    initialize_monitoring
    start_monitoring_daemon
    
    # Complete setup
    update_jamf_inventory
    send_installation_notification
    cleanup_temp_files
    
    log_message "=== Post-installation completed successfully ==="
    log_message "Monitor status: $(launchctl list | grep jamfconnectmonitor | awk '{print $1}' | head -1)"
    log_message "Log files: /var/log/jamf_connect_monitor/"
    log_message "Configuration: $CONFIG_FILE"
    log_message "Approved admins: $APPROVED_ADMINS ($(wc -l < "$APPROVED_ADMINS" | tr -d ' ') users)"
    
    exit 0
}

# Execute main function
main