#!/bin/bash

# Jamf Connect Monitor - Repository Debug & Fix Script
# Run this in your repository root to identify and fix issues

set -e

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

error_count=0
warning_count=0

# Check repository structure
check_structure() {
    print_status "$BLUE" "=== Checking Repository Structure ==="
    
    local required_dirs=("scripts" "jamf" "docs" "examples")
    local required_files=(
        "README.md"
        "CHANGELOG.md" 
        "CONTRIBUTING.md"
        ".gitignore"
        "scripts/jamf_connect_monitor.sh"
        "scripts/deployment_script.sh"
        "scripts/package_creation_script.sh"
        "scripts/preinstall_script.sh"
        "scripts/postinstall_script.sh"
        "jamf/extension-attribute.sh"
        "jamf/launchdaemon.plist"
    )
    
    # Check directories
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_status "$GREEN" "✅ Directory exists: $dir"
        else
            print_status "$RED" "❌ Missing directory: $dir"
            ((error_count++))
            mkdir -p "$dir"
            print_status "$YELLOW" "📁 Created directory: $dir"
        fi
    done
    
    # Check files
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            print_status "$GREEN" "✅ File exists: $file"
        else
            print_status "$RED" "❌ Missing file: $file"
            ((error_count++))
        fi
    done
}

# Check script syntax
check_syntax() {
    print_status "$BLUE" "=== Checking Script Syntax ==="
    
    local script_files=(
        "scripts/jamf_connect_monitor.sh"
        "scripts/deployment_script.sh"
        "scripts/package_creation_script.sh"
        "scripts/preinstall_script.sh"
        "scripts/postinstall_script.sh"
        "jamf/extension-attribute.sh"
    )
    
    for script in "${script_files[@]}"; do
        if [[ -f "$script" ]]; then
            if bash -n "$script" 2>/dev/null; then
                print_status "$GREEN" "✅ Syntax OK: $script"
            else
                print_status "$RED" "❌ Syntax error in: $script"
                bash -n "$script"
                ((error_count++))
            fi
        fi
    done
}

# Check file permissions
check_permissions() {
    print_status "$BLUE" "=== Checking File Permissions ==="
    
    local script_files=(
        "scripts/jamf_connect_monitor.sh"
        "scripts/deployment_script.sh"
        "scripts/package_creation_script.sh"
        "scripts/preinstall_script.sh"
        "scripts/postinstall_script.sh"
        "jamf/extension-attribute.sh"
    )
    
    for script in "${script_files[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                print_status "$GREEN" "✅ Executable: $script"
            else
                print_status "$YELLOW" "⚠️  Not executable: $script"
                chmod +x "$script"
                print_status "$GREEN" "🔧 Fixed permissions: $script"
                ((warning_count++))
            fi
        fi
    done
}

# Check path consistency
check_paths() {
    print_status "$BLUE" "=== Checking Path Consistency ==="
    
    local expected_paths=(
        "/usr/local/bin/jamf_connect_monitor.sh"
        "/var/log/jamf_connect_monitor"
        "/usr/local/etc/approved_admins.txt"
        "/Library/LaunchDaemons/com.company.jamfconnectmonitor.plist"
    )
    
    print_status "$BLUE" "Checking for consistent path usage across files..."
    
    # Check main monitor script paths
    if [[ -f "scripts/jamf_connect_monitor.sh" ]]; then
        local script_paths=(
            "LOG_DIR=\"/var/log/jamf_connect_monitor\""
            "ADMIN_WHITELIST=\"/usr/local/etc/approved_admins.txt\""
            "REPORT_LOG=\"\$LOG_DIR/admin_violations.log\""
        )
        
        for path_pattern in "${script_paths[@]}"; do
            if grep -q "$path_pattern" "scripts/jamf_connect_monitor.sh"; then
                print_status "$GREEN" "✅ Found: $path_pattern"
            else
                print_status "$RED" "❌ Missing or incorrect: $path_pattern"
                ((error_count++))
            fi
        done
    fi
}

# Check plist syntax
check_plist() {
    print_status "$BLUE" "=== Checking LaunchDaemon Plist ==="
    
    if [[ -f "jamf/launchdaemon.plist" ]]; then
        if plutil -lint "jamf/launchdaemon.plist" >/dev/null 2>&1; then
            print_status "$GREEN" "✅ Plist syntax valid"
        else
            print_status "$RED" "❌ Plist syntax error"
            plutil -lint "jamf/launchdaemon.plist"
            ((error_count++))
        fi
    fi
}

# Test package creation
test_package_creation() {
    print_status "$BLUE" "=== Testing Package Creation ==="
    
    if [[ -f "scripts/package_creation_script.sh" ]]; then
        # Check if script references correct file paths
        local current_dir=$(pwd)
        cd scripts/
        
        # Test for required source files
        local source_files=(
            "jamf_connect_monitor.sh"
            "preinstall_script.sh" 
            "postinstall_script.sh"
        )
        
        for file in "${source_files[@]}"; do
            if [[ -f "$file" ]]; then
                print_status "$GREEN" "✅ Source file found: $file"
            else
                print_status "$RED" "❌ Source file missing: $file"
                ((error_count++))
            fi
        done
        
        # Test package creation (dry run)
        if [[ $error_count -eq 0 ]]; then
            print_status "$BLUE" "🧪 Testing package creation..."
            if sudo ./package_creation_script.sh build >/dev/null 2>&1; then
                print_status "$GREEN" "✅ Package creation successful"
                if [[ -f "output/JamfConnectMonitor-1.0.pkg" ]]; then
                    local pkg_size=$(du -h "output/JamfConnectMonitor-1.0.pkg" | cut -f1)
                    print_status "$GREEN" "📦 Package created: $pkg_size"
                fi
            else
                print_status "$RED" "❌ Package creation failed"
                ((error_count++))
            fi
        fi
        
        cd "$current_dir"
    fi
}

# Create missing files
create_missing_files() {
    print_status "$BLUE" "=== Creating Missing Files ==="
    
    # Create docs/configuration.md
    if [[ ! -f "docs/configuration.md" ]]; then
        cat > "docs/configuration.md" << 'EOF'
# Configuration Guide

## Monitoring Settings

### Monitoring Interval
Default: 300 seconds (5 minutes)
Configure via Jamf Pro policy parameter 6 or LaunchDaemon StartInterval

### Approved Administrators
File: `/usr/local/etc/approved_admins.txt`
- One username per line
- Automatically populated with current admins during installation
- Manage via command line or manual editing

## Notification Configuration

### Slack/Teams Webhooks
Configure via Jamf Pro policy parameter 4 or script variable:
```bash
WEBHOOK_URL="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXX"
```

### Email Notifications  
Configure via Jamf Pro policy parameter 5 or script variable:
```bash
EMAIL_RECIPIENT="security@yourcompany.com"
```

## Company Customization

### Branding
Configure via Jamf Pro policy parameter 7:
```bash
COMPANY_NAME="YourCompany"
```

### Package Identifier
Update in package_creation_script.sh:
```bash
PACKAGE_IDENTIFIER="com.yourcompany.jamfconnectmonitor"
```
EOF
        print_status "$GREEN" "📄 Created: docs/configuration.md"
    fi
    
    # Create docs/troubleshooting.md
    if [[ ! -f "docs/troubleshooting.md" ]]; then
        cat > "docs/troubleshooting.md" << 'EOF'
# Troubleshooting Guide

## Common Issues

### Extension Attribute Not Populating
**Symptoms**: Empty or "Not configured" in Jamf Pro
**Solutions**:
1. Check script permissions: `ls -la /usr/local/etc/jamf_ea_admin_violations.sh`
2. Test manually: `sudo /usr/local/etc/jamf_ea_admin_violations.sh`
3. Force inventory update: `sudo jamf recon`

### Monitoring Not Running
**Symptoms**: No log entries, violations not detected
**Solutions**:
1. Check daemon status: `sudo launchctl list | grep jamfconnectmonitor`
2. Load daemon: `sudo launchctl load /Library/LaunchDaemons/com.company.jamfconnectmonitor.plist`
3. Check logs: `tail -f /var/log/jamf_connect_monitor/monitor.log`

### False Violation Alerts
**Symptoms**: Approved admins being flagged
**Solutions**:
1. Check approved list: `cat /usr/local/etc/approved_admins.txt`
2. Add user: `sudo /usr/local/bin/jamf_connect_monitor.sh add-admin username`
3. Verify admin group: `dscl . -read /Groups/admin GroupMembership`

## Log Analysis

### Key Log Locations
- Installation: `/var/log/jamf_connect_monitor_install.log`
- Activity: `/var/log/jamf_connect_monitor/monitor.log`
- Violations: `/var/log/jamf_connect_monitor/admin_violations.log`
- Daemon: `/var/log/jamf_connect_monitor/daemon.log`

### Performance Tuning
- Increase monitoring interval for large environments
- Implement log rotation for disk space management
- Consider network bandwidth for notifications
EOF
        print_status "$GREEN" "📄 Created: docs/troubleshooting.md"
    fi
    
    # Create examples/approved_admins.txt.example
    if [[ ! -f "examples/approved_admins.txt.example" ]]; then
        cat > "examples/approved_admins.txt.example" << 'EOF'
# Example Approved Administrators
# Add one username per line
# This file is automatically populated during installation

admin
it_support
helpdesk_admin
system_administrator
EOF
        print_status "$GREEN" "📄 Created: examples/approved_admins.txt.example"
    fi
    
    # Create examples/webhook_config.example
    if [[ ! -f "examples/webhook_config.example" ]]; then
        cat > "examples/webhook_config.example" << 'EOF'
# Webhook Configuration Examples

## Slack Webhook
WEBHOOK_URL="https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"

## Microsoft Teams Webhook  
WEBHOOK_URL="https://your-tenant.webhook.office.com/webhookb2/..."

## Discord Webhook
WEBHOOK_URL="https://discord.com/api/webhooks/000000000000000000/XXXXXXXXXXXXXXXXXXXXXXXX"

## Custom Webhook Payload Example
{
  "text": "🚨 Admin Privilege Violation Detected",
  "attachments": [{
    "color": "danger",
    "fields": [
      {"title": "Hostname", "value": "MacBook-Pro", "short": true},
      {"title": "Unauthorized User", "value": "john.doe", "short": true},
      {"title": "Action Taken", "value": "Admin privileges removed", "short": false}
    ]
  }]
}
EOF
        print_status "$GREEN" "📄 Created: examples/webhook_config.example"
    fi
}

# Fix common issues
fix_issues() {
    print_status "$BLUE" "=== Applying Common Fixes ==="
    
    # Fix shebang lines
    local script_files=(
        "scripts/jamf_connect_monitor.sh"
        "scripts/deployment_script.sh"
        "scripts/package_creation_script.sh"
        "scripts/preinstall_script.sh"
        "scripts/postinstall_script.sh"
        "jamf/extension-attribute.sh"
    )
    
    for script in "${script_files[@]}"; do
        if [[ -f "$script" ]]; then
            if ! head -1 "$script" | grep -q "#!/bin/bash"; then
                print_status "$YELLOW" "🔧 Fixing shebang in: $script"
                sed -i '1i#!/bin/bash' "$script"
            fi
        fi
    done
    
    # Fix package creation script paths if needed
    if [[ -f "scripts/package_creation_script.sh" ]]; then
        # Update relative paths to work from scripts directory
        sed -i '' 's|"jamf_connect_monitor.sh"|"./jamf_connect_monitor.sh"|g' scripts/package_creation_script.sh
        sed -i '' 's|"preinstall_script.sh"|"./preinstall_script.sh"|g' scripts/package_creation_script.sh
        sed -i '' 's|"postinstall_script.sh"|"./postinstall_script.sh"|g' scripts/package_creation_script.sh
        print_status "$GREEN" "🔧 Fixed package creation script paths"
    fi
}

# Generate summary report
generate_summary() {
    print_status "$BLUE" "=== Summary Report ==="
    
    if [[ $error_count -eq 0 ]]; then
        print_status "$GREEN" "✅ All critical checks passed!"
    else
        print_status "$RED" "❌ Found $error_count critical issues"
    fi
    
    if [[ $warning_count -gt 0 ]]; then
        print_status "$YELLOW" "⚠️  Fixed $warning_count warnings"
    fi
    
    echo
    print_status "$BLUE" "Next Steps:"
    echo "1. Review any remaining errors above"
    echo "2. Test package creation: cd scripts && sudo ./package_creation_script.sh build"
    echo "3. Commit changes: git add . && git commit -m 'Fix repository issues'"
    echo "4. Create GitHub release with generated package"
    echo
    
    if [[ $error_count -eq 0 ]]; then
        print_status "$GREEN" "Repository is ready for deployment! 🚀"
    else
        print_status "$RED" "Please fix the errors above before proceeding."
    fi
}

# Main execution
main() {
    print_status "$GREEN" "Starting Jamf Connect Monitor Repository Debug..."
    echo
    
    check_structure
    check_syntax
    check_permissions
    check_paths
    check_plist
    create_missing_files
    fix_issues
    test_package_creation
    generate_summary
}

# Check if running from repository root
if [[ ! -f "README.md" ]] && [[ ! -f ".gitignore" ]]; then
    print_status "$RED" "Error: Please run this script from your repository root directory"
    exit 1
fi

main