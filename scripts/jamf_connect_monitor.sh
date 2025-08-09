#!/bin/bash

# Jamf Connect Elevation Monitor & Admin Account Remediation Script
# Version: 2.4.0 - Added legitimate elevation tracking and audit logging
# Author: MacJediWizard

# Centralized Version Management
VERSION="2.4.0"
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
        WEBHOOK_TYPE=$(echo "$config_data" | awk -F' = ' '/WebhookType/ {gsub(/[";]/, "", $2); print $2}' | head -1 || echo "none")
        WEBHOOK_URL=$(echo "$config_data" | grep -A1 "WebhookURL" | grep -o 'https://[^"]*' | head -1 || echo "")
        EMAIL_RECIPIENT=$(echo "$config_data" | grep -A1 "EmailRecipient" | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]*' | head -1 || echo "")
        
        # SMTP Configuration - NEW with Provider support
        SMTP_PROVIDER=$(echo "$config_data" | awk -F' = ' '/SMTPProvider/ {gsub(/[";]/, "", $2); print $2}' | head -1 || echo "custom")
        
        # Auto-configure SMTP settings based on provider if not explicitly set
        case "$SMTP_PROVIDER" in
            "gmail")
                DEFAULT_SMTP_SERVER="smtp.gmail.com"
                DEFAULT_SMTP_PORT="587"
                ;;
            "office365")
                DEFAULT_SMTP_SERVER="smtp.office365.com"
                DEFAULT_SMTP_PORT="587"
                ;;
            "sendgrid")
                DEFAULT_SMTP_SERVER="smtp.sendgrid.net"
                DEFAULT_SMTP_PORT="587"
                ;;
            "aws_ses")
                DEFAULT_SMTP_SERVER="email-smtp.us-east-1.amazonaws.com"
                DEFAULT_SMTP_PORT="587"
                ;;
            "smtp2go")
                DEFAULT_SMTP_SERVER="mail.smtp2go.com"
                DEFAULT_SMTP_PORT="587"
                ;;
            "mailgun")
                DEFAULT_SMTP_SERVER="smtp.mailgun.org"
                DEFAULT_SMTP_PORT="587"
                ;;
            *)
                DEFAULT_SMTP_SERVER=""
                DEFAULT_SMTP_PORT="587"
                ;;
        esac
        
        # Use configured values or fall back to provider defaults
        SMTP_SERVER=$(echo "$config_data" | awk -F' = ' '/SMTPServer/ {gsub(/[";]/, "", $2); print $2}' | head -1)
        [[ -z "$SMTP_SERVER" ]] && SMTP_SERVER="$DEFAULT_SMTP_SERVER"
        
        SMTP_PORT=$(echo "$config_data" | awk -F' = ' '/SMTPPort/ {gsub(/[";]/, "", $2); print $2}' | head -1)
        [[ -z "$SMTP_PORT" ]] && SMTP_PORT="$DEFAULT_SMTP_PORT"
        # Fixed: Robust extraction using awk for SMTP username
        SMTP_USERNAME=$(echo "$config_data" | awk -F' = ' '/SMTPUsername/ {gsub(/[";]/, "", $2); print $2}' | head -1 || echo "")
        # Fixed: Robust extraction using awk for SMTP password  
        SMTP_PASSWORD=$(echo "$config_data" | awk -F' = ' '/SMTPPassword/ {gsub(/[";]/, "", $2); print $2}' | head -1 || echo "")
        # SMTP From Address is REQUIRED - must be verified with SMTP provider
        SMTP_FROM_ADDRESS=$(echo "$config_data" | grep -A1 "SMTPFromAddress" | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]*' | head -1 || echo "")
        
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
        log_message "DEBUG" "SMTP Username: $([[ -n "$SMTP_USERNAME" ]] && echo "${SMTP_USERNAME}" || echo "None")"
        log_message "DEBUG" "SMTP Password: $([[ -n "$SMTP_PASSWORD" ]] && echo "***configured***" || echo "None")"
        log_message "DEBUG" "SMTP From Address: $([[ -n "$SMTP_FROM_ADDRESS" ]] && echo "${SMTP_FROM_ADDRESS}" || echo "WARNING: Not configured!")"
        log_message "DEBUG" "Monitoring Mode: $MONITORING_MODE"
        log_message "DEBUG" "Auto Remediation: $AUTO_REMEDIATION"
        log_message "DEBUG" "Violation Reporting: $VIOLATION_REPORTING"
        log_message "DEBUG" "Company: $COMPANY_NAME"
    fi
    
    # Warn if SMTP is configured but From Address is missing
    if [[ -n "$SMTP_SERVER" && -z "$SMTP_FROM_ADDRESS" ]]; then
        log_message "WARN" "SMTP From Address not configured - email delivery may fail!"
        log_message "WARN" "Please configure SMTPFromAddress in Configuration Profile"
    fi
    
    # Provider-specific validation and guidance
    case "$SMTP_PROVIDER" in
        "gmail")
            if [[ -n "$SMTP_PASSWORD" && ${#SMTP_PASSWORD} -ne 16 ]]; then
                log_message "WARN" "Gmail typically requires a 16-character App Password, not your regular password"
            fi
            ;;
        "smtp2go"|"mailgun"|"sendgrid")
            if [[ -n "$SMTP_FROM_ADDRESS" ]]; then
                log_message "INFO" "Note: $SMTP_PROVIDER requires sender domain/email verification"
            fi
            ;;
        "sendgrid")
            if [[ "$SMTP_USERNAME" != "apikey" ]]; then
                log_message "WARN" "SendGrid requires username to be 'apikey' (literal string)"
            fi
            ;;
    esac
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
    
    # Log provider-specific info for debugging
    log_message "INFO" "Attempting authenticated SMTP delivery via $SMTP_PROVIDER provider"
    log_message "INFO" "SMTP Server: $SMTP_SERVER:$SMTP_PORT, User: $SMTP_USERNAME"
    
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
    
    # Check if mailx supports SMTP authentication (GNU mailx only, not BSD/macOS mailx)
    if command -v mailx >/dev/null 2>&1 && mailx -? 2>&1 | grep -q "smtp-auth"; then
        log_message "DEBUG" "Using GNU mailx for authenticated SMTP"
        
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
        
        # Send email using mailx with custom configuration and capture output
        local mailx_output=""
        mailx_output=$(echo "$body" | MAILRC="$temp_mailrc" mailx -v -s "$subject" "$recipient" 2>&1)
        local mailx_result=$?
        
        # Cleanup
        rm -f "$temp_mailrc"
        
        # Check for authentication failures in output
        if echo "$mailx_output" | grep -q "authentication failed\|AUTH failed\|535\|550"; then
            log_message "ERROR" "mailx SMTP authentication failed - check credentials"
            log_message "DEBUG" "mailx output: ${mailx_output:0:500}"
            return 1
        fi
        
        if [[ $mailx_result -eq 0 ]]; then
            log_message "INFO" "mailx command completed - check inbox for delivery"
            log_message "DEBUG" "Note: mailx may report success even if authentication fails"
            return 0
        else
            log_message "ERROR" "mailx failed with exit code $mailx_result"
            log_message "DEBUG" "mailx output: ${mailx_output:0:500}"
            return 1
        fi
    fi
    
    # Fallback to curl for SMTP (built into macOS)
    if command -v curl >/dev/null 2>&1; then
        log_message "DEBUG" "Using curl for authenticated SMTP"
        
        # Create email in RFC 2822 format
        local temp_email="/tmp/jamf_monitor_email_$$"
        cat > "$temp_email" << EOF
From: ${SMTP_FROM_ADDRESS:-$SMTP_USERNAME}
To: $recipient
Subject: $subject
Date: $(date -R 2>/dev/null || date '+%a, %d %b %Y %H:%M:%S %z')

$body
EOF
        
        # Determine protocol based on port
        local protocol="smtp"
        local curl_opts=""
        if [[ "$SMTP_PORT" == "465" ]]; then
            protocol="smtps"
            curl_opts="--ssl-reqd"
        else
            curl_opts="--ssl"
        fi
        
        # Send via curl with verbose error capture
        local curl_output
        curl_output=$(curl -v --url "${protocol}://${SMTP_SERVER}:${SMTP_PORT}" \
               --mail-from "${SMTP_FROM_ADDRESS:-$SMTP_USERNAME}" \
               --mail-rcpt "$recipient" \
               --user "${SMTP_USERNAME}:${SMTP_PASSWORD}" \
               $curl_opts \
               --upload-file "$temp_email" 2>&1)
        
        local curl_exit_code=$?
        
        if [[ $curl_exit_code -eq 0 ]]; then
            rm -f "$temp_email"
            log_message "INFO" "Authenticated email sent successfully via curl to $recipient"
            return 0
        else
            rm -f "$temp_email"
            log_message "ERROR" "curl SMTP failed (exit code: $curl_exit_code)"
            
            # Check for common SMTP errors and provide helpful messages
            if echo "$curl_output" | grep -q "550.*not verified"; then
                log_message "ERROR" "SMTP2GO requires sender domain verification"
                log_message "ERROR" "Please verify ${SMTP_FROM_ADDRESS:-$SMTP_USERNAME} in SMTP2GO dashboard:"
                log_message "ERROR" "1. Log into SMTP2GO dashboard"
                log_message "ERROR" "2. Go to Settings > Verified Senders"
                log_message "ERROR" "3. Add and verify: successacademies.org or ${SMTP_FROM_ADDRESS:-$SMTP_USERNAME}"
            elif echo "$curl_output" | grep -q "535.*Authentication failed"; then
                log_message "ERROR" "SMTP authentication failed - check username and password"
            else
                log_message "DEBUG" "curl error output: ${curl_output}"
            fi
            return 1
        fi
    fi
    
    log_message "ERROR" "No suitable authenticated email command available (install swaks or use curl)"
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

# Calculate duration between two timestamps
calculate_duration() {
    local start_time="$1"
    local end_time="$2"
    
    # Convert to epoch seconds if possible
    if command -v date >/dev/null 2>&1; then
        local start_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$start_time" "+%s" 2>/dev/null || echo "0")
        local end_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$end_time" "+%s" 2>/dev/null || echo "0")
        
        if [[ $start_epoch -gt 0 && $end_epoch -gt 0 ]]; then
            local diff=$((end_epoch - start_epoch))
            local hours=$((diff / 3600))
            local minutes=$(( (diff % 3600) / 60 ))
            
            if [[ $hours -gt 0 ]]; then
                echo "${hours}h ${minutes}m"
            else
                echo "${minutes} minutes"
            fi
        else
            echo "Unknown"
        fi
    else
        echo "Unknown"
    fi
}

# Update elevation statistics for reporting
update_elevation_statistics() {
    local user="$1"
    local reason="$2"
    local stats_file="$LOG_DIR/elevation_statistics.json"
    local today=$(date '+%Y-%m-%d')
    
    # Initialize stats file if it doesn't exist
    if [[ ! -f "$stats_file" ]]; then
        echo "{\"total_elevations\": 0, \"daily_elevations\": {}, \"user_elevations\": {}, \"reasons\": {}}" > "$stats_file"
    fi
    
    # Update statistics using simple counters (avoiding complex JSON manipulation)
    local total_count_file="$LOG_DIR/.stats_total"
    local user_count_file="$LOG_DIR/.stats_user_$user"
    local daily_count_file="$LOG_DIR/.stats_daily_$today"
    local reason_count_file="$LOG_DIR/.stats_reason_$(echo "$reason" | tr ' ' '_')"
    
    # Increment counters
    echo $(($(cat "$total_count_file" 2>/dev/null || echo 0) + 1)) > "$total_count_file"
    echo $(($(cat "$user_count_file" 2>/dev/null || echo 0) + 1)) > "$user_count_file"
    echo $(($(cat "$daily_count_file" 2>/dev/null || echo 0) + 1)) > "$daily_count_file"
    echo $(($(cat "$reason_count_file" 2>/dev/null || echo 0) + 1)) > "$reason_count_file"
    
    log_message "INFO" "Updated elevation statistics for $user"
}

# Generate elevation summary report
generate_elevation_summary() {
    local legitimate_log="$LOG_DIR/legitimate_elevations.log"
    local summary=""
    
    if [[ -f "$legitimate_log" ]]; then
        # Count total legitimate elevations
        local total_elevations=$(grep -c "LEGITIMATE_ELEVATION" "$legitimate_log" 2>/dev/null || echo "0")
        
        # Get today's elevations
        local today=$(date '+%Y-%m-%d')
        local today_elevations=$(grep "$today" "$legitimate_log" | grep -c "LEGITIMATE_ELEVATION" || echo "0")
        
        # Get unique users who elevated
        local unique_users=$(grep "LEGITIMATE_ELEVATION" "$legitimate_log" | awk -F'|' '{print $3}' | sort -u | wc -l | tr -d ' ')
        
        # Get most common reasons (top 3)
        local top_reasons=$(grep "LEGITIMATE_ELEVATION" "$legitimate_log" | awk -F'|' '{print $4}' | sort | uniq -c | sort -rn | head -3 | awk '{$1="["$1"]"; print}' | tr '\n' '; ')
        
        summary="Total Elevations: $total_elevations | Today: $today_elevations | Unique Users: $unique_users | Top Reasons: $top_reasons"
    else
        summary="No legitimate elevation data available"
    fi
    
    echo "$summary"
}

# Process individual elevation events with enhanced tracking
process_elevation_event() {
    local event_line="$1"
    local timestamp=$(echo "$event_line" | awk '{print $1 " " $2}')
    local elevation_log="$LOG_DIR/elevation_history.log"
    local legitimate_log="$LOG_DIR/legitimate_elevations.log"
    
    if echo "$event_line" | grep -q "Added user"; then
        local user=$(echo "$event_line" | sed -n 's/.*Added user \([^[:space:]]*\).*/\1/p')
        log_message "INFO" "User elevated via Jamf Connect: $user"
        
        # Log elevation event
        echo "$timestamp | ELEVATED | $user | Awaiting reason..." >> "$elevation_log"
        
        # Store elevation time for duration calculation
        echo "$timestamp" > "$LOG_DIR/.elevation_time_$user"
        
        # Check authorization with grace period
        check_user_with_grace_period "$user"
        
    elif echo "$event_line" | grep -q "elevated to admin for stated reason"; then
        # Capture the elevation reason
        local user=$(echo "$event_line" | sed -n 's/.*User \([^[:space:]]*\) elevated.*/\1/p')
        local reason=$(echo "$event_line" | sed -n 's/.*stated reason: \(.*\)/\1/p')
        log_message "INFO" "Elevation reason for $user: $reason"
        
        # Update the elevation log with reason
        echo "$timestamp | REASON | $user | $reason" >> "$elevation_log"
        
        # Log legitimate elevation for audit trail
        echo "$timestamp | LEGITIMATE_ELEVATION | $user | $reason | $hostname" >> "$legitimate_log"
        
        # Store current elevation info for notifications
        echo "{\"user\":\"$user\",\"reason\":\"$reason\",\"time\":\"$timestamp\"}" > "$LOG_DIR/.current_elevation_$user"
        
        # Update elevation statistics
        update_elevation_statistics "$user" "$reason"
        
    elif echo "$event_line" | grep -q "Removed user"; then
        local user=$(echo "$event_line" | sed -n 's/.*Removed user \([^[:space:]]*\).*/\1/p')
        log_message "INFO" "User demoted via Jamf Connect: $user"
        
        # Calculate elevation duration
        if [[ -f "$LOG_DIR/.elevation_time_$user" ]]; then
            local start_time=$(cat "$LOG_DIR/.elevation_time_$user")
            local duration=$(calculate_duration "$start_time" "$timestamp")
            echo "$timestamp | DEMOTED | $user | Duration: $duration" >> "$elevation_log"
            
            # Log to legitimate elevations audit
            echo "$timestamp | LEGITIMATE_DEMOTION | $user | Duration: $duration" >> "$legitimate_log"
            
            # Clean up temporary files
            rm -f "$LOG_DIR/.elevation_time_$user"
            rm -f "$LOG_DIR/.current_elevation_$user"
        else
            echo "$timestamp | DEMOTED | $user | Duration: Unknown" >> "$elevation_log"
        fi
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

# Enhanced violation handling with configuration support and elevation context
handle_violation() {
    local user="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname=$(hostname)
    local current_user=$(who | awk 'NR==1{print $1}')
    
    # Get legitimate elevation context
    local elevation_context=""
    local legitimate_elevations=""
    for elevation_file in "$LOG_DIR"/.current_elevation_*; do
        if [[ -f "$elevation_file" ]]; then
            local elevated_user=$(basename "$elevation_file" | sed 's/.current_elevation_//')
            local elevation_info=$(cat "$elevation_file")
            local reason=$(echo "$elevation_info" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
            local elev_time=$(echo "$elevation_info" | sed -n 's/.*"time":"\([^"]*\)".*/\1/p')
            legitimate_elevations="${legitimate_elevations}\n  - $elevated_user: $reason (at $elev_time)"
        fi
    done
    
    if [[ -n "$legitimate_elevations" ]]; then
        elevation_context="Legitimate Elevations:$legitimate_elevations"
    fi
    
    # Check if violation reporting is enabled (FIXED BOOLEAN PARSING)
    if [[ "$VIOLATION_REPORTING" != "true" ]]; then
        log_message "INFO" "Violation reporting disabled - skipping report for $user"
        return
    fi
    
    # Create detailed violation report with elevation context
    local violation_report="ADMIN PRIVILEGE VIOLATION DETECTED
Company: $COMPANY_NAME
Timestamp: $timestamp
Hostname: $hostname
Unauthorized User: $user
Current Console User: $current_user
Monitoring Mode: $MONITORING_MODE
Action Taken: $([[ "$AUTO_REMEDIATION" == "true" ]] && echo "Admin privileges removed" || echo "Violation logged only")

$elevation_context

Current Admin Group Members:
$(get_current_admins)

Recent Elevation History:
$(tail -n 10 "$LOG_DIR/elevation_history.log" 2>/dev/null || echo "No elevation history available")

Recent Jamf Connect Activity:
$(tail -n 5 "$JAMF_LOG" 2>/dev/null || echo "No recent activity")

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

# Enhanced webhook notification with platform-specific formatting
send_webhook_notification_enhanced() {
    local user="$1"
    local hostname="$2"
    
    # Get elevation context for the notification
    local elevation_info=""
    for elevation_file in "$LOG_DIR"/.current_elevation_*; do
        if [[ -f "$elevation_file" ]]; then
            local elevated_user=$(basename "$elevation_file" | sed 's/.current_elevation_//')
            local info=$(cat "$elevation_file")
            local reason=$(echo "$info" | sed -n 's/.*"reason":"\([^"]*\)".*/\1/p')
            elevation_info="${elevation_info}${elevated_user}: ${reason}; "
        fi
    done
    
    if [[ -z "$elevation_info" ]]; then
        elevation_info="No legitimate elevations active"
    fi
    
    local payload=""
    
    # Format message based on webhook platform
    case "$WEBHOOK_TYPE" in
        "teams")
            # Microsoft Teams adaptive card format
            if [[ "$NOTIFICATION_TEMPLATE" == "detailed" ]]; then
                payload="{
                    \"@type\": \"MessageCard\",
                    \"@context\": \"http://schema.org/extensions\",
                    \"themeColor\": \"FF0000\",
                    \"summary\": \"Admin Privilege Violation Detected\",
                    \"sections\": [{
                        \"activityTitle\": \"🚨 Admin Privilege Violation - $COMPANY_NAME\",
                        \"activitySubtitle\": \"Unauthorized Admin Account Detected\",
                        \"facts\": [
                            {\"name\": \"Company:\", \"value\": \"$COMPANY_NAME\"},
                            {\"name\": \"Hostname:\", \"value\": \"$hostname\"},
                            {\"name\": \"Unauthorized User:\", \"value\": \"$user\"},
                            {\"name\": \"Legitimate Elevations:\", \"value\": \"$elevation_info\"},
                            {\"name\": \"Monitoring:\", \"value\": \"$MONITORING_MODE\"},
                            {\"name\": \"Auto Remediation:\", \"value\": \"$AUTO_REMEDIATION\"},
                            {\"name\": \"Timestamp:\", \"value\": \"$(date)\"},
                            {\"name\": \"IT Contact:\", \"value\": \"${IT_CONTACT_EMAIL:-Not configured}\"}
                        ],
                        \"markdown\": true
                    }]
                }"
            else
                payload="{
                    \"@type\": \"MessageCard\",
                    \"@context\": \"http://schema.org/extensions\",
                    \"themeColor\": \"FF0000\",
                    \"text\": \"🚨 **Admin Violation**: User $user on $hostname is not authorized\"
                }"
            fi
            ;;
        
        "slack")
            # Slack block kit format
            if [[ "$NOTIFICATION_TEMPLATE" == "detailed" ]]; then
                payload="{
                    \"text\": \"🚨 Admin Privilege Violation - $COMPANY_NAME\",
                    \"attachments\": [{
                        \"color\": \"danger\",
                        \"title\": \"Unauthorized Admin Account Detected\",
                        \"fields\": [
                            {\"title\": \"Company\", \"value\": \"$COMPANY_NAME\", \"short\": true},
                            {\"title\": \"Hostname\", \"value\": \"$hostname\", \"short\": true},
                            {\"title\": \"Unauthorized User\", \"value\": \"$user\", \"short\": true},
                            {\"title\": \"Legitimate Elevations\", \"value\": \"$elevation_info\", \"short\": false},
                            {\"title\": \"Monitoring\", \"value\": \"$MONITORING_MODE\", \"short\": true},
                            {\"title\": \"Auto Remediation\", \"value\": \"$AUTO_REMEDIATION\", \"short\": true},
                            {\"title\": \"Timestamp\", \"value\": \"$(date)\", \"short\": true},
                            {\"title\": \"IT Contact\", \"value\": \"${IT_CONTACT_EMAIL:-Not configured}\", \"short\": false}
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
                    {\"title\": \"✅ Legitimate Elevations\", \"value\": \"$elevation_info\", \"short\": false},
                    {\"title\": \"🔍 Detection Method\", \"value\": \"$MONITORING_MODE monitoring\", \"short\": true},
                    {\"title\": \"⚡ Response Status\", \"value\": \"$([[ "$AUTO_REMEDIATION" == "true" ]] && echo "Auto-remediated" || echo "Manual intervention required")\", \"short\": true},
                    {\"title\": \"📞 IT Support\", \"value\": \"$IT_CONTACT_EMAIL\", \"short\": true},
                    {\"title\": \"🕐 Incident Time\", \"value\": \"$(date '+%Y-%m-%d %H:%M:%S %Z')\", \"short\": false}
                ]
            }]
        }"
            else
                # Simple template for Slack
                payload="{
                    \"text\": \"🚨 Admin Violation: User $user on $hostname - $COMPANY_NAME\"
                }"
            fi
            ;;
            
        *)
            # Default/generic webhook format
            log_message "WARN" "Unknown webhook type: $WEBHOOK_TYPE, using generic format"
            payload="{
                \"text\": \"Admin Violation Detected\",
                \"user\": \"$user\",
                \"hostname\": \"$hostname\",
                \"company\": \"$COMPANY_NAME\",
                \"timestamp\": \"$(date)\"
            }"
            ;;
    esac
    
    # Send webhook notification
    if [[ -n "$payload" && -n "$WEBHOOK_URL" ]]; then
        curl -X POST -H 'Content-type: application/json' \
             --data "$payload" \
             "$WEBHOOK_URL" &>/dev/null && \
        log_message "INFO" "Webhook notification sent ($WEBHOOK_TYPE: $NOTIFICATION_TEMPLATE template)" || \
        log_message "ERROR" "Failed to send webhook notification to $WEBHOOK_TYPE"
    fi
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
    
    # Determine monitoring behavior based on configuration
    if [[ "$MONITOR_JAMF_CONNECT_ONLY" == "true" ]]; then
        # Only check for violations if Jamf Connect elevation is detected
        log_message "INFO" "Monitoring mode: Jamf Connect events only"
        
        # Check for recent Jamf Connect elevation events
        local time_window="${MONITORING_INTERVAL}s"
        local recent_events=$(log show --style compact --predicate '(subsystem == "com.jamf.connect.daemon") && (category == "PrivilegeElevation")' --last "$time_window" 2>/dev/null)
        
        if [[ -n "$recent_events" ]]; then
            log_message "INFO" "Recent Jamf Connect elevation detected - checking for violations"
            echo "$recent_events" >> "$JAMF_LOG"
            
            # Only check for unauthorized admins if Jamf Connect activity detected
            check_unauthorized_admins
        else
            log_message "INFO" "No recent Jamf Connect elevation - skipping admin check"
        fi
    else
        # Always monitor for unauthorized admins regardless of Jamf Connect activity
        log_message "INFO" "Monitoring mode: Always check for unauthorized admins"
        
        # Still log Jamf Connect events if they exist
        monitor_jamf_connect_elevation
        
        # Always check for unauthorized admin accounts
        check_unauthorized_admins
    fi
    
    log_message "INFO" "Monitoring cycle completed"
}

# Test webhook functionality
send_test_webhook() {
    if [[ -z "$WEBHOOK_URL" ]]; then
        echo "❌ No webhook URL configured"
        echo "Please configure WebhookURL in Configuration Profile"
        return 1
    fi
    
    echo "Testing webhook notification..."
    echo "  Platform: $WEBHOOK_TYPE"
    echo "  URL: ${WEBHOOK_URL:0:50}..."
    echo "  Template: $NOTIFICATION_TEMPLATE"
    echo ""
    
    # Send test notification
    local test_user="testuser"
    local test_hostname=$(hostname)
    
    send_webhook_notification_enhanced "$test_user" "$test_hostname"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Test webhook sent successfully!"
        echo ""
        echo "Check your $WEBHOOK_TYPE channel for the test message."
        
        if [[ "$WEBHOOK_TYPE" == "teams" ]]; then
            echo ""
            echo "📝 Microsoft Teams Setup:"
            echo "1. In Teams, go to the channel where you want notifications"
            echo "2. Click ••• (More options) → Connectors"
            echo "3. Search for 'Incoming Webhook' and click Configure"
            echo "4. Give it a name (e.g., 'Jamf Monitor') and optionally upload an image"
            echo "5. Click Create and copy the webhook URL"
            echo "6. Add the URL to your Jamf Configuration Profile"
        elif [[ "$WEBHOOK_TYPE" == "slack" ]]; then
            echo ""
            echo "📝 Slack Setup (Legacy Webhooks):"
            echo "1. Go to https://api.slack.com/apps"
            echo "2. Create new app → From scratch"
            echo "3. Enable Incoming Webhooks"
            echo "4. Add New Webhook to Workspace"
            echo "5. Choose channel and copy the webhook URL"
            echo "6. Add the URL to your Jamf Configuration Profile"
        fi
    else
        echo "❌ Failed to send test webhook"
        echo "Check the logs for detailed error information:"
        echo "  tail -f /var/log/jamf_connect_monitor/monitor.log"
    fi
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
    "elevation-report")
        echo "=== Legitimate Elevation Report ==="
        echo
        generate_elevation_summary
        echo
        echo "Recent Legitimate Elevations:"
        if [[ -f "$LOG_DIR/legitimate_elevations.log" ]]; then
            tail -10 "$LOG_DIR/legitimate_elevations.log" | while IFS='|' read -r timestamp type user reason host; do
                echo "  $timestamp |$type |$user |$reason"
            done
        else
            echo "  No legitimate elevation data available"
        fi
        echo
        echo "Current Elevation Statistics:"
        if [[ -f "$LOG_DIR/.stats_total" ]]; then
            echo "  Total Elevations: $(cat "$LOG_DIR/.stats_total" 2>/dev/null || echo "0")"
            echo "  Today's Elevations: $(cat "$LOG_DIR/.stats_daily_$(date '+%Y-%m-%d')" 2>/dev/null || echo "0")"
        fi
        echo
        echo "Top Users (by elevation count):"
        if ls "$LOG_DIR"/.stats_user_* >/dev/null 2>&1; then
            for stats_file in "$LOG_DIR"/.stats_user_*; do
                if [[ -f "$stats_file" ]]; then
                    local user=$(basename "$stats_file" | sed 's/.stats_user_//')
                    local count=$(cat "$stats_file")
                    echo "  $user: $count elevations"
                fi
            done | sort -t: -k2 -rn | head -5
        else
            echo "  No elevation statistics available yet"
        fi
        ;;
    "test-config")
        read_configuration
        echo "=== Configuration Profile Test ==="
        echo "Profile Status: $([[ -n "$(defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null || sudo defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null)" ]] && echo "Deployed" || echo "Not deployed")"
        echo
        echo "Notification Settings:"
        echo "  Webhook: $([[ -n "$WEBHOOK_URL" ]] && echo "Configured" || echo "None")"
        echo "  Email: $([[ -n "$EMAIL_RECIPIENT" ]] && echo "$EMAIL_RECIPIENT" || echo "None")"
        echo "  SMTP Provider: $SMTP_PROVIDER"
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
    "test-webhook")
        read_configuration
        send_test_webhook
        ;;
    "help")
        echo "Usage: $0 [command]"
        echo "Commands:"
        echo "  monitor          Run monitoring cycle (default)"
        echo "  status           Show current status and configuration"
        echo "  elevation-report View legitimate elevation statistics and history"
        echo "  add-admin        Add user to approved admin list"
        echo "  remove-admin     Remove user from approved admin list"
        echo "  force-check      Force check for unauthorized admins"
        echo "  test-config      Test configuration profile settings"
        echo "  test-email       Send test email to verify delivery"
        echo "  test-webhook     Test webhook notification (Slack/Teams)"
        echo "  help             Show this help message"
        echo
        echo "Version $VERSION Features:"
        echo "  • NEW: Legitimate elevation tracking and audit logging"
        echo "  • NEW: Elevation analytics and compliance reporting"
        echo "  • Configuration Profile support for centralized management"
        echo "  • SMTP provider selection with auto-configuration"
        echo "  • Real-time monitoring capabilities"
        echo "  • Enhanced notification templates with elevation context"
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