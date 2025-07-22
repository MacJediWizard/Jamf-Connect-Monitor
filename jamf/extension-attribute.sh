#!/bin/bash

# Jamf Pro Extension Attribute - Admin Account Violations
# Version: 2.0.0 - Enhanced with Configuration Profile support
# Author: MacJediWizard
# Description: Reports unauthorized admin account violations, monitoring status, and configuration
# Compatible with: Jamf Pro 10.19+ and macOS 10.14+
# Last Updated: 2025-07-14

REPORT_LOG="/var/log/jamf_connect_monitor/admin_violations.log"
REALTIME_LOG="/var/log/jamf_connect_monitor/realtime_monitor.log"
ADMIN_WHITELIST="/usr/local/etc/approved_admins.txt"
CONFIG_DOMAIN="com.macjediwizard.jamfconnectmonitor"

# Function to get current admin users (excluding system accounts)
get_current_admins() {
    dscl . -read /Groups/admin GroupMembership 2>/dev/null | \
    sed 's/GroupMembership: //' | \
    tr ' ' '\n' | \
    grep -v '^_' | \
    grep -v '^root$' | \
    grep -v '^daemon$' | \
    sort | tr '\n' ',' | sed 's/,$//'
}

# Function to get approved admin users
get_approved_admins() {
    if [[ -f "$ADMIN_WHITELIST" ]]; then
        cat "$ADMIN_WHITELIST" | sort | tr '\n' ',' | sed 's/,$//'
    else
        echo "Not configured"
    fi
}

# Function to check Configuration Profile deployment status
get_config_profile_status() {
    local webhook_status="Not Configured"
    local email_status="Not Configured"
    local profile_version="Not Deployed"
    local monitoring_mode="Unknown"
    local company_name="Unknown"
    
    if defaults read "$CONFIG_DOMAIN" >/dev/null 2>&1; then
        profile_version="Deployed"
        
        # Check notification settings
        if defaults read "$CONFIG_DOMAIN" NotificationSettings.WebhookURL 2>/dev/null | grep -q "http"; then
            webhook_status="Configured"
        fi
        
        if defaults read "$CONFIG_DOMAIN" NotificationSettings.EmailRecipient 2>/dev/null | grep -q "@"; then
            email_status="Configured"
        fi
        
        # Get monitoring mode
        monitoring_mode=$(defaults read "$CONFIG_DOMAIN" MonitoringBehavior.MonitoringMode 2>/dev/null || echo "periodic")
        
        # Get company name
        company_name=$(defaults read "$CONFIG_DOMAIN" JamfProIntegration.CompanyName 2>/dev/null || echo "Not Set")
    fi
    
    echo "Profile: $profile_version, Webhook: $webhook_status, Email: $email_status, Mode: $monitoring_mode, Company: $company_name"
}

# Function to get comprehensive monitoring status
get_monitoring_status() {
    local periodic_status="Not Running"
    local realtime_status="Not Running"
    local version="Unknown"
    
    # Check for version 2.0.0 script
    if [[ -f "/usr/local/bin/jamf_connect_monitor.sh" ]]; then
        version=$(grep "Version: 2.0.0" /usr/local/bin/jamf_connect_monitor.sh >/dev/null 2>&1 && echo "2.0.0" || echo "1.x")
    fi
    
    # Check periodic monitoring (LaunchDaemon)
    if launchctl list | grep -q "com.macjediwizard.jamfconnectmonitor"; then
        periodic_status="Running"
    fi
    
    # Check real-time monitoring
    if pgrep -f "jamf_connect_realtime_monitor" > /dev/null; then
        realtime_status="Active"
    elif launchctl list | grep -q "realtime"; then
        realtime_status="Loaded"
    fi
    
    echo "Version: $version, Periodic: $periodic_status, Real-time: $realtime_status"
}

# Function to get violation summary with enhanced details
get_violation_summary() {
    local total_violations=0
    local recent_violations=0
    local last_violation="None"
    local unauthorized_count=0
    
    # Get violation counts
    if [[ -f "$REPORT_LOG" ]]; then
        total_violations=$(grep -c "ADMIN PRIVILEGE VIOLATION DETECTED" "$REPORT_LOG" 2>/dev/null || echo "0")
        recent_violations=$(grep "ADMIN PRIVILEGE VIOLATION DETECTED" "$REPORT_LOG" 2>/dev/null | tail -7 | wc -l | tr -d ' ')
        
        if [[ $total_violations -gt 0 ]]; then
            last_violation=$(grep "ADMIN PRIVILEGE VIOLATION DETECTED" "$REPORT_LOG" | tail -1 | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}' || echo "Unknown")
        fi
    fi
    
    # Check for currently unauthorized admins
    if [[ -f "$ADMIN_WHITELIST" ]]; then
        local current_admins=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | \
            sed 's/GroupMembership: //' | tr ' ' '\n' | \
            grep -v '^_' | grep -v '^root$' | grep -v '^daemon$' | sort)
        local approved_admins=$(cat "$ADMIN_WHITELIST" | sort)
        
        while IFS= read -r user; do
            if [[ -n "$user" ]] && ! echo "$approved_admins" | grep -q "^$user$"; then
                ((unauthorized_count++))
            fi
        done <<< "$current_admins"
    fi
    
    echo "Total: $total_violations, Recent: $recent_violations, Last: $last_violation, Unauthorized: $unauthorized_count"
}

# Function to get Jamf Connect integration status
get_jamf_connect_status() {
    local connect_installed="No"
    local elevation_enabled="No"
    local monitoring_jamf_events="No"
    
    # Check if Jamf Connect is installed
    if [[ -f "/Applications/Jamf Connect.app/Contents/Info.plist" ]]; then
        connect_installed="Yes"
        
        # Check if elevation is enabled (check multiple possible locations and formats)
        if defaults read "/Library/Managed Preferences/com.jamf.connect.plist" TemporaryUserPromotion 2>/dev/null | grep -q "1"; then
            elevation_enabled="Yes"
        elif /usr/libexec/PlistBuddy -c "Print :TemporaryUserPermissions:TemporaryUserPromotion" "/Library/Managed Preferences/com.jamf.connect.plist" 2>/dev/null | grep -q "true"; then
            elevation_enabled="Yes"
        elif defaults read "/Library/Preferences/com.jamf.connect.plist" TemporaryUserPromotion 2>/dev/null | grep -q "1"; then
            elevation_enabled="Yes"
        fi
    fi
    
    # Check if we're actively monitoring Jamf Connect events
    if [[ -f "/var/log/jamf_connect_monitor/jamf_connect_events.log" ]]; then
        local recent_events=$(find /var/log/jamf_connect_monitor/jamf_connect_events.log -mtime -1 2>/dev/null)
        if [[ -n "$recent_events" ]]; then
            monitoring_jamf_events="Yes"
        fi
    fi
    
    echo "Installed: $connect_installed, Elevation: $elevation_enabled, Monitoring: $monitoring_jamf_events"
}

# Function to get system health and performance metrics
get_health_metrics() {
    local last_check="Unknown"
    local daemon_health="Unknown"
    local log_size="0MB"
    local config_test="Unknown"
    
    # Get last monitoring check
    if [[ -f "/var/log/jamf_connect_monitor/monitor.log" ]]; then
        last_check=$(tail -1 /var/log/jamf_connect_monitor/monitor.log 2>/dev/null | grep -o '\[.*\]' | head -1 | tr -d '[]')
        if [[ -z "$last_check" ]]; then
            last_check="No recent activity"
        fi
    fi
    
    # Check daemon health
    if launchctl list | grep -q "jamfconnectmonitor"; then
        daemon_health="Healthy"
    else
        daemon_health="Not Running"
    fi
    
    # Get log directory size
    if [[ -d "/var/log/jamf_connect_monitor" ]]; then
        log_size=$(du -sh /var/log/jamf_connect_monitor 2>/dev/null | cut -f1 || echo "0MB")
    fi
    
    # Test configuration profile reading
    if defaults read "$CONFIG_DOMAIN" >/dev/null 2>&1; then
        config_test="OK"
    else
        config_test="Failed"
    fi
    
    echo "Last Check: $last_check, Daemon: $daemon_health, Logs: $log_size, Config Test: $config_test"
}

# Main execution - Enhanced format for v2.0.0
main() {
    local monitoring_status=$(get_monitoring_status)
    local config_status=$(get_config_profile_status)  
    local violation_summary=$(get_violation_summary)
    local admin_status="Current: [$(get_current_admins)], Approved: [$(get_approved_admins)]"
    local jamf_connect_status=$(get_jamf_connect_status)
    local health_metrics=$(get_health_metrics)
    
    # Enhanced result format for better Smart Group compatibility
    local result="=== JAMF CONNECT MONITOR STATUS v2.0 ===
$monitoring_status
Configuration: $config_status
Violations: $violation_summary
Admin Status: $admin_status
Jamf Connect: $jamf_connect_status
Health: $health_metrics
Report Generated: $(date '+%Y-%m-%d %H:%M:%S')"

    echo "<result>$result</result>"
}

main