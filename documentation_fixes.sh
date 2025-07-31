#!/bin/bash

# Quick Documentation Fixes for v2.0.0
# Fixes common inconsistencies found in documentation review

echo "🔧 APPLYING DOCUMENTATION FIXES FOR v2.0.0"
echo "============================================"

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

# 1. Fix Package Identifier in deployment_script.sh
echo
print_status "$BLUE" "1. 🔧 Fixing package identifier in deployment_script.sh..."

if [[ -f "scripts/deployment_script.sh" ]]; then
    # Replace old package identifier with correct one
    sed -i.backup 's/com\.company\.jamfconnectmonitor/com.macjediwizard.jamfconnectmonitor/g' scripts/deployment_script.sh
    
    # Check if changes were made
    if diff scripts/deployment_script.sh scripts/deployment_script.sh.backup >/dev/null 2>&1; then
        print_status "$YELLOW" "   ⚠️  No changes needed in deployment_script.sh"
        rm scripts/deployment_script.sh.backup
    else
        changes=$(diff scripts/deployment_script.sh scripts/deployment_script.sh.backup | wc -l)
        print_status "$GREEN" "   ✅ Fixed $changes lines in deployment_script.sh"
        print_status "$BLUE" "   📁 Backup saved as: scripts/deployment_script.sh.backup"
    fi
else
    print_status "$YELLOW" "   ⚠️  deployment_script.sh not found (may not exist in this version)"
fi

# 2. Fix Package Identifier in preinstall_script.sh
echo
print_status "$BLUE" "2. 🔧 Fixing package identifier in preinstall_script.sh..."

if [[ -f "scripts/preinstall_script.sh" ]]; then
    # Replace old package identifier with correct one
    sed -i.backup 's/com\.company\.jamfconnectmonitor/com.macjediwizard.jamfconnectmonitor/g' scripts/preinstall_script.sh
    
    # Check if changes were made
    if diff scripts/preinstall_script.sh scripts/preinstall_script.sh.backup >/dev/null 2>&1; then
        print_status "$YELLOW" "   ⚠️  No changes needed in preinstall_script.sh"
        rm scripts/preinstall_script.sh.backup
    else
        changes=$(diff scripts/preinstall_script.sh scripts/preinstall_script.sh.backup | wc -l)
        print_status "$GREEN" "   ✅ Fixed $changes lines in preinstall_script.sh"
        print_status "$BLUE" "   📁 Backup saved as: scripts/preinstall_script.sh.backup"
    fi
else
    print_status "$RED" "   ❌ preinstall_script.sh not found"
fi

# 3. Fix Package Identifier in postinstall_script.sh
echo
print_status "$BLUE" "3. 🔧 Fixing package identifier in postinstall_script.sh..."

if [[ -f "scripts/postinstall_script.sh" ]]; then
    # Replace old package identifier with correct one
    sed -i.backup 's/com\.company\.jamfconnectmonitor/com.macjediwizard.jamfconnectmonitor/g' scripts/postinstall_script.sh
    
    # Check if changes were made
    if diff scripts/postinstall_script.sh scripts/postinstall_script.sh.backup >/dev/null 2>&1; then
        print_status "$YELLOW" "   ⚠️  No changes needed in postinstall_script.sh"
        rm scripts/postinstall_script.sh.backup
    else
        changes=$(diff scripts/postinstall_script.sh scripts/postinstall_script.sh.backup | wc -l)
        print_status "$GREEN" "   ✅ Fixed $changes lines in postinstall_script.sh"
        print_status "$BLUE" "   📁 Backup saved as: scripts/postinstall_script.sh.backup"
    fi
else
    print_status "$RED" "   ❌ postinstall_script.sh not found"
fi

# 4. Check and fix any other files with old identifiers
echo
print_status "$BLUE" "4. 🔧 Checking for other files with old package identifiers..."

# Find files with old identifiers (excluding backups and git)
old_id_files=$(grep -r "com\.company\.jamfconnectmonitor" . --exclude="*.backup" --exclude-dir=.git --exclude-dir=scripts/build --exclude-dir=scripts/output 2>/dev/null | cut -d: -f1 | sort | uniq)

if [[ -n "$old_id_files" ]]; then
    print_status "$YELLOW" "   ⚠️  Found files with old identifiers:"
    echo "$old_id_files" | while read -r file; do
        if [[ -f "$file" ]]; then
            print_status "$YELLOW" "      📄 $file"
            # Fix the file
            sed -i.backup 's/com\.company\.jamfconnectmonitor/com.macjediwizard.jamfconnectmonitor/g' "$file"
            print_status "$GREEN" "         ✅ Fixed package identifier in $file"
        fi
    done
else
    print_status "$GREEN" "   ✅ No other files found with old package identifiers"
fi

# 5. Verify LaunchDaemon label consistency
echo
print_status "$BLUE" "5. 🔧 Verifying LaunchDaemon label consistency..."

expected_label="com.macjediwizard.jamfconnectmonitor"

# Check jamf/launchdaemon.plist if it exists
if [[ -f "jamf/launchdaemon.plist" ]]; then
    if grep -q "$expected_label" "jamf/launchdaemon.plist"; then
        print_status "$GREEN" "   ✅ jamf/launchdaemon.plist has correct label"
    else
        print_status "$RED" "   ❌ jamf/launchdaemon.plist has incorrect label"
        # Fix it
        sed -i.backup "s/com\.company\.jamfconnectmonitor/$expected_label/g" "jamf/launchdaemon.plist"
        print_status "$GREEN" "   ✅ Fixed LaunchDaemon label in jamf/launchdaemon.plist"
    fi
else
    print_status "$YELLOW" "   ⚠️  jamf/launchdaemon.plist not found (may be generated during package creation)"
fi

# 6. Check main monitor script configuration domain
echo
print_status "$BLUE" "6. 🔧 Verifying configuration domain in main script..."

if [[ -f "scripts/jamf_connect_monitor.sh" ]]; then
    if grep -q 'CONFIG_PROFILE_DOMAIN="com.macjediwizard.jamfconnectmonitor"' "scripts/jamf_connect_monitor.sh"; then
        print_status "$GREEN" "   ✅ Main script has correct configuration domain"
    else
        print_status "$RED" "   ❌ Main script configuration domain needs checking"
        grep -n "CONFIG_PROFILE_DOMAIN" "scripts/jamf_connect_monitor.sh"
    fi
else
    print_status "$RED" "   ❌ Main monitor script not found"
fi

# 7. Check JSON schema file exists and is valid
echo
print_status "$BLUE" "7. 🔧 Verifying JSON schema..."

if [[ -f "jamf_connect_monitor_schema.json" ]]; then
    if python3 -m json.tool jamf_connect_monitor_schema.json >/dev/null 2>&1; then
        print_status "$GREEN" "   ✅ JSON schema is valid"
    else
        print_status "$RED" "   ❌ JSON schema has syntax errors"
        python3 -m json.tool jamf_connect_monitor_schema.json
    fi
else
    print_status "$RED" "   ❌ JSON schema file not found: jamf_connect_monitor_schema.json"
fi

# 8. Verify critical CLI commands exist in main script
echo
print_status "$BLUE" "8. 🔧 Verifying CLI commands in main script..."

if [[ -f "scripts/jamf_connect_monitor.sh" ]]; then
    cli_commands=("status" "test-config" "add-admin" "remove-admin" "force-check" "help")
    
    for cmd in "${cli_commands[@]}"; do
        if grep -q "\"$cmd\")" "scripts/jamf_connect_monitor.sh"; then
            print_status "$GREEN" "   ✅ CLI command '$cmd' found in script"
        else
            print_status "$RED" "   ❌ CLI command '$cmd' missing from script"
        fi
    done
else
    print_status "$RED" "   ❌ Main monitor script not found"
fi

# Final Summary
echo
print_status "$BLUE" "============================================"
print_status "$BLUE" "📊 DOCUMENTATION FIXES SUMMARY"
print_status "$BLUE" "============================================"

# Count backup files created (indicates fixes applied)
backup_count=$(find . -name "*.backup" -type f 2>/dev/null | wc -l)

if [[ $backup_count -gt 0 ]]; then
    print_status "$GREEN" "✅ Applied fixes to $backup_count files"
    print_status "$BLUE" "📁 Backup files created (can be removed after verification):"
    find . -name "*.backup" -type f 2>/dev/null | sed 's/^/   /'
    echo
    print_status "$YELLOW" "🔧 To remove backup files after verification:"
    print_status "$YELLOW" "   find . -name '*.backup' -type f -delete"
else
    print_status "$GREEN" "✅ No fixes needed - all files already consistent"
fi

echo
print_status "$GREEN" "🎉 DOCUMENTATION FIXES COMPLETED!"
print_status "$BLUE" "📋 Next step: Run documentation verification to confirm all issues resolved"
