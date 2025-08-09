#!/bin/bash

# Jamf Pro Extension Attribute - Admin Account Violations
# Version: 2.4.0 - Added legitimate elevation tracking and analytics
# Author: MacJediWizard
# Description: Reports unauthorized admin account violations, monitoring status, elevation tracking, and configuration
# Compatible with: Jamf Pro 10.19+ and macOS 10.14+
# Last Updated: 2025-08-09

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

# Function to auto-detect version from main script
get_version_from_main_script() {
    local version="Unknown"
    
    if [[ -f "/usr/local/bin/jamf_connect_monitor.sh" ]]; then
        # Method 1: Extract from VERSION= variable (preferred for v2.0.1+)
        version=$(grep "^VERSION=" /usr/local/bin/jamf_connect_monitor.sh 2>/dev/null | cut -d'"' -f2)
        
        # Method 2: Extract from header comment (fallback)
        if [[ -z "$version" || "$version" == "" ]]; then
            version=$(head -10 /usr/local/bin/jamf_connect_monitor.sh | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        fi
        
        # Method 3: Check for v2.x indicators if version still not found
        if [[ -z "$version" || "$version" == "" ]]; then
            if grep -q "Configuration Profile" /usr/local/bin/jamf_connect_monitor.sh 2>/dev/null; then
                version="2.x"
            else
                version="1.x"
            fi
        fi
    else
        version="Not Installed"
    fi
    
    echo "$version"
}

# Function to check Configuration Profile deployment status - WORKING VERSION
get_config_profile_status() {
    local webhook_status="Not Configured"
    local email_status="Not Configured"
    local smtp_status="Not Configured"
    local profile_version="Not Deployed"
    local monitoring_mode="Unknown"
    local company_name="Unknown"
    
    # Use the working methods from diagnostic
    local config_data=""
    
    # Method 2: Managed Preferences path (WORKS)
    if config_data=$(defaults read "/Library/Managed Preferences/$CONFIG_DOMAIN" 2>/dev/null); then
        profile_version="Deployed"
    # Method 4: Full path managed preferences (WORKS) 
    elif config_data=$(sudo defaults read "/Library/Managed Preferences/$CONFIG_DOMAIN" 2>/dev/null); then
        profile_version="Deployed"
    # Method 3: Root context (backup)
    elif config_data=$(sudo defaults read "$CONFIG_DOMAIN" 2>/dev/null); then
        profile_version="Deployed"
    fi
    
    # Parse configuration data if found
    if [[ "$profile_version" == "Deployed" && -n "$config_data" ]]; then
        # Parse webhook - look for WebhookURL with actual URL
        if echo "$config_data" | grep -q "WebhookURL" && echo "$config_data" | grep -q "http"; then
            webhook_status="Configured"
        fi
        
        # Parse email - look for EmailRecipient with @ symbol
        if echo "$config_data" | grep -q "EmailRecipient"; then
            local email_addr=$(echo "$config_data" | awk -F' = ' '/EmailRecipient/ {gsub(/[";]/, "", $2); print $2}' | head -1)
            if [[ -n "$email_addr" ]]; then
                email_status="$email_addr"
            fi
        fi
        
        # Parse SMTP configuration
        local smtp_provider=$(echo "$config_data" | awk -F' = ' '/SMTPProvider/ {gsub(/[";]/, "", $2); print $2}' | head -1)
        local smtp_server=$(echo "$config_data" | awk -F' = ' '/SMTPServer/ {gsub(/[";]/, "", $2); print $2}' | head -1)
        if [[ -n "$smtp_server" ]]; then
            if [[ -n "$smtp_provider" ]]; then
                smtp_status="${smtp_provider}:${smtp_server}"
            else
                smtp_status="$smtp_server"
            fi
        fi
        
        # Parse monitoring mode - enhanced detection
        if echo "$config_data" | grep -q "MonitoringMode"; then
            # Look for periodic, realtime, or hybrid
            monitoring_mode=$(echo "$config_data" | grep -A2 -B2 "MonitoringMode" | grep -o -E "(periodic|realtime|hybrid)" | head -1)
            # Alternative parsing method
            if [[ -z "$monitoring_mode" ]]; then
                if echo "$config_data" | grep -q "periodic"; then
                    monitoring_mode="periodic"
                elif echo "$config_data" | grep -q "realtime"; then
                    monitoring_mode="realtime"
                elif echo "$config_data" | grep -q "hybrid"; then
                    monitoring_mode="hybrid"
                fi
            fi
            # Final fallback
            [[ -z "$monitoring_mode" ]] && monitoring_mode="periodic"
        else
            monitoring_mode="periodic"
        fi
        
        # Parse company name
        if echo "$config_data" | grep -q "CompanyName"; then
            company_name=$(echo "$config_data" | grep -A1 "CompanyName" | grep -o '"[^"]*"' | head -1 | tr -d '"')
            [[ -z "$company_name" ]] && company_name="Configured"
        fi
    fi
    
    echo "Profile: $profile_version, Webhook: $webhook_status, Email: $email_status, SMTP: $smtp_status, Mode: $monitoring_mode, Company: $company_name"
}

# Function to get current elevation status with analytics
get_elevation_status() {
    local elevation_status="None"
    local elevation_log="/var/log/jamf_connect_monitor/elevation_history.log"
    local legitimate_log="/var/log/jamf_connect_monitor/legitimate_elevations.log"
    
    # Check for current elevations
    local current_elevations=""
    for elevation_file in /var/log/jamf_connect_monitor/.current_elevation_*; do
        if [[ -f "$elevation_file" ]]; then
            local user=$(basename "$elevation_file" | sed 's/.current_elevation_//')
            local info=$(cat "$elevation_file")
            local reason=$(echo "$info" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
            if [[ -n "$current_elevations" ]]; then
                current_elevations="$current_elevations; "
            fi
            current_elevations="${current_elevations}${user}:${reason}"
        fi
    done
    
    # Add legitimate elevation count
    local legit_count=0
    if [[ -f "$legitimate_log" ]]; then
        legit_count=$(grep -c "LEGITIMATE_ELEVATION" "$legitimate_log" 2>/dev/null || echo "0")
    fi
    
    if [[ -n "$current_elevations" ]]; then
        elevation_status="Current: $current_elevations (Total Legit: $legit_count)"
    elif [[ $legit_count -gt 0 ]]; then
        elevation_status="None Active (Total Legit: $legit_count)"
    fi
    
    echo "$elevation_status"
}

# Function to get comprehensive monitoring status with auto-detection
get_monitoring_status() {
    local periodic_status="Not Running"
    local realtime_status="Not Running"
    local version=$(get_version_from_main_script)
    
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
            # Get the timestamp from the last violation entry
            last_violation=$(grep -A2 "ADMIN PRIVILEGE VIOLATION DETECTED" "$REPORT_LOG" | grep "Timestamp:" | tail -1 | sed 's/Timestamp: //' || echo "Unknown")
            # Clean up any extra whitespace but preserve the space between date and time
            last_violation=$(echo "$last_violation" | xargs)
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
    
    echo "Total: $total_violations, Recent: $recent_violations, Last: \"$last_violation\", Unauthorized: $unauthorized_count"
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
    
    # Test configuration profile reading using working methods
    config_test="Failed"
    if defaults read "/Library/Managed Preferences/$CONFIG_DOMAIN" >/dev/null 2>&1; then
        config_test="OK"
    elif sudo defaults read "/Library/Managed Preferences/$CONFIG_DOMAIN" >/dev/null 2>&1; then
        config_test="OK"
    elif sudo defaults read "$CONFIG_DOMAIN" >/dev/null 2>&1; then
        config_test="OK"
    fi
    
    echo "Last Check: $last_check, Daemon: $daemon_health, Logs: $log_size, Config Test: $config_test"
}

# Main execution - Enhanced format for v2.x with working Configuration Profile detection
main() {
    local monitoring_status=$(get_monitoring_status)
    local config_status=$(get_config_profile_status)  
    local violation_summary=$(get_violation_summary)
    local admin_status="Current: [$(get_current_admins)], Approved: [$(get_approved_admins)]"
    local jamf_connect_status=$(get_jamf_connect_status)
    local elevation_status=$(get_elevation_status)
    local health_metrics=$(get_health_metrics)
    
    # Enhanced result format for better Smart Group compatibility
    local result="=== JAMF CONNECT MONITOR STATUS v2.x ===
$monitoring_status
Configuration: $config_status
Violations: $violation_summary
Admin Status: $admin_status
Elevations: $elevation_status
Jamf Connect: $jamf_connect_status
Health: $health_metrics
Report Generated: $(date '+%Y-%m-%d %H:%M:%S')"

    echo "<result>$result</result>"
}

main