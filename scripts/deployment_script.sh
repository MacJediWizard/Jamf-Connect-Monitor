#!/bin/bash

# Jamf Connect Monitor - One-Click Deployment Script
# This script automates the complete installation and configuration

set -e  # Exit on any error

SCRIPT_NAME="Jamf Connect Monitor Deployment"
LOG_FILE="/tmp/jamf_monitor_deployment.log"

# Configuration - Modify these as needed
WEBHOOK_URL=""  # Add your Slack/Teams webhook URL
EMAIL_RECIPIENT=""  # Add your email for notifications
MONITORING_INTERVAL=300  # 5 minutes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
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
    log "INFO" "$message"
}

# Error handling
error_exit() {
    print_status "$RED" "ERROR: $1"
    log "ERROR" "$1"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root. Use: sudo $0"
    fi
}

# Check prerequisites
check_prerequisites() {
    print_status "$BLUE" "Checking prerequisites..."
    
    # Check macOS version
    local macos_version=$(sw_vers -productVersion)
    print_status "$GREEN" "macOS Version: $macos_version"
    
    # Check if Jamf Connect is installed
    if [[ -f "/Applications/Jamf Connect.app/Contents/Info.plist" ]]; then
        local jc_version=$(defaults read "/Applications/Jamf Connect.app/Contents/Info.plist" CFBundleShortVersionString)
        print_status "$GREEN" "Jamf Connect installed: Version $jc_version"
    else
        print_status "$YELLOW" "WARNING: Jamf Connect not found. Installing monitoring anyway."
    fi
    
    # Check if Jamf Pro binary exists
    if command -v jamf &> /dev/null; then
        print_status "$GREEN" "Jamf Pro binary found"
    else
        print_status "$YELLOW" "WARNING: Jamf Pro binary not found. Some features may be limited."
    fi
}

# Create necessary directories
create_directories() {
    print_status "$BLUE" "Creating directories..."
    
    local directories=(
        "/usr/local/bin"
        "/var/log/jamf_connect_monitor"
        "/usr/local/etc"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_status "$GREEN" "Created directory: $dir"
        else
            print_status "$GREEN" "Directory already exists: $dir"
        fi
    done
    
    # Set permissions
    chmod 755 /usr/local/bin /var/log/jamf_connect_monitor /usr/local/etc
    chown root:wheel /usr/local/bin /var/log/jamf_connect_monitor /usr/local/etc
}

# Deploy main monitor script
deploy_monitor_script() {
    print_status "$BLUE" "Deploying main monitor script..."
    
    local script_path="/usr/local/bin/jamf_connect_monitor.sh"
    
    # Note: In a real deployment, you would either:
    # 1. Download from a URL: curl -o "$script_path" "https://your-server.com/jamf_connect_monitor.sh"
    # 2. Copy from a mounted share: cp "/path/to/jamf_connect_monitor.sh" "$script_path"
    # 3. Embed the script content directly in this deployment script
    
    # For this example, we'll assume the script is in the same directory
    if [[ -f "./jamf_connect_monitor.sh" ]]; then
        cp "./jamf_connect_monitor.sh" "$script_path"
    else
        error_exit "Monitor script not found. Please ensure jamf_connect_monitor.sh is in the current directory."
    fi
    
    # Update configuration in the script if webhook/email provided
    if [[ -n "$WEBHOOK_URL" ]]; then
        sed -i '' "s|WEBHOOK_URL=\"\"|WEBHOOK_URL=\"$WEBHOOK_URL\"|" "$script_path"
        print_status "$GREEN" "Configured webhook URL"
    fi
    
    if [[ -n "$EMAIL_RECIPIENT" ]]; then
        sed -i '' "s|EMAIL_RECIPIENT=\"\"|EMAIL_RECIPIENT=\"$EMAIL_RECIPIENT\"|" "$script_path"
        print_status "$GREEN" "Configured email recipient"
    fi
    
    # Set permissions
    chmod +x "$script_path"
    chown root:wheel "$script_path"
    
    print_status "$GREEN" "Monitor script deployed successfully"
}

# Create LaunchDaemon
create_launch_daemon() {
    print_status "$BLUE" "Creating LaunchDaemon..."
    
    local plist_path="/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
    
    cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.macjediwizard.jamfconnectmonitor</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/jamf_connect_monitor.sh</string>
        <string>monitor</string>
    </array>
    
    <key>StartInterval</key>
    <integer>$MONITORING_INTERVAL</integer>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <false/>
    
    <key>StandardOutPath</key>
    <string>/var/log/jamf_connect_monitor/daemon.log</string>
    
    <key>StandardErrorPath</key>
    <string>/var/log/jamf_connect_monitor/daemon_error.log</string>
    
    <key>UserName</key>
    <string>root</string>
    
    <key>GroupName</key>
    <string>wheel</string>
    
    <key>ProcessType</key>
    <string>Background</string>
</dict>
</plist>
EOF
    
    # Set permissions
    chown root:wheel "$plist_path"
    chmod 644 "$plist_path"
    
    print_status "$GREEN" "LaunchDaemon created successfully"
}

# Initialize monitoring
initialize_monitoring() {
    print_status "$BLUE" "Initializing monitoring..."
    
    # Run initial monitoring to create approved admin list
    /usr/local/bin/jamf_connect_monitor.sh monitor
    
    print_status "$GREEN" "Initial monitoring completed"
    
    # Show current admin status
    print_status "$BLUE" "Current admin status:"
    /usr/local/bin/jamf_connect_monitor.sh status
}

# Load and start LaunchDaemon
start_daemon() {
    print_status "$BLUE" "Starting monitoring daemon..."
    
    local plist_path="/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
    
    # Unload if already loaded (for reinstalls)
    launchctl unload "$plist_path" 2>/dev/null || true
    
    # Load the daemon
    launchctl load "$plist_path"
    
    # Verify it's loaded
    if launchctl list | grep -q "com.macjediwizard.jamfconnectmonitor"; then
        print_status "$GREEN" "Monitoring daemon started successfully"
    else
        error_exit "Failed to start monitoring daemon"
    fi
}

# Create Jamf Pro Extension Attribute script file
create_jamf_ea() {
    print_status "$BLUE" "Creating Jamf Pro Extension Attribute script..."
    
    local ea_path="/usr/local/etc/jamf_ea_admin_violations.sh"
    
    # Copy the EA script (assuming it's in the same directory)
    if [[ -f "./jamf_ea_admin_violations.sh" ]]; then
        cp "./jamf_ea_admin_violations.sh" "$ea_path"
        chmod +x "$ea_path"
        chown root:wheel "$ea_path"
        print_status "$GREEN" "Extension Attribute script created at $ea_path"
        print_status "$YELLOW" "Remember to create the Extension Attribute in Jamf Pro using this script"
    else
        print_status "$YELLOW" "Extension Attribute script not found. Create manually if needed."
    fi
}

# Verify installation
verify_installation() {
    print_status "$BLUE" "Verifying installation..."
    
    local errors=0
    
    # Check script
    if [[ -x "/usr/local/bin/jamf_connect_monitor.sh" ]]; then
        print_status "$GREEN" "✓ Monitor script installed and executable"
    else
        print_status "$RED" "✗ Monitor script not found or not executable"
        ((errors++))
    fi
    
    # Check LaunchDaemon
    if [[ -f "/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist" ]]; then
        print_status "$GREEN" "✓ LaunchDaemon plist installed"
    else
        print_status "$RED" "✗ LaunchDaemon plist not found"
        ((errors++))
    fi
    
    # Check if daemon is running
    if launchctl list | grep -q "com.macjediwizard.jamfconnectmonitor"; then
        print_status "$GREEN" "✓ Monitoring daemon is running"
    else
        print_status "$RED" "✗ Monitoring daemon is not running"
        ((errors++))
    fi
    
    # Check approved admin list
    if [[ -f "/usr/local/etc/approved_admins.txt" ]]; then
        local admin_count=$(wc -l < /usr/local/etc/approved_admins.txt)
        print_status "$GREEN" "✓ Approved admin list created with $admin_count users"
    else
        print_status "$RED" "✗ Approved admin list not found"
        ((errors++))
    fi
    
    # Check log directory
    if [[ -d "/var/log/jamf_connect_monitor" ]]; then
        print_status "$GREEN" "✓ Log directory created"
    else
        print_status "$RED" "✗ Log directory not found"
        ((errors++))
    fi
    
    return $errors
}

# Display post-installation instructions
show_post_install() {
    print_status "$GREEN" "Installation completed successfully!"
    echo
    print_status "$BLUE" "Post-installation steps:"
    echo "1. Review approved admin list: cat /usr/local/etc/approved_admins.txt"
    echo "2. Add/remove approved admins as needed:"
    echo "   sudo /usr/local/bin/jamf_connect_monitor.sh add-admin username"
    echo "   sudo /usr/local/bin/jamf_connect_monitor.sh remove-admin username"
    echo "3. Monitor logs: tail -f /var/log/jamf_connect_monitor/monitor.log"
    echo "4. Check status: sudo /usr/local/bin/jamf_connect_monitor.sh status"
    echo
    
    if [[ -f "/usr/local/etc/jamf_ea_admin_violations.sh" ]]; then
        print_status "$BLUE" "Jamf Pro Integration:"
        echo "5. Create Extension Attribute in Jamf Pro using: /usr/local/etc/jamf_ea_admin_violations.sh"
        echo "6. Create Smart Group for devices with violations"
        echo "7. Set up policies for automated response if desired"
        echo
    fi
    
    print_status "$BLUE" "Monitoring Configuration:"
    echo "- Monitoring interval: $MONITORING_INTERVAL seconds"
    echo "- Log location: /var/log/jamf_connect_monitor/"
    echo "- Configuration: /usr/local/etc/approved_admins.txt"
    echo
    
    if [[ -n "$WEBHOOK_URL" ]]; then
        print_status "$GREEN" "Webhook notifications configured"
    fi
    
    if [[ -n "$EMAIL_RECIPIENT" ]]; then
        print_status "$GREEN" "Email notifications configured for: $EMAIL_RECIPIENT"
    fi
}

# Main execution
main() {
    print_status "$GREEN" "Starting $SCRIPT_NAME"
    echo "Log file: $LOG_FILE"
    echo
    
    check_root
    check_prerequisites
    create_directories
    deploy_monitor_script
    create_launch_daemon
    initialize_monitoring
    start_daemon
    create_jamf_ea
    
    if verify_installation; then
        show_post_install
    else
        error_exit "Installation verification failed. Check logs for details."
    fi
    
    print_status "$GREEN" "Deployment completed successfully!"
}

# Configuration prompt for interactive installation
interactive_config() {
    echo "=== Jamf Connect Monitor - Interactive Configuration ==="
    echo
    
    read -p "Enter Slack/Teams webhook URL (optional): " webhook_input
    if [[ -n "$webhook_input" ]]; then
        WEBHOOK_URL="$webhook_input"
    fi
    
    read -p "Enter email recipient for notifications (optional): " email_input
    if [[ -n "$email_input" ]]; then
        EMAIL_RECIPIENT="$email_input"
    fi
    
    read -p "Enter monitoring interval in seconds (default 300): " interval_input
    if [[ -n "$interval_input" && "$interval_input" =~ ^[0-9]+$ ]]; then
        MONITORING_INTERVAL="$interval_input"
    fi
    
    echo
}

# Command line options
case "${1:-install}" in
    "install")
        main
        ;;
    "interactive")
        interactive_config
        main
        ;;
    "verify")
        verify_installation
        ;;
    "uninstall")
        print_status "$YELLOW" "Uninstalling Jamf Connect Monitor..."
        launchctl unload /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist 2>/dev/null || true
        rm -f /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
        rm -f /usr/local/bin/jamf_connect_monitor.sh
        rm -rf /var/log/jamf_connect_monitor
        rm -f /usr/local/etc/approved_admins.txt
        rm -f /usr/local/etc/jamf_ea_admin_violations.sh
        print_status "$GREEN" "Uninstallation completed"
        ;;
    "help")
        echo "Usage: $0 [command]"
        echo "Commands:"
        echo "  install       Install with default settings"
        echo "  interactive   Install with interactive configuration"
        echo "  verify        Verify existing installation"
        echo "  uninstall     Remove all components"
        echo "  help          Show this help"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac