#!/bin/bash

# Jamf Connect Monitor - Verification Script v2.4.0
# Use this script to verify monitoring is working properly

echo "🔍 JAMF CONNECT MONITOR VERIFICATION v2.4.0"
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

# 1. Check Installation Status
echo
print_status "$BLUE" "1. 🔧 Installation Status"
echo "----------------------------------------"

if [[ -f "/usr/local/bin/jamf_connect_monitor.sh" ]]; then
    # Auto-extract version from VERSION= variable
    version=$(grep "^VERSION=" /usr/local/bin/jamf_connect_monitor.sh 2>/dev/null | cut -d'"' -f2)
    [[ -z "$version" ]] && version="Unknown"
    print_status "$GREEN" "✅ Main script installed: Version $version"
    
    # Check permissions
    perms=$(ls -la /usr/local/bin/jamf_connect_monitor.sh | awk '{print $1}')
    if [[ "$perms" == "-rwxr-xr-x" ]]; then
        print_status "$GREEN" "✅ Permissions correct: $perms"
    else
        print_status "$RED" "❌ Permissions incorrect: $perms (should be -rwxr-xr-x)"
    fi
else
    print_status "$RED" "❌ Main script NOT found at /usr/local/bin/jamf_connect_monitor.sh"
fi

if [[ -f "/usr/local/etc/jamf_ea_admin_violations.sh" ]]; then
    # Auto-extract EA version from header
    ea_version=$(head -10 /usr/local/etc/jamf_ea_admin_violations.sh 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    [[ -z "$ea_version" ]] && ea_version="Unknown"
    print_status "$GREEN" "✅ Extension Attribute script installed: Version $ea_version"
    
    # Check EA permissions
    ea_perms=$(ls -la /usr/local/etc/jamf_ea_admin_violations.sh | awk '{print $1}')
    if [[ "$ea_perms" == "-rwxr-xr-x" ]]; then
        print_status "$GREEN" "✅ EA permissions correct: $ea_perms"
    else
        print_status "$RED" "❌ EA permissions incorrect: $ea_perms (should be -rwxr-xr-x)"
    fi
else
    print_status "$RED" "❌ Extension Attribute script NOT found"
fi

# 2. Check LaunchDaemon Status
echo
print_status "$BLUE" "2. 🔄 LaunchDaemon Status"
echo "----------------------------------------"

if [[ -f "/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist" ]]; then
    print_status "$GREEN" "✅ LaunchDaemon plist exists"
    
    # Check if loaded
    if launchctl list | grep -q "com.macjediwizard.jamfconnectmonitor"; then
        pid=$(launchctl list | grep "com.macjediwizard.jamfconnectmonitor" | awk '{print $1}')
        if [[ "$pid" != "-" ]]; then
            print_status "$GREEN" "✅ LaunchDaemon running (PID: $pid)"
        else
            print_status "$YELLOW" "⚠️  LaunchDaemon loaded but not running"
        fi
    else
        print_status "$RED" "❌ LaunchDaemon NOT loaded"
        echo "   Try: sudo launchctl load /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
    fi
else
    print_status "$RED" "❌ LaunchDaemon plist NOT found"
fi

# 3. Check Configuration Profile Status
echo
print_status "$BLUE" "3. ⚙️  Configuration Profile Status"
echo "----------------------------------------"

if sudo profiles list | grep -q "jamfconnectmonitor"; then
    print_status "$GREEN" "✅ Configuration Profile installed"
    
    # Test configuration reading
    if sudo defaults read com.macjediwizard.jamfconnectmonitor >/dev/null 2>&1; then
        print_status "$GREEN" "✅ Configuration Profile readable"
        
        # Show webhook status
        webhook=$(sudo defaults read com.macjediwizard.jamfconnectmonitor NotificationSettings.WebhookURL 2>/dev/null || echo "")
        if [[ -n "$webhook" ]]; then
            print_status "$GREEN" "✅ Webhook configured"
        else
            print_status "$YELLOW" "⚠️  No webhook configured"
        fi
        
        # Show email status
        email=$(sudo defaults read com.macjediwizard.jamfconnectmonitor NotificationSettings.EmailRecipient 2>/dev/null || echo "")
        if [[ -n "$email" ]]; then
            print_status "$GREEN" "✅ Email configured: $email"
        else
            print_status "$YELLOW" "⚠️  No email configured"
        fi
    else
        print_status "$RED" "❌ Configuration Profile NOT readable"
    fi
else
    print_status "$YELLOW" "⚠️  Configuration Profile NOT installed (optional but recommended)"
fi

# 4. Test Extension Attribute
echo
print_status "$BLUE" "4. 📊 Extension Attribute Test"
echo "----------------------------------------"

if [[ -f "/usr/local/etc/jamf_ea_admin_violations.sh" ]]; then
    print_status "$BLUE" "Running Extension Attribute test..."
    ea_output=$(sudo /usr/local/etc/jamf_ea_admin_violations.sh 2>&1)
    
    if echo "$ea_output" | grep -q "<result>"; then
        print_status "$GREEN" "✅ Extension Attribute runs successfully"
        
        # Check for version info
        if echo "$ea_output" | grep -q "Version: 2."; then
            version_info=$(echo "$ea_output" | grep "Version:" | head -1)
            print_status "$GREEN" "✅ Version detected: $version_info"
        else
            print_status "$YELLOW" "⚠️  Version info not found in output"
        fi
        
        # Check for monitoring mode info (v2.4.0 enhanced)
        if echo "$ea_output" | grep -q "Mode: "; then
            mode_info=$(echo "$ea_output" | grep -o "Mode: [^,]*" | head -1)
            if [[ "$mode_info" != "Mode: " ]]; then
                print_status "$GREEN" "✅ Monitoring mode detected: $mode_info"
            else
                print_status "$RED" "❌ Monitoring mode EMPTY (check v2.4.0 installation)"
            fi
        else
            print_status "$YELLOW" "⚠️  Monitoring mode info not found"
        fi
        
        # Show sample output
        echo
        print_status "$BLUE" "Extension Attribute Sample Output:"
        echo "$ea_output" | head -10
        
    else
        print_status "$RED" "❌ Extension Attribute failed to run"
        echo "Error output:"
        echo "$ea_output"
    fi
else
    print_status "$RED" "❌ Extension Attribute script not found"
fi

# 5. Check Main Script Functions
echo
print_status "$BLUE" "5. 🛠️ Main Script Function Test"
echo "----------------------------------------"

if [[ -f "/usr/local/bin/jamf_connect_monitor.sh" ]]; then
    
    # Test status command
    print_status "$BLUE" "Testing status command..."
    status_output=$(sudo /usr/local/bin/jamf_connect_monitor.sh status 2>&1)
    if echo "$status_output" | grep -q "Monitor Status"; then
        print_status "$GREEN" "✅ Status command works"
        
        # Check for v2.x indicators
        if echo "$status_output" | grep -q "v2.0"; then
            print_status "$GREEN" "✅ v2.x features detected"
        fi
    else
        print_status "$RED" "❌ Status command failed"
        echo "Output: $status_output"
    fi
    
    # Test config command (v2.x feature)
    print_status "$BLUE" "Testing config test command..."
    config_output=$(sudo /usr/local/bin/jamf_connect_monitor.sh test-config 2>&1)
    if echo "$config_output" | grep -q "Configuration Profile Test"; then
        print_status "$GREEN" "✅ Config test command works (v2.x feature)"
    else
        print_status "$YELLOW" "⚠️  Config test command not working (check Configuration Profile)"
    fi
    
else
    print_status "$RED" "❌ Main script not found"
fi

# 6. Check Log Files
echo
print_status "$BLUE" "6. 📝 Log File Status"
echo "----------------------------------------"

log_dir="/var/log/jamf_connect_monitor"
if [[ -d "$log_dir" ]]; then
    print_status "$GREEN" "✅ Log directory exists: $log_dir"
    
    # Check individual log files
    log_files=("monitor.log" "admin_violations.log" "jamf_connect_events.log" "daemon.log")
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_dir/$log_file" ]]; then
            size=$(ls -lh "$log_dir/$log_file" | awk '{print $5}')
            last_modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$log_dir/$log_file" 2>/dev/null || echo "Unknown")
            print_status "$GREEN" "✅ $log_file exists ($size, modified: $last_modified)"
            
            # Show recent activity
            if [[ "$log_file" == "monitor.log" ]]; then
                recent_entries=$(tail -1 "$log_dir/$log_file" 2>/dev/null)
                if [[ -n "$recent_entries" ]]; then
                    print_status "$BLUE" "   Recent activity: $recent_entries"
                fi
            fi
        else
            print_status "$YELLOW" "⚠️  $log_file not found"
        fi
    done
else
    print_status "$RED" "❌ Log directory not found: $log_dir"
fi

# 7. Check Approved Admin List
echo
print_status "$BLUE" "7. 👥 Approved Admin List"
echo "----------------------------------------"

if [[ -f "/usr/local/etc/approved_admins.txt" ]]; then
    admin_count=$(wc -l < /usr/local/etc/approved_admins.txt | tr -d ' ')
    print_status "$GREEN" "✅ Approved admin list exists ($admin_count users)"
    
    # Show current admins
    print_status "$BLUE" "   Current approved admins:"
    cat /usr/local/etc/approved_admins.txt | sed 's/^/     /'
    
    # Compare with actual admin group
    current_admins=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | sed 's/GroupMembership: //' | tr ' ' '\n' | grep -v '^_' | grep -v '^root$' | grep -v '^daemon$' | sort)
    print_status "$BLUE" "   Current system admins:"
    echo "$current_admins" | sed 's/^/     /'
    
else
    print_status "$RED" "❌ Approved admin list not found"
fi

# 8. Summary and Recommendations
echo
print_status "$BLUE" "8. 📋 Summary and Recommendations"
echo "============================================"

# Count issues
issues=0

# Critical checks
if [[ ! -f "/usr/local/bin/jamf_connect_monitor.sh" ]]; then ((issues++)); fi
if ! launchctl list | grep -q "com.macjediwizard.jamfconnectmonitor"; then ((issues++)); fi
if [[ ! -f "/usr/local/etc/jamf_ea_admin_violations.sh" ]]; then ((issues++)); fi

if [[ $issues -eq 0 ]]; then
    print_status "$GREEN" "🎉 MONITORING APPEARS TO BE WORKING CORRECTLY"
    echo
    print_status "$BLUE" "Next Steps:"
    echo "  1. Check Jamf Pro computer record for Extension Attribute data"
    echo "  2. Verify Smart Groups are populating"
    echo "  3. Test notification delivery (if configured)"
    echo "  4. Monitor logs for ongoing activity"
else
    print_status "$RED" "⚠️  ISSUES FOUND - $issues critical problems detected"
    echo
    print_status "$BLUE" "Recommended Actions:"
    echo "  1. Reinstall package if main components missing"
    echo "  2. Load LaunchDaemon if not running"
    echo "  3. Check file permissions on scripts"
    echo "  4. Review installation logs"
fi

echo
print_status "$BLUE" "Real-time Monitoring Commands:"
echo "  sudo tail -f /var/log/jamf_connect_monitor/monitor.log"
echo "  sudo jamf_connect_monitor.sh status"
echo "  sudo jamf_connect_monitor.sh test-config"
echo "  sudo jamf recon  # Update Jamf Pro inventory"