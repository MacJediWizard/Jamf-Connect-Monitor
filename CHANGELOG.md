# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced documentation suite with CLI reference
- Improved package creation reliability

## [1.0.1] - 2025-07-11

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
  - Corrected package version numbering to 1.0.1

### Changed
- **Documentation Structure**
  - Renamed "API Reference" to "CLI Reference" for accuracy
  - Consolidated deployment guides to prevent duplication
  - Improved file structure with proper build artifact exclusion
  - Enhanced professional presentation and consistency

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
  
- **Configuration Options**
  - Customizable monitoring intervals
  - Company-specific branding
  - Flexible notification settings
  - Environment-specific parameters

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

- **1.0.1**: Documentation improvements and package creation fixes
- **1.0.0**: Full production release with complete feature set
- **0.1.0**: Initial development and testing phase

## Support

For issues, feature requests, or support:
- **GitHub Issues**: [Report bugs or request features](https://github.com/MacJediWizard/jamf-connect-monitor/issues)
- **GitHub Discussions**: [Ask questions or discuss usage](https://github.com/MacJediWizard/jamf-connect-monitor/discussions)
- **Documentation**: [Check the wiki](https://github.com/MacJediWizard/jamf-connect-monitor/wiki)

---

**Note**: This changelog follows the [Keep a Changelog](https://keepachangelog.com/) format. Each version should include Added, Changed, Deprecated, Removed, Fixed, and Security sections as applicable.
