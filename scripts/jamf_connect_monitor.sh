#!/bin/bash

# Jamf Connect Elevation Monitor & Admin Account Remediation Script
# Version: 2.2.0 - SMTP-only email delivery (removed unreliable system mail fallback)
# Author: MacJediWizard

# Centralized Version Management
VERSION="2.2.0"
SCRIPT_NAME="JamfConnectMonitor"

# Configuration Variables
LOG_DIR="/var/log/jamf_connect_monitor"
ELEVATION_LOG="/Library/Logs/JamfConnect/UserElevationReasons.log"
ADMIN_WHITELIST="/usr/local/etc/approved_admins.txt"
REPORT_LOG="$LOG_DIR/admin_violations.log"
JAMF_LOG="$LOG_DIR/jamf_connect_events.log"
LOCKFILE="/tmp/jamf_connect_monitor.lock"

# Configuration Profile domain
CONFIG_PROFILE_DOMAIN="com.macjediwizard.jamfconnectmonitor"

# Read configuration from managed preferences (Configuration Profile) - FIXED VERSION WITH SMTP
read_configuration() {
    local config_data=""
    local config_source=""
    
    # Use the same working methods as Extension Attribute (Methods 2 & 4)
    if config_data=$(defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null); then
        config_source="Method 2 (Managed Preferences)"
    elif config_data=$(sudo defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null); then
        config_source="Method 4 (sudo Managed Preferences)"
    elif config_data=$(defaults read "$CONFIG_PROFILE_DOMAIN" 2>/dev/null); then
        config_source="Method 1 (Standard)"
    fi
    
    if [[ -n "$config_data" ]]; then
        log_message "INFO" "Configuration Profile found via $config_source"
        
        # Helper function to parse boolean values from Configuration Profile
        parse_boolean() {
            local key="$1"
            local default_value="$2"
            local value=$(echo "$config_data" | grep -A1 "$key" | grep -o -E "(true|false|1|0)" | head -1)
            
            case "$value" in
                "true"|"1") echo "true" ;;
                "false"|"0") echo "false" ;;
                *) echo "$default_value" ;;
            esac
        }
        
        # Parse settings from the config data using robust extraction
        # Notification Settings
        WEBHOOK_URL=$(echo "$config_data" | grep -A1 "WebhookURL" | grep -o 'https://[^"]*' | head -1 || echo "")
        EMAIL_RECIPIENT=$(echo "$config_data" | grep -A1 "EmailRecipient" | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]*' | head -1 || echo "")
        
        # SMTP Configuration - NEW
        SMTP_SERVER=$(echo "$config_data" | grep -A1 "SMTPServer" | grep -o '"[^"]*"' | tr -d '"' | head -1 || echo "")
        SMTP_PORT=$(echo "$config_data" | grep -A1 "SMTPPort" | grep -o '[0-9]*' | head -1 || echo "465")
        SMTP_USERNAME=$(echo "$config_data" | grep -A1 "SMTPUsername" | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]*' | head -1 || echo "")
        SMTP_PASSWORD=$(echo "$config_data" | grep -A1 "SMTPPassword" | grep -o '"[^"]*"' | tr -d '"' | head -1 || echo "")
        SMTP_FROM_ADDRESS=$(echo "$config_data" | grep -A1 "SMTPFromAddress" | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]*' | head -1 || echo "$SMTP_USERNAME")
        
        NOTIFICATION_TEMPLATE=$(echo "$config_data" | grep -A1 "NotificationTemplate" | grep -o '"[^"]*"' | tr -d '"' | grep -E "(simple|detailed|security_report)" | head -1 || echo "detailed")
        NOTIFICATION_COOLDOWN=$(echo "$config_data" | grep -A1 "NotificationCooldownMinutes" | grep -o '[0-9]*' | head -1 || echo "15")
        
        # Monitoring Behavior - FIXED BOOLEAN PARSING
        MONITORING_MODE=$(echo "$config_data" | grep -A1 "MonitoringMode" | grep -o -E "(periodic|realtime|hybrid)" | head -1 || echo "periodic")
        AUTO_REMEDIATION=$(parse_boolean "AutoRemediation" "true")
        GRACE_PERIOD_MINUTES=$(echo "$config_data" | grep -A1 "GracePeriodMinutes" | grep -o '[0-9]*' | head -1 || echo "5")
        MONITOR_JAMF_CONNECT_ONLY=$(parse_boolean "MonitorJamfConnectOnly" "true")
        
        # Security Settings - FIXED BOOLEAN PARSING
        REQUIRE_CONFIRMATION=$(parse_boolean "RequireConfirmation" "false")
        VIOLATION_REPORTING=$(parse_boolean "ViolationReporting" "true")
        LOG_RETENTION_DAYS=$(echo "$config_data" | grep -A1 "LogRetentionDays" | grep -o '[0-9]*' | head -1 || echo "30")
        
        # Jamf Pro Integration - FIXED COMPANY NAME READING
        UPDATE_INVENTORY_ON_VIOLATION=$(parse_boolean "UpdateInventoryOnViolation" "true")
        TRIGGER_POLICY_ON_VIOLATION=$(echo "$config_data" | grep -A1 "TriggerPolicyOnViolation" | grep -o '"[^"]*"' | tr -d '"' | head -1 || echo "")
        COMPANY_NAME=$(echo "$config_data" | grep -A1 "CompanyName" | grep -o '"[^"]*"' | tr -d '"' | head -1 || echo "Your Company")
        IT_CONTACT_EMAIL=$(echo "$config_data" | grep -A1 "ITContactEmail" | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]*' | head -1 || echo "")
        
        # Advanced Settings - FIXED BOOLEAN PARSING
        DEBUG_LOGGING=$(parse_boolean "DebugLogging" "false")
        MONITORING_INTERVAL=$(echo "$config_data" | grep -A1 "MonitoringInterval" | grep -o '[0-9]*' | head -1 || echo "300")
        MAX_NOTIFICATIONS_PER_HOUR=$(echo "$config_data" | grep -A1 "MaxNotificationsPerHour" | grep -o '[0-9]*' | head -1 || echo "10")
        AUTO_POPULATE_APPROVED_ADMINS=$(parse_boolean "AutoPopulateApprovedAdmins" "true")
        
        # Set default SMTP from address if not configured
        [[ -z "$SMTP_FROM_ADDRESS" ]] && SMTP_FROM_ADDRESS="$SMTP_USERNAME"
        
    else
        # Fallback to default values if no Configuration Profile found
        log_message "INFO" "No Configuration Profile found, using default values"
        
        WEBHOOK_URL=""
        EMAIL_RECIPIENT=""
        SMTP_SERVER=""
        SMTP_PORT="465"
        SMTP_USERNAME=""
        SMTP_PASSWORD=""
        SMTP_FROM_ADDRESS=""
        NOTIFICATION_TEMPLATE="detailed"
        NOTIFICATION_COOLDOWN="15"
        MONITORING_MODE="periodic"
        AUTO_REMEDIATION="true"
        GRACE_PERIOD_MINUTES="5"
        MONITOR_JAMF_CONNECT_ONLY="true"
        REQUIRE_CONFIRMATION="false"
        VIOLATION_REPORTING="true"
        LOG_RETENTION_DAYS="30"
        UPDATE_INVENTORY_ON_VIOLATION="true"
        TRIGGER_POLICY_ON_VIOLATION=""
        COMPANY_NAME="Your Company"
        IT_CONTACT_EMAIL=""
        DEBUG_LOGGING="false"
        MONITORING_INTERVAL="300"
        MAX_NOTIFICATIONS_PER_HOUR="10"
        AUTO_POPULATE_APPROVED_ADMINS="true"
    fi
    
    log_message "INFO" "Configuration loaded from managed preferences"
    if [[ "$DEBUG_LOGGING" == "true" ]]; then
        log_message "DEBUG" "Webhook: $([[ -n "$WEBHOOK_URL" ]] && echo "Configured" || echo "None")"
        log_message "DEBUG" "Email: $([[ -n "$EMAIL_RECIPIENT" ]] && echo "$EMAIL_RECIPIENT" || echo "None")"
        log_message "DEBUG" "SMTP: $([[ -n "$SMTP_SERVER" ]] && echo "Configured ($SMTP_SERVER:$SMTP_PORT)" || echo "System mail")"
        log_message "DEBUG" "Monitoring Mode: $MONITORING_MODE"
        log_message "DEBUG" "Auto Remediation: $AUTO_REMEDIATION"
        log_message "DEBUG" "Violation Reporting: $VIOLATION_REPORTING"
        log_message "DEBUG" "Company: $COMPANY_NAME"
    fi
}

# Create necessary directories
mkdir -p "$LOG_DIR"

# Enhanced logging function with debug support
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Always log INFO, WARN, ERROR, CRITICAL
    # Only log DEBUG if debug logging is enabled
    if [[ "$level" == "DEBUG" && "$DEBUG_LOGGING" != "true" ]]; then
        return
    fi
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/monitor.log"
}

# Check if script is already running
check_lock() {
    if [[ -f "$LOCKFILE" ]]; then
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

# FIXED: Improved SMTP Authentication Functions for Reliable Email Delivery
# Test SMTP connectivity
test_smtp_connection() {
    local smtp_host="$1"
    local smtp_port="$2"
    
    log_message "INFO" "Testing SMTP connectivity to $smtp_host:$smtp_port"
    
    # Test basic connectivity with multiple methods
    if command -v nc >/dev/null 2>&1; then
        # Use nc directly without timeout (macOS doesn't have timeout by default)
        if nc -z -w 10 "$smtp_host" "$smtp_port" 2>/dev/null; then
            log_message "INFO" "SMTP server reachable: $smtp_host:$smtp_port"
            return 0
        fi
    fi
    
    # Fallback connectivity test using bash TCP socket
    if exec 3<>/dev/tcp/"$smtp_host"/"$smtp_port" 2>/dev/null; then
        exec 3<&-
        exec 3>&-
        log_message "INFO" "SMTP server reachable via TCP socket: $smtp_host:$smtp_port"
        return 0
    fi
    
    log_message "ERROR" "Cannot connect to SMTP server: $smtp_host:$smtp_port"
    return 1
}

# FIXED: Improved authenticated email sending with better error handling
send_authenticated_email() {
    local recipient="$1"
    local subject="$2"
    local body="$3"
    
    if [[ -z "$SMTP_SERVER" || -z "$SMTP_USERNAME" || -z "$SMTP_PASSWORD" ]]; then
        log_message "DEBUG" "SMTP authentication not configured - cannot send authenticated email"
        return 1
    fi
    
    # Test SMTP connectivity first
    if ! test_smtp_connection "$SMTP_SERVER" "$SMTP_PORT"; then
        log_message "ERROR" "SMTP connectivity test failed for $SMTP_SERVER:$SMTP_PORT"
        return 1
    fi
    
    log_message "INFO" "Attempting authenticated SMTP delivery to $recipient via $SMTP_SERVER"
    
    # Try swaks first (most reliable for SMTP auth)
    if command -v swaks >/dev/null 2>&1; then
        log_message "DEBUG" "Using swaks for authenticated SMTP"
        
        # Add TLS options based on port
        local tls_option=""
        if [[ "$SMTP_PORT" == "465" ]]; then
            tls_option="--tlsc"  # Use TLS on connect for port 465
        else
            tls_option="--tls"   # Use STARTTLS for other ports
        fi
        
        local swaks_result=$(swaks \
            --to "$recipient" \
            --from "$SMTP_FROM_ADDRESS" \
            --server "$SMTP_SERVER:$SMTP_PORT" \
            --auth-user "$SMTP_USERNAME" \
            --auth-password "$SMTP_PASSWORD" \
            --header "Subject: $subject" \
            --body "$body" \
            $tls_option \
            --suppress-data \
            2>&1)
        
        if echo "$swaks_result" | grep -q "250.*OK"; then
            log_message "INFO" "Authenticated email sent successfully via swaks to $recipient"
            return 0
        else
            log_message "ERROR" "swaks authentication failed: $(echo "$swaks_result" | tail -1)"
            return 1
        fi
    fi
    
    # Fallback to mailx with configuration
    if command -v mailx >/dev/null 2>&1; then
        log_message "DEBUG" "Using mailx for authenticated SMTP"
        
        # Create temporary mailx configuration with proper SSL/TLS settings
        local temp_mailrc="/tmp/jamf_monitor_mailrc_$$"
        
        # Determine SSL/TLS settings based on port
        local use_ssl="no"
        local use_starttls="yes"
        if [[ "$SMTP_PORT" == "465" ]]; then
            use_ssl="yes"
            use_starttls="no"
        fi
        
        cat > "$temp_mailrc" << EOF
set smtp-host=$SMTP_SERVER:$SMTP_PORT
set smtp-use-starttls=$use_starttls
set smtp-use-ssl=$use_ssl
set smtp-auth=yes
set smtp-auth-user=$SMTP_USERNAME
set smtp-auth-password=$SMTP_PASSWORD
set from=$SMTP_FROM_ADDRESS
set ssl-verify=ignore
set nss-config-dir=/etc/ssl/certs
EOF
        
        # Send email using mailx with custom configuration
        local mailx_result=""
        if echo "$body" | MAILRC="$temp_mailrc" mailx -s "$subject" "$recipient" 2>&1; then
            mailx_result=$?
        else
            mailx_result=$?
        fi
        
        # Cleanup
        rm -f "$temp_mailrc"
        
        if [[ $mailx_result -eq 0 ]]; then
            log_message "INFO" "Authenticated email sent successfully via mailx to $recipient"
            return 0
        else
            log_message "ERROR" "mailx authentication failed with exit code $mailx_result"
            return 1
        fi
    fi
    
    log_message "ERROR" "No suitable authenticated email command available (install swaks or mailx)"
    return 1
}

# System mail function removed - SMTP authentication required
# This function is kept as a stub for backwards compatibility but always returns failure
# Configure SMTP settings in Configuration Profile for email delivery
send_system_mail() {
    local recipient="$1"
    log_message "WARN" "System mail is deprecated - SMTP configuration required"
    log_message "INFO" "Configure SMTP settings in Configuration Profile to enable email notifications"
    return 1
}

# Enhanced email sending - SMTP authentication only (no system mail fallback)
enhanced_send_email() {
    local recipient="$1"
    local subject="$2"
    local body="$3"
    
    if [[ -z "$recipient" ]]; then
        log_message "ERROR" "No email recipient specified"
        return 1
    fi
    
    log_message "INFO" "Sending email to $recipient: $subject"
    
    # Require SMTP configuration
    if [[ -z "$SMTP_SERVER" ]]; then
        log_message "ERROR" "SMTP server not configured - email delivery disabled"
        log_message "ERROR" "Configure SMTP settings in Configuration Profile to enable email notifications"
        return 1
    fi
    
    # Send via authenticated SMTP only
    if send_authenticated_email "$recipient" "$subject" "$body"; then
        return 0
    else
        log_message "ERROR" "SMTP email delivery failed - check SMTP configuration and credentials"
        log_message "ERROR" "Ensure SMTP server, port, username, and password are correctly configured"
        return 1
    fi
}

# FIXED: Improved test email function with better diagnostics
send_test_email() {
    local test_recipient="${1:-$EMAIL_RECIPIENT}"
    
    if [[ -z "$test_recipient" ]]; then
        echo "Usage: test-email [recipient@domain.com]"
        echo "No recipient specified and EMAIL_RECIPIENT not configured"
        return 1
    fi
    
    local hostname=$(hostname)
    local test_subject="🧪 Jamf Connect Monitor Test Email - $hostname"
    local test_body="This is a test email from Jamf Connect Monitor v$VERSION

System Information:
- Hostname: $hostname
- Company: $COMPANY_NAME
- Monitoring Version: $VERSION
- Test Time: $(date)
- Configuration Profile: $([[ -n "$(defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null)" ]] && echo "Active" || echo "Not deployed")

Email Configuration:
- Recipient: $test_recipient
- SMTP Server: $([[ -n "$SMTP_SERVER" ]] && echo "$SMTP_SERVER:$SMTP_PORT" || echo "System mail only")
- SMTP Authentication: $([[ -n "$SMTP_USERNAME" ]] && echo "Enabled ($SMTP_USERNAME)" || echo "Not configured")
- From Address: $([[ -n "$SMTP_FROM_ADDRESS" ]] && echo "$SMTP_FROM_ADDRESS" || echo "System default")

Delivery Methods Available:
$([[ -n "$SMTP_SERVER" ]] && echo "- Authenticated SMTP: Configured" || echo "- Authenticated SMTP: Not configured")
- System Mail Commands: $(command -v mail >/dev/null && echo "mail") $(command -v mailx >/dev/null && echo "mailx") $(command -v sendmail >/dev/null && echo "sendmail")
- Postfix Service: $(launchctl list | grep -q "org.postfix.master" && echo "Running" || echo "Not running")

If you received this email, your notification system is working correctly.

Next Steps:
1. Verify this email was received
2. Check email headers to see delivery method used
3. Configure additional recipients if needed
4. Test violation notifications

IT Contact: $IT_CONTACT_EMAIL
Monitoring System: Jamf Connect Monitor v$VERSION
Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    
    echo "Sending test email to: $test_recipient"
    echo "Subject: $test_subject"
    echo
    echo "Configuration:"
    echo "  SMTP Server: $([[ -n "$SMTP_SERVER" ]] && echo "$SMTP_SERVER:$SMTP_PORT" || echo "System mail only")"
    echo "  Authentication: $([[ -n "$SMTP_USERNAME" ]] && echo "Enabled" || echo "Disabled")"
    echo "  From Address: $([[ -n "$SMTP_FROM_ADDRESS" ]] && echo "$SMTP_FROM_ADDRESS" || echo "System default")"
    echo
    
    if enhanced_send_email "$test_recipient" "$test_subject" "$test_body"; then
        echo "✅ Test email sent successfully!"
        echo "Please check your inbox for the test message."
        echo "If you don't receive it within 5 minutes, check spam folder."
        return 0
    else
        echo "❌ Failed to send test email"
        echo "Check the logs for detailed error information:"
        echo "  tail -f $LOG_DIR/monitor.log"
        echo
        echo "Troubleshooting suggestions:"
        echo "1. Check Configuration Profile settings in Jamf Pro"
        echo "2. Verify SMTP credentials (try App Password for Gmail)"
        echo "3. Ensure network connectivity to SMTP server"
        echo "4. Check system mail configuration (postfix)"
        echo "5. Run email diagnostics: sudo ./tools/email_test.sh diagnostics"
        return 1
    fi
}

# Initialize approved admin list with configuration profile support
initialize_admin_whitelist() {
    if [[ ! -f "$ADMIN_WHITELIST" ]]; then
        log_message "INFO" "Creating initial admin whitelist"
        
        # Check if auto-population is enabled
        if [[ "$AUTO_POPULATE_APPROVED_ADMINS" == "true" ]]; then
            # Get excluded system accounts from configuration
            local excluded_accounts=""
            if defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" SecuritySettings.ExcludeSystemAccounts >/dev/null 2>&1; then
                excluded_accounts=$(defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" SecuritySettings.ExcludeSystemAccounts 2>/dev/null)
            fi
            
            # Get current admin users (excluding system accounts)
            local current_admins=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | \
                sed 's/GroupMembership: //' | \
                tr ' ' '\n' | \
                grep -v '^_' | \
                grep -v '^root$' | \
                grep -v '^daemon$' | \
                sort)
            
            # Apply additional exclusions from configuration profile if they exist
            if [[ -n "$excluded_accounts" ]]; then
                # Convert plist array to individual accounts and exclude them
                echo "$excluded_accounts" | grep -o '"[^"]*"' | tr -d '"' | while read -r account; do
                    current_admins=$(echo "$current_admins" | grep -v "^$account$")
                done
            fi
            
            echo "$current_admins" | sort > "$ADMIN_WHITELIST"
            
            log_message "INFO" "Auto-populated admin whitelist with $(wc -l < "$ADMIN_WHITELIST" | tr -d ' ') users"
            
            if [[ "$DEBUG_LOGGING" == "true" ]]; then
                log_message "DEBUG" "Approved admins: $(cat "$ADMIN_WHITELIST" | tr '\n' ',' | sed 's/,$//')"
            fi
        else
            # Create empty whitelist if auto-population is disabled
            touch "$ADMIN_WHITELIST"
            log_message "INFO" "Created empty admin whitelist (auto-population disabled)"
        fi
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
    if [[ -f "$ADMIN_WHITELIST" ]]; then
        cat "$ADMIN_WHITELIST" | sort
    else
        echo ""
    fi
}

# Enhanced Jamf Connect elevation monitoring
monitor_jamf_connect_elevation() {
    log_message "INFO" "Monitoring Jamf Connect elevation events"
    
    # Check if Jamf Connect elevation log exists
    if [[ ! -f "$ELEVATION_LOG" ]]; then
        log_message "WARN" "Jamf Connect elevation log not found at $ELEVATION_LOG"
        return 1
    fi
    
    # Determine monitoring approach based on configuration
    if [[ "$MONITORING_MODE" == "realtime" ]]; then
        monitor_realtime_events
    else
        monitor_periodic_events
    fi
}

# Periodic event monitoring (original method)
monitor_periodic_events() {
    # Get recent elevation events based on monitoring interval
    local time_window="${MONITORING_INTERVAL}s"
    local recent_events=$(log show --style compact --predicate '(subsystem == "com.jamf.connect.daemon") && (category == "PrivilegeElevation")' --last "$time_window" 2>/dev/null)
    
    if [[ -n "$recent_events" ]]; then
        log_message "INFO" "Recent Jamf Connect elevation detected"
        echo "$recent_events" >> "$JAMF_LOG"
        
        # Process events
        echo "$recent_events" | while read -r line; do
            process_elevation_event "$line"
        done
    fi
}

# Real-time event monitoring using log stream
monitor_realtime_events() {
    log_message "INFO" "Starting real-time event monitoring"
    
    # This would typically be run as a separate daemon
    # For now, we'll implement a short-term stream
    timeout 30 log stream --style compact \
        --predicate '(subsystem == "com.jamf.connect.daemon") && (category == "PrivilegeElevation")' \
        --info 2>/dev/null | while read -r line; do
        process_elevation_event "$line"
    done
}

# Process individual elevation events
process_elevation_event() {
    local event_line="$1"
    
    if echo "$event_line" | grep -q "Added user"; then
        local user=$(echo "$event_line" | sed -n 's/.*Added user \([^[:space:]]*\).*/\1/p')
        log_message "INFO" "User elevated via Jamf Connect: $user"
        
        # Check authorization with grace period
        check_user_with_grace_period "$user"
        
    elif echo "$event_line" | grep -q "Removed user"; then
        local user=$(echo "$event_line" | sed -n 's/.*Removed user \([^[:space:]]*\).*/\1/p')
        log_message "INFO" "User demoted via Jamf Connect: $user"
    fi
}

# Check user authorization with configurable grace period
check_user_with_grace_period() {
    local user="$1"
    
    if [[ "$GRACE_PERIOD_MINUTES" -gt 0 ]]; then
        log_message "INFO" "Grace period active for $user ($GRACE_PERIOD_MINUTES minutes)"
        sleep $((GRACE_PERIOD_MINUTES * 60))
    fi
    
    # Check if user is still admin and authorized
    if dsmemberutil checkmembership -U "$user" -G admin | grep -q "user is a member"; then
        check_user_authorization "$user"
    else
        log_message "INFO" "User $user no longer has admin privileges (automatic demotion)"
    fi
}

# Check user authorization against whitelist
check_user_authorization() {
    local user="$1"
    
    if [[ ! -f "$ADMIN_WHITELIST" ]]; then
        log_message "ERROR" "Admin whitelist not found - cannot verify authorization"
        return 1
    fi
    
    if grep -q "^$user$" "$ADMIN_WHITELIST"; then
        log_message "INFO" "AUTHORIZED: User $user is approved for admin privileges"
    else
        log_message "ERROR" "UNAUTHORIZED: User $user is NOT approved for admin privileges"
        handle_violation "$user"
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
        if [[ -n "$user" ]] && ! echo "$approved_admins" | grep -q "^$user$"; then
            unauthorized_admins="$unauthorized_admins $user"
        fi
    done <<< "$current_admins"
    
    if [[ -n "$unauthorized_admins" ]]; then
        log_message "ERROR" "Unauthorized admin accounts detected: $unauthorized_admins"
        
        for user in $unauthorized_admins; do
            handle_violation "$user"
        done
    else
        log_message "INFO" "No unauthorized admin accounts detected"
    fi
}

# Enhanced violation handling with configuration support
handle_violation() {
    local user="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname=$(hostname)
    local current_user=$(who | awk 'NR==1{print $1}')
    
    # Check if violation reporting is enabled (FIXED BOOLEAN PARSING)
    if [[ "$VIOLATION_REPORTING" != "true" ]]; then
        log_message "INFO" "Violation reporting disabled - skipping report for $user"
        return
    fi
    
    # Create detailed violation report
    local violation_report="ADMIN PRIVILEGE VIOLATION DETECTED
Company: $COMPANY_NAME
Timestamp: $timestamp
Hostname: $hostname
Unauthorized User: $user
Current Console User: $current_user
Monitoring Mode: $MONITORING_MODE
Action Taken: $([[ "$AUTO_REMEDIATION" == "true" ]] && echo "Admin privileges removed" || echo "Violation logged only")

Recent Admin Group Members:
$(get_current_admins)

Recent Jamf Connect Activity:
$(tail -n 10 "$JAMF_LOG" 2>/dev/null || echo "No recent activity")

System Information:
macOS Version: $(sw_vers -productVersion)
Build: $(sw_vers -buildVersion)
Configuration Profile: $([[ -n "$(defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null || sudo defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null)" ]] && echo "Active" || echo "Not deployed")
"
    
    # Log the violation
    echo "$violation_report" >> "$REPORT_LOG"
    log_message "ERROR" "Violation report created for user: $user"
    
    # Send notifications if configured
    send_enhanced_notifications "$user" "$hostname" "$violation_report"
    
    # Remove admin privileges if auto-remediation is enabled
    if [[ "$AUTO_REMEDIATION" == "true" ]]; then
        remove_admin_privileges "$user"
    else
        log_message "INFO" "Auto-remediation disabled - violation logged only"
    fi
    
    # Update Jamf Pro if configured
    if [[ "$UPDATE_INVENTORY_ON_VIOLATION" == "true" ]]; then
        update_jamf_inventory "$user"
    fi
    
    # Trigger policy if configured
    if [[ -n "$TRIGGER_POLICY_ON_VIOLATION" ]]; then
        trigger_jamf_policy "$TRIGGER_POLICY_ON_VIOLATION"
    fi
}

# Enhanced notification system with template support
send_enhanced_notifications() {
    local user="$1"
    local hostname="$2"
    local report="$3"
    
    # Send webhook notification
    if [[ -n "$WEBHOOK_URL" ]]; then
        send_webhook_notification_enhanced "$user" "$hostname"
    fi
    
    # Send email notification (with FIXED SMTP support)
    if [[ -n "$EMAIL_RECIPIENT" ]]; then
        send_email_notification_enhanced "$user" "$hostname" "$report"
    fi
}

# Enhanced webhook notification with template support
send_webhook_notification_enhanced() {
    local user="$1"
    local hostname="$2"
    
    local payload=""
    
    if [[ "$NOTIFICATION_TEMPLATE" == "detailed" ]]; then
        payload="{
            \"text\": \"🚨 Admin Privilege Violation - $COMPANY_NAME\",
            \"attachments\": [{
                \"color\": \"danger\",
                \"title\": \"Unauthorized Admin Account Detected\",
                \"fields\": [
                    {\"title\": \"Company\", \"value\": \"$COMPANY_NAME\", \"short\": true},
                    {\"title\": \"Hostname\", \"value\": \"$hostname\", \"short\": true},
                    {\"title\": \"User\", \"value\": \"$user\", \"short\": true},
                    {\"title\": \"Monitoring\", \"value\": \"$MONITORING_MODE\", \"short\": true},
                    {\"title\": \"Auto Remediation\", \"value\": \"$AUTO_REMEDIATION\", \"short\": true},
                    {\"title\": \"Timestamp\", \"value\": \"$(date)\", \"short\": true},
                    {\"title\": \"IT Contact\", \"value\": \"$IT_CONTACT_EMAIL\", \"short\": false}
                ]
            }]
        }"
    elif [[ "$NOTIFICATION_TEMPLATE" == "security_report" ]]; then
        payload="{
            \"text\": \"🚨 SECURITY INCIDENT - Unauthorized Admin Account\",
            \"attachments\": [{
                \"color\": \"danger\",
                \"title\": \"CRITICAL: Admin Privilege Violation Detected\",
                \"fields\": [
                    {\"title\": \"🏢 Organization\", \"value\": \"$COMPANY_NAME\", \"short\": true},
                    {\"title\": \"💻 Affected System\", \"value\": \"$hostname\", \"short\": true},
                    {\"title\": \"👤 Unauthorized User\", \"value\": \"$user\", \"short\": true},
                    {\"title\": \"🔍 Detection Method\", \"value\": \"$MONITORING_MODE monitoring\", \"short\": true},
                    {\"title\": \"⚡ Response Status\", \"value\": \"$([[ "$AUTO_REMEDIATION" == "true" ]] && echo "Auto-remediated" || echo "Manual intervention required")\", \"short\": true},
                    {\"title\": \"📞 IT Support\", \"value\": \"$IT_CONTACT_EMAIL\", \"short\": true},
                    {\"title\": \"🕐 Incident Time\", \"value\": \"$(date '+%Y-%m-%d %H:%M:%S %Z')\", \"short\": false}
                ]
            }]
        }"
    else
        # Simple template
        payload="{
            \"text\": \"🚨 Admin Violation: User $user on $hostname - $COMPANY_NAME\"
        }"
    fi
    
    curl -X POST -H 'Content-type: application/json' \
         --data "$payload" \
         "$WEBHOOK_URL" &>/dev/null && \
    log_message "INFO" "Enhanced webhook notification sent ($NOTIFICATION_TEMPLATE template)"
}

# FIXED: Enhanced email notification with improved SMTP authentication support
send_email_notification_enhanced() {
    local user="$1"
    local hostname="$2"
    local report="$3"
    
    local subject=""
    local body=""
    
    if [[ "$NOTIFICATION_TEMPLATE" == "security_report" ]]; then
        subject="🚨 SECURITY ALERT: Unauthorized Admin Account - $hostname ($COMPANY_NAME)"
        body="SECURITY INCIDENT REPORT - IMMEDIATE ACTION REQUIRED

$report

INCIDENT DETAILS:
- Company: $COMPANY_NAME
- Affected System: $hostname
- Unauthorized User: $user
- Detection Method: $MONITORING_MODE monitoring
- Auto-Remediation: $([[ "$AUTO_REMEDIATION" == "true" ]] && echo "ENABLED - Admin privileges automatically removed" || echo "DISABLED - Manual intervention required")
- Grace Period: $GRACE_PERIOD_MINUTES minutes

IMMEDIATE ACTIONS REQUIRED:
1. Verify if this elevation was authorized
2. Contact the user: $user
3. Review admin account policies with user
4. Update approved admin list if this was legitimate

SYSTEM INFORMATION:
- Monitoring Version: v$VERSION
- Configuration Profile: $([[ -n "$(defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null || sudo defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null)" ]] && echo "Active" || echo "Not deployed")
- Real-time Monitoring: $([[ "$MONITORING_MODE" == "realtime" ]] && echo "Enabled" || echo "Disabled")

IT Support Contact: $IT_CONTACT_EMAIL
Report Generated: $(date)
Monitoring System: Jamf Connect Monitor v$VERSION

This is an automated security notification from $COMPANY_NAME's admin monitoring system.
Do not reply to this email - contact IT support for assistance."
        
    elif [[ "$NOTIFICATION_TEMPLATE" == "detailed" ]]; then
        subject="Admin Account Violation Detected - $hostname"
        body="Admin Privilege Violation Report

Company: $COMPANY_NAME
Hostname: $hostname
User: $user
Timestamp: $(date)
Monitoring Mode: $MONITORING_MODE
Auto-Remediation: $AUTO_REMEDIATION

$report

IT Contact: $IT_CONTACT_EMAIL"
    else
        # Simple template
        subject="Admin Violation - $hostname"
        body="User $user had unauthorized admin privileges on $hostname.

$report"
    fi
    
    # Use improved email sending function
    if enhanced_send_email "$EMAIL_RECIPIENT" "$subject" "$body"; then
        log_message "INFO" "Enhanced email notification sent ($NOTIFICATION_TEMPLATE template)"
    else
        log_message "ERROR" "Failed to send email notification"
    fi
}

# Remove admin privileges
remove_admin_privileges() {
    local user="$1"
    
    log_message "WARN" "Removing admin privileges from unauthorized user: $user"
    
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

# Update Jamf Pro inventory
update_jamf_inventory() {
    local user="$1"
    
    if command -v jamf &> /dev/null; then
        jamf recon &
        log_message "INFO" "Jamf Pro inventory update triggered for violation by $user"
    fi
}

# Trigger Jamf Pro policy
trigger_jamf_policy() {
    local trigger="$1"
    
    if command -v jamf &> /dev/null; then
        jamf policy -trigger "$trigger" &>/dev/null &
        log_message "INFO" "Jamf Pro policy triggered: $trigger"
    fi
}

# Add user to approved admin list
add_approved_admin() {
    local user="$1"
    
    if [[ -n "$user" ]]; then
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
    
    if [[ -n "$user" ]] && [[ -f "$ADMIN_WHITELIST" ]]; then
        if grep -q "^$user$" "$ADMIN_WHITELIST"; then
            grep -v "^$user$" "$ADMIN_WHITELIST" > "${ADMIN_WHITELIST}.tmp"
            mv "${ADMIN_WHITELIST}.tmp" "$ADMIN_WHITELIST"
            log_message "INFO" "Removed $user from approved admin list"
        else
            log_message "INFO" "User $user not found in approved admin list"
        fi
    fi
}

# Enhanced status display with working configuration information
show_status() {
    echo "=== Jamf Connect Elevation Monitor Status (v$VERSION) ==="
    echo "Configuration Profile: $([[ -n "$(defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null || sudo defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null)" ]] && echo "Active" || echo "Not deployed")"
    echo "Company: $COMPANY_NAME"
    echo "Monitoring Mode: $MONITORING_MODE"
    echo "Auto Remediation: $AUTO_REMEDIATION"
    echo "Grace Period: $GRACE_PERIOD_MINUTES minutes"
    echo "Notifications:"
    echo "  Webhook: $([[ -n "$WEBHOOK_URL" ]] && echo "Configured" || echo "None")"
    echo "  Email: $([[ -n "$EMAIL_RECIPIENT" ]] && echo "$EMAIL_RECIPIENT" || echo "None")"
    echo "  SMTP: $([[ -n "$SMTP_SERVER" ]] && echo "Configured ($SMTP_SERVER:$SMTP_PORT)" || echo "System mail")"
    echo "  Template: $NOTIFICATION_TEMPLATE"
    echo "  Cooldown: $NOTIFICATION_COOLDOWN minutes"
    echo
    echo "Current Admin Users:"
    get_current_admins | sed 's/^/  /'
    echo
    echo "Approved Admin Users:"
    get_approved_admins | sed 's/^/  /'
    echo
    echo "Recent Violations:"
    if [[ -f "$REPORT_LOG" ]]; then
        tail -n 5 "$REPORT_LOG" | grep "ADMIN PRIVILEGE VIOLATION" | sed 's/^/  /'
    else
        echo "  No violations recorded"
    fi
    echo
    echo "System Health:"
    echo "  Debug Logging: $DEBUG_LOGGING"
    echo "  Log Retention: $LOG_RETENTION_DAYS days"
    echo "  Jamf Connect Only: $MONITOR_JAMF_CONNECT_ONLY"
    echo "  Auto-populate Admins: $AUTO_POPULATE_APPROVED_ADMINS"
    echo "  IT Contact: $([[ -n "$IT_CONTACT_EMAIL" ]] && echo "$IT_CONTACT_EMAIL" || echo "Not configured")"
    echo "  Violation Reporting: $VIOLATION_REPORTING"
}

# Main monitoring function with enhanced configuration
main_monitor() {
    log_message "INFO" "Starting Jamf Connect elevation monitoring (v$VERSION)"
    
    # Read configuration from managed preferences
    read_configuration
    
    # Initialize whitelist if needed
    initialize_admin_whitelist
    
    # Monitor Jamf Connect elevation events
    monitor_jamf_connect_elevation
    
    # Check for unauthorized admin accounts
    check_unauthorized_admins
    
    log_message "INFO" "Monitoring cycle completed"
}

# Command line interface (enhanced with FIXED email support)
case "${1:-monitor}" in
    "monitor")
        check_lock
        main_monitor
        ;;
    "status")
        read_configuration
        show_status
        ;;
    "add-admin")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 add-admin <username>"
            exit 1
        fi
        add_approved_admin "$2"
        ;;
    "remove-admin")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 remove-admin <username>"
            exit 1
        fi
        remove_approved_admin "$2"
        ;;
    "force-check")
        check_lock
        read_configuration
        check_unauthorized_admins
        ;;
    "test-config")
        read_configuration
        echo "=== Configuration Profile Test ==="
        echo "Profile Status: $([[ -n "$(defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null || sudo defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null)" ]] && echo "Deployed" || echo "Not deployed")"
        echo
        echo "Notification Settings:"
        echo "  Webhook: $([[ -n "$WEBHOOK_URL" ]] && echo "Configured" || echo "None")"
        echo "  Email: $([[ -n "$EMAIL_RECIPIENT" ]] && echo "$EMAIL_RECIPIENT" || echo "None")"
        echo "  SMTP Server: $([[ -n "$SMTP_SERVER" ]] && echo "$SMTP_SERVER:$SMTP_PORT" || echo "Not configured")"
        echo "  SMTP Auth: $([[ -n "$SMTP_USERNAME" ]] && echo "Configured ($SMTP_USERNAME)" || echo "None")"
        echo "  From Address: $([[ -n "$SMTP_FROM_ADDRESS" ]] && echo "$SMTP_FROM_ADDRESS" || echo "Default")"
        echo "  Template: $NOTIFICATION_TEMPLATE"
        echo "  Cooldown: $NOTIFICATION_COOLDOWN minutes"
        echo
        echo "Monitoring Behavior:"
        echo "  Mode: $MONITORING_MODE"
        echo "  Auto Remediation: $AUTO_REMEDIATION"
        echo "  Grace Period: $GRACE_PERIOD_MINUTES minutes"
        echo "  Jamf Connect Only: $MONITOR_JAMF_CONNECT_ONLY"
        echo
        echo "Security Settings:"
        echo "  Require Confirmation: $REQUIRE_CONFIRMATION"
        echo "  Violation Reporting: $VIOLATION_REPORTING"
        echo "  Log Retention: $LOG_RETENTION_DAYS days"
        echo
        echo "Jamf Pro Integration:"
        echo "  Company Name: $COMPANY_NAME"
        echo "  IT Contact: $([[ -n "$IT_CONTACT_EMAIL" ]] && echo "$IT_CONTACT_EMAIL" || echo "None")"
        echo "  Update Inventory: $UPDATE_INVENTORY_ON_VIOLATION"
        echo "  Policy Trigger: $([[ -n "$TRIGGER_POLICY_ON_VIOLATION" ]] && echo "$TRIGGER_POLICY_ON_VIOLATION" || echo "None")"
        echo
        echo "Advanced Settings:"
        echo "  Debug Logging: $DEBUG_LOGGING"
        echo "  Monitoring Interval: $MONITORING_INTERVAL seconds"
        echo "  Max Notifications/Hour: $MAX_NOTIFICATIONS_PER_HOUR"
        echo "  Auto-populate Admins: $AUTO_POPULATE_APPROVED_ADMINS"
        ;;
    "test-email")
        read_configuration
        send_test_email "$2"
        ;;
    "help")
        echo "Usage: $0 [command]"
        echo "Commands:"
        echo "  monitor        Run monitoring cycle (default)"
        echo "  status         Show current status and configuration"
        echo "  add-admin      Add user to approved admin list"
        echo "  remove-admin   Remove user from approved admin list"
        echo "  force-check    Force check for unauthorized admins"
        echo "  test-config    Test configuration profile settings"
        echo "  test-email     Send test email to verify delivery (FIXED in v2.0.1)"
        echo "  help           Show this help message"
        echo
        echo "Version $VERSION Features:"
        echo "  • Configuration Profile support for centralized management"
        echo "  • FIXED: Reliable email delivery with multiple fallback methods"
        echo "  • Real-time monitoring capabilities"
        echo "  • Enhanced notification templates"
        echo "  • Configurable grace periods and auto-remediation"
        echo "  • Advanced Jamf Pro integration"
        echo
        echo "Email Testing:"
        echo "  sudo $0 test-email                    # Test with configured recipient"
        echo "  sudo $0 test-email user@domain.com    # Test with specific recipient"
        echo "  sudo ./tools/email_test.sh test       # Comprehensive email diagnostics"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac