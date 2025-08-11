# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Advanced SIEM integration capabilities
- Department-specific configuration profiles
- Performance monitoring dashboard
- Automated compliance reporting

## [2.4.0] - 2025-08-09

### Added

#### **Webhook Platform Selection**
- **WebhookType Configuration**: Select between Slack and Microsoft Teams for proper message formatting
- **Platform-Specific Formatting**: 
  - Slack: Uses attachments with color coding and fields
  - Teams: Uses MessageCard format with themeColor and sections
- **Auto-Detection**: Automatically formats messages based on selected platform
- **Enhanced Templates**: security_report, detailed, and simple templates for each platform

#### **Legitimate Elevation Tracking**
- **Audit Trail**: New `legitimate_elevations.log` for all authorized elevations
- **Elevation Lifecycle**: Tracks elevation → reason → demotion with timestamps
- **Duration Tracking**: Calculates and logs how long users remain elevated
- **Reason Capture**: Records why users elevated for compliance
- **Current Status**: Real-time tracking of who's currently elevated and why

#### **Elevation Analytics & Reporting**
- **Statistics Tracking**: Total, daily, per-user, and per-reason counts
- **New Command**: `elevation-report` shows comprehensive statistics and history
- **Top Users Report**: Shows users with most frequent elevations
- **Reason Analytics**: Tracks most common elevation reasons
- **Extension Attribute**: Shows elevation counts and current status

#### **MonitorJamfConnectOnly Setting**
- **New Configuration**: Only check for violations after Jamf Connect elevation detected
- **Flexible Monitoring**: Choose between always monitoring or event-driven checks
- **Resource Optimization**: Reduces unnecessary checks when no elevations occur
- **Default True**: Focuses on Jamf Connect elevation events by default

#### **SMTP Improvements**
- **Fixed SMTP_FROM_ADDRESS**: Now correctly uses SMTPFromAddress from config
- **Enhanced Authentication**: Fixed credential extraction using awk instead of regex
- **Provider Auto-Configuration**: Automatically configures settings based on provider
- **Required From Address**: Made SMTP From Address required in schema
- **Better Error Handling**: Improved SMTP error messages and diagnostics

#### **Enhanced Violation Context**
- **Legitimate vs Unauthorized**: Clear distinction in all notifications
- **Elevation Reasons in Alerts**: Shows why users elevated in violations
- **Current Elevations Display**: Shows who's legitimately elevated during violations
- **Better Decision Context**: Security teams see full picture for informed decisions

### Changed
- **Extension Attribute v2.4.0**: Enhanced with elevation tracking and SMTP details
- **Webhook Notifications**: Now platform-aware with proper formatting
- **Violation Reports**: Include legitimate elevation context
- **SMTP Configuration**: More robust with provider-specific guidance
- **Monitoring Logic**: Can now be Jamf Connect event-driven
- **Log Structure**: Added multiple new log files for elevation tracking

### Fixed
- **SMTP Authentication**: Fixed credential extraction for all providers
- **SMTP From Address**: Correctly reads from Configuration Profile
- **Webhook Type Detection**: Properly extracts WebhookType from config
- **Last Violation Timestamp**: Fixed extraction with proper formatting
- **Elevation Reason Capture**: Now properly logged for audit trail
- **Duration Calculation**: Correctly handles elevation-to-demotion timing

## [2.3.0] - 2025-08-08

### Added
- **SMTP Provider Selection**: New dropdown field in Configuration Profile to select SMTP provider type
  - Supports: Gmail/Google Workspace, Office 365, SendGrid, AWS SES, SMTP2GO, Mailgun, Custom
  - Provider-specific configuration guidance and troubleshooting
- **Enhanced Email Diagnostics**: Provider-aware recommendations in email test tool
- **Improved Configuration**: All SMTP configurations now require authentication for security

### Changed
- Updated Configuration Profile schema with SMTPProvider field
- Enhanced email test tool with provider-specific tips
- Improved SMTP configuration examples in documentation
- Default SMTP port changed from 465 to 587 (more universal)

### Fixed
- Better handling of SMTP configuration for different email providers
- Clearer error messages for authentication failures

## [2.2.0] - 2025-08-07

### 🔄 **Breaking Change: Removed System Mail Fallback**

This release removes the unreliable system mail fallback, requiring SMTP configuration for all email notifications. This ensures consistent, authenticated email delivery in enterprise environments.

### Breaking Changes

#### **Removed System Mail Fallback**
- **Impact:** Email notifications now require SMTP configuration
- **Rationale:** System mail was unreliable with DNS issues, postfix problems, and stuck mail queues
- **Migration:** Configure SMTP settings in Configuration Profile (Gmail, Office365, or corporate SMTP)

### Changed

#### **Email Delivery Architecture**
- **SMTP-Only:** All email notifications now require authenticated SMTP
- **No Fallback:** Removed unreliable system mail fallback that caused silent failures
- **Better Errors:** Clear error messages when SMTP is not configured
- **Enterprise Focus:** Designed for corporate environments with proper email infrastructure

### Fixed

#### **Email Reliability Issues**
- **Problem:** System mail fallback created false sense of success while emails never delivered
- **Solution:** Removed system mail entirely, requiring reliable SMTP configuration
- **Impact:** No more stuck emails in local mail queues or DNS resolution failures

### Enhanced

#### **Package Installation Process**
- **Clean Upgrades:** Preinstall script now removes old files before installing new ones
- **ACL Clearing:** Clears extended attributes on old files to prevent permission issues
- **Preserves Configuration:** Keeps approved admin lists and logs during upgrade
- **Prevents Conflicts:** Ensures clean installation by removing previous version files

### Security

- **Authenticated Only:** All emails now sent via authenticated SMTP connections
- **No Local Queue:** Eliminates security risks from emails stuck in local postfix queues
- **Enterprise Standards:** Aligns with corporate email security requirements

## [2.1.0] - 2025-08-07

### 🚀 **Major Feature Release: Enhanced SMTP Authentication & Security**

This release introduces comprehensive SMTP authentication support with enterprise-grade email delivery capabilities, addressing common corporate network restrictions and security requirements.

### Added

#### **Full SMTP Authentication Support**
- **Multiple SMTP Methods:** Implemented swaks, mailx, and sendmail with proper authentication
- **Port 465 SSL Support:** Added automatic SSL/TLS detection based on port
  - Port 465: Uses SSL connection (--tlsc for swaks, smtp-use-ssl for mailx)
  - Port 587: Uses STARTTLS (--tls for swaks, smtp-use-starttls for mailx)
- **Fallback Chain:** Automatic fallback from authenticated SMTP to system mail
- **Network Testing:** Built-in connectivity testing before sending emails

#### **Configuration Profile Security**
- **Password Field Security:** SMTP password now displays as masked field in Jamf Pro GUI
- **Format:** Added `"format": "password"` to schema for secure input
- **No Clear Text:** Passwords are hidden during input and after saving

#### **Email Testing Tools**
- **Comprehensive Test Suite:** Enhanced `tools/email_test.sh` with:
  - SMTP connectivity testing
  - Authentication validation
  - System mail verification
  - Diagnostic reporting with fix recommendations
- **Test Commands:** New `test-email` and `test-config` commands in main script

### Changed

#### **Default Port Configuration**
- **Changed default SMTP port from 587 to 465** across all components
- **Rationale:** Many corporate networks block port 587 but allow 465
- **Backwards Compatible:** Still supports port 587 when configured

#### **Configuration Schema Updates**
- Added SMTP configuration fields to JSON schema:
  - SMTPServer, SMTPPort, SMTPUsername, SMTPPassword, SMTPFromAddress
- Enhanced documentation in schema for port selection
- Improved help text for Gmail App Password requirements

### Fixed

#### **Email Delivery Issues**
- **Problem:** Email notifications failed in networks blocking port 587
- **Solution:** Implemented port 465 SSL support with proper TLS handling
- **Impact:** Email now works in restrictive corporate environments

#### **SMTP Authentication**
- **Problem:** Basic mail command couldn't authenticate with modern mail servers
- **Solution:** Integrated swaks and configured mailx for authenticated SMTP
- **Impact:** Supports Gmail, Office365, and corporate SMTP servers

### Security

- **Password Protection:** SMTP passwords are now masked in Configuration Profile GUI
- **No Customer Data:** Removed all organization-specific references from code
- **Secure Defaults:** Port 465 with SSL as default for better security

## [2.0.1] - 2025-08-05

### 🔧 **Production-Ready Release: All Critical Fixes Verified**

This release addresses critical production issues identified during enterprise deployment, with all fixes verified working in enterprise environments.

### Fixed

#### **Critical Issue 1: ACL Clearing for Script Execution**
- **Problem:** Extension Attribute script had `@` symbols in permissions causing execution failures in enterprise environments
- **Root Cause:** macOS Extended Attributes (ACLs) preventing script execution after package installation
- **Solution:** Added comprehensive `xattr -c` clearing in postinstall script for all installed components
- **Verification:** File permissions now show clean `-rwxr-xr-x` without `@` symbols
- **Impact:** Eliminates "Permission denied" errors during Extension Attribute execution

#### **Critical Issue 2: Configuration Profile Reading Methods**
- **Problem:** Main monitoring script used failing Configuration Profile reading method while Extension Attribute used working methods
- **Root Cause:** Inconsistent Configuration Profile access methods between script components
- **Solution:** Standardized all scripts to use verified working methods (Methods 2 & 4)
  - Method 2: `defaults read "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor"`
  - Method 4: `sudo defaults read "/Library/Managed Preferences/com.macjediwizard.jamfconnectmonitor"`
- **Verification:** Company name now correctly displays configured company name instead of "Your Company"
- **Impact:** Configuration Profile integration now works consistently across all components

#### **Critical Issue 3: Extension Attribute Auto-Version Detection**
- **Problem:** Version detection was hardcoded and monitoring mode displayed as empty
- **Root Cause:** Extension Attribute script lacked dynamic version detection from main script
- **Solution:** Implemented auto-detection system that reads VERSION variable from main script
- **Enhanced Monitoring Mode Detection:** Robust Configuration Profile parsing with multiple fallback strategies
- **Verification:** Extension Attribute now shows proper version, mode, and company information
- **Impact:** Future-proof version management - works automatically with v2.0.2, v2.1.0, v3.0.0+

### Added

#### **New Production Tools**
- **tools/verify_monitoring.sh** - Comprehensive verification script for production deployments
  - Tests all critical components (main script, Extension Attribute, permissions, Configuration Profile)
  - Validates ACL clearing and script execution capabilities
  - Provides detailed diagnostic output for troubleshooting
  - Verifies version detection and Configuration Profile integration
  - Usage: `sudo ./tools/verify_monitoring.sh`

#### **Enhanced Uninstall Script (`scripts/uninstall_script.sh`)**
- **Complete System Removal** - Removes all components including new v2.0.1 enhancements
- **Configuration Backup** - Preserves approved admin lists and settings with `.uninstall_backup` suffix
- **Log Archiving** - Archives all logs to timestamped directory before removal
- **Verification Mode** - `sudo ./uninstall_script.sh verify` to check removal completeness
- **Silent Operation** - `sudo ./uninstall_script.sh --force` for automated mass uninstallation
- **Package Receipt Cleanup** - Removes all package identifiers from system database
- **ACL and Extended Attribute Cleanup** - Comprehensive system state restoration
- **Multiple Package ID Support** - Handles legacy and current package identifiers
- **Jamf Pro Integration** - Triggers inventory update after removal

#### **Future-Proof Version Management Architecture**
- **Centralized Version Reference** - All components read from single VERSION variable in main script
- **Auto-Detection System** - Extension Attribute automatically detects version without hardcoding
- **Package Creation Sync** - Package version auto-extracts from main script
- **Smart Group Compatibility** - Flexible criteria work with all future v2.x+ versions
- **Zero Maintenance** - No version updates needed in Extension Attribute for future releases

### Enhanced

#### **Extension Attribute (`jamf/extension-attribute.sh`)**
- **Robust Configuration Profile Parsing** - Multiple extraction methods with comprehensive fallback logic
- **Auto-Version Detection** - Dynamically reads version from main script installation
- **Enhanced Monitoring Mode Detection** - Pattern matching for "periodic", "realtime", or "hybrid" keywords
- **Better Error Handling** - Graceful degradation when Configuration Profile unavailable
- **Production-Tested Output Format** - Verified working with enterprise Jamf Pro environments

#### **Main Monitor Script (`scripts/jamf_connect_monitor.sh`)**
- **Standardized Configuration Profile Access** - Uses same proven methods as Extension Attribute
- **Enhanced Error Logging** - Better diagnostic information for troubleshooting
- **Improved Company Name Display** - Correctly reads and displays from Configuration Profile
- **Consistent Method Implementation** - Unified approach across all script components

#### **Package Creation (`scripts/package_creation_script.sh`)**
- **ACL Prevention** - Ensures clean file permissions during package creation
- **Enhanced Verification** - Comprehensive component validation before package build
- **Production Documentation** - Detailed deployment instructions for enterprise environments
- **Checksum Generation** - Automatic SHA256 verification for package integrity

#### **Postinstall Script (`scripts/postinstall_script.sh`)**
- **Comprehensive ACL Clearing** - `xattr -c` for all installed scripts and configuration files
- **Enhanced Permission Setting** - Ensures proper execution permissions for all components
- **Configuration Validation** - Verifies Configuration Profile accessibility after installation
- **Production Logging** - Detailed installation logs for enterprise troubleshooting

### Technical Details

#### **Configuration Profile Integration Fixes**
```bash
# BEFORE (v2.0.0 - FAILING):
Company Name: "Your Company" (fallback value)
Configuration: Profile: Not Deployed (false negative)

# AFTER (v2.0.1 - WORKING):
Company Name: "[Configured Company Name]" (actual Configuration Profile value)
Configuration: Profile: Deployed, Mode: periodic, Company: [Configured Company Name]
```

#### **ACL Clearing Implementation**
```bash
# Postinstall script now includes:
xattr -c /usr/local/bin/jamf_connect_monitor.sh
xattr -c /usr/local/etc/jamf_ea_admin_violations.sh
xattr -c /usr/local/etc/approved_admins.txt
xattr -c /usr/local/share/jamf_connect_monitor/uninstall_script.sh

# Result: Clean permissions without @ symbols
-rwxr-xr-x  root  wheel  jamf_ea_admin_violations.sh  (no @ symbol)
```

#### **Future-Proof Version Architecture**
```bash
# Main Script: VERSION="2.0.1"
#      ↓
# Extension Attribute: get_version_from_main_script() auto-detects
#      ↓  
# Package Creation: Auto-extracts from main script
#      ↓
# All Components: Use centralized version reference
```

### Compatibility

#### **Seamless Upgrade Path**
- **v2.0.0 → v2.0.1** - Automatic upgrade preserving all existing configurations
- **Configuration Profile Preservation** - All existing webhook/email settings maintained
- **Smart Group Migration** - Existing Smart Groups work immediately with enhanced data
- **Zero Downtime** - Monitoring continues during upgrade process

#### **Enterprise Environment Verification**
- **Enterprise Production Environment** - All fixes verified working in production Jamf Pro setup
- **Configuration Profile Active** - Confirmed working with enterprise managed preferences
- **Extension Attribute Population** - Verified correct data display in Jamf Pro computer records
- **Smart Group Automation** - Confirmed proper population with flexible v2.x criteria

### Security

#### **Enhanced System Integrity**
- **ACL Management** - Prevents macOS Extended Attribute interference with script execution
- **Configuration Profile Security** - Robust reading methods prevent credential exposure
- **Permission Validation** - Comprehensive verification of all component permissions
- **Clean Uninstallation** - Complete system state restoration with security preservation

### Documentation

#### **New Documentation Added**
- **tools/verify_monitoring.sh** - Production verification script with comprehensive testing
- **Enhanced Uninstall Guide** - Complete removal procedures with verification steps
- **Production Deployment Guide** - Enterprise-specific deployment procedures
- **Troubleshooting Enhancements** - ACL clearing and Configuration Profile debugging

#### **Updated Documentation**
- **Installation Guide** - Enhanced with ACL clearing procedures and verification steps
- **Jamf Pro Deployment Guide** - Updated with v2.0.1 production fixes and verification procedures
- **Smart Groups Guide** - Enhanced with future-proof criteria design
- **CLI Reference** - Updated with new verification and uninstall options

### Migration

#### **Automatic Migration Features**
- **Configuration Preservation** - All v2.0.0 settings automatically preserved
- **Enhanced Functionality** - New capabilities enabled without configuration changes
- **Smart Group Compatibility** - Existing Smart Groups work better with enhanced data format
- **Production Continuity** - Zero interruption to monitoring during upgrade

#### **Verification and Validation**
- **Built-in Testing** - New verification script validates all components after upgrade
- **Comprehensive Diagnostics** - Tools to verify ACL clearing and Configuration Profile integration
- **Enterprise Validation** - Production-tested in enterprise environments

## [2.0.0] - 2025-07-14

### 🚀 **Major Release: Configuration Profile Management & Real-time Monitoring**

### Added
- **Configuration Profile Support**
  - JSON Schema for Jamf Pro Application & Custom Settings deployment
  - Centralized webhook/email management via Jamf Pro interface
  - No more hardcoded credentials in scripts
  - Real-time configuration updates without script modifications
  - Domain: `com.macjediwizard.jamfconnectmonitor`

- **Real-time Monitoring Capabilities**
  - Immediate violation detection using log streaming
  - Event-driven architecture instead of polling
  - Continuous admin group change monitoring
  - Jamf Protect-like real-time response capabilities
  - Configurable monitoring modes: periodic/realtime/hybrid

- **Enhanced Notification System**
  - Professional notification templates (simple/detailed/security_report)
  - Company branding support in all notifications
  - Rate limiting and cooldown periods
  - Enhanced webhook payloads with rich formatting
  - Comprehensive email reports with incident details

- **Advanced Jamf Pro Integration**
  - Enhanced Extension Attribute with Configuration Profile status reporting
  - Smart Group automation for enterprise workflows
  - Automated policy triggers on violations
  - Real-time inventory updates
  - Performance and health metrics reporting

- **Enterprise Security Features**
  - Configurable grace periods for legitimate elevations
  - Advanced security settings and compliance options
  - Excluded system accounts management
  - Detailed audit trails with system context
  - SIEM-ready structured logging

- **JSON Schema Documentation**
  - Complete Jamf Pro deployment schema
  - User-friendly configuration interface
  - Field validation and help text
  - Default value recommendations
  - Property ordering for optimal user experience

### Enhanced
- **Main Monitor Script (`scripts/jamf_connect_monitor.sh`)**
  - Complete rewrite for Configuration Profile integration
  - Real-time monitoring capability addition
  - Enhanced error handling and logging
  - New CLI commands: `test-config`, enhanced `status`
  - Backward compatibility with v1.x approved admin lists

- **Extension Attribute (`jamf/extension-attribute.sh`)**
  - v2.0.0 status reporting format
  - Configuration Profile deployment status
  - Real-time monitoring status detection
  - Enhanced Smart Group compatibility
  - Comprehensive health metrics reporting

- **Package Creation (`scripts/package_creation_script.sh`)**
  - JSON Schema inclusion in package
  - Enhanced documentation generation
  - Configuration Profile deployment instructions
  - Version 2.0.0 metadata and branding
  - Improved build verification and testing

### Changed
- **Breaking Change:** Configuration Profile domain standardized to `com.macjediwizard.jamfconnectmonitor`
- **Package Version:** Updated to 2.0.0 with Configuration Profile support
- **Notification Format:** Enhanced templates with professional security reporting
- **Extension Attribute Format:** New data structure for v2.0.0 Smart Group compatibility
- **Documentation Structure:** Complete reorganization for Configuration Profile deployment

### Fixed
- **Configuration Persistence:** Settings now managed via Configuration Profiles instead of hardcoded values
- **Real-time Detection:** Immediate violation response instead of 5-minute delays
- **Notification Reliability:** Rate limiting prevents spam during multiple violations
- **Smart Group Data:** Enhanced Extension Attribute format for better Jamf Pro integration
- **Installation Robustness:** Improved package creation with comprehensive validation

### Security
- **Enhanced Credential Management:** Webhook URLs and email addresses managed via encrypted Configuration Profiles
- **Real-time Response:** Immediate violation detection and remediation
- **Audit Trail Improvements:** Comprehensive logging with system context and user information
- **Tamper Resistance:** Configuration Profile protection against unauthorized modifications

### Documentation
- **New Guides Added:**
  - Configuration Profile deployment instructions
  - JSON Schema documentation
  - Real-time monitoring setup guide
  - Enterprise deployment strategies
  - Smart Group automation workflows

- **Updated Guides:**
  - Complete installation guide rewrite
  - Enhanced Jamf Pro deployment documentation
  - Troubleshooting guide expansion
  - CLI reference updates for v2.0.0 features

### Migration
- **Automatic Upgrade:** v1.x installations automatically migrate to v2.0.0
- **Configuration Preservation:** Approved admin lists and settings preserved during upgrade
- **Backward Compatibility:** v1.x Extension Attribute data remains functional
- **Zero Downtime:** Seamless upgrade without monitoring interruption

## [1.0.2] - 2025-07-11

### Added
- **Documentation Improvements**
  - Complete CLI reference guide (docs/cli-reference.md)
  - Comprehensive installation guide (docs/installation-guide.md) 
  - Detailed Jamf Pro deployment guide (docs/jamf-pro-deployment.md)
  - Enhanced README with corrected documentation links
  - Professional MacJediWizard branding throughout

### Fixed
- **Package Creation Issues**
  - Fixed Extension Attribute script path resolution in package builds
  - Improved package creation reliability with fallback logic
  - Enhanced build process with better component verification
  - Corrected package version numbering

### Changed
- **Documentation Structure**
  - Renamed "API Reference" to "CLI Reference" for accuracy
  - Consolidated deployment guides to prevent duplication
  - Improved file structure with proper build artifact exclusion
  - Enhanced professional presentation and consistency

## [1.0.1] - 2025-07-11

### Added
- Enhanced documentation suite with CLI reference
- Improved package creation reliability
- Professional branding implementation

### Fixed
- LaunchDaemon filename mismatch between scripts and plists
- Extension Attribute script permissions in package creation
- Jamf Connect elevation detection for nested configuration values
- Boolean comparison logic for configuration reading

## [1.0.0] - 2025-07-10

### Added
- **Core Features**
  - Real-time Jamf Connect elevation monitoring
  - Automated unauthorized admin account detection and removal
  - Comprehensive audit logging system
  - Approved administrator whitelist management
  
- **Jamf Pro Integration**
  - Extension Attribute for violation reporting
  - Smart Group compatibility
  - Silent deployment via policies
  - Inventory integration
  
- **Monitoring & Logging**
  - Real-time log monitoring via `log show` and `log stream`
  - Dedicated log files for different event types
  - Structured logging for SIEM integration
  - Log rotation and retention management
  
- **Notification System**
  - Slack/Teams webhook support
  - Email notification capability
  - Customizable alert templates
  - Installation success notifications
  
- **Command Line Interface**
  - Status checking and reporting
  - Approved admin list management
  - Manual violation checking
  - Comprehensive help system
  
- **Automated Deployment**
  - One-click deployment script
  - Jamf Pro package creation
  - Silent installation with configuration
  - Pre/post-installation automation
  
- **Security Features**
  - Tamper-resistant design
  - Root privilege requirement
  - Secure configuration file handling
  - Protected log file access

### Security
- All scripts run with minimal required privileges
- Secure handling of sensitive configuration data
- Protected log file permissions
- Validation of all user inputs

### Documentation
- Complete installation and configuration guide
- Jamf Pro deployment instructions
- Troubleshooting documentation
- Community contribution guidelines

## [0.1.0] - 2025-07-08

### Added
- Initial project conception and planning
- Core script development
- Basic Jamf Connect integration research
- Proof of concept testing

---

## Version History Summary

- **2.2.0**: **BREAKING CHANGE** - Removed unreliable system mail fallback, SMTP-only email delivery
- **2.1.0**: Enhanced SMTP authentication with port 465 SSL support and password security
- **2.0.1**: **PRODUCTION READY** - ACL clearing, Configuration Profile fixes, auto-version detection, verification tools
- **2.0.0**: Configuration Profile management, real-time monitoring, enterprise features
- **1.0.2**: Documentation improvements and package creation fixes
- **1.0.1**: Enhanced documentation and professional branding
- **1.0.0**: Full production release with complete feature set
- **0.1.0**: Initial development and testing phase

## Upgrade Path

### From v2.0.0 to v2.0.1 (CRITICAL PRODUCTION FIXES)
1. **Upload v2.0.1 package** - Seamless upgrade with ACL clearing and Configuration Profile fixes
2. **Update Extension Attribute script** - MOST IMPORTANT: Enables proper version display and Configuration Profile integration
3. **Deploy verification script** - Use `tools/verify_monitoring.sh` to validate all components
4. **Verify Smart Groups** - Confirm proper population with enhanced monitoring mode display
5. **Configuration Profile validation** - Verify company name displays correctly (not "Your Company")

### From v1.x to v2.0.1 (RECOMMENDED UPGRADE PATH)
1. **Deploy v2.0.1 package** - Automatic migration with all production fixes included
2. **Deploy Configuration Profile** - Enable centralized management features
3. **Update Extension Attribute** - Enhanced Smart Group compatibility with auto-version detection
4. **Configure real-time monitoring** - Optional immediate detection capabilities
5. **Use verification tools** - Validate complete deployment with included diagnostic script

### Configuration Profile Migration
v2.0.0+ introduces Configuration Profile management for:
- Webhook URLs (no more hardcoded credentials)
- Email notification settings
- Monitoring behavior configuration
- Company branding and contact information
- Advanced security and compliance settings

## Breaking Changes

### v2.0.1
- **No Breaking Changes:** Seamless upgrade from v2.0.0 with all configuration preservation
- **Enhanced Functionality:** All fixes improve existing features without removing capabilities
- **Future-Proof Design:** Auto-version detection works with all future v2.x+ releases

### v2.0.0
- **Configuration Profile Domain:** New domain `com.macjediwizard.jamfconnectmonitor`
- **Extension Attribute Format:** Enhanced data structure for Smart Groups
- **Package Identifier:** Updated to reflect v2.0.0 capabilities
- **Notification Templates:** New format with enhanced security reporting

**Migration Impact:** Automatic - existing installations upgrade seamlessly with configuration preservation.

## Uninstall Script Features (New in v2.0.1)

### Complete System Removal
The enhanced uninstall script provides enterprise-grade removal capabilities:

#### **Comprehensive Component Removal**
```bash
# Components Removed:
- /usr/local/bin/jamf_connect_monitor.sh (main monitoring script)
- /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist (daemon)
- /usr/local/etc/approved_admins.txt (configuration files)
- /usr/local/share/jamf_connect_monitor/ (application directory)
- /var/log/jamf_connect_monitor/ (archived before removal)
- Package receipts and system cache entries
```

#### **Data Preservation Features**
```bash
# What's Preserved:
- Log Archives: /var/log/jamf_connect_monitor_archive_[timestamp]/
- Configuration Backups: *.uninstall_backup.[timestamp] files
- Approved admin lists backed up before removal
```

#### **Usage Options**
```bash
# Interactive uninstall with confirmation prompts
sudo ./uninstall_script.sh

# Silent uninstall for mass deployment  
sudo ./uninstall_script.sh --force

# Verify complete removal
sudo ./uninstall_script.sh verify
```

#### **Enterprise Integration**
- **Jamf Pro Inventory Updates** - Triggers inventory collection after removal
- **Notification Support** - Sends uninstall confirmation via configured webhooks
- **Multiple Package ID Support** - Handles all legacy and current package identifiers
- **Process Cleanup** - Ensures all monitoring processes are stopped before removal

## Production Verification Tools (New in v2.0.1)

### Comprehensive Monitoring Verification
The new verification script provides enterprise-grade testing capabilities:

#### **tools/verify_monitoring.sh Features**
```bash
# Usage:
sudo ./tools/verify_monitoring.sh

# Tests Include:
✅ Main script installation and version detection
✅ Extension Attribute script installation and execution
✅ File permissions and ACL clearing verification  
✅ Configuration Profile integration testing
✅ Version auto-detection validation
✅ Company name display verification
✅ Monitoring mode detection testing
```

#### **Production Validation Results**
```bash
# Example Output:
🔍 JAMF CONNECT MONITOR VERIFICATION v2.0.1
✅ Main script installed: Version 2.0.1
✅ Permissions correct: -rwxr-xr-x (no @ symbols)
✅ Extension Attribute script installed: Version 2.0.1  
✅ EA permissions correct: -rwxr-xr-x (no @ symbols)
✅ Extension Attribute runs successfully
✅ Version detected: Version: 2.0.1, Periodic: Running
✅ Monitoring mode detected: Mode: periodic
✅ Company name: [Your Company Name]/(from Configuration Profile)
🎉 MONITORING APPEARS TO BE WORKING CORRECTLY
```

#### **Enterprise Deployment Integration**
- **Post-Installation Validation** - Run after package deployment to verify success
- **Troubleshooting Support** - Identifies specific issues with detailed diagnostics
- **Jamf Pro Integration** - Can be deployed as script for automated validation
- **Production Testing** - Verified working in enterprise environments

## Support

For issues, feature requests, or support:
- **GitHub Issues**: [Report bugs or request features](https://github.com/MacJediWizard/jamf-connect-monitor/issues)
- **Documentation**: [Complete guides in docs/](https://github.com/MacJediWizard/jamf-connect-monitor/tree/main/docs)
- **Production Issues**: Use included verification script for immediate diagnostics

---

**Note**: This changelog follows the [Keep a Changelog](https://keepachangelog.com/) format. Each version includes Added, Changed, Deprecated, Removed, Fixed, and Security sections as applicable.

**v2.0.1 Status**: ✅ **PRODUCTION READY** - All critical fixes verified working in enterprise environment