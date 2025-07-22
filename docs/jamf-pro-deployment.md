# Jamf Pro Deployment Guide v2.0.0

## Overview
This guide provides detailed instructions for deploying Jamf Connect Monitor v2.0.0 through Jamf Pro with complete Configuration Profile automation and real-time monitoring capabilities.

## Prerequisites

### Jamf Pro Requirements
- **Jamf Pro Version**: 10.19 or later (for JSON Schema support)
- **Admin Privileges**: Full administrator access to Jamf Pro
- **Target Environment**: macOS 10.14+ with Jamf Connect installed

### New in v2.0.0
- **Configuration Profile Support** - Centralized webhook/email management
- **JSON Schema Integration** - Easy Application & Custom Settings deployment  
- **Real-time Monitoring** - Immediate violation detection capabilities
- **Enhanced Notifications** - Professional security report templates

## Step-by-Step Deployment

### Phase 1: Package Management

#### 1.1 Upload Installation Package
1. **Download Package:**
   - Go to [GitHub Releases](https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest)
   - Download `JamfConnectMonitor-2.0.0.pkg`
   - Download `jamf_connect_monitor_schema.json`

2. **Upload to Jamf Pro:**
   - Navigate: **Settings → Computer Management → Packages**
   - Click **"New"**
   - **Configuration:**
     ```
     Display Name: Jamf Connect Monitor v2.0.0
     Category: Security
     Priority: 10
     Description: Enterprise security monitoring with Configuration Profile support
     ```

#### 1.2 Package Verification
```bash
# Verify package integrity
pkgutil --check-signature JamfConnectMonitor-2.0.0.pkg

# Check package contents
pkgutil --payload-files JamfConnectMonitor-2.0.0.pkg | grep schema
# Should show: usr/local/share/jamf_connect_monitor/schema/jamf_connect_monitor_schema.json
```

### Phase 2: Configuration Profile Deployment

#### 2.1 Create Configuration Profile
1. **Navigate:** Computer Management → Configuration Profiles → New
2. **General Settings:**
   ```
   Display Name: Jamf Connect Monitor Configuration
   Description: Security monitoring with centralized webhook/email management
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
Company Name: Your Company Name
IT Contact Email: ithelp@yourcompany.com
Update Inventory on Violation: true
```

#### 2.3 Scope Configuration Profile
```
Target: "Jamf Connect Monitor - Installed v2.0" Smart Group
Exclusions: None (unless testing specific groups)
```

### Phase 3: Extension Attribute Creation

#### 3.1 Create Enhanced Extension Attribute
1. **Navigate:** Settings → Computer Management → Extension Attributes → New
2. **Configuration:**
   ```
   Display Name: [ Jamf Connect ] - Monitor Status v2.0
   Description: Enhanced monitoring status with Configuration Profile support
   Data Type: String
   Input Type: Script
   ```
3. **Script:** Use the enhanced Extension Attribute script (v2.0.0 format)

#### 3.2 Extension Attribute Features
- **Configuration Profile Status** - Reports profile deployment
- **Real-time Monitoring Status** - Tracks monitoring modes
- **Violation History** - Comprehensive security incident reporting
- **Health Metrics** - System performance and status
- **Smart Group Compatibility** - Enhanced data format for automation

### Phase 4: Smart Group Configuration

#### 4.1 Essential Smart Groups

**Jamf Connect Monitor - Installed v2.0**
```
Name: Jamf Connect Monitor - Installed v2.0
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Version: 2.0.0"
Purpose: Track v2.0.0 installations and scope Configuration Profiles
```

**Jamf Connect Monitor - Config Profile Active**
```
Name: Jamf Connect Monitor - Config Profile Active
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Profile: Deployed"
Purpose: Verify Configuration Profile deployment success
```

**Jamf Connect Monitor - CRITICAL VIOLATIONS**
```
Name: Jamf Connect Monitor - CRITICAL VIOLATIONS
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Unauthorized:"
AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" does not contain "Unauthorized: 0"
Purpose: Immediate security incident response
⚠️ CONFIGURE WEBHOOK ALERTS FOR THIS GROUP
```

**Jamf Connect Monitor - Real-time Active**
```
Name: Jamf Connect Monitor - Real-time Active
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Real-time: Active"
Purpose: Track real-time monitoring deployment and performance impact
```

#### 4.2 Advanced Smart Groups

**Jamf Connect Monitor - Notifications Configured**
```
Name: Jamf Connect Monitor - Notifications Configured
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Webhook: Configured"
OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Email: Configured"
Purpose: Verify notification system deployment
```

**Jamf Connect Monitor - Needs Attention**
```
Name: Jamf Connect Monitor - Needs Attention
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Daemon: Not Running"
OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Profile: Not Deployed"
Purpose: Proactive maintenance and troubleshooting
```

### Phase 5: Policy Configuration

#### 5.1 Main Deployment Policy
1. **General Settings:**
   ```
   Display Name: Deploy Jamf Connect Monitor v2.0.0
   Category: Security
   Trigger: Enrollment Complete, Recurring Check-in
   Execution Frequency: Once per computer
   ```

2. **Packages:**
   ```
   Package: Jamf Connect Monitor v2.0.0
   Action: Install
   ```

3. **Scope:**
   ```
   Target: "Jamf Connect Devices" smart group
   Exclusions: "Jamf Connect Monitor - Installed v2.0"
   ```

4. **Maintenance:**
   ```
   Update Inventory: Enabled
   ```

#### 5.2 Configuration Profile Deployment Policy
1. **General Settings:**
   ```
   Display Name: Deploy Jamf Connect Monitor Configuration
   Category: Security
   Trigger: Enrollment Complete, Check-in
   ```

2. **Configuration Profiles:**
   ```
   Jamf Connect Monitor Configuration
   ```

3. **Scope:**
   ```
   Target: "Jamf Connect Monitor - Installed v2.0"
   Exclusions: "Jamf Connect Monitor - Config Profile Active"
   ```

### Phase 6: Testing and Validation

#### 6.1 Pilot Testing
1. **Create Test Policy** scoped to 5-10 test machines
2. **Test Scenarios:**
   ```bash
   # Test 1: Package installation
   sudo installer -pkg JamfConnectMonitor-2.0.0.pkg -target /
   
   # Test 2: Configuration Profile reading
   sudo jamf_connect_monitor.sh test-config
   
   # Test 3: Extension Attribute execution
   sudo /usr/local/etc/jamf_ea_admin_violations.sh
   
   # Test 4: Smart Group population
   # Check Jamf Pro computer record for Extension Attribute data
   
   # Test 5: Notification delivery
   # Configure test webhook/email and verify delivery
   ```

3. **Validation Checklist:**
   - [ ] Package installs successfully with v2.0.0 components
   - [ ] Configuration Profile deploys and applies settings
   - [ ] Extension Attribute populates with v2.0.0 data format
   - [ ] Smart Groups show correct membership
   - [ ] Webhook/email notifications deliver successfully
   - [ ] Real-time monitoring active (if configured)

#### 6.2 Configuration Profile Testing
```bash
# Verify Configuration Profile deployment
sudo profiles list | grep jamfconnectmonitor

# Test configuration reading
sudo defaults read com.macjediwizard.jamfconnectmonitor

# Expected output should show configured webhook, email, etc.
```

#### 6.3 Production Rollout Strategy
1. **Phase 1: IT Department** (10-20 devices)
2. **Phase 2: Administrative Users** (50-100 devices)
3. **Phase 3: General Fleet** (remaining devices)

### Phase 7: Advanced Configuration

#### 7.1 Department-Specific Configuration Profiles
Create multiple Configuration Profiles for different departments:

**IT Department Configuration:**
```json
{
  "NotificationSettings": {
    "WebhookURL": "https://hooks.slack.com/services/IT-TEAM/WEBHOOK",
    "NotificationTemplate": "detailed"
  },
  "MonitoringBehavior": {
    "MonitoringMode": "hybrid",
    "GracePeriodMinutes": 10
  }
}
```

**General Staff Configuration:**
```json
{
  "NotificationSettings": {
    "WebhookURL": "https://hooks.slack.com/services/SECURITY-TEAM/WEBHOOK",
    "NotificationTemplate": "security_report"
  },
  "MonitoringBehavior": {
    "MonitoringMode": "realtime",
    "GracePeriodMinutes": 2
  }
}
```

#### 7.2 Real-time Monitoring Deployment
For organizations wanting immediate violation detection:

1. **Configure Real-time Mode** in Configuration Profile
2. **Monitor Performance Impact** via Smart Groups
3. **Adjust Settings** based on resource usage
4. **Scale Gradually** across the fleet

### Phase 8: Monitoring and Maintenance

#### 8.1 Daily Operations Dashboard
**Create Jamf Pro Dashboard Widgets:**
- **Critical Violations:** Count of "CRITICAL VIOLATIONS" Smart Group (goal: 0)
- **Deployment Progress:** "Installed v2.0" vs "Config Profile Active"
- **Monitoring Modes:** "Real-time Active" vs "Periodic Only"
- **System Health:** "Healthy" vs "Needs Attention"

#### 8.2 Automated Alerting
**Configure webhook notifications for Smart Group membership changes:**
- **Critical Violations Group** → Immediate Slack/Teams alert
- **Needs Attention Group** → Daily maintenance notifications
- **Configuration Profile Failures** → IT team alerts

#### 8.3 Compliance Reporting
**Weekly Security Reports:**
- **Total Monitoring Coverage:** Percentage of Jamf Connect devices with monitoring
- **Configuration Compliance:** Profile deployment success rate
- **Violation Trends:** Historical incident analysis
- **Performance Metrics:** Real-time monitoring resource impact

## Configuration Profile Management Benefits

### Centralized Administration
- **No Script Editing:** Webhook URLs and email managed via Jamf Pro interface
- **Immediate Updates:** Configuration changes apply without script deployment
- **Encrypted Storage:** Sensitive credentials protected via Configuration Profiles
- **Department Flexibility:** Different settings per Smart Group/department

### Enterprise Features
- **JSON Schema Validation:** Jamf Pro validates configuration during deployment
- **User-Friendly Interface:** Point-and-click configuration management
- **Version Control:** Configuration Profile versioning and rollback capabilities
- **Audit Trail:** Complete change history via Jamf Pro logs

## Troubleshooting Deployment

### Common Issues

#### Configuration Profile Not Applying
```bash
# Force profile renewal
sudo profiles renew -type=config

# Check profile status
sudo profiles list | grep jamfconnectmonitor

# Validate JSON schema
python3 -m json.tool jamf_connect_monitor_schema.json
```

#### Extension Attribute Not Updating
```bash
# Test Extension Attribute manually
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Check Extension Attribute permissions
ls -la /usr/local/etc/jamf_ea_admin_violations.sh

# Force inventory update
sudo jamf recon
```

#### Smart Groups Not Populating
- **Verify Extension Attribute data format** matches Smart Group criteria
- **Check inventory update frequency** in Jamf Pro settings
- **Ensure devices have checked in** since Extension Attribute deployment

### Performance Considerations

#### Real-time Monitoring Impact
- **CPU Usage:** Monitor via Activity Monitor on pilot devices
- **Memory Usage:** Track background process resource consumption
- **Log Growth:** Monitor `/var/log/jamf_connect_monitor/` disk usage
- **Network Impact:** Minimal - only during violation notifications

#### Scalability Recommendations
- **Gradual Rollout:** Deploy real-time monitoring in phases
- **Department Targeting:** Start with high-security departments
- **Performance Monitoring:** Use Smart Groups to track resource impact
- **Adjustment Capability:** Configuration Profiles enable quick setting changes

---

## Next Steps After Deployment

1. **Monitor Smart Group "CRITICAL VIOLATIONS"** - Should remain at 0 members
2. **Review Configuration Profile Compliance** - Target 100% deployment
3. **Analyze Violation Trends** - Identify patterns and training needs
4. **Optimize Performance** - Adjust real-time monitoring based on resource usage
5. **Plan Advanced Features** - Consider SIEM integration and automated response policies

---

**Created with ❤️ by MacJediWizard**

**Enterprise-grade security monitoring with Configuration Profile management and real-time detection capabilities.**