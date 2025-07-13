#!/bin/bash

# Jamf Pro Extension Attribute - Admin Account Violations
# Version: 1.0.1
# Author: System Administrator  
# Description: Reports unauthorized admin account violations and current monitoring status
# Compatible with: Jamf Pro 10.27+ and macOS 10.14+
# Last Updated: $(date '+%Y-%m-%d')

REPORT_LOG="/var/log/jamf_connect_monitor/admin_violations.log"
ADMIN_WHITELIST="/usr/local/etc/approved_admins.txt"

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
    if [ -f "$ADMIN_WHITELIST" ]; then
        cat "$ADMIN_WHITELIST" | sort | tr '\n' ',' | sed 's/,$//'
    else
        echo "Not configured"
    fi
}

# Function to check for recent violations
get_recent_violations() {
    if [ -f "$REPORT_LOG" ]; then
        # Get violations from last 7 days
        local recent_violations=$(grep "ADMIN PRIVILEGE VIOLATION DETECTED" "$REPORT_LOG" | tail -n 5)
        if [ -n "$recent_violations" ]; then
            echo "$recent_violations" | while read line; do
                # Extract timestamp and user from violation log
                local timestamp=$(echo "$line" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}')
                local user=$(sed -n '/'"$(echo "$line" | head -1)"'/,/^$/p' "$REPORT_LOG" | grep "Unauthorized User:" | head -1 | awk '{print $3}')
                echo "[$timestamp] User: $user"
            done | tr '\n' '; '
        else
            echo "None"
        fi
    else
        echo "Not monitored"
    fi
}

# Function to check if monitoring is active
check_monitoring_status() {
    if pgrep -f "jamf_connect_monitor.sh" > /dev/null; then
        echo "Active"
    elif [ -f "/Library/LaunchDaemons/com.company.jamfconnectmonitor.plist" ]; then
        if launchctl list | grep -q "com.company.jamfconnectmonitor"; then
            echo "Scheduled"
        else
            echo "Configured but not running"
        fi
    else
        echo "Not configured"
    fi
}

# Function to get Jamf Connect elevation status
get_jamf_connect_status() {
    # Check if Jamf Connect is installed and elevation is enabled
    if [ -f "/Applications/Jamf Connect.app/Contents/Info.plist" ]; then
        # Check if elevation is configured
        local elevation_enabled=$(defaults read /Library/Managed\ Preferences/com.jamf.connect.plist TemporaryUserPromotion 2>/dev/null)
        if [ "$elevation_enabled" = "1" ]; then
            echo "Enabled"
        else
            echo "Installed but elevation disabled"
        fi
    else
        echo "Not installed"
    fi
}

# Function to detect unauthorized admins
detect_unauthorized_admins() {
    if [ ! -f "$ADMIN_WHITELIST" ]; then
        echo "Monitoring not configured"
        return
    fi
    
    local current_admins=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | sed 's/GroupMembership: //' | tr ' ' '\n' | grep -v '^_' | grep -v '^root$' | grep -v '^daemon$' | sort)
    local approved_admins=$(cat "$ADMIN_WHITELIST" | sort)
    local unauthorized=""
    
    while IFS= read -r user; do
        if [ -n "$user" ] && ! echo "$approved_admins" | grep -q "^$user$"; then
            if [ -z "$unauthorized" ]; then
                unauthorized="$user"
            else
                unauthorized="$unauthorized,$user"
            fi
        fi
    done <<< "$current_admins"
    
    if [ -n "$unauthorized" ]; then
        echo "$unauthorized"
    else
        echo "None"
    fi
}

# Main execution
main() {
    local monitoring_status=$(check_monitoring_status)
    local jamf_connect_status=$(get_jamf_connect_status)
    local current_admins=$(get_current_admins)
    local approved_admins=$(get_approved_admins)
    local recent_violations=$(get_recent_violations)
    local unauthorized_admins=$(detect_unauthorized_admins)
    local last_check="Unknown"
    
    # Get last monitoring check time
    if [ -f "/var/log/jamf_connect_monitor/monitor.log" ]; then
        last_check=$(tail -1 /var/log/jamf_connect_monitor/monitor.log | grep -o '\[.*\]' | head -1 | tr -d '[]' | head -1)
    fi
    
    # Format result for Jamf Pro
    local result="Monitoring Status: $monitoring_status
Jamf Connect Status: $jamf_connect_status
Last Check: $last_check
Current Admins: $current_admins
Approved Admins: $approved_admins
Unauthorized Admins: $unauthorized_admins
Recent Violations: $recent_violations"

    echo "<result>$result</result>"
}

# Execute main function
main