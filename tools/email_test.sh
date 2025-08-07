#!/bin/bash

# Jamf Connect Monitor - Email Testing & Verification Tool
# Version: 1.0.0
# Author: MacJediWizard
# Description: Comprehensive email delivery testing for production deployment

set -e  # Exit on any error

# Configuration
SCRIPT_NAME="JamfConnectMonitor-EmailTest"
LOG_FILE="/var/log/jamf_connect_monitor_email_test.log"
CONFIG_PROFILE_DOMAIN="com.macjediwizard.jamfconnectmonitor"

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
    return 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root. Use: sudo $0"
        return 1
    fi
}

# Read Configuration Profile settings
read_email_configuration() {
    print_status "$BLUE" "Reading email configuration from Configuration Profile..."
    
    local config_data=""
    local config_source=""
    
    # Use same methods as main script
    if config_data=$(defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null); then
        config_source="Method 2 (Managed Preferences)"
    elif config_data=$(sudo defaults read "/Library/Managed Preferences/$CONFIG_PROFILE_DOMAIN" 2>/dev/null); then
        config_source="Method 4 (sudo Managed Preferences)"
    elif config_data=$(defaults read "$CONFIG_PROFILE_DOMAIN" 2>/dev/null); then
        config_source="Method 1 (Standard)"
    fi
    
    if [[ -n "$config_data" ]]; then
        print_status "$GREEN" "✅ Configuration Profile found via $config_source"
        
        # Parse email settings
        EMAIL_RECIPIENT=$(echo "$config_data" | grep -A1 "EmailRecipient" | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]*' | head -1 || echo "")
        SMTP_SERVER=$(echo "$config_data" | grep -A1 "SMTPServer" | grep -o '"[^"]*"' | tr -d '"' | head -1 || echo "")
        SMTP_PORT=$(echo "$config_data" | grep -A1 "SMTPPort" | grep -o '[0-9]*' | head -1 || echo "465")
        SMTP_USERNAME=$(echo "$config_data" | grep -A1 "SMTPUsername" | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]*' | head -1 || echo "")
        SMTP_PASSWORD=$(echo "$config_data" | grep -A1 "SMTPPassword" | grep -o '"[^"]*"' | tr -d '"' | head -1 || echo "")
        SMTP_FROM_ADDRESS=$(echo "$config_data" | grep -A1 "SMTPFromAddress" | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]*' | head -1 || echo "$SMTP_USERNAME")
        COMPANY_NAME=$(echo "$config_data" | grep -A1 "CompanyName" | grep -o '"[^"]*"' | tr -d '"' | head -1 || echo "Your Company")
        
        # Set default from address if not configured
        [[ -z "$SMTP_FROM_ADDRESS" ]] && SMTP_FROM_ADDRESS="$SMTP_USERNAME"
        
        return 0
    else
        print_status "$RED" "❌ Configuration Profile not found"
        EMAIL_RECIPIENT=""
        SMTP_SERVER=""
        SMTP_PORT="465"
        SMTP_USERNAME=""
        SMTP_PASSWORD=""
        SMTP_FROM_ADDRESS=""
        COMPANY_NAME="Your Company"
        return 1
    fi
}

# Display current email configuration
show_email_configuration() {
    print_status "$BLUE" "=== Current Email Configuration ==="
    echo "Email Recipient: $([[ -n "$EMAIL_RECIPIENT" ]] && echo "$EMAIL_RECIPIENT" || echo "Not configured")"
    echo "SMTP Server: $([[ -n "$SMTP_SERVER" ]] && echo "$SMTP_SERVER:$SMTP_PORT" || echo "Not configured")"
    echo "SMTP Username: $([[ -n "$SMTP_USERNAME" ]] && echo "$SMTP_USERNAME" || echo "Not configured")"
    echo "SMTP Password: $([[ -n "$SMTP_PASSWORD" ]] && echo "Configured (hidden)" || echo "Not configured")"
    echo "From Address: $([[ -n "$SMTP_FROM_ADDRESS" ]] && echo "$SMTP_FROM_ADDRESS" || echo "Default")"
    echo "Company: $COMPANY_NAME"
    echo
}

# Test network connectivity to SMTP server
test_smtp_connectivity() {
    if [[ -z "$SMTP_SERVER" ]]; then
        print_status "$YELLOW" "⚠️  SMTP server not configured - skipping connectivity test"
        return 1
    fi
    
    print_status "$BLUE" "Testing SMTP connectivity to $SMTP_SERVER:$SMTP_PORT..."
    
    # Test basic network connectivity
    if command -v nc >/dev/null 2>&1; then
        if timeout 10 nc -z "$SMTP_SERVER" "$SMTP_PORT" 2>/dev/null; then
            print_status "$GREEN" "✅ Network connectivity to $SMTP_SERVER:$SMTP_PORT successful"
            return 0
        else
            print_status "$RED" "❌ Cannot connect to $SMTP_SERVER:$SMTP_PORT"
            print_status "$YELLOW" "   Check: Network connectivity, firewall, SMTP server address"
            return 1
        fi
    else
        print_status "$YELLOW" "⚠️  nc (netcat) not available - cannot test connectivity"
        return 1
    fi
}

# Test SMTP authentication (without sending email)
test_smtp_authentication() {
    if [[ -z "$SMTP_SERVER" || -z "$SMTP_USERNAME" || -z "$SMTP_PASSWORD" ]]; then
        print_status "$YELLOW" "⚠️  SMTP authentication not fully configured - skipping auth test"
        return 1
    fi
    
    print_status "$BLUE" "Testing SMTP authentication for $SMTP_USERNAME..."
    
    # Create temporary SMTP test script using swaks if available
    if command -v swaks >/dev/null 2>&1; then
        local auth_test=$(swaks --auth --server "$SMTP_SERVER:$SMTP_PORT" \
                               --auth-user "$SMTP_USERNAME" \
                               --auth-password "$SMTP_PASSWORD" \
                               --to "$SMTP_USERNAME" \
                               --from "$SMTP_FROM_ADDRESS" \
                               --header "Subject: SMTP Auth Test" \
                               --body "Test" \
                               --suppress-data \
                               --hide-all 2>&1)
        
        if echo "$auth_test" | grep -q "AUTH.*accepted"; then
            print_status "$GREEN" "✅ SMTP authentication successful"
            return 0
        else
            print_status "$RED" "❌ SMTP authentication failed"
            print_status "$YELLOW" "   Check: Username, password, 2FA/App Password settings"
            echo "   Error details: $auth_test"
            return 1
        fi
    else
        print_status "$YELLOW" "⚠️  swaks not available - cannot test authentication separately"
        return 1
    fi
}

# Test system mail availability and configuration
test_system_mail() {
    print_status "$BLUE" "Testing system mail configuration..."
    
    local mail_commands=("mail" "mailx" "sendmail")
    local available_commands=()
    
    for cmd in "${mail_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            available_commands+=("$cmd")
            print_status "$GREEN" "✅ $cmd command available"
        else
            print_status "$YELLOW" "⚠️  $cmd command not available"
        fi
    done
    
    if [[ ${#available_commands[@]} -eq 0 ]]; then
        print_status "$RED" "❌ No system mail commands available"
        print_status "$YELLOW" "   Install mailx or configure postfix/sendmail"
        return 1
    fi
    
    # Test postfix/sendmail configuration
    if [[ -f "/etc/postfix/main.cf" ]]; then
        print_status "$GREEN" "✅ Postfix configuration found"
        local relay_host=$(grep "^relayhost" /etc/postfix/main.cf 2>/dev/null || echo "")
        if [[ -n "$relay_host" ]]; then
            print_status "$GREEN" "✅ SMTP relay configured: $relay_host"
        else
            print_status "$YELLOW" "⚠️  No SMTP relay configured in postfix"
        fi
    else
        print_status "$YELLOW" "⚠️  Postfix not configured"
    fi
    
    return 0
}

# Send test email via authenticated SMTP
send_smtp_test_email() {
    local test_recipient="${1:-$EMAIL_RECIPIENT}"
    
    if [[ -z "$test_recipient" ]]; then
        print_status "$RED" "❌ No recipient specified for SMTP test"
        return 1
    fi
    
    if [[ -z "$SMTP_SERVER" || -z "$SMTP_USERNAME" || -z "$SMTP_PASSWORD" ]]; then
        print_status "$YELLOW" "⚠️  SMTP not fully configured - skipping SMTP test"
        return 1
    fi
    
    print_status "$BLUE" "Sending test email via authenticated SMTP..."
    
    local temp_config="/tmp/smtp_test_config_$$"
    local temp_message="/tmp/smtp_test_message_$$"
    local hostname=$(hostname)
    
    # Create SMTP configuration
    cat > "$temp_config" << EOF
set smtp-host=$SMTP_SERVER:$SMTP_PORT
set smtp-use-starttls=$([[ "$SMTP_PORT" == "465" ]] && echo "no" || echo "yes")
set smtp-use-ssl=$([[ "$SMTP_PORT" == "465" ]] && echo "yes" || echo "no")
set smtp-auth=yes
set smtp-auth-user=$SMTP_USERNAME
set smtp-auth-password='$SMTP_PASSWORD'
set from=$SMTP_FROM_ADDRESS
set ssl-verify=ignore
EOF
    
    # Create test message
    cat > "$temp_message" << EOF
🧪 SMTP Authentication Test - Jamf Connect Monitor

This is a test email from the Jamf Connect Monitor email testing tool.

Test Details:
- Hostname: $hostname  
- Company: $COMPANY_NAME
- SMTP Server: $SMTP_SERVER:$SMTP_PORT
- Authentication: $SMTP_USERNAME
- From Address: $SMTP_FROM_ADDRESS
- Test Time: $(date)
- Delivery Method: Authenticated SMTP

If you received this email, your SMTP authentication is working correctly.

Technical Details:
- Configuration Profile: Active
- Test Tool: email_test.sh v1.0.0
- System: macOS $(sw_vers -productVersion)

Next steps: Configure your monitoring system with these SMTP settings.
EOF
    
    local result=1
    
    # Try different mail commands with SMTP config
    if command -v mailx >/dev/null 2>&1; then
        if mailx -S "$temp_config" -s "🧪 SMTP Test - $hostname ($COMPANY_NAME)" "$test_recipient" < "$temp_message" 2>/dev/null; then
            result=0
        fi
    elif command -v mail >/dev/null 2>&1; then
        # Note: Basic mail command may not support SMTP auth
        print_status "$YELLOW" "⚠️  Using basic mail command - SMTP auth may not work"
        if mail -s "🧪 SMTP Test - $hostname ($COMPANY_NAME)" "$test_recipient" < "$temp_message" 2>/dev/null; then
            result=0
        fi
    fi
    
    # Cleanup
    rm -f "$temp_config" "$temp_message"
    
    if [[ $result -eq 0 ]]; then
        print_status "$GREEN" "✅ SMTP test email sent successfully to $test_recipient"
        return 0
    else
        print_status "$RED" "❌ Failed to send SMTP test email"
        return 1
    fi
}

# Send test email via system mail
send_system_mail_test() {
    local test_recipient="${1:-$EMAIL_RECIPIENT}"
    
    if [[ -z "$test_recipient" ]]; then
        print_status "$RED" "❌ No recipient specified for system mail test"
        return 1
    fi
    
    print_status "$BLUE" "Sending test email via system mail..."
    
    local hostname=$(hostname)
    local test_body="🧪 System Mail Test - Jamf Connect Monitor

This is a test email from the Jamf Connect Monitor email testing tool using system mail.

Test Details:
- Hostname: $hostname
- Company: $COMPANY_NAME  
- Test Time: $(date)
- Delivery Method: System Mail (no SMTP auth)

System Mail Configuration:
- Postfix Status: $([[ -f "/etc/postfix/main.cf" ]] && echo "Configured" || echo "Not configured")
- Available Commands: $(command -v mail >/dev/null && echo "mail") $(command -v mailx >/dev/null && echo "mailx") $(command -v sendmail >/dev/null && echo "sendmail")

If you received this email, your system mail is working correctly.

Technical Details:
- Test Tool: email_test.sh v1.0.0  
- System: macOS $(sw_vers -productVersion)
- User: $(whoami)

This email was sent without SMTP authentication using the system's built-in mail capabilities."
    
    local result=1
    
    # Try different system mail methods
    if command -v mail >/dev/null 2>&1; then
        if echo "$test_body" | mail -s "🧪 System Mail Test - $hostname ($COMPANY_NAME)" "$test_recipient" 2>/dev/null; then
            result=0
        fi
    elif command -v mailx >/dev/null 2>&1; then
        if echo "$test_body" | mailx -s "🧪 System Mail Test - $hostname ($COMPANY_NAME)" "$test_recipient" 2>/dev/null; then
            result=0
        fi
    elif command -v sendmail >/dev/null 2>&1; then
        local temp_mail="/tmp/system_mail_test_$$"
        cat > "$temp_mail" << EOF
To: $test_recipient
Subject: 🧪 System Mail Test - $hostname ($COMPANY_NAME)

$test_body
EOF
        if sendmail "$test_recipient" < "$temp_mail" 2>/dev/null; then
            result=0
        fi
        rm -f "$temp_mail"
    fi
    
    if [[ $result -eq 0 ]]; then
        print_status "$GREEN" "✅ System mail test email sent successfully to $test_recipient"
        return 0
    else
        print_status "$RED" "❌ Failed to send system mail test email"
        return 1
    fi
}

# Comprehensive email diagnostics
run_email_diagnostics() {
    print_status "$BLUE" "Running comprehensive email diagnostics..."
    echo
    
    # Check system requirements
    print_status "$BLUE" "=== System Requirements Check ==="
    
    # Check mail commands
    local mail_score=0
    local mail_commands=("mail" "mailx" "sendmail")
    for cmd in "${mail_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            print_status "$GREEN" "✅ $cmd available"
            ((mail_score++))
        else
            print_status "$RED" "❌ $cmd not available"
        fi
    done
    
    # Check network tools
    if command -v nc >/dev/null 2>&1; then
        print_status "$GREEN" "✅ nc (netcat) available for connectivity testing"
    else
        print_status "$YELLOW" "⚠️  nc (netcat) not available - install via: brew install netcat"
    fi
    
    if command -v swaks >/dev/null 2>&1; then
        print_status "$GREEN" "✅ swaks available for SMTP testing"
    else
        print_status "$YELLOW" "⚠️  swaks not available - install via: brew install swaks"
    fi
    
    echo
    
    # Configuration analysis  
    print_status "$BLUE" "=== Configuration Analysis ==="
    if [[ -n "$EMAIL_RECIPIENT" ]]; then
        print_status "$GREEN" "✅ Email recipient configured: $EMAIL_RECIPIENT"
    else
        print_status "$RED" "❌ Email recipient not configured"
    fi
    
    if [[ -n "$SMTP_SERVER" ]]; then
        print_status "$GREEN" "✅ SMTP server configured: $SMTP_SERVER:$SMTP_PORT"
        
        if [[ -n "$SMTP_USERNAME" ]]; then
            print_status "$GREEN" "✅ SMTP authentication configured: $SMTP_USERNAME"
        else
            print_status "$YELLOW" "⚠️  SMTP username not configured"
        fi
        
        if [[ -n "$SMTP_PASSWORD" ]]; then
            print_status "$GREEN" "✅ SMTP password configured"
        else
            print_status "$YELLOW" "⚠️  SMTP password not configured"
        fi
    else
        print_status "$YELLOW" "⚠️  SMTP server not configured - will use system mail"
    fi
    
    echo
    
    # System mail configuration
    print_status "$BLUE" "=== System Mail Configuration ==="
    
    if [[ -f "/etc/postfix/main.cf" ]]; then
        print_status "$GREEN" "✅ Postfix configuration found"
        
        local relay_host=$(grep "^relayhost" /etc/postfix/main.cf 2>/dev/null | cut -d'=' -f2 | xargs)
        if [[ -n "$relay_host" ]]; then
            print_status "$GREEN" "✅ Postfix relay host: $relay_host"
        else
            print_status "$YELLOW" "⚠️  No postfix relay host configured"
        fi
        
        local mydomain=$(grep "^mydomain" /etc/postfix/main.cf 2>/dev/null | cut -d'=' -f2 | xargs)
        if [[ -n "$mydomain" ]]; then
            print_status "$GREEN" "✅ Postfix domain: $mydomain"
        else
            print_status "$YELLOW" "⚠️  No postfix domain configured"
        fi
    else
        print_status "$RED" "❌ Postfix not configured"
        print_status "$YELLOW" "   System mail may not work reliably without SMTP relay"
    fi
    
    # Check postfix status
    if launchctl list | grep -q "org.postfix.master"; then
        print_status "$GREEN" "✅ Postfix service running"
    else
        print_status "$YELLOW" "⚠️  Postfix service not running"
        print_status "$YELLOW" "   Start with: sudo launchctl load /System/Library/LaunchDaemons/org.postfix.master.plist"
    fi
    
    echo
    
    # Network connectivity tests
    if [[ -n "$SMTP_SERVER" ]]; then
        print_status "$BLUE" "=== Network Connectivity Tests ==="
        test_smtp_connectivity
        echo
    fi
    
    # Scoring and recommendations
    print_status "$BLUE" "=== Email Delivery Assessment ==="
    
    local total_score=0
    
    # SMTP readiness
    if [[ -n "$SMTP_SERVER" && -n "$SMTP_USERNAME" && -n "$SMTP_PASSWORD" ]]; then
        print_status "$GREEN" "✅ SMTP Authentication: Ready"
        ((total_score += 3))
    elif [[ -n "$SMTP_SERVER" ]]; then
        print_status "$YELLOW" "⚠️  SMTP Authentication: Partially configured"
        ((total_score += 1))
    else
        print_status "$RED" "❌ SMTP Authentication: Not configured"
    fi
    
    # System mail readiness
    if [[ $mail_score -gt 0 ]]; then
        print_status "$GREEN" "✅ System Mail: Available ($mail_score/3 commands)"
        ((total_score += $mail_score))
    else
        print_status "$RED" "❌ System Mail: Not available"
    fi
    
    echo
    print_status "$BLUE" "Overall Email Readiness Score: $total_score/6"
    
    if [[ $total_score -ge 5 ]]; then
        print_status "$GREEN" "✅ Email delivery should work reliably"
    elif [[ $total_score -ge 3 ]]; then
        print_status "$YELLOW" "⚠️  Email delivery may work with some issues"
    else
        print_status "$RED" "❌ Email delivery likely to fail - configuration needed"
    fi
}

# Provide fix recommendations
provide_fix_recommendations() {
    print_status "$BLUE" "=== Fix Recommendations ==="
    
    local recommendations=()
    
    # Email recipient
    if [[ -z "$EMAIL_RECIPIENT" ]]; then
        recommendations+=("Configure email recipient in Configuration Profile: NotificationSettings.EmailRecipient")
    fi
    
    # SMTP configuration
    if [[ -z "$SMTP_SERVER" ]]; then
        recommendations+=("For reliable delivery, configure SMTP server in Configuration Profile: NotificationSettings.SMTPServer")
    fi
    
    if [[ -n "$SMTP_SERVER" && -z "$SMTP_USERNAME" ]]; then
        recommendations+=("Configure SMTP username: NotificationSettings.SMTPUsername")
    fi
    
    if [[ -n "$SMTP_SERVER" && -z "$SMTP_PASSWORD" ]]; then
        recommendations+=("Configure SMTP password (use App Password for Gmail): NotificationSettings.SMTPPassword")
    fi
    
    # System mail improvements
    if ! command -v mail >/dev/null 2>&1 && ! command -v mailx >/dev/null 2>&1; then
        recommendations+=("Install mail command: xcode-select --install")
    fi
    
    if [[ ! -f "/etc/postfix/main.cf" ]]; then
        recommendations+=("Configure postfix for system mail reliability")
    fi
    
    # Network tools
    if ! command -v nc >/dev/null 2>&1; then
        recommendations+=("Install netcat for connectivity testing: brew install netcat")
    fi
    
    if ! command -v swaks >/dev/null 2>&1; then
        recommendations+=("Install swaks for SMTP testing: brew install swaks")
    fi
    
    # Gmail specific
    if [[ "$SMTP_SERVER" == *"gmail"* ]]; then
        recommendations+=("For Gmail: Enable 2-Step Verification and create App Password")
        recommendations+=("Gmail App Password: Google Account → Security → App passwords")
    fi
    
    # Office365 specific  
    if [[ "$SMTP_SERVER" == *"office365"* || "$SMTP_SERVER" == *"outlook"* ]]; then
        recommendations+=("For Office365: Use account password or create app-specific password")
    fi
    
    if [[ ${#recommendations[@]} -eq 0 ]]; then
        print_status "$GREEN" "✅ No additional configuration needed"
    else
        for ((i=0; i<${#recommendations[@]}; i++)); do
            print_status "$YELLOW" "$((i+1)). ${recommendations[i]}"
        done
    fi
    
    echo
    print_status "$BLUE" "=== Quick Fix Commands ==="
    echo "# Install development tools (includes mail command):"
    echo "xcode-select --install"
    echo
    echo "# Install testing tools via Homebrew:"
    echo "brew install netcat swaks"
    echo
    echo "# Test email after configuration:"
    echo "sudo ./tools/email_test.sh test your-email@domain.com"
    echo
    echo "# Enable postfix if needed:"
    echo "sudo launchctl load /System/Library/LaunchDaemons/org.postfix.master.plist"
}

# Main testing function
run_comprehensive_test() {
    local test_recipient="${1:-$EMAIL_RECIPIENT}"
    
    print_status "$GREEN" "🧪 COMPREHENSIVE EMAIL TESTING"
    print_status "$GREEN" "==============================="
    echo
    
    # Configuration and diagnostics
    read_email_configuration
    show_email_configuration
    run_email_diagnostics
    
    if [[ -z "$test_recipient" ]]; then
        print_status "$RED" "❌ No test recipient specified"
        print_status "$YELLOW" "Usage: $0 test recipient@domain.com"
        return 1
    fi
    
    print_status "$BLUE" "=== Live Email Testing to: $test_recipient ==="
    
    local smtp_result=1
    local system_result=1
    
    # Test SMTP if configured
    if [[ -n "$SMTP_SERVER" ]]; then
        if send_smtp_test_email "$test_recipient"; then
            smtp_result=0
        fi
    else
        print_status "$YELLOW" "⚠️  Skipping SMTP test - not configured"
    fi
    
    echo
    
    # Test system mail
    if send_system_mail_test "$test_recipient"; then
        system_result=0
    fi
    
    echo
    
    # Summary
    print_status "$BLUE" "=== Test Results Summary ==="
    if [[ $smtp_result -eq 0 ]]; then
        print_status "$GREEN" "✅ SMTP Authentication: SUCCESS"
    else
        print_status "$RED" "❌ SMTP Authentication: FAILED"
    fi
    
    if [[ $system_result -eq 0 ]]; then
        print_status "$GREEN" "✅ System Mail: SUCCESS" 
    else
        print_status "$RED" "❌ System Mail: FAILED"
    fi
    
    if [[ $smtp_result -eq 0 || $system_result -eq 0 ]]; then
        print_status "$GREEN" "🎉 EMAIL DELIVERY IS WORKING"
        print_status "$BLUE" "Your monitoring system will be able to send notifications"
    else
        print_status "$RED" "💥 EMAIL DELIVERY COMPLETELY FAILED"
        provide_fix_recommendations
    fi
}

# Quick connectivity test
quick_connectivity_test() {
    print_status "$BLUE" "🔌 Quick Connectivity Test"
    print_status "$BLUE" "=========================="
    
    read_email_configuration >/dev/null 2>&1
    
    if [[ -n "$SMTP_SERVER" ]]; then
        test_smtp_connectivity
    else
        print_status "$YELLOW" "⚠️  No SMTP server configured to test"
    fi
    
    # Test common mail servers
    local common_servers=("smtp.gmail.com:465" "smtp.gmail.com:587" "smtp.office365.com:587" "smtp-mail.outlook.com:587")
    
    print_status "$BLUE" "Testing common SMTP servers..."
    for server in "${common_servers[@]}"; do
        local host=$(echo "$server" | cut -d':' -f1)
        local port=$(echo "$server" | cut -d':' -f2)
        
        if command -v nc >/dev/null 2>&1; then
            if timeout 5 nc -z "$host" "$port" 2>/dev/null; then
                print_status "$GREEN" "✅ $server reachable"
            else
                print_status "$RED" "❌ $server unreachable"
            fi
        fi
    done
}

# Main execution
main() {
    case "${1:-help}" in
        "test")
            check_root || exit 1
            run_comprehensive_test "$2"
            ;;
        "diagnostics"|"diag")
            check_root || exit 1
            read_email_configuration
            show_email_configuration  
            run_email_diagnostics
            provide_fix_recommendations
            ;;
        "connectivity"|"conn") 
            quick_connectivity_test
            ;;
        "smtp")
            check_root || exit 1
            read_email_configuration
            send_smtp_test_email "$2"
            ;;
        "system-mail"|"sys")
            check_root || exit 1
            read_email_configuration
            send_system_mail_test "$2"
            ;;
        "config")
            check_root || exit 1
            read_email_configuration
            show_email_configuration
            ;;
        "help")
            echo "Jamf Connect Monitor - Email Testing Tool v1.0.0"
            echo "Usage: $0 [command] [email@domain.com]"
            echo
            echo "Commands:"
            echo "  test [email]        Complete email testing (SMTP + system mail)"
            echo "  diagnostics         Full diagnostic report with recommendations"
            echo "  connectivity        Test network connectivity to SMTP servers"
            echo "  smtp [email]        Test SMTP authentication only"
            echo "  system-mail [email] Test system mail only"
            echo "  config              Show current email configuration"
            echo "  help                Show this help"
            echo
            echo "Examples:"
            echo "  sudo $0 test admin@yourcompany.com"
            echo "  sudo $0 diagnostics"
            echo "  sudo $0 connectivity"
            echo
            echo "Features:"
            echo "  • Tests SMTP authentication (Gmail, Office365, etc.)"
            echo "  • Tests system mail fallback"
            echo "  • Network connectivity validation"
            echo "  • Configuration Profile integration"
            echo "  • Comprehensive diagnostics with fix recommendations"
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"