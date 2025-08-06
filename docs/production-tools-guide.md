# Production Tools & Verification Guide

## Overview
This guide documents the production verification tools and diagnostic procedures for Jamf Connect Monitor v2.0.1, providing comprehensive deployment confidence and troubleshooting capabilities.

## Built-in Verification Tools

### Primary Diagnostic Commands

#### Status Check with Full Configuration
```bash
# Comprehensive system status
sudo jamf_connect_monitor.sh status

# Expected v2.0.1 output:
# === Jamf Connect Elevation Monitor Status (v2.0.1) ===
# Configuration Profile: Active
# Company: [Actual Company Name] (not "Your Company")
# Monitoring Mode: periodic (or realtime/hybrid)
# Auto Remediation: true
# Grace Period: 5 minutes
# Notifications:
#   Webhook: Configured
#   Email: security@company.com
#   Template: security_report
#   Cooldown: 15 minutes
```

#### Configuration Profile Integration Test
```bash
# Test Configuration Profile parsing
sudo jamf_connect_monitor.sh test-config

# Expected v2.0.1 output:
# === Configuration Profile Test ===
# Profile Status: Deployed
# Notification Settings:
#   Webhook: Configured
#   Email: security@company.com
#   Template: security_report
#   Cooldown: 15 minutes
# Monitoring Behavior:
#   Mode: periodic
#   Auto Remediation: true
#   Grace Period: 5 minutes
#   Company Name: [Actual Company Name]
```

#### Extension Attribute Verification
```bash
# Test Extension Attribute directly
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Expected v2.0.1 output format:
# <result>=== JAMF CONNECT MONITOR STATUS v2.0 ===
# Version: 2.0.1, Periodic: Running, Real-time: Not Running
# Configuration: Profile: Deployed, Webhook: Configured, Email: Configured, Mode: periodic, Company: [Actual Company Name]
# Violations: Total: 0, Recent: 0, Last: None, Unauthorized: 0
# Admin Status: Current: [admin,user1], Approved: [admin,user1]
# Jamf Connect: Installed: Yes, Elevation: Yes, Monitoring: Yes
# Health: Last Check: 2025-08-05 14:30:15, Daemon: Healthy, Logs: 2MB, Config Test: OK
# Report Generated: 2025-08-05 14:30:15
# </result>
```

### Permission and ACL Verification

#### File Permission Check
```bash
# Verify no ACL issues (v2.0.1 automatically clears ACLs)
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
ls -la@ /usr/local/etc/jamf_ea_admin_violations.sh

# Expected output (no @ symbols):
# -rwxr-xr-x  1 root  wheel  45K Aug  5 14:30 /usr/local/bin/jamf_connect_monitor.sh
# -rwxr-xr-x  1 root  wheel  12K Aug  5 14:30 /usr/local/etc/jamf_ea_admin_violations.sh
```

#### Manual ACL Clearing (if needed)
```bash
# Clear ACLs manually if automatic clearing failed
sudo xattr -c /usr/local/bin/jamf_connect_monitor.sh
sudo xattr -c /usr/local/etc/jamf_ea_admin_violations.sh

# Verify clearing worked
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
# Should show no @ symbol at end of permissions
```

### System Integration Verification

#### LaunchDaemon Status
```bash
# Check daemon registration and status
sudo launchctl list | grep jamfconnectmonitor

# Expected output:
# 12345   0   com.macjediwizard.jamfconnectmonitor

# Check daemon configuration
plutil -lint /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
# Expected: OK
```

#### Configuration Profile Status
```bash
# Verify Configuration Profile installation
sudo profiles list | grep jamfconnectmonitor

# Expected output shows profile UUID and details

# Read actual configuration values
sudo defaults read com.macjediwizard.jamfconnectmonitor
# Should display configured webhook, email, company name, etc.
```

#### Log System Health
```bash
# Check log directory and files
ls -la /var/log/jamf_connect_monitor/

# Monitor live activity
tail -f /var/log/jamf_connect_monitor/monitor.log

# Check for recent violations
tail -10 /var/log/jamf_connect_monitor/admin_violations.log
```

## Comprehensive Deployment Verification

### Pre-Deployment Checklist
```bash
# 1. Package integrity check
pkgutil --check-signature JamfConnectMonitor-2.0.1.pkg
shasum -a 256 -c JamfConnectMonitor-2.0.1.pkg.sha256

# 2. JSON Schema validation
python3 -m json.tool jamf_connect_monitor_schema.json

# 3. Jamf Pro connectivity
jamf checkJSSConnection

# 4. Target system requirements
sw_vers | grep ProductVersion
# Should show macOS 10.14+
```

### Post-Installation Validation
```bash
# 1. Installation verification
sudo jamf_connect_monitor.sh status | grep "Version: 2.0.1"

# 2. Configuration Profile integration
sudo jamf_connect_monitor.sh test-config | grep "Profile Status: Deployed"

# 3. Extension Attribute functionality
sudo /usr/local/etc/jamf_ea_admin_violations.sh | grep "Version: 2.0.1"

# 4. Permission verification (no ACL @ symbols)
ls -la@ /usr/local/bin/jamf_connect_monitor.sh | grep -v '@'

# 5. Daemon health
sudo launchctl list | grep jamfconnectmonitor | grep -v '-'

# 6. Company name verification (should not be "Your Company")
sudo jamf_connect_monitor.sh test-config | grep "Company Name:" | grep -v "Your Company"
```

### Jamf Pro Integration Testing
```bash
# 1. Force inventory update
sudo jamf recon

# 2. Check Extension Attribute population in Jamf Pro
# Navigate to computer record → Extension Attributes
# Verify "[ Jamf Connect ] - Monitor Status v2.x" shows proper data

# 3. Smart Group validation
# Check Smart Groups for proper membership:
# - "Jamf Connect Monitor - Installed v2.x" should include the device
# - "Jamf Connect Monitor - Latest v2.0.1+" should include the device
# - Extension Attribute data should match expected format
```

## Troubleshooting Tools

### Diagnostic Information Collection
```bash
# Comprehensive system information
cat << 'EOF' > jamf_monitor_diagnostics.sh
#!/bin/bash
echo "=== Jamf Connect Monitor Diagnostics ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "macOS Version: $(sw_vers -productVersion)"
echo ""

echo "=== Package Information ==="
pkgutil --pkg-info com.macjediwizard.jamfconnectmonitor 2>/dev/null || echo "Package not found"
echo ""

echo "=== File Status ==="
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
ls -la@ /usr/local/etc/jamf_ea_admin_violations.sh
echo ""

echo "=== Configuration Profile ==="
sudo profiles list | grep jamfconnectmonitor || echo "No profile found"
sudo defaults read com.macjediwizard.jamfconnectmonitor 2>/dev/null || echo "No configuration found"
echo ""

echo "=== LaunchDaemon Status ==="
sudo launchctl list | grep jamfconnectmonitor || echo "Daemon not loaded"
plutil -lint /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist 2>/dev/null || echo "Plist not found/invalid"
echo ""

echo "=== Monitor Status ==="
sudo /usr/local/bin/jamf_connect_monitor.sh status 2>/dev/null || echo "Monitor script not functional"
echo ""

echo "=== Extension Attribute Test ==="
sudo /usr/local/etc/jamf_ea_admin_violations.sh 2>/dev/null || echo "Extension Attribute script not functional"
echo ""

echo "=== Recent Logs ==="
tail -5 /var/log/jamf_connect_monitor/monitor.log 2>/dev/null || echo "No recent logs"
EOF

chmod +x jamf_monitor_diagnostics.sh
sudo ./jamf_monitor_diagnostics.sh
```

### Performance Monitoring
```bash
# Monitor resource usage
ps aux | grep jamf_connect_monitor

# Check log sizes
du -sh /var/log/jamf_connect_monitor/

# Monitor real-time activity
tail -f /var/log/jamf_connect_monitor/monitor.log &
TAIL_PID=$!

# Run a test check
sudo jamf_connect_monitor.sh force-check

# Stop monitoring
kill $TAIL_PID
```

### Network Connectivity Testing
```bash
# Test webhook connectivity (if configured)
WEBHOOK_URL=$(sudo defaults read com.macjediwizard.jamfconnectmonitor NotificationSettings.WebhookURL 2>/dev/null)
if [[ -n "$WEBHOOK_URL" ]]; then
    curl -X POST -H 'Content-type: application/json' \
         --data '{"text":"Test from Jamf Connect Monitor v2.0.1"}' \
         "$WEBHOOK_URL" && echo "Webhook test successful"
fi

# Test Jamf Pro connectivity
jamf checkJSSConnection

# Test DNS resolution
nslookup hooks.slack.com 2>/dev/null || echo "DNS resolution test failed"
```

## Production Deployment Validation

### Pilot Group Testing
```bash
# Deploy to 5-10 test systems and run this validation on each:

# 1. Automated validation script
cat << 'EOF' > pilot_validation.sh
#!/bin/bash
ERRORS=0

echo "=== Pilot System Validation ==="

# Test 1: Version detection
if sudo jamf_connect_monitor.sh status | grep -q "Version: 2.0.1"; then
    echo "✅ Version 2.0.1 detected"
else
    echo "❌ Version detection failed"
    ((ERRORS++))
fi

# Test 2: Configuration Profile
if sudo jamf_connect_monitor.sh test-config | grep -q "Profile Status: Deployed"; then
    echo "✅ Configuration Profile active"
else
    echo "❌ Configuration Profile not active"
    ((ERRORS++))
fi

# Test 3: Extension Attribute
if sudo /usr/local/etc/jamf_ea_admin_violations.sh | grep -q "Version: 2.0.1"; then
    echo "✅ Extension Attribute functional"
else
    echo "❌ Extension Attribute not functional"
    ((ERRORS++))
fi

# Test 4: ACL clearing
if ! ls -la@ /usr/local/bin/jamf_connect_monitor.sh | grep -q '@'; then
    echo "✅ ACLs cleared successfully"
else
    echo "❌ ACLs still present"
    ((ERRORS++))
fi

# Test 5: Company name (should not be default)
if sudo jamf_connect_monitor.sh test-config | grep "Company Name:" | grep -qv "Your Company"; then
    echo "✅ Company name configured correctly"
else
    echo "⚠️  Company name shows default value"
fi

echo ""
echo "Validation complete: $ERRORS errors found"
exit $ERRORS
EOF

chmod +x pilot_validation.sh
sudo ./pilot_validation.sh
```

### Fleet Deployment Monitoring
```bash
# Smart Group validation queries for Jamf Pro API
# Use these to monitor deployment progress

# Check v2.0.1 deployment percentage
# Smart Group: "Jamf Connect Monitor - Latest v2.0.1+"

# Check Configuration Profile deployment
# Smart Group: "Jamf Connect Monitor - Config Profile Active"

# Monitor for violations
# Smart Group: "Jamf Connect Monitor - CRITICAL VIOLATIONS" (should be 0)

# Check system health
# Smart Group: "Jamf Connect Monitor - Needs Attention"
```

## Advanced Diagnostic Procedures

### Configuration Profile Deep Dive
```bash
# Extract and examine Configuration Profile
sudo profiles show -output /tmp/profiles.plist
/usr/libexec/PlistBuddy -c "Print" /tmp/profiles.plist | grep -A 20 jamfconnectmonitor

# Test specific Configuration Profile values
sudo defaults read com.macjediwizard.jamfconnectmonitor NotificationSettings.WebhookURL
sudo defaults read com.macjediwizard.jamfconnectmonitor JamfProIntegration.CompanyName
sudo defaults read com.macjediwizard.jamfconnectmonitor MonitoringBehavior.MonitoringMode
```

### Extension Attribute Data Analysis
```bash
# Parse Extension Attribute output for specific values
EA_OUTPUT=$(sudo /usr/local/etc/jamf_ea_admin_violations.sh)

# Extract version
echo "$EA_OUTPUT" | grep -o "Version: [0-9]\+\.[0-9]\+\.[0-9]\+"

# Extract company name
echo "$EA_OUTPUT" | grep -o "Company: [^,]*"

# Extract violation count
echo "$EA_OUTPUT" | grep -o "Unauthorized: [0-9]\+"

# Extract monitoring mode
echo "$EA_OUTPUT" | grep -o "Mode: [a-z]*"
```

### Performance Impact Assessment
```bash
# Measure monitoring impact
cat << 'EOF' > performance_test.sh
#!/bin/bash
echo "=== Performance Impact Assessment ==="

# CPU usage
CPU_USAGE=$(ps aux | grep jamf_connect_monitor | grep -v grep | awk '{print $3}')
echo "CPU Usage: ${CPU_USAGE:-0}%"

# Memory usage
MEM_USAGE=$(ps aux | grep jamf_connect_monitor | grep -v grep | awk '{print $4}')
echo "Memory Usage: ${MEM_USAGE:-0}%"

# Log sizes
LOG_SIZE=$(du -sh /var/log/jamf_connect_monitor/ 2>/dev/null | cut -f1)
echo "Log Directory Size: ${LOG_SIZE:-0MB}"

# Daemon check frequency impact
DAEMON_RUNS=$(grep "Starting Jamf Connect elevation monitoring" /var/log/jamf_connect_monitor/monitor.log | wc -l)
echo "Monitoring Cycles: $DAEMON_RUNS"

# Network requests (if webhook configured)
WEBHOOK_REQUESTS=$(grep -c "webhook notification sent" /var/log/jamf_connect_monitor/monitor.log 2>/dev/null || echo "0")
echo "Webhook Notifications: $WEBHOOK_REQUESTS"
EOF

chmod +x performance_test.sh
./performance_test.sh
```

## Quality Assurance Procedures

### Automated Testing Framework
```bash
# Comprehensive automated test suite
cat << 'EOF' > qa_test_suite.sh
#!/bin/bash
# Jamf Connect Monitor v2.0.1 QA Test Suite

PASSED=0
FAILED=0

test_result() {
    if [[ $1 -eq 0 ]]; then
        echo "✅ $2"
        ((PASSED++))
    else
        echo "❌ $2"
        ((FAILED++))
    fi
}

echo "=== Jamf Connect Monitor v2.0.1 QA Test Suite ==="

# Test 1: Package Installation
sudo jamf_connect_monitor.sh status &>/dev/null
test_result $? "Package installation and script functionality"

# Test 2: Version Detection
sudo jamf_connect_monitor.sh status | grep -q "Version: 2.0.1"
test_result $? "Version 2.0.1 detection"

# Test 3: Configuration Profile Integration
sudo jamf_connect_monitor.sh test-config | grep -q "Profile Status: Deployed"
test_result $? "Configuration Profile integration"

# Test 4: Extension Attribute Functionality
sudo /usr/local/etc/jamf_ea_admin_violations.sh | grep -q "Version: 2.0.1"
test_result $? "Extension Attribute version detection"

# Test 5: ACL Clearing
! ls -la@ /usr/local/bin/jamf_connect_monitor.sh | grep -q '@'
test_result $? "ACL clearing (no @ symbols)"

# Test 6: LaunchDaemon Status
sudo launchctl list | grep -q jamfconnectmonitor
test_result $? "LaunchDaemon registration"

# Test 7: Company Name Configuration
! sudo jamf_connect_monitor.sh test-config | grep "Company Name:" | grep -q "Your Company"
test_result $? "Company name not using default fallback"

# Test 8: File Permissions
[[ -x /usr/local/bin/jamf_connect_monitor.sh ]] && [[ -x /usr/local/etc/jamf_ea_admin_violations.sh ]]
test_result $? "Script execution permissions"

# Test 9: Log Directory
[[ -d /var/log/jamf_connect_monitor ]]
test_result $? "Log directory creation"

# Test 10: Approved Admin List
[[ -f /usr/local/etc/approved_admins.txt ]]
test_result $? "Approved admin list file"

echo ""
echo "=== Test Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [[ $FAILED -eq 0 ]]; then
    echo "🎉 All tests passed! System is production ready."
    exit 0
else
    echo "⚠️ $FAILED test(s) failed. Review system before production deployment."
    exit 1
fi
EOF

chmod +x qa_test_suite.sh
sudo ./qa_test_suite.sh
```

### Pre-Production Checklist
- [ ] **Package Integrity**: Checksum verification passed
- [ ] **Version Detection**: Extension Attribute shows "Version: 2.0.1"
- [ ] **Configuration Profile**: Active and displaying actual company name
- [ ] **ACL Clearing**: No @ symbols in script permissions
- [ ] **Smart Group Compatibility**: Extension Attribute data format correct
- [ ] **LaunchDaemon**: Loaded and running properly
- [ ] **Notification Testing**: Webhook/email delivery confirmed
- [ ] **Performance Impact**: Resource usage within acceptable limits
- [ ] **Jamf Pro Integration**: Extension Attribute populating correctly
- [ ] **Future Compatibility**: Flexible Smart Group criteria implemented

---

## Emergency Diagnostic Commands

### Quick Health Check
```bash
# One-liner health check
sudo jamf_connect_monitor.sh status | head -5 && sudo /usr/local/etc/jamf_ea_admin_violations.sh | grep "Version:" && ls -la@ /usr/local/bin/jamf_connect_monitor.sh | grep -v '@' && echo "Basic health check complete"
```

### Emergency Repair
```bash
# Emergency repair procedures
sudo xattr -c /usr/local/bin/jamf_connect_monitor.sh
sudo xattr -c /usr/local/etc/jamf_ea_admin_violations.sh
sudo chmod +x /usr/local/bin/jamf_connect_monitor.sh
sudo chmod +x /usr/local/etc/jamf_ea_admin_violations.sh
sudo launchctl unload /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
sudo launchctl load /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist
echo "Emergency repair complete"
```

---

**Created with ❤️ by MacJediWizard**

**Comprehensive production verification and diagnostic tools for enterprise deployment confidence.**