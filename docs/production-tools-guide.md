# Production Tools & Verification Guide - v2.3.0

## Overview
Jamf Connect Monitor v2.3.0 introduces comprehensive production tools for enterprise deployment validation, troubleshooting, and system maintenance. These tools ensure reliable deployment and ongoing operational excellence.

## 🔧 **tools/ Directory Structure**

```
tools/
├── verify_monitoring.sh          # Comprehensive production verification script
├── README.md                     # Tools documentation and usage guide
└── (future diagnostic tools)     # Planned: performance monitoring, SIEM integration
```

## 🔍 **verify_monitoring.sh - Comprehensive Production Verification**

### Purpose
The verification script provides enterprise-grade validation of all Jamf Connect Monitor components after installation, upgrade, or troubleshooting scenarios.

### Usage
```bash
# Basic verification (recommended after installation)
sudo ./tools/verify_monitoring.sh

# Verbose output for troubleshooting
sudo ./tools/verify_monitoring.sh --verbose

# Quick health check (minimal output)
sudo ./tools/verify_monitoring.sh --quick
```

### What It Tests

#### **1. Main Script Validation**
```bash
✅ Script Installation: /usr/local/bin/jamf_connect_monitor.sh exists
✅ Version Detection: Extracts and displays VERSION variable
✅ Permissions: Validates executable permissions (755)
✅ ACL Status: Ensures no @ symbols in permissions
✅ Functionality: Tests basic CLI commands
```

#### **2. Extension Attribute Validation**
```bash
✅ Script Installation: /usr/local/etc/jamf_ea_admin_violations.sh exists
✅ Version Compatibility: Confirms v2.3.0 features present
✅ Permissions: Validates executable permissions without ACL symbols
✅ Execution Test: Runs script and validates output format
✅ Data Format: Ensures Jamf Pro and Smart Group compatibility
```

#### **3. Configuration Profile Integration**
```bash
✅ Profile Detection: Tests multiple Configuration Profile reading methods
✅ Company Name Validation: Verifies actual company name (not "Your Company")
✅ Settings Reading: Validates webhook, email, and monitoring mode settings
✅ Method Compatibility: Tests Methods 2 & 4 for enterprise environments
```

#### **4. Monitoring System Health**
```bash
✅ LaunchDaemon Status: Verifies daemon is loaded and running
✅ Process Monitoring: Checks for active monitoring processes
✅ Log Directory: Validates log directory existence and permissions
✅ Recent Activity: Confirms recent monitoring activity
```

#### **5. Version Auto-Detection System**
```bash
✅ Main Script Version: Extracts VERSION variable from main script
✅ Extension Attribute Detection: Validates auto-detection functionality
✅ Future-Proof Design: Confirms system works with version updates
✅ Package Compatibility: Verifies package creation integration
```

### Sample Output

#### **Successful Verification**
```bash
🔍 JAMF CONNECT MONITOR VERIFICATION v2.3.0
======================================

✅ Main script installed: Version 2.3.0
✅ Permissions correct: -rwxr-xr-x
✅ Extension Attribute script installed: Version 2.3.0
✅ EA permissions correct: -rwxr-xr-x (no @ symbols)
✅ Extension Attribute runs successfully
✅ Version detected: Version: 2.3.0, Periodic: Running
✅ Monitoring mode detected: Mode: periodic
✅ Company name: [Your Company Name] (from Configuration Profile)
✅ Configuration Profile integration: Working (Method 2)
✅ LaunchDaemon status: Loaded and running
✅ Recent monitoring activity: Last check 2 minutes ago

🎉 MONITORING APPEARS TO BE WORKING CORRECTLY

📊 SUMMARY:
- Version Detection: Working (auto-detects from main script)
- Configuration Profile: Active (company name correctly displayed)  
- ACL Clearing: Successful (no @ symbols in permissions)
- Smart Group Compatibility: Ready (enhanced data format)
- Extension Attribute: Functional (all tests passed)

✅ READY FOR PRODUCTION DEPLOYMENT
```

#### **Troubleshooting Output**
```bash
🔍 JAMF CONNECT MONITOR VERIFICATION v2.3.0
======================================

❌ Main script installed: Missing
✅ Extension Attribute script installed: Version 2.3.0
⚠️  EA permissions incorrect: -rw-r--r--@ (has @ symbol)
❌ Extension Attribute execution: Permission denied
⚠️  Configuration Profile: Method 1 failed, trying Method 2...
✅ Configuration Profile integration: Working (Method 2)

🚨 ISSUES DETECTED - MANUAL INTERVENTION REQUIRED

🔧 RECOMMENDED FIXES:
1. Install main monitoring script: sudo installer -pkg JamfConnectMonitor-2.3.0.pkg -target /
2. Clear ACLs on Extension Attribute: sudo xattr -c /usr/local/etc/jamf_ea_admin_violations.sh
3. Set correct permissions: sudo chmod +x /usr/local/etc/jamf_ea_admin_violations.sh

📞 For support: https://github.com/MacJediWizard/jamf-connect-monitor/issues
```

### Enterprise Integration

#### **Jamf Pro Script Deployment**
Deploy verification script as Jamf Pro script for automated validation:

```bash
# Script Configuration in Jamf Pro:
Display Name: Jamf Connect Monitor - Production Verification
Category: Diagnostic
Priority: After
Parameter 4: Verification Mode (quick|verbose|standard)
```

#### **Policy Integration**
```bash
# Deployment Validation Policy:
1. Deploy JamfConnectMonitor-2.3.0.pkg
2. Run Production Verification script
3. Update inventory if verification passes
4. Send notification with results

# Maintenance Policy:
1. Run verification script weekly
2. Generate health report
3. Alert if issues detected
```

#### **Smart Group Integration**
Create Smart Groups based on verification results:

```bash
# Jamf Connect Monitor - Verification Passed
Criteria: Script Result "Production Verification" contains "READY FOR PRODUCTION"

# Jamf Connect Monitor - Needs Attention  
Criteria: Script Result "Production Verification" contains "ISSUES DETECTED"
```

## 🧪 **Testing Scenarios**

### Pre-Deployment Testing
```bash
# Test on clean system
1. Run verification (should show "not installed")
2. Install package
3. Run verification (should show "READY FOR PRODUCTION")
4. Validate Extension Attribute in Jamf Pro
```

### Post-Deployment Validation
```bash
# Enterprise deployment validation
1. Deploy to pilot group via Jamf Pro
2. Run verification script on pilot systems
3. Force inventory update: sudo jamf recon
4. Verify Extension Attribute data in Jamf Pro
5. Check Smart Group population
6. Proceed with full deployment
```

### Troubleshooting Workflows
```bash
# User reports monitoring not working
1. Run verification script for comprehensive diagnosis
2. Apply recommended fixes from script output
3. Re-run verification to confirm resolution
4. Update Jamf Pro inventory
5. Document resolution for future reference
```

### Upgrade Validation
```bash
# v2.3.0 → v2.3.0 upgrade verification
1. Note pre-upgrade version: sudo jamf_connect_monitor.sh status
2. Deploy v2.3.0 package
3. Run verification script
4. Confirm version shows "2.3.0" 
5. Verify Configuration Profile improvements
6. Test Extension Attribute execution
```

## 🚀 **Advanced Verification Features**

### Configuration Profile Deep Testing
```bash
# Tests all Configuration Profile reading methods:
Method 1: defaults read com.macjediwizard.jamfconnectmonitor
Method 2: defaults read "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor"  
Method 3: sudo defaults read com.macjediwizard.jamfconnectmonitor
Method 4: sudo defaults read "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor"

# Reports which methods work in your environment
# Validates company name displays correctly
# Confirms webhook/email configuration reading
```

### ACL and Extended Attribute Validation
```bash
# Comprehensive permission testing:
- Checks for @ symbols in file listings (indicates ACL problems)
- Validates execute permissions on all scripts
- Tests script execution without permission errors
- Confirms xattr -c clearing was successful
- Validates proper ownership (root:wheel)
```

### Version Management Testing
```bash
# Future-proof version architecture validation:
- Extracts VERSION variable from main script
- Tests Extension Attribute auto-detection capability  
- Validates package creation integration
- Confirms Smart Group compatibility
- Tests with simulated future versions (2.0.2, 2.1.0, etc.)
```

## 📋 **Deployment Checklist Integration**

### Pre-Production Checklist
- [ ] **Package Upload** - JamfConnectMonitor-2.3.0.pkg uploaded to Jamf Pro
- [ ] **Extension Attribute Update** - v2.3.0 script deployed in Jamf Pro
- [ ] **Configuration Profile** - JSON Schema deployed and scoped
- [ ] **Verification Script** - Available for post-deployment testing
- [ ] **Smart Groups** - Created with flexible v2.x criteria
- [ ] **Pilot Group** - Test deployment target identified

### Post-Deployment Validation
- [ ] **Run Verification** - `sudo ./tools/verify_monitoring.sh` on pilot systems
- [ ] **Check Output** - All tests show ✅ status
- [ ] **Extension Attribute** - Jamf Pro shows proper v2.3.0 data format
- [ ] **Smart Groups** - Pilot systems populate correctly
- [ ] **Configuration Profile** - Company name displays correctly
- [ ] **Force Inventory** - `sudo jamf recon` on pilot systems
- [ ] **Production Ready** - All validations passed

### Ongoing Maintenance
- [ ] **Weekly Verification** - Run on random sampling of fleet
- [ ] **Extension Attribute Monitoring** - Check for consistent data format
- [ ] **Smart Group Health** - Verify proper population trends
- [ ] **Version Tracking** - Monitor auto-detection functionality
- [ ] **Configuration Profile** - Validate settings consistency

## 🔮 **Future Tools (Planned)**

### Performance Monitoring
```bash
# tools/performance_monitor.sh (planned)
- Real-time monitoring resource usage tracking
- Log growth rate analysis
- CPU/Memory impact measurement
- Network utilization for notifications
- Jamf Pro inventory impact assessment
```

### SIEM Integration
```bash
# tools/siem_export.sh (planned)  
- Structured log export for security information systems
- JSON format violation reports
- API integration for security platforms
- Automated incident response triggers
- Compliance reporting generation
```

### Health Dashboard
```bash
# tools/health_dashboard.sh (planned)
- Web-based monitoring dashboard
- Real-time fleet health status
- Configuration Profile compliance tracking
- Violation trend analysis
- Automated reporting capabilities
```

## 📞 **Support and Troubleshooting**

### Common Issues and Solutions

#### **Verification Script Not Found**
```bash
# If tools/verify_monitoring.sh missing:
1. Re-download from GitHub releases
2. Extract from package: pkgutil --expand JamfConnectMonitor-2.3.0.pkg temp
3. Copy to appropriate location
4. Set permissions: chmod +x tools/verify_monitoring.sh
```

#### **Permission Denied Errors**
```bash
# If verification fails with permission errors:
1. Run with sudo: sudo ./tools/verify_monitoring.sh
2. Check file permissions: ls -la tools/verify_monitoring.sh
3. Clear ACLs if needed: sudo xattr -c tools/verify_monitoring.sh
4. Set execute permission: sudo chmod +x tools/verify_monitoring.sh
```

#### **Configuration Profile Not Detected**
```bash
# If Configuration Profile tests fail:
1. Verify profile deployment in Jamf Pro
2. Force profile renewal: sudo profiles renew -type=config
3. Check profile list: sudo profiles list | grep jamfconnectmonitor
4. Test manual reading: sudo defaults read com.macjediwizard.jamfconnectmonitor
```

### Getting Help
- **GitHub Issues**: [Report verification problems](https://github.com/MacJediWizard/jamf-connect-monitor/issues)
- **Documentation**: [Complete troubleshooting guide](docs/troubleshooting.md)
- **Community**: [Share verification results and solutions](https://github.com/MacJediWizard/jamf-connect-monitor/discussions)

---

## 🎯 **Bottom Line**

The production verification tools in v2.3.0 provide enterprise administrators with:

- **✅ Deployment Confidence** - Comprehensive validation before production rollout
- **✅ Troubleshooting Speed** - Immediate diagnosis of common issues
- **✅ Maintenance Automation** - Ongoing health monitoring capabilities  
- **✅ Future Compatibility** - Tools designed to work with all future versions
- **✅ Enterprise Integration** - Jamf Pro policy and Smart Group compatibility

**Use `sudo ./tools/verify_monitoring.sh` after every installation, upgrade, or when troubleshooting issues.**

---

**Created with ❤️ by MacJediWizard**

**Production-grade tools for enterprise reliability and operational excellence.**