# Jamf Pro Deployment Guide

## Overview
This guide provides detailed instructions for deploying Jamf Connect Monitor through Jamf Pro with complete automation.

## Prerequisites

### Jamf Pro Requirements
- **Jamf Pro Version**: 10.27 or later
- **Admin Privileges**: Full administrator access to Jamf Pro
- **Target Environment**: macOS 10.14+ with Jamf Connect installed

## Step-by-Step Deployment

### Phase 1: Package Management

#### 1.1 Upload Installation Package
1. **Download Package:**
   - Go to [GitHub Releases](https://github.com/MacJediWizard/jamf-connect-monitor/releases/latest)
   - Download `JamfConnectMonitor-1.0.pkg`

2. **Upload to Jamf Pro:**
   - Navigate: **Settings → Computer Management → Packages**
   - Click **"New"**
   - **Configuration:**
     ```
     Display Name: Jamf Connect Monitor
     Category: Security
     Priority: 10
     Description: Monitors unauthorized admin privilege escalations
     ```

### Phase 2: Extension Attribute Creation

#### 2.1 Create Extension Attribute
1. **Navigate:** Settings → Computer Management → Extension Attributes
2. **Configuration:**
   ```
   Display Name: Admin Account Violations
   Description: Reports unauthorized admin account violations
   Data Type: String
   Input Type: Script
   ```
3. **Script:** Copy content from `jamf/extension-attribute.sh`

### Phase 3: Smart Group Configuration

#### 3.1 Target Deployment Group
```
Name: Jamf Connect Devices
Criteria: Application Title | is | Jamf Connect.app
```

#### 3.2 Installation Tracking Group
```
Name: Jamf Connect Monitor - Installed
Criteria: Admin Account Violations | is not | Not configured
```

#### 3.3 Violation Detection Group
```
Name: Jamf Connect Monitor - Violations Detected
Criteria: Admin Account Violations | contains | Unauthorized Admins:
```

### Phase 4: Policy Configuration

#### 4.1 Main Deployment Policy
1. **General Settings:**
   ```
   Display Name: Deploy Jamf Connect Monitor
   Category: Security
   Trigger: Enrollment Complete, Recurring Check-in
   Execution Frequency: Once per computer
   ```

2. **Packages:**
   ```
   Package: Jamf Connect Monitor
   Action: Install
   ```

3. **Scope:**
   ```
   Target: "Jamf Connect Devices" smart group
   Exclusions: "Jamf Connect Monitor - Installed"
   ```

### Phase 5: Testing and Validation

#### 5.1 Pilot Testing
1. **Create Test Policy** scoped to 5-10 test machines
2. **Test Scenarios:**
   ```bash
   # Test 1: Normal operation
   sudo jamf_connect_monitor.sh status
   
   # Test 2: Create unauthorized admin
   sudo dseditgroup -o edit -a testuser admin
   
   # Test 3: Monitor detection
   tail -f /var/log/jamf_connect_monitor/monitor.log
   ```

3. **Validation Checklist:**
   - [ ] Package installs successfully
   - [ ] LaunchDaemon loads and runs
   - [ ] Extension Attribute populates
   - [ ] Violations detected and remediated

#### 5.2 Production Rollout
1. **Phase 1: IT Department**
2. **Phase 2: Administrative Users** 
3. **Phase 3: General Fleet**

## Advanced Configuration

### Custom Notification Integration
Configure webhooks for Slack/Teams integration:

```bash
# Slack webhook
Parameter 4: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXX

# Email notifications
Parameter 5: security@company.com
```

### Compliance Reporting
Generate weekly compliance reports and monitor Smart Groups for ongoing violation tracking.

## Troubleshooting Deployment

### Common Issues

#### Policy Not Executing
- Verify Smart Group membership
- Check policy scope and exclusions
- Test with custom trigger: `sudo jamf policy -event install_jamf_monitor`

#### Package Installation Fails
- Check distribution point connectivity
- Verify package integrity
- Review installation logs

#### Extension Attribute Not Updating
- Test EA script manually
- Force inventory update: `sudo jamf recon`
- Check script permissions

---

**Created with ❤️ by MacJediWizard**
