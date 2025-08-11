<p align="center">
  <img src="../JamfConnectMonitor-815x1024.png" alt="Jamf Connect Monitor Logo" width="200">
</p>

# Jamf Pro Deployment Guide v2.4.0

## Overview
This guide provides detailed instructions for deploying Jamf Connect Monitor v2.4.0 through Jamf Pro with complete Configuration Profile automation, real-time monitoring capabilities, and **critical v2.4.0 production fixes**.

## 🚨 **CRITICAL v2.4.0 UPDATE REQUIREMENT**

### **⚠️ MOST IMPORTANT STEP: Extension Attribute Update**

**If upgrading from v2.4.0 or deploying v2.4.0, YOU MUST update the Extension Attribute script in Jamf Pro:**

1. **Navigate:** Settings → Computer Management → Extension Attributes
2. **Find:** "[ Jamf Connect ] - Monitor Status v2.x" (or similar)
3. **Edit Script Content** → Replace with v2.4.0 Enhanced Extension Attribute Script
4. **Save Changes**

**Without this update:**
- ❌ Extension Attribute shows empty version data
- ❌ Smart Groups won't populate correctly
- ❌ Configuration Profile integration appears broken
- ❌ Company name shows "Your Company" instead of actual name

**With this update:**
- ✅ Extension Attribute shows "Version: 2.4.0" automatically
- ✅ Smart Groups populate correctly with flexible criteria
- ✅ Configuration Profile shows actual company names
- ✅ All v2.4.0 production fixes enabled

## Prerequisites

### Jamf Pro Requirements
- **Jamf Pro Version**: 10.19 or later (for JSON Schema support)
- **Admin Privileges**: Full administrator access to Jamf Pro
- **Target Environment**: macOS 10.14+ with Jamf Connect installed

### v2.4.0 Production Features
- **✅ ACL Clearing** - Eliminates script execution permission issues
- **✅ Configuration Profile Integration** - Standardized reading methods for enterprise environments
- **✅ Auto-Version Detection** - Future-proof version management for all v2.x+ releases
- **✅ Enhanced Uninstall** - Complete system removal with configuration backup
- **✅ Production Verification** - Comprehensive diagnostic tools for enterprise deployment

## Step-by-Step Deployment

### Phase 1: Package Management

#### 1.1 Upload Installation Package
1. **Download Package:**
   - Go to [GitHub Releases](https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest)
   - Download `JamfConnectMonitor-2.4.0.pkg` (or latest 2.x version)
   - Download `jamf_connect_monitor_schema.json`

2. **Upload to Jamf Pro:**
   - Navigate: **Settings → Computer Management → Packages**
   - Click **"New"**
   - **Configuration:**
     ```
     Display Name: Jamf Connect Monitor v2.4.0
     Category: Security
     Priority: 10
     Description: Enterprise security monitoring with v2.4.0 production fixes
     ```

#### 1.2 Package Verification
```bash
# Verify package integrity
pkgutil --check-signature JamfConnectMonitor-2.4.0.pkg

# Check package contents for v2.4.0 features
pkgutil --payload-files JamfConnectMonitor-2.4.0.pkg | grep -E "(verify_monitoring|uninstall_script)"
# Should show: tools/verify_monitoring.sh and enhanced uninstall script
```

### Phase 2: Configuration Profile Deployment

#### 2.1 Create Configuration Profile
1. **Navigate:** Computer Management → Configuration Profiles → New
2. **General Settings:**
   ```
   Display Name: Jamf Connect Monitor Configuration v2.4.0
   Description: Security monitoring with v2.4.0 production fixes and centralized management
   Category: Security
   Level: Computer Level
   Distribution Method: Install Automatically
   ```

3. **Add Application & Custom Settings Payload:**
   - Click **"Add"** → **"Application & Custom Settings"**
   - **Source:** Custom Schema
   - **Preference Domain:** `com.macjediwizard.jamfconnectmonitor`
   - **Upload Schema:** Select `jamf_connect_monitor_schema.json`

#### 2.2 Configure Settings via Jamf Pro Interface

**Notification Settings:**
```
Webhook URL: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
Email Recipient: security@yourcompany.com
Notification Template: security_report
Notification Cooldown: 15 minutes
```

**Monitoring Behavior:**
```
Monitoring Mode: realtime
Auto Remediation: true
Grace Period: 5 minutes
Monitor Jamf Connect Only: true
```

**Jamf Pro Integration:**
```
Company Name: Your Company Name (CRITICAL - this now displays correctly in v2.4.0)
IT Contact Email: ithelp@yourcompany.com
Update Inventory on Violation: true
```

#### 2.3 Scope Configuration Profile
```
Target: "Jamf Connect Monitor - Installed v2.x" Smart Group
Exclusions: None (unless testing specific groups)
```

### Phase 3: Extension Attribute Creation/Update

#### 3.1 🚨 CRITICAL: Update Extension Attribute for v2.4.0

**For Existing v2.4.0 Installations:**
1. **Navigate:** Settings → Computer Management → Extension Attributes
2. **Find Existing:** "[ Jamf Connect ] - Monitor Status v2.x"
3. **Edit:** Click on existing Extension Attribute
4. **Replace Script Content:** Paste v2.4.0 Enhanced Extension Attribute Script
5. **Save Changes**

**For New Installations:**
1. **Navigate:** Settings → Computer Management → Extension Attributes → New
2. **Configuration:**
   ```
   Display Name: [ Jamf Connect ] - Monitor Status v2.4.0
   Description: Enhanced monitoring with v2.4.0 production fixes
   Data Type: String
   Input Type: Script
   ```
3. **Script:** Use the v2.4.0 Enhanced Extension Attribute script

#### 3.2 v2.4.0 Extension Attribute Features
- **✅ Auto-Version Detection** - Shows "Version: 2.4.0" automatically
- **✅ Configuration Profile Status** - Reports actual company names
- **✅ ACL Compatibility** - Works reliably with v2.4.0 ACL clearing
- **✅ Future-Proof Design** - Auto-detects v2.0.2, v2.1.0, v3.0.0+ automatically
- **✅ Enhanced Monitoring Mode** - Shows "Mode: periodic/realtime/hybrid" correctly
- **✅ Smart Group Compatibility** - Enhanced data format for automation

### Phase 4: Smart Group Configuration (Future-Proof v2.x)

#### 4.1 Essential Smart Groups

**Jamf Connect Monitor - Installed v2.x (Future-Proof)**
```
Name: Jamf Connect Monitor - Installed v2.x
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Version: 2.*"
Purpose: Track ALL v2.x installations (2.4.0, 2.3.0, 2.0.2, etc.)
```

**Jamf Connect Monitor - Config Profile Active**
```
Name: Jamf Connect Monitor - Config Profile Active
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Profile: Deployed*"
Purpose: Verify Configuration Profile deployment success
```

**Jamf Connect Monitor - CRITICAL VIOLATIONS**
```
Name: Jamf Connect Monitor - CRITICAL VIOLATIONS
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Unauthorized:*"
AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" not like "*Unauthorized: 0*"
Purpose: Immediate security incident response
⚠️ CONFIGURE WEBHOOK ALERTS FOR THIS GROUP
```

**Jamf Connect Monitor - v2.4.0 Production Ready**
```
Name: Jamf Connect Monitor - v2.4.0 Production Ready
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Version: 2.4.0*"
AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Profile: Deployed*"
AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Daemon: Healthy*"
Purpose: Track systems with all v2.4.0 fixes and full functionality
```

#### 4.2 Advanced Smart Groups

**Jamf Connect Monitor - Real-time Active**
```
Name: Jamf Connect Monitor - Real-time Active
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Mode: realtime*"
Purpose: Track real-time monitoring deployment and performance impact
```

**Jamf Connect Monitor - Needs Attention**
```
Name: Jamf Connect Monitor - Needs Attention
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Daemon: Not Running*"
OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Profile: Not Deployed*"
OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.4.0" like "*Config Test: Failed*"
Purpose: Proactive maintenance and troubleshooting (enhanced in v2.4.0)
```

### Phase 5: Policy Configuration

#### 5.1 Main Deployment Policy
1. **General Settings:**
   ```
   Display Name: Deploy Jamf Connect Monitor v2.4.0
   Category: Security
   Trigger: Enrollment Complete, Recurring Check-in
   Execution Frequency: Once per computer
   ```

2. **Packages:**
   ```
   Package: Jamf Connect Monitor v2.4.0
   Action: Install
   ```

3. **Scope:**
   ```
   Target: "Jamf Connect Devices" smart group
   Exclusions: "Jamf Connect Monitor - Installed v2.x"
   ```

4. **Maintenance:**
   ```
   Update Inventory: Enabled
   ```

#### 5.2 v2.4.0 Upgrade Policy (For Existing v2.4.0 Systems)
1. **General Settings:**
   ```
   Display Name: Upgrade to Jamf Connect Monitor v2.4.0
   Category: Security
   Trigger: Custom Event "upgrade_jamf_monitor_v201"
   Execution Frequency: Once per computer
   ```

2. **Packages:**
   ```
   Package: Jamf Connect Monitor v2.4.0 (upgrades seamlessly)
   Action: Install
   ```

3. **Scope:**
   ```
   Target: Smart Group with Extension Attribute like "*Version: 2.0.0*"
   ```

4. **Files and Processes:**
   ```
   Execute Command: /usr/local/bin/jamf_connect_monitor.sh status
   (Validates upgrade success)
   ```

### Phase 6: Testing and Validation

#### 6.1 Pilot Testing
1. **Create Test Policy** scoped to 5-10 test machines
2. **Test Scenarios:**
   ```bash
   # Test 1: Package installation
   sudo installer -pkg JamfConnectMonitor-2.4.0.pkg -target /
   
   # Test 2: Production verification (NEW in v2.4.0)
   sudo ./tools/verify_monitoring.sh
   
   # Test 3: Configuration Profile reading
   sudo jamf_connect_monitor.sh test-config
   
   # Test 4: Extension Attribute execution (CRITICAL)
   sudo /usr/local/etc/jamf_ea_admin_violations.sh
   
   # Test 5: Smart Group population
   # Check Jamf Pro computer record for Extension Attribute data
   
   # Test 6: ACL clearing verification (v2.4.0 fix)
   ls -la /usr/local/etc/jamf_ea_admin_violations.sh
   # Expected: -rwxr-xr-x (no @ symbol)
   ```

3. **v2.4.0 Validation Checklist:**
   - [ ] Package installs successfully with v2.4.0 components
   - [ ] **CRITICAL:** Extension Attribute shows "Version: 2.4.0"
   - [ ] Configuration Profile shows actual company name (not "Your Company")
   - [ ] File permissions show no @ symbols (ACL clearing worked)
   - [ ] Smart Groups populate with pilot systems
   - [ ] Webhook/email notifications deliver successfully
   - [ ] Production verification script passes all tests

#### 6.2 Configuration Profile Testing
```bash
# Verify Configuration Profile deployment
sudo profiles list | grep jamfconnectmonitor

# Test configuration reading (v2.4.0 improvements)
sudo defaults read com.macjediwizard.jamfconnectmonitor

# Expected output should show configured webhook, email, company name
# Company name should show YOUR actual company name, not "Your Company"
```

#### 6.3 v2.4.0 Production Rollout Strategy
1. **Phase 1: IT Department** (10-20 devices) - Test all v2.4.0 fixes
2. **Phase 2: Administrative Users** (50-100 devices) - Validate production stability
3. **Phase 3: General Fleet** (remaining devices) - Full deployment

### Phase 7: Advanced Configuration

#### 7.1 Department-Specific Configuration Profiles
Create multiple Configuration Profiles for different departments:

**IT Department Configuration (Enhanced Security):**
```json
{
  "NotificationSettings": {
    "WebhookURL": "https://hooks.slack.com/services/IT-TEAM/WEBHOOK",
    "NotificationTemplate": "security_report",
    "NotificationCooldownMinutes": 5
  },
  "MonitoringBehavior": {
    "MonitoringMode": "realtime",
    "GracePeriodMinutes": 2
  },
  "JamfProIntegration": {
    "CompanyName": "IT Department - Your Company"
  }
}
```

**General Staff Configuration (Balanced):**
```json
{
  "NotificationSettings": {
    "WebhookURL": "https://hooks.slack.com/services/SECURITY-TEAM/WEBHOOK",
    "NotificationTemplate": "detailed",
    "NotificationCooldownMinutes": 15
  },
  "MonitoringBehavior": {
    "MonitoringMode": "periodic",
    "GracePeriodMinutes": 10
  },
  "JamfProIntegration": {
    "CompanyName": "General Staff - Your Company"
  }
}
```

#### 7.2 Real-time Monitoring Deployment
For organizations wanting immediate violation detection:

1. **Configure Real-time Mode** in Configuration Profile
2. **Monitor Performance Impact** via Smart Groups
3. **Use Production Verification** to validate resource usage
4. **Scale Gradually** across the fleet

### Phase 8: Monitoring and Maintenance

#### 8.1 Daily Operations Dashboard
**Create Jamf Pro Dashboard Widgets:**
- **Critical Violations:** Count of "CRITICAL VIOLATIONS" Smart Group (goal: 0)
- **v2.4.0 Deployment:** "v2.4.0 Production Ready" vs "Needs Upgrade"
- **Configuration Profile Compliance:** "Config Profile Active" vs total installations
- **System Health:** "Healthy" vs "Needs Attention"

#### 8.2 Automated Alerting
**Configure webhook notifications for Smart Group membership changes:**
- **Critical Violations Group** → Immediate Slack/Teams alert
- **Needs Attention Group** → Daily maintenance notifications
- **Configuration Profile Failures** → IT team alerts

#### 8.3 Compliance Reporting
**Weekly Security Reports:**
- **v2.4.0 Coverage:** Percentage of fleet with production fixes
- **Configuration Compliance:** Profile deployment success rate
- **Violation Trends:** Historical incident analysis with enhanced v2.4.0 data
- **Performance Metrics:** Real-time monitoring resource impact

## Production Deployment Benefits (v2.4.0)

### Centralized Administration
- **No Script Editing:** Webhook URLs and email managed via Jamf Pro interface
- **Immediate Updates:** Configuration changes apply without script deployment
- **Encrypted Storage:** Sensitive credentials protected via Configuration Profiles
- **Department Flexibility:** Different settings per Smart Group/department

### Enterprise Reliability (v2.4.0)
- **ACL Resolution:** Eliminates script execution permission issues
- **Configuration Integration:** Standardized reading methods for enterprise environments
- **Auto-Version Management:** Future-proof system requiring zero maintenance
- **Production Verification:** Built-in diagnostic tools for deployment confidence

## Version-Specific Deployment Notes

### v2.4.0 Critical Improvements
- **Extension Attribute Update Required** - MUST update script in Jamf Pro for v2.4.0 features
- **ACL Clearing Automatic** - No more @ symbols in file permissions
- **Configuration Profile Integration** - Displays actual company names correctly
- **Auto-Version Detection** - Works automatically with all future versions

### v2.4.0 Enhanced Features
- SMTP provider selection and configuration
- Enhanced email delivery with authentication
- Production-verified Configuration Profile integration
- Provider-specific troubleshooting guidance

## Troubleshooting Deployment

### Common v2.4.0 Issues

#### Extension Attribute Not Showing v2.4.0 Data
```bash
# CRITICAL: Ensure Extension Attribute script is updated in Jamf Pro
# Settings → Extension Attributes → [ Jamf Connect ] - Monitor Status
# Replace script content with v2.4.0 version

# Test Extension Attribute manually:
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Expected: Version: 2.4.0, Company: [Your Company Name]
```

#### Configuration Profile Shows "Your Company" Instead of Actual Name
```bash
# This indicates v2.4.0 issue - should be fixed in v2.4.0
# Force Configuration Profile renewal:
sudo profiles renew -type=config

# Test configuration reading:
sudo jamf_connect_monitor.sh test-config
# Should show YOUR actual company name, not "Your Company"
```

#### Smart Groups Not Populating with v2.4.0 Systems
```bash
# Use flexible criteria for future-proof Smart Groups:
Extension Attribute "Monitor Status" like "*Version: 2.*"
# This catches 2.4.0, 2.3.0, 2.0.2, etc. automatically

# Force inventory update on sample systems:
sudo jamf recon

# Verify Extension Attribute data format matches criteria
```

### Performance Considerations

#### v2.4.0 Performance Improvements
- **Efficient ACL Clearing** - One-time operation during installation
- **Optimized Configuration Profile Reading** - Uses fastest working methods
- **Reduced Execution Overhead** - Auto-version detection eliminates script parsing
- **Enhanced Error Handling** - Graceful degradation prevents resource waste

#### Real-time Monitoring Impact
- **CPU Usage:** Monitor via Activity Monitor on pilot devices
- **Memory Usage:** Track background process resource consumption
- **Log Growth:** Monitor `/var/log/jamf_connect_monitor/` disk usage
- **Network Impact:** Minimal - only during violation notifications

#### Scalability Recommendations
- **Gradual Rollout:** Deploy v2.4.0 in phases
- **Department Targeting:** Start with IT and high-security departments
- **Performance Monitoring:** Use Smart Groups to track resource impact
- **Production Verification:** Use built-in tools to validate deployment success

---

## Next Steps After Deployment

1. **Verify Smart Group "CRITICAL VIOLATIONS"** - Should remain at 0 members
2. **Monitor "v2.4.0 Production Ready" Smart Group** - Track deployment progress
3. **Review Configuration Profile Compliance** - Target 100% deployment
4. **Use Production Verification Tools** - Validate installation success
5. **Plan Advanced Features** - Consider department-specific configurations

---

**Created with ❤️ by MacJediWizard**

**Enterprise-grade deployment with v2.4.0 production fixes, Configuration Profile management, and comprehensive verification procedures.**