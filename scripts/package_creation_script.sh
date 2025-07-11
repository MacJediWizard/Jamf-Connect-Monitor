#!/bin/bash

# Package Creation Script for Jamf Connect Monitor
# This script creates a deployable .pkg file for Jamf Pro

set -e  # Exit on any error

# Configuration
PACKAGE_NAME="JamfConnectMonitor"
PACKAGE_VERSION="1.0.1"
PACKAGE_IDENTIFIER="com.macjediwizard.jamfconnectmonitor"
BUILD_DIR="$(pwd)/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_DIR="$BUILD_DIR/scripts"
OUTPUT_DIR="$(pwd)/output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}$message${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_status "$BLUE" "Checking prerequisites..."
    
    # Check if required files exist
    local required_files=(
        "./jamf_connect_monitor.sh"
        "./preinstall_script.sh"
        "./postinstall_script.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_status "$RED" "ERROR: Required file not found: $file"
            exit 1
        fi
    done
    
    # Check if pkgbuild exists
    if ! command -v pkgbuild &> /dev/null; then
        print_status "$RED" "ERROR: pkgbuild not found. This script must run on macOS."
        exit 1
    fi
    
    print_status "$GREEN" "Prerequisites check passed"
}

# Clean and create build directories
setup_build_environment() {
    print_status "$BLUE" "Setting up build environment..."
    
    # Clean existing build directory
    rm -rf "$BUILD_DIR"
    rm -rf "$OUTPUT_DIR"
    
    # Create directory structure
    mkdir -p "$PAYLOAD_DIR"
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    # Create payload directory structure
    mkdir -p "$PAYLOAD_DIR/usr/local/bin"
    mkdir -p "$PAYLOAD_DIR/usr/local/etc"
    mkdir -p "$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor"
    mkdir -p "$PAYLOAD_DIR/Library/LaunchDaemons"
    mkdir -p "$PAYLOAD_DIR/var/log/jamf_connect_monitor"
    
    print_status "$GREEN" "Build environment created"
}

# Create LaunchDaemon plist
create_launch_daemon() {
    print_status "$BLUE" "Creating LaunchDaemon..."
    
    cat > "$PAYLOAD_DIR/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist" << 'EOF'
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
    <integer>300</integer>
    
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

    print_status "$GREEN" "LaunchDaemon created"
}

# Create default configuration file
create_default_config() {
    print_status "$BLUE" "Creating default configuration..."
    
    cat > "$PAYLOAD_DIR/usr/local/etc/jamf_connect_monitor.conf" << 'EOF'
# Jamf Connect Monitor Default Configuration
# This file will be customized during installation

[Settings]
MonitoringInterval=300
LogRetentionDays=30
AutoRemediation=true
ViolationReporting=true

[Notifications]
WebhookURL=
EmailRecipient=

[System]
CompanyName=YourCompany
InstallDate=
Version=1.0

[Paths]
ApprovedAdminsList=/usr/local/etc/approved_admins.txt
LogDirectory=/var/log/jamf_connect_monitor
ScriptPath=/usr/local/bin/jamf_connect_monitor.sh
EOF

    print_status "$GREEN" "Default configuration created"
}

# Create default approved admins template
create_admin_template() {
    print_status "$BLUE" "Creating admin template..."
    
    cat > "$PAYLOAD_DIR/usr/local/etc/approved_admins_template.txt" << 'EOF'
# Default Approved Administrators
# This file will be populated with current admins during installation
# Add one username per line
EOF

    print_status "$GREEN" "Admin template created"
}

# Create documentation
create_documentation() {
    print_status "$BLUE" "Creating documentation..."
    
    cat > "$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor/README.txt" << 'EOF'
Jamf Connect Monitor - Version 1.0

DESCRIPTION:
This package installs a monitoring system that tracks Jamf Connect privilege 
elevation events and automatically removes unauthorized admin accounts.

COMPONENTS:
- Monitor Script: /usr/local/bin/jamf_connect_monitor.sh
- LaunchDaemon: /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
- Configuration: /usr/local/etc/jamf_connect_monitor.conf
- Approved Admins: /usr/local/etc/approved_admins.txt
- Logs: /var/log/jamf_connect_monitor/

USAGE:
- View status: sudo jamf_connect_monitor.sh status
- Add admin: sudo jamf_connect_monitor.sh add-admin <username>
- Remove admin: sudo jamf_connect_monitor.sh remove-admin <username>

LOGS:
- Monitor activity: /var/log/jamf_connect_monitor/monitor.log
- Violations: /var/log/jamf_connect_monitor/admin_violations.log
- Daemon output: /var/log/jamf_connect_monitor/daemon.log

For support, contact your IT administrator.
EOF

    # Create version file
    cat > "$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor/version.txt" << EOF
Package: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Build Date: $(date)
Identifier: $PACKAGE_IDENTIFIER
EOF

    print_status "$GREEN" "Documentation created"
}

# Copy main files to payload
copy_main_files() {
    print_status "$BLUE" "Copying main files..."
    
    # Copy monitor script
    cp "./jamf_connect_monitor.sh" "$PAYLOAD_DIR/usr/local/bin/"
    
    # Copy uninstall script to share directory
    if [[ -f "./uninstall_script.sh" ]]; then
        cp "./uninstall_script.sh" "$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor/"
        print_status "$GREEN" "Uninstall script included"
    else
        print_status "$YELLOW" "WARNING: uninstall_script.sh not found"
    fi
    
    # Copy Extension Attribute script - fix path reference
    local ea_script_path=""
    if [[ -f "../jamf/extension-attribute.sh" ]]; then
        ea_script_path="../jamf/extension-attribute.sh"
    elif [[ -f "jamf/extension-attribute.sh" ]]; then
        ea_script_path="jamf/extension-attribute.sh"
    elif [[ -f "./jamf/extension-attribute.sh" ]]; then
        ea_script_path="./jamf/extension-attribute.sh"
    fi
    
    if [[ -n "$ea_script_path" && -f "$ea_script_path" ]]; then
        cp "$ea_script_path" "$PAYLOAD_DIR/usr/local/etc/jamf_ea_admin_violations.sh"
        print_status "$GREEN" "Extension Attribute script included"
    else
        print_status "$YELLOW" "WARNING: Extension Attribute script not found"
    fi
    
    print_status "$GREEN" "Main files copied"
}

# Prepare installation scripts
prepare_scripts() {
    print_status "$BLUE" "Preparing installation scripts..."
    
    # Copy pre-install script
    cp "./preinstall_script.sh" "$SCRIPTS_DIR/preinstall"
    chmod +x "$SCRIPTS_DIR/preinstall"
    
    # Copy post-install script  
    cp "./postinstall_script.sh" "$SCRIPTS_DIR/postinstall"
    chmod +x "$SCRIPTS_DIR/postinstall"
    
    print_status "$GREEN" "Installation scripts prepared"
}

# Set proper permissions for payload
set_payload_permissions() {
    print_status "$BLUE" "Setting payload permissions..."
    
    # Set ownership to root:wheel
    chown -R root:wheel "$PAYLOAD_DIR"
    
    # Set directory permissions
    find "$PAYLOAD_DIR" -type d -exec chmod 755 {} \;
    
    # Set file permissions
    find "$PAYLOAD_DIR" -type f -exec chmod 644 {} \;
    
    # Make scripts executable
    chmod +x "$PAYLOAD_DIR/usr/local/bin/jamf_connect_monitor.sh"
    
    print_status "$GREEN" "Permissions set"
}

# Build the package
build_package() {
    print_status "$BLUE" "Building package..."
    
    local package_path="$OUTPUT_DIR/${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg"
    
    pkgbuild \
        --root "$PAYLOAD_DIR" \
        --scripts "$SCRIPTS_DIR" \
        --identifier "$PACKAGE_IDENTIFIER" \
        --version "$PACKAGE_VERSION" \
        --install-location "/" \
        "$package_path"
    
    if [[ -f "$package_path" ]]; then
        local package_size=$(du -h "$package_path" | cut -f1)
        print_status "$GREEN" "Package created successfully: $package_path ($package_size)"
        
        # Create checksum
        shasum -a 256 "$package_path" > "$package_path.sha256"
        print_status "$GREEN" "Checksum created: $package_path.sha256"
        
        return 0
    else
        print_status "$RED" "ERROR: Package creation failed"
        return 1
    fi
}

# Create Jamf Pro upload instructions
create_jamf_instructions() {
    print_status "$BLUE" "Creating Jamf Pro instructions..."
    
    cat > "$OUTPUT_DIR/Jamf_Pro_Deployment_Instructions.txt" << EOF
JAMF PRO DEPLOYMENT INSTRUCTIONS
Package: ${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg

1. UPLOAD PACKAGE:
   - Log into Jamf Pro
   - Go to Settings > Computer Management > Packages
   - Click "New" and upload ${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg
   - Set Category: "Security" or "Utilities"
   - Set Priority: 10

2. CREATE EXTENSION ATTRIBUTE:
   - Go to Settings > Computer Management > Extension Attributes
   - Create new attribute:
     * Display Name: "Admin Account Violations"
     * Description: "Monitors unauthorized admin account violations"
     * Data Type: "String"
     * Input Type: "Script"
     * Script: Use the jamf_ea_admin_violations.sh script content

3. CREATE SMART GROUPS:
   - "Jamf Connect Monitor - Installed"
     * Criteria: "Admin Account Violations" "is not" "Not configured"
   
   - "Jamf Connect Monitor - Violations Detected"  
     * Criteria: "Admin Account Violations" "contains" "Unauthorized Admins:"

4. CREATE POLICY:
   - General:
     * Display Name: "Install Jamf Connect Monitor"
     * Category: "Security"
     * Trigger: "Enrollment Complete", "Recurring Check-in"
     * Execution Frequency: "Once per computer"
   
   - Packages:
     * Add: ${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg
     * Action: "Install"
   
   - Scripts (if using parameters):
     * Parameter 4: Webhook URL (optional)
     * Parameter 5: Email recipient (optional)  
     * Parameter 6: Monitoring interval in seconds (default: 300)
     * Parameter 7: Company name (default: YourCompany)
   
   - Scope:
     * Target: Computers with Jamf Connect installed
     * Exclusions: "Jamf Connect Monitor - Installed" smart group

5. MONITORING:
   - Check "Jamf Connect Monitor - Violations Detected" smart group regularly
   - Review Extension Attribute data for violation reports
   - Monitor log files on individual machines if needed

6. MAINTENANCE:
   - Update approved admin lists as staff changes
   - Review violation reports monthly
   - Update package when new versions are available

PACKAGE PARAMETERS:
- Parameter 4: Slack/Teams Webhook URL
- Parameter 5: Email recipient for notifications
- Parameter 6: Monitoring interval (seconds, default 300)
- Parameter 7: Company name for branding

VERIFICATION:
After deployment, verify installation on a test machine:
sudo /usr/local/bin/jamf_connect_monitor.sh status

LOG LOCATIONS:
- /var/log/jamf_connect_monitor/monitor.log
- /var/log/jamf_connect_monitor/admin_violations.log
- /var/log/jamf_connect_monitor_install.log
EOF

    print_status "$GREEN" "Jamf Pro instructions created"
}

# Create deployment summary
create_deployment_summary() {
    local package_path="$OUTPUT_DIR/${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg"
    local package_size=$(du -h "$package_path" | cut -f1)
    
    print_status "$GREEN" "=== DEPLOYMENT PACKAGE READY ==="
    echo
    print_status "$BLUE" "Package Details:"
    echo "  Name: ${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg"
    echo "  Size: $package_size"
    echo "  Location: $package_path"
    echo "  Identifier: $PACKAGE_IDENTIFIER"
    echo
    print_status "$BLUE" "Files Created:"
    echo "  📦 $package_path"
    echo "  🔐 $package_path.sha256"
    echo "  📋 $OUTPUT_DIR/Jamf_Pro_Deployment_Instructions.txt"
    echo
    print_status "$BLUE" "Next Steps:"
    echo "  1. Upload package to Jamf Pro"
    echo "  2. Create Extension Attribute using provided script"
    echo "  3. Create Smart Groups for monitoring"
    echo "  4. Create deployment policy"
    echo "  5. Test on pilot machines"
    echo
    print_status "$GREEN" "Ready for silent deployment via Jamf Pro!"
}

# Main execution
main() {
    print_status "$GREEN" "Starting Jamf Connect Monitor package creation"
    
    check_prerequisites
    setup_build_environment
    create_launch_daemon
    create_default_config
    create_admin_template
    create_documentation
    copy_main_files
    prepare_scripts
    set_payload_permissions
    
    if build_package; then
        create_jamf_instructions
        create_deployment_summary
    else
        print_status "$RED" "Package creation failed"
        exit 1
    fi
}

# Command line options
case "${1:-build}" in
    "build")
        main
        ;;
    "clean")
        print_status "$YELLOW" "Cleaning build directories..."
        rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
        print_status "$GREEN" "Clean completed"
        ;;
    "help")
        echo "Usage: $0 [command]"
        echo "Commands:"
        echo "  build   Create deployment package (default)"
        echo "  clean   Remove build directories"
        echo "  help    Show this help"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac