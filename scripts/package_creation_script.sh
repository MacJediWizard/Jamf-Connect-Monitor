#!/bin/bash

# Package Creation Script for Jamf Connect Monitor
# This script creates a deployable .pkg file for Jamf Pro with Configuration Profile support

set -e  # Exit on any error

# Configuration
PACKAGE_NAME="JamfConnectMonitor"
PACKAGE_IDENTIFIER="com.macjediwizard.jamfconnectmonitor"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/build"
PAYLOAD_DIR="$BUILD_DIR/payload"
SCRIPTS_BUILD_DIR="$BUILD_DIR/scripts"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Auto-extract version from main script (centralized version management)
if [[ -f "$PROJECT_ROOT/scripts/jamf_connect_monitor.sh" ]]; then
    PACKAGE_VERSION=$(grep "^VERSION=" "$PROJECT_ROOT/scripts/jamf_connect_monitor.sh" | cut -d'"' -f2)
    if [[ -z "$PACKAGE_VERSION" ]]; then
        # Fallback to header comment
        PACKAGE_VERSION=$(head -10 "$PROJECT_ROOT/scripts/jamf_connect_monitor.sh" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    fi
    if [[ -z "$PACKAGE_VERSION" ]]; then
        echo "ERROR: Could not extract version from main script"
        exit 1
    fi
else
    echo "ERROR: Main script not found at $PROJECT_ROOT/scripts/jamf_connect_monitor.sh"
    exit 1
fi

echo "Auto-detected package version: $PACKAGE_VERSION"

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
        "$PROJECT_ROOT/scripts/jamf_connect_monitor.sh"
        "$PROJECT_ROOT/scripts/preinstall_script.sh"
        "$PROJECT_ROOT/scripts/postinstall_script.sh"
        "$PROJECT_ROOT/jamf/extension-attribute.sh"
        "$PROJECT_ROOT/jamf_connect_monitor_schema.json"
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
    mkdir -p "$SCRIPTS_BUILD_DIR"
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
    
    cat > "$PAYLOAD_DIR/usr/local/etc/jamf_connect_monitor.conf" << EOF
# Jamf Connect Monitor Default Configuration
# This file will be customized during installation with Configuration Profile support

[Settings]
MonitoringInterval=300
LogRetentionDays=30
AutoRemediation=true
ViolationReporting=true

[ConfigurationProfile]
Domain=com.macjediwizard.jamfconnectmonitor
Enabled=true
JsonSchemaVersion=$PACKAGE_VERSION

[System]
Version=$PACKAGE_VERSION
InstallDate=
PackageIdentifier=com.macjediwizard.jamfconnectmonitor

[Paths]
ApprovedAdminsList=/usr/local/etc/approved_admins.txt
LogDirectory=/var/log/jamf_connect_monitor
ScriptPath=/usr/local/bin/jamf_connect_monitor.sh
JsonSchema=/usr/local/share/jamf_connect_monitor/schema/jamf_connect_monitor_schema.json
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
# Configuration Profile support enables centralized management
EOF

    print_status "$GREEN" "Admin template created"
}

# Create JSON schema for Configuration Profile
create_json_schema() {
    print_status "$BLUE" "Creating JSON schema for Configuration Profile..."
    
    local schema_dir="$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor/schema"
    mkdir -p "$schema_dir"
    
    if [[ -f "$PROJECT_ROOT/jamf_connect_monitor_schema.json" ]]; then
        cp "$PROJECT_ROOT/jamf_connect_monitor_schema.json" "$schema_dir/"
        print_status "$GREEN" "JSON schema copied from project"
    else
        print_status "$RED" "ERROR: jamf_connect_monitor_schema.json not found in project root"
        print_status "$YELLOW" "Please ensure jamf_connect_monitor_schema.json exists in the project directory"
        exit 1
    fi
    
    # Verify JSON schema is valid
    if command -v python3 &> /dev/null; then
        python3 -m json.tool "$schema_dir/jamf_connect_monitor_schema.json" >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            print_status "$GREEN" "JSON schema validation passed"
        else
            print_status "$YELLOW" "Warning: JSON schema validation failed, but continuing"
        fi
    fi
}

# Create documentation
create_documentation() {
    print_status "$BLUE" "Creating documentation..."
    
    cat > "$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor/README.txt" << EOF
Jamf Connect Monitor - Version $PACKAGE_VERSION

DESCRIPTION:
This package installs an enterprise security monitoring system that tracks Jamf Connect 
privilege elevation events and automatically removes unauthorized admin accounts with 
real-time detection and Configuration Profile management.

VERSION $PACKAGE_VERSION FEATURES:
- Configuration Profile support for centralized webhook/email management
- Real-time monitoring capabilities (immediate violation detection)
- Enhanced notification templates (simple, detailed, security_report)
- JSON Schema for easy Jamf Pro Application & Custom Settings deployment
- Advanced security settings and compliance options
- Auto-detection version management (future-proof for all releases)

COMPONENTS:
- Monitor Script: /usr/local/bin/jamf_connect_monitor.sh
- LaunchDaemon: /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
- Configuration Profile Domain: com.macjediwizard.jamfconnectmonitor
- JSON Schema: /usr/local/share/jamf_connect_monitor/schema/jamf_connect_monitor_schema.json
- Approved Admins: /usr/local/etc/approved_admins.txt
- Logs: /var/log/jamf_connect_monitor/

CONFIGURATION PROFILE DEPLOYMENT:
1. In Jamf Pro: Computer Management > Configuration Profiles > New
2. Add Application & Custom Settings payload
3. Source: Custom Schema
4. Preference Domain: com.macjediwizard.jamfconnectmonitor
5. Upload JSON Schema from: /usr/local/share/jamf_connect_monitor/schema/jamf_connect_monitor_schema.json
6. Configure settings through Jamf Pro interface
7. Scope to target computers

USAGE:
- View status: sudo jamf_connect_monitor.sh status
- Test config: sudo jamf_connect_monitor.sh test-config
- Add admin: sudo jamf_connect_monitor.sh add-admin <username>
- Remove admin: sudo jamf_connect_monitor.sh remove-admin <username>
- Force check: sudo jamf_connect_monitor.sh force-check

LOGS:
- Monitor activity: /var/log/jamf_connect_monitor/monitor.log
- Violations: /var/log/jamf_connect_monitor/admin_violations.log
- Real-time events: /var/log/jamf_connect_monitor/realtime_monitor.log
- Daemon output: /var/log/jamf_connect_monitor/daemon.log

MONITORING MODES:
- Periodic: Traditional 5-minute interval checking
- Real-time: Immediate violation detection
- Hybrid: Both periodic and real-time monitoring

For support, contact your IT administrator or see documentation at:
https://github.com/MacJediWizard/jamf-connect-monitor
EOF

    # Create version file
    cat > "$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor/version.txt" << EOF
Package: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Build Date: $(date)
Identifier: $PACKAGE_IDENTIFIER
Configuration Profile Domain: com.macjediwizard.jamfconnectmonitor
JSON Schema: Available for Jamf Pro Application & Custom Settings
Features: Configuration Profile Support, Real-time Monitoring, Enhanced Notifications, Auto-Detection
EOF

    print_status "$GREEN" "Documentation created"
}

# Copy main files to payload
copy_main_files() {
    print_status "$BLUE" "Copying main files..."
    
    # Copy monitor script
    if [[ -f "$PROJECT_ROOT/scripts/jamf_connect_monitor.sh" ]]; then
        cp "$PROJECT_ROOT/scripts/jamf_connect_monitor.sh" "$PAYLOAD_DIR/usr/local/bin/"
        print_status "$GREEN" "Monitor script copied"
    else
        print_status "$RED" "ERROR: scripts/jamf_connect_monitor.sh not found"
        exit 1
    fi
    
    # Copy uninstall script to share directory
    if [[ -f "$PROJECT_ROOT/scripts/uninstall_script.sh" ]]; then
        cp "$PROJECT_ROOT/scripts/uninstall_script.sh" "$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor/"
        print_status "$GREEN" "Uninstall script included"
    else
        print_status "$YELLOW" "WARNING: scripts/uninstall_script.sh not found"
    fi
    
    # Copy Extension Attribute script - check multiple possible locations
    local ea_script_path=""
    if [[ -f "$PROJECT_ROOT/jamf/extension-attribute.sh" ]]; then
        ea_script_path="$PROJECT_ROOT/jamf/extension-attribute.sh"
    fi
    
    if [[ -n "$ea_script_path" && -f "$ea_script_path" ]]; then
        cp "$ea_script_path" "$PAYLOAD_DIR/usr/local/etc/jamf_ea_admin_violations.sh"
        chmod +x "$PAYLOAD_DIR/usr/local/etc/jamf_ea_admin_violations.sh"
        print_status "$GREEN" "Extension Attribute script included"
    else
        print_status "$RED" "ERROR: Extension Attribute script not found"
        print_status "$YELLOW" "Expected location: jamf/extension-attribute.sh"
        exit 1
    fi
    
    print_status "$GREEN" "Main files copied"
}

# Prepare installation scripts
prepare_scripts() {
    print_status "$BLUE" "Preparing installation scripts..."
    
    # Copy pre-install script
    if [[ -f "$PROJECT_ROOT/scripts/preinstall_script.sh" ]]; then
        cp "$PROJECT_ROOT/scripts/preinstall_script.sh" "$SCRIPTS_BUILD_DIR/preinstall"
        chmod +x "$SCRIPTS_BUILD_DIR/preinstall"
        print_status "$GREEN" "Pre-install script prepared"
    else
        print_status "$RED" "ERROR: scripts/preinstall_script.sh not found"
        exit 1
    fi
    
    # Copy post-install script  
    if [[ -f "$PROJECT_ROOT/scripts/postinstall_script.sh" ]]; then
        cp "$PROJECT_ROOT/scripts/postinstall_script.sh" "$SCRIPTS_BUILD_DIR/postinstall"
        chmod +x "$SCRIPTS_BUILD_DIR/postinstall"
        print_status "$GREEN" "Post-install script prepared"
    else
        print_status "$RED" "ERROR: scripts/postinstall_script.sh not found"
        exit 1
    fi
    
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
    chmod +x "$PAYLOAD_DIR/usr/local/etc/jamf_ea_admin_violations.sh"
    
    # Make uninstall script executable
    if [[ -f "$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor/uninstall_script.sh" ]]; then
      chmod +x "$PAYLOAD_DIR/usr/local/share/jamf_connect_monitor/uninstall_script.sh"
      print_status "$GREEN" "Set execute permissions for uninstall script"
    fi
    
    # Set LaunchDaemon permissions
    chmod 644 "$PAYLOAD_DIR/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
    
    print_status "$GREEN" "Permissions set"
}

# Build the package
build_package() {
    print_status "$BLUE" "Building package..."
    
    local package_path="$OUTPUT_DIR/${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg"
    
    pkgbuild \
        --root "$PAYLOAD_DIR" \
        --scripts "$SCRIPTS_BUILD_DIR" \
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
        
        # Copy JSON schema to output for easy access
        cp "$PROJECT_ROOT/jamf_connect_monitor_schema.json" "$OUTPUT_DIR/"
        print_status "$GREEN" "JSON schema copied to output directory"
        
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
JAMF PRO DEPLOYMENT INSTRUCTIONS - VERSION $PACKAGE_VERSION
Package: ${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg

🚀 VERSION $PACKAGE_VERSION FEATURES:
- Configuration Profile support for centralized webhook/email management
- Real-time monitoring capabilities (immediate violation detection)
- Enhanced notification templates with company branding
- JSON Schema for easy Jamf Pro deployment
- Auto-detection version management (future-proof)

====================================================================
PHASE 1: PACKAGE DEPLOYMENT
====================================================================

1. UPLOAD PACKAGE:
   - Log into Jamf Pro
   - Go to Settings > Computer Management > Packages
   - Click "New" and upload ${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg
   - Set Category: "Security" or "Utilities"
   - Set Priority: 10

2. CREATE DEPLOYMENT POLICY:
   - General:
     * Display Name: "Deploy Jamf Connect Monitor v$PACKAGE_VERSION"
     * Category: "Security"
     * Trigger: "Enrollment Complete", "Recurring Check-in"
     * Execution Frequency: "Once per computer"
   
   - Packages:
     * Add: ${PACKAGE_NAME}-${PACKAGE_VERSION}.pkg
     * Action: "Install"
   
   - Scope:
     * Target: Computers with Jamf Connect installed
     * Exclusions: Create Smart Group "Jamf Connect Monitor - Installed v2.x"

====================================================================
PHASE 2: CONFIGURATION PROFILE DEPLOYMENT
====================================================================

3. CREATE CONFIGURATION PROFILE:
   - Navigate: Computer Management > Configuration Profiles > New
   - General Settings:
     * Display Name: "Jamf Connect Monitor Configuration"
     * Description: "Security monitoring settings with webhook/email configuration"
     * Category: "Security"
     * Level: "Computer Level"
     * Distribution Method: "Install Automatically"

4. ADD APPLICATION & CUSTOM SETTINGS PAYLOAD:
   - Click "Add" > "Application & Custom Settings"
   - Source: "Custom Schema"
   - Preference Domain: "com.macjediwizard.jamfconnectmonitor"
   
   - Upload JSON Schema:
     * Use file: jamf_connect_monitor_schema.json (included in output directory)
     * Or extract from deployed device: /usr/local/share/jamf_connect_monitor/schema/jamf_connect_monitor_schema.json
   
   - Configure Key Settings:
     ┌─ Notification Settings ─────────────────────────────────┐
     │ Webhook URL: https://hooks.slack.com/services/YOUR/URL  │
     │ Email Recipient: security@yourcompany.com               │
     │ Notification Template: detailed                         │
     │ Notification Cooldown: 15 minutes                      │
     └─────────────────────────────────────────────────────────┘
     
     ┌─ Monitoring Behavior ───────────────────────────────────┐
     │ Monitoring Mode: realtime (or periodic)                │
     │ Auto Remediation: true                                  │
     │ Grace Period: 5 minutes                                │
     │ Monitor Jamf Connect Only: true                        │
     └─────────────────────────────────────────────────────────┘
     
     ┌─ Jamf Pro Integration ──────────────────────────────────┐
     │ Company Name: Your Company Name                         │
     │ IT Contact Email: ithelp@yourcompany.com               │
     │ Update Inventory on Violation: true                    │
     └─────────────────────────────────────────────────────────┘

5. SCOPE CONFIGURATION PROFILE:
   - Target: Smart Group "Jamf Connect Monitor - Installed v2.x"
   - This ensures only devices with monitoring get the configuration

====================================================================
PHASE 3: EXTENSION ATTRIBUTE SETUP
====================================================================

6. CREATE/UPDATE EXTENSION ATTRIBUTE:
   - Navigate: Settings > Computer Management > Extension Attributes
   - Create new attribute:
     * Display Name: "[ Jamf Connect ] - Monitor Status v2.x"
     * Description: "Enhanced monitoring status with auto-detection and Configuration Profile support"
     * Data Type: "String"
     * Input Type: "Script"
     * Script: Use the enhanced Extension Attribute script from package

CRITICAL: The Extension Attribute now uses auto-detection and will work with
all future versions (2.0.1, 2.0.2, 2.1.0, 3.0.0, etc.) without updates!

====================================================================
PHASE 4: SMART GROUPS FOR MONITORING (FLEXIBLE v2.x)
====================================================================

7. CREATE FLEXIBLE SMART GROUPS:

   a) Jamf Connect Monitor - Installed v2.x (FLEXIBLE)
      Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Version: 2.*"
      Purpose: Catches 2.0.0, 2.0.1, 2.0.2, 2.1.0, etc. automatically
   
   b) Jamf Connect Monitor - Config Profile Active
      Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Profile: Deployed*"
      Purpose: Verify Configuration Profile deployment success
   
   c) Jamf Connect Monitor - CRITICAL VIOLATIONS
      Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Unauthorized:*"
      AND Extension Attribute does not contain "Unauthorized: 0"
      ** CONFIGURE ALERTS FOR THIS GROUP **
   
   d) Jamf Connect Monitor - Real-time Active
      Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Real-time: Active*"
      Purpose: Track real-time monitoring deployment

====================================================================
VALIDATION & TESTING
====================================================================

8. TEST DEPLOYMENT:
   - Deploy to 5-10 test machines first
   - Verify package installation: sudo jamf_connect_monitor.sh status
   - Test configuration: sudo jamf_connect_monitor.sh test-config
   - Check Extension Attribute population in Jamf Pro
   - Verify Smart Group membership with flexible criteria

====================================================================
VERSION MANAGEMENT BENEFITS
====================================================================

✅ CENTRALIZED VERSION CONTROL:
- Single VERSION variable in main script controls everything
- Package version auto-syncs from main script
- Extension Attribute auto-detects any version
- Future releases work without EA script updates

✅ CONFIGURATION PROFILE BENEFITS:
- Centralized webhook/email management
- No hardcoded credentials in scripts
- Real-time configuration updates
- Department-specific settings per Smart Group
- Enhanced security with encrypted preferences

✅ SMART GROUP FUTURE-PROOFING:
- Flexible criteria catch all v2.x versions automatically
- No Smart Group updates needed for new releases
- Automated workflows continue to work

Package Information:
- Version: $PACKAGE_VERSION (auto-detected from main script)
- Identifier: $PACKAGE_IDENTIFIER
- Configuration Domain: com.macjediwizard.jamfconnectmonitor
- JSON Schema: Included for Jamf Pro deployment

Created with ❤️ by MacJediWizard
EOF

    print_status "$GREEN" "Enhanced Jamf Pro instructions created"
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
    echo "  Version: $PACKAGE_VERSION (auto-detected from main script)"
    echo
    print_status "$BLUE" "Files Created:"
    echo "  📦 $package_path"
    echo "  🔐 $package_path.sha256"
    echo "  📋 $OUTPUT_DIR/Jamf_Pro_Deployment_Instructions.txt"
    echo "  📄 $OUTPUT_DIR/jamf_connect_monitor_schema.json"
    echo
    print_status "$BLUE" "Configuration Profile Features:"
    echo "  ✅ JSON Schema for Jamf Pro Application & Custom Settings"
    echo "  ✅ Centralized webhook/email management"
    echo "  ✅ Real-time monitoring configuration"
    echo "  ✅ Enhanced notification templates"
    echo "  ✅ Enterprise security settings"
    echo
    print_status "$BLUE" "Version Management (FUTURE-PROOF):"
    echo "  ✅ Auto-synced from main script VERSION variable"
    echo "  ✅ Single source of truth for all version references"
    echo "  ✅ Extension Attribute auto-detects version"
    echo "  ✅ Future versions (2.0.2, 2.1.0, 3.0.0) work automatically"
    echo "  ✅ Smart Groups use flexible criteria for all v2.x+"
    echo "  ✅ Zero maintenance version detection system"
    echo
    print_status "$BLUE" "Next Steps:"
    echo "  1. Upload package to Jamf Pro"
    echo "  2. Create Configuration Profile using JSON Schema"
    echo "  3. Configure webhook/email settings via Jamf Pro interface"
    echo "  4. Update Extension Attribute with auto-detection script"
    echo "  5. Create flexible Smart Groups for automated monitoring"
    echo "  6. Test on pilot machines before fleet deployment"
    echo
    print_status "$GREEN" "Ready for enterprise deployment with future-proof centralized version management!"
}

# Main execution
main() {
    print_status "$GREEN" "Starting Jamf Connect Monitor v$PACKAGE_VERSION package creation"
    
    check_prerequisites
    setup_build_environment
    create_launch_daemon
    create_default_config
    create_admin_template
    create_json_schema
    create_documentation
    copy_main_files
    prepare_scripts
    set_payload_permissions
    
    if build_package; then
        create_jamf_instructions
        create_deployment_summary
        print_status "$GREEN" "Package creation completed successfully!"
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
        rm -rf "$SCRIPT_DIR/build" "$SCRIPT_DIR/output"
        print_status "$GREEN" "Clean completed"
        ;;
    "help")
        echo "Usage: $0 [command]"
        echo "Commands:"
        echo "  build   Create deployment package (default)"
        echo "  clean   Remove build directories"
        echo "  help    Show this help"
        echo
        echo "Centralized Version Management:"
        echo "  • Version auto-extracted from main script VERSION variable"
        echo "  • Single VERSION variable controls all references"
        echo "  • Extension Attribute auto-detects any version"
        echo "  • Future-proof for all v2.x and v3.x releases"
        echo "  • Package version always matches script version"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac