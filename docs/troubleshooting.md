# Troubleshooting Guide v2.3.0

## v2.3.0 Critical Issue Resolution

### **Issue 1: Extension Attribute Execution Failures (FIXED in v2.3.0)**

#### **Root Cause**
macOS Extended Attributes (ACLs) prevent script execution after package installation.

#### **Solution (Automatic in v2.3.0)**
The v2.3.0 postinstall script automatically clears ACLs:
```bash
# Automatically applied during v2.3.0 installation:
xattr -c /usr/local/bin/jamf_connect_monitor.sh
xattr -c /usr/local/etc/jamf_ea_admin_violations.sh
```

#### **Manual Fix (if needed)**
```bash
# Clear ACLs manually if issues persist:
sudo xattr -c /usr/local/bin/jamf_connect_monitor.sh
sudo xattr -c /usr/local/etc/jamf_ea_admin_violations.sh

# Verify no ACLs remain:
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
# Should show: -rwxr-xr-x (no @ symbol)
```

### **Issue 2: Configuration Profile Integration (ENHANCED in v2.3.0)**

#### **Symptom**
Extension Attribute shows "Company: Your Company" instead of actual configured company name.

#### **Root Cause**
v2.3.0 had fallback issues when Configuration Profile wasn't fully processed.

#### **Solution (Automatic in v2.3.0)**
Enhanced parsing logic automatically detects and displays actual company names:
```bash
# Test Configuration Profile integration:
sudo jamf_connect_monitor.sh test-config

# Expected output shows actual configured values:
# Company Name: [Your Actual Company Name]
# Webhook: Configured
# Email: configured@yourcompany.com
```

### **Issue 3: Extension Attribute Version Detection (FIXED in v2.3.0)**

#### **Symptom**
Extension Attribute shows "Version: Unknown" or empty version field.

#### **Solution (Automatic in v2.3.0)**
Auto-detection now works reliably:
```bash
# Test Extension Attribute manually:
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Expected output shows:
# Version: 2.3.0, Periodic: Running, Real-time: Not Running
```

## Common Issues and Solutions

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
2. Load daemon: `sudo launchctl load /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist`
3. Check logs: `tail -f /var/log/jamf_connect_monitor/monitor.log`

### False Violation Alerts
**Symptoms**: Approved admins being flagged
**Solutions**:
1. Check approved list: `cat /usr/local/etc/approved_admins.txt`
2. Add user: `sudo /usr/local/bin/jamf_connect_monitor.sh add-admin username`
3. Verify admin group: `dscl . -read /Groups/admin GroupMembership`

### Configuration Profile Not Applying
**Symptoms**: Settings not taking effect
**Solutions**:
1. Force profile renewal: `sudo profiles renew -type=config`
2. Check profile status: `sudo profiles list | grep jamfconnectmonitor`
3. Validate JSON schema: `python3 -m json.tool jamf_connect_monitor_schema.json`

### Smart Groups Not Populating
**Symptoms**: Empty Smart Groups despite installations
**Solutions**:
1. Update Extension Attribute script in Jamf Pro (CRITICAL for v2.3.0)
2. Use flexible criteria: "Version: 2." instead of "Version: 2.0.0"
3. Force inventory updates: `sudo jamf recon`
4. Allow time for Smart Group processing

## Production Verification

### Comprehensive System Check
```bash
# 1. Verify installation
sudo jamf_connect_monitor.sh status

# 2. Test Configuration Profile
sudo jamf_connect_monitor.sh test-config

# 3. Check Extension Attribute
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# 4. Verify file permissions (no ACL @ symbols)
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
ls -la@ /usr/local/etc/jamf_ea_admin_violations.sh

# 5. Check daemon status
sudo launchctl list | grep jamfconnectmonitor
```

### Expected v2.3.0 Output
```bash
# jamf_connect_monitor.sh status should show:
=== Jamf Connect Elevation Monitor Status (v2.3.0) ===
Configuration Profile: Active (or Not deployed)
Company: [Your Actual Company Name]
Monitoring Mode: periodic (or realtime/hybrid)

# Extension Attribute should show:
Version: 2.3.0, Periodic: Running, Real-time: Not Running
Configuration: Profile: Deployed, Webhook: Configured, Mode: periodic
```

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

## Enterprise Deployment Issues

### Mass Deployment Troubleshooting
1. **Staged Rollout**: Deploy to pilot group first
2. **Inventory Management**: Force updates after deployment
3. **Smart Group Validation**: Use flexible version criteria
4. **Performance Monitoring**: Track resource usage

### Configuration Profile Management
1. **JSON Schema Validation**: Test schema before deployment
2. **Department-Specific Settings**: Use multiple profiles if needed
3. **Update Procedures**: Configuration changes without script updates
4. **Backup and Recovery**: Document profile configurations

---

**Created with ❤️ by MacJediWizard**