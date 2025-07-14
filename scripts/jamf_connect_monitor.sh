#!/bin/bash

# Jamf Connect Elevation Monitor & Admin Account Remediation Script
# This script monitors Jamf Connect elevation events and detects/removes unauthorized admin accounts
# Version: 1.0.2
# Author: System Administrator

# Configuration Variables
SCRIPT_NAME="JamfConnectMonitor"
LOG_DIR="/var/log/jamf_connect_monitor"
ELEVATION_LOG="/Library/Logs/JamfConnect/UserElevationReasons.log"
ADMIN_WHITELIST="/usr/local/etc/approved_admins.txt"
REPORT_LOG="$LOG_DIR/admin_violations.log"
JAMF_LOG="$LOG_DIR/jamf_connect_events.log"
LOCKFILE="/tmp/jamf_connect_monitor.lock"

# Slack/Teams webhook for notifications (optional)
WEBHOOK_URL=""  # Add your webhook URL here

# Email settings (optional)
EMAIL_RECIPIENT=""  # Add email for reports
EMAIL_SUBJECT="Admin Account Violation Detected"

# Create necessary directories
mkdir -p "$LOG_DIR"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/monitor.log"
}

# Check if script is already running
check_lock() {
    if [ -f "$LOCKFILE" ]; then
        local pid=$(cat "$LOCKFILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_message "INFO" "Script already running with PID $pid"
            exit 0
        else
            rm -f "$LOCKFILE"
        fi
    fi
    echo $$ > "$LOCKFILE"
}

# Cleanup function
cleanup() {
    rm -f "$LOCKFILE"
    exit 0
}
trap cleanup EXIT INT TERM

# Initialize approved admin list if it doesn't exist
initialize_admin_whitelist() {
    if [ ! -f "$ADMIN_WHITELIST" ]; then
        log_message "INFO" "Creating initial admin whitelist"
        
        # Get current admin users (excluding system accounts)
        dscl . -read /Groups/admin GroupMembership 2>/dev/null | \
        sed 's/GroupMembership: //' | \
        tr ' ' '\n' | \
        grep -v '^_' | \
        grep -v '^root$' | \
        grep -v '^daemon$' | \
        sort > "$ADMIN_WHITELIST"
        
        log_message "INFO" "Initial admin whitelist created with $(wc -l < "$ADMIN_WHITELIST") users"
    fi
}

# Get current admin users
get_current_admins() {
    dscl . -read /Groups/admin GroupMembership 2>/dev/null | \
    sed 's/GroupMembership: //' | \
    tr ' ' '\n' | \
    grep -v '^_' | \
    grep -v '^root$' | \
    grep -v '^daemon$' | \
    sort
}

# Get approved admin users
get_approved_admins() {
    if [ -f "$ADMIN_WHITELIST" ]; then
        cat "$ADMIN_WHITELIST" | sort
    else
        echo ""
    fi
}

# Check for Jamf Connect elevation events
monitor_jamf_connect_elevation() {
    log_message "INFO" "Monitoring Jamf Connect elevation events"
    
    # Check if Jamf Connect elevation log exists
    if [ ! -f "$ELEVATION_LOG" ]; then
        log_message "WARN" "Jamf Connect elevation log not found at $ELEVATION_LOG"
        return 1
    fi
    
    # Get recent elevation events (last 5 minutes)
    local recent_events=$(log show --style compact --predicate '(subsystem == "com.jamf.connect.daemon") && (category == "PrivilegeElevation")' --last 5m 2>/dev/null)
    
    if [ -n "$recent_events" ]; then
        log_message "INFO" "Recent Jamf Connect elevation detected"
        echo "$recent_events" >> "$JAMF_LOG"
        
        # Extract elevation and demotion events
        echo "$recent_events" | while read line; do
            if echo "$line" | grep -q "Added user"; then
                local user=$(echo "$line" | sed -n 's/.*Added user \([^[:space:]]*\).*/\1/p')
                log_message "INFO" "User elevated via Jamf Connect: $user"
            elif echo "$line" | grep -q "Removed user"; then
                local user=$(echo "$line" | sed -n 's/.*Removed user \([^[:space:]]*\).*/\1/p')
                log_message "INFO" "User demoted via Jamf Connect: $user"
            fi
        done
    fi
}

# Check for unauthorized admin accounts
check_unauthorized_admins() {
    log_message "INFO" "Checking for unauthorized admin accounts"
    
    local current_admins=$(get_current_admins)
    local approved_admins=$(get_approved_admins)
    local unauthorized_admins=""
    
    # Find users who are admin but not approved
    while IFS= read -r user; do
        if [ -n "$user" ] && ! echo "$approved_admins" | grep -q "^$user$"; then
            unauthorized_admins="$unauthorized_admins $user"
        fi
    done <<< "$current_admins"
    
    if [ -n "$unauthorized_admins" ]; then
        log_message "ERROR" "Unauthorized admin accounts detected: $unauthorized_admins"
        
        for user in $unauthorized_admins; do
            report_violation "$user"
            remove_admin_privileges "$user"
        done
    else
        log_message "INFO" "No unauthorized admin accounts detected"
    fi
}

# Report admin privilege violation
report_violation() {
    local user="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname=$(hostname)
    local current_user=$(who | awk 'NR==1{print $1}')
    
    # Create detailed violation report
    local violation_report="ADMIN PRIVILEGE VIOLATION DETECTED
Timestamp: $timestamp
Hostname: $hostname
Unauthorized User: $user
Current Console User: $current_user
Action Taken: Admin privileges removed

Recent Admin Group Members:
$(get_current_admins)

Recent Jamf Connect Activity:
$(tail -n 10 "$JAMF_LOG" 2>/dev/null || echo "No recent activity")

System Information:
macOS Version: $(sw_vers -productVersion)
Build: $(sw_vers -buildVersion)
"
    
    # Log the violation
    echo "$violation_report" >> "$REPORT_LOG"
    log_message "ERROR" "Violation report created for user: $user"
    
    # Send notification if webhook configured
    if [ -n "$WEBHOOK_URL" ]; then
        send_webhook_notification "$user" "$hostname"
    fi
    
    # Send email if configured
    if [ -n "$EMAIL_RECIPIENT" ]; then
        send_email_notification "$user" "$hostname" "$violation_report"
    fi
    
    # Report to Jamf Pro if available
    report_to_jamf_pro "$user" "$violation_report"
}

# Remove admin privileges from unauthorized user
remove_admin_privileges() {
    local user="$1"
    
    log_message "WARN" "Removing admin privileges from unauthorized user: $user"
    
    # Remove user from admin group
    if dseditgroup -o edit -d "$user" admin; then
        log_message "INFO" "Successfully removed $user from admin group"
        
        # Verify removal
        if dsmemberutil checkmembership -U "$user" -G admin | grep -q "user is not"; then
            log_message "INFO" "Confirmed: $user no longer has admin privileges"
        else
            log_message "ERROR" "Failed to verify admin privilege removal for $user"
        fi
    else
        log_message "ERROR" "Failed to remove admin privileges from $user"
    fi
}

# Send webhook notification
send_webhook_notification() {
    local user="$1"
    local hostname="$2"
    
    if [ -n "$WEBHOOK_URL" ]; then
        local payload="{
            \"text\": \"🚨 Admin Privilege Violation Detected\",
            \"attachments\": [{
                \"color\": \"danger\",
                \"fields\": [
                    {\"title\": \"Hostname\", \"value\": \"$hostname\", \"short\": true},
                    {\"title\": \"Unauthorized User\", \"value\": \"$user\", \"short\": true},
                    {\"title\": \"Action Taken\", \"value\": \"Admin privileges removed\", \"short\": false},
                    {\"title\": \"Timestamp\", \"value\": \"$(date)\", \"short\": false}
                ]
            }]
        }"
        
        curl -X POST -H 'Content-type: application/json' \
             --data "$payload" \
             "$WEBHOOK_URL" &>/dev/null
        
        log_message "INFO" "Webhook notification sent for user: $user"
    fi
}

# Send email notification
send_email_notification() {
    local user="$1"
    local hostname="$2"
    local report="$3"
    
    if [ -n "$EMAIL_RECIPIENT" ]; then
        echo "$report" | mail -s "$EMAIL_SUBJECT - $hostname" "$EMAIL_RECIPIENT" 2>/dev/null
        log_message "INFO" "Email notification sent for user: $user"
    fi
}

# Report to Jamf Pro (if available)
report_to_jamf_pro() {
    local user="$1"
    local report="$2"
    
    # Check if Jamf binary exists
    if command -v jamf &> /dev/null; then
        # Create a Jamf Pro Extension Attribute to track violations
        local ea_result="<result>VIOLATION: User $user had unauthorized admin privileges removed at $(date)</result>"
        
        # You can submit this via a custom EA or policy
        log_message "INFO" "Jamf Pro integration: Violation recorded for $user"
        
        # Trigger a policy to report the violation (optional)
        # jamf policy -trigger admin_violation_detected &>/dev/null
    fi
}

# Add user to approved admin list
add_approved_admin() {
    local user="$1"
    
    if [ -n "$user" ]; then
        if ! grep -q "^$user$" "$ADMIN_WHITELIST" 2>/dev/null; then
            echo "$user" >> "$ADMIN_WHITELIST"
            sort -u "$ADMIN_WHITELIST" -o "$ADMIN_WHITELIST"
            log_message "INFO" "Added $user to approved admin list"
        else
            log_message "INFO" "User $user already in approved admin list"
        fi
    fi
}

# Remove user from approved admin list
remove_approved_admin() {
    local user="$1"
    
    if [ -n "$user" ] && [ -f "$ADMIN_WHITELIST" ]; then
        if grep -q "^$user$" "$ADMIN_WHITELIST"; then
            grep -v "^$user$" "$ADMIN_WHITELIST" > "${ADMIN_WHITELIST}.tmp"
            mv "${ADMIN_WHITELIST}.tmp" "$ADMIN_WHITELIST"
            log_message "INFO" "Removed $user from approved admin list"
        else
            log_message "INFO" "User $user not found in approved admin list"
        fi
    fi
}

# Display current status
show_status() {
    echo "=== Jamf Connect Elevation Monitor Status ==="
    echo "Current Admin Users:"
    get_current_admins | sed 's/^/  /'
    echo
    echo "Approved Admin Users:"
    get_approved_admins | sed 's/^/  /'
    echo
    echo "Recent Violations:"
    if [ -f "$REPORT_LOG" ]; then
        tail -n 5 "$REPORT_LOG" | grep "ADMIN PRIVILEGE VIOLATION" | sed 's/^/  /'
    else
        echo "  No violations recorded"
    fi
}

# Main monitoring function
main_monitor() {
    log_message "INFO" "Starting Jamf Connect elevation monitoring"
    
    # Initialize whitelist if needed
    initialize_admin_whitelist
    
    # Monitor Jamf Connect elevation events
    monitor_jamf_connect_elevation
    
    # Check for unauthorized admin accounts
    check_unauthorized_admins
    
    log_message "INFO" "Monitoring cycle completed"
}

# Command line interface
case "${1:-monitor}" in
    "monitor")
        check_lock
        main_monitor
        ;;
    "status")
        show_status
        ;;
    "add-admin")
        if [ -z "$2" ]; then
            echo "Usage: $0 add-admin <username>"
            exit 1
        fi
        add_approved_admin "$2"
        ;;
    "remove-admin")
        if [ -z "$2" ]; then
            echo "Usage: $0 remove-admin <username>"
            exit 1
        fi
        remove_approved_admin "$2"
        ;;
    "force-check")
        check_lock
        check_unauthorized_admins
        ;;
    "help")
        echo "Usage: $0 [command]"
        echo "Commands:"
        echo "  monitor        Run monitoring cycle (default)"
        echo "  status         Show current status"
        echo "  add-admin      Add user to approved admin list"
        echo "  remove-admin   Remove user from approved admin list"
        echo "  force-check    Force check for unauthorized admins"
        echo "  help           Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac