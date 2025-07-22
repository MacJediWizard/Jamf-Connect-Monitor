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

- **2.0.0**: Configuration Profile management, real-time monitoring, enterprise features
- **1.0.2**: Documentation improvements and package creation fixes
- **1.0.1**: Enhanced documentation and professional branding
- **1.0.0**: Full production release with complete feature set
- **0.1.0**: Initial development and testing phase

## Upgrade Path

### From v1.x to v2.0.0
1. **Deploy v2.0.0 package** - Automatic migration of existing installations
2. **Deploy Configuration Profile** - Enable centralized management features
3. **Update Extension Attribute** - Enhanced Smart Group compatibility
4. **Configure real-time monitoring** - Optional immediate detection capabilities

### Configuration Profile Migration
v2.0.0 introduces Configuration Profile management for:
- Webhook URLs (no more hardcoded credentials)
- Email notification settings
- Monitoring behavior configuration
- Company branding and contact information
- Advanced security and compliance settings

## Breaking Changes

### v2.0.0
- **Configuration Profile Domain:** New domain `com.macjediwizard.jamfconnectmonitor`
- **Extension Attribute Format:** Enhanced data structure for Smart Groups
- **Package Identifier:** Updated to reflect v2.0.0 capabilities
- **Notification Templates:** New format with enhanced security reporting

**Migration Impact:** Automatic - existing installations upgrade seamlessly with configuration preservation.

## Support

For issues, feature requests, or support:
- **GitHub Issues**: [Report bugs or request features](https://github.com/MacJediWizard/jamf-connect-monitor/issues)
- **Documentation**: [Complete guides in docs/](https://github.com/MacJediWizard/jamf-connect-monitor/tree/main/docs)
- **Discussions**: [Community discussions](https://github.com/MacJediWizard/jamf-connect-monitor/discussions)

---

**Note**: This changelog follows the [Keep a Changelog](https://keepachangelog.com/) format. Each version includes Added, Changed, Deprecated, Removed, Fixed, and Security sections as applicable.