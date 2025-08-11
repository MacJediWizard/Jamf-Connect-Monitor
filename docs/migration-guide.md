# Migration Guide: v1.x to v2.x & Within v2.x Versions

## Overview
This guide covers migration paths for upgrading to and within the v2.x series of Jamf Connect Monitor, including automatic upgrades, configuration preservation, and critical v2.4.0 production fixes.

## Migration Paths

### v1.x → v2.4.0 (Major Upgrade)
- **From:** v1.0.0, v1.0.1, v1.0.2
- **To:** v2.4.0 (recommended latest with production fixes)
- **Type:** Major upgrade with Configuration Profile features and critical fixes

### v2.x → v2.x (Patch Updates)
- **Within v2.x series:** v2.4.0 → v2.4.0 → v2.0.2+
- **Type:** Seamless updates with configuration preservation and enhanced features

## Quick Migration Summary

### v1.x to v2.4.0 Migration Steps
1. **Deploy v2.4.0 Package** - Automatic migration of existing installations
2. **Add Configuration Profile** - Enable centralized management
3. **Update Extension Attribute** - Critical for v2.4.0 compatibility
4. **Create Future-Proof Smart Groups** - Use flexible "Version: 2." criteria
5. **Test and Validate** - Verify functionality with production fixes

### v2.4.0 to v2.4.0 Migration Steps (CRITICAL FIXES)
1. **Upload v2.4.0 package** - Seamless upgrade with automatic fixes
2. **Update Extension Attribute script** - REQUIRED for proper v2.4.0 functionality
3. **Deploy to existing systems** - Automatic ACL clearing and enhanced parsing
4. **Verify Smart Groups** - Confirm improved data format population

## Critical v2.4.0 Production Fixes

### Automatic ACL Clearing
- **Issue:** Script execution failures due to Extended Attributes
- **Fix:** Postinstall script automatically clears all ACLs
- **Result:** Eliminates @ symbols in file permissions

### Enhanced Configuration Profile Parsing
- **Issue:** Extension Attribute showed "Company: Your Company" fallback
- **Fix:** Robust parsing displays actual configured company names
- **Result:** Professional branding in all Extension Attribute data

### Future-Proof Version Detection
- **Issue:** Version detection required manual updates
- **Fix:** Automatic detection of all v2.x+ versions
- **Result:** Zero maintenance for future version updates

## Detailed Migration Instructions

### From v1.x to v2.4.0

#### Phase 1: Preparation (30 minutes)
```bash
# 1. Backup current approved admin lists
sudo cp /usr/local/etc/approved_admins.txt /usr/local/etc/approved_admins.txt.v1_backup

# 2. Export current configuration
sudo jamf_connect_monitor.sh status > monitor_status_v1.txt

# 3. Note current admin violations (if any)
sudo tail -20 /var/log/jamf_connect_monitor/admin_violations.log
```

#### Phase 2: Deploy v2.4.0 Package (1 hour)
```bash
# 1. Build v2.4.0 package
sudo ./scripts/package_creation_script.sh build
# Creates: output/JamfConnectMonitor-2.4.0.pkg

# 2. Upload to Jamf Pro
# - Upload package via Settings → Packages
# - Create deployment policy
# - Target existing v1.x installations
```

#### Phase 3: Configuration Profile Setup (2 hours)
```bash
# 1. Deploy Configuration Profile using JSON Schema
# 2. Configure centralized webhook/email settings
# 3. Update Extension Attribute script in Jamf Pro (CRITICAL)
# 4. Create future-proof Smart Groups with flexible criteria
```

#### Phase 4: Testing and Validation (2 hours)
```bash
# 1. Deploy to pilot group (5-10 machines)
# 2. Verify upgrade success with v2.4.0 fixes
sudo jamf_connect_monitor.sh status | grep "Version: 2.4.0"

# 3. Test Configuration Profile integration (should show actual company name)
sudo jamf_connect_monitor.sh test-config | grep "Company Name:" | grep -v "Your Company"

# 4. Verify ACL clearing (no @ symbols)
ls -la@ /usr/local/bin/jamf_connect_monitor.sh | grep -v '@'

# 5. Test Extension Attribute with v2.4.0 enhancements
sudo /usr/local/etc/jamf_ea_admin_violations.sh | grep "Version: 2.4.0"

# 6. Verify Smart Group population with future-proof criteria
# Check Jamf Pro → Smart Groups → membership
```

### From v2.4.0 to v2.4.0 (Critical Production Fixes)

#### Quick Upgrade Process (1 hour)
```bash
# 1. Upload v2.4.0 package to Jamf Pro
# 2. Update Extension Attribute script (CRITICAL for v2.4.0)
# 3. Deploy via existing policy
# 4. Verify production fixes applied automatically
```

#### v2.4.0 Critical Fixes Verification
```bash
# Test ACL clearing (should show no @ symbols)
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
ls -la@ /usr/local/etc/jamf_ea_admin_violations.sh

# Test enhanced Configuration Profile parsing (should show actual company name)
sudo jamf_connect_monitor.sh test-config | grep "Company Name:"

# Test future-proof version detection
sudo /usr/local/etc/jamf_ea_admin_violations.sh | grep "Version: 2.4.0"

# Verify Smart Groups populate with improved data format
# Check Jamf Pro computer records for Extension Attribute data
```

## What's Preserved During Migration

### Automatic Preservation
- ✅ **Approved admin lists** - `/usr/local/etc/approved_admins.txt`
- ✅ **Historical violation logs** - All files in `/var/log/jamf_connect_monitor/`
- ✅ **Monitoring functionality** - Continues during upgrade with improvements
- ✅ **LaunchDaemon settings** - Maintained with enhancements
- ✅ **Configuration Profiles** - Existing profiles work with enhanced parsing

### Enhanced After Migration to v2.4.0
- 🚀 **Automatic ACL clearing** - No more script execution permission issues
- 🚀 **Enhanced Configuration Profile parsing** - Actual company names displayed
- 🚀 **Future-proof version detection** - Automatic compatibility with all v2.x+ versions
- 🚀 **Improved Smart Group data** - Reliable Extension Attribute format
- 🚀 **Professional notifications** - Enhanced templates with actual branding

## Migration Testing Checklist

### Pre-Migration Validation
- [ ] Current monitoring is functioning
- [ ] Approved admin list is documented
- [ ] Jamf Pro access confirmed
- [ ] Test environment prepared

### Post-Migration v2.4.0 Verification
- [ ] **Version Check:** `sudo jamf_connect_monitor.sh status | grep "Version: 2.4.0"`
- [ ] **ACL Clearing:** `ls -la@ /usr/local/bin/jamf_connect_monitor.sh | grep -v '@'`
- [ ] **Configuration Profile:** Actual company name displays (not "Your Company")
- [ ] **Extension Attribute:** Shows "Version: 2.4.0" automatically
- [ ] **Smart Groups:** Population with future-proof criteria
- [ ] **Notifications:** Test webhook/email delivery with actual branding
- [ ] **Approved Admins:** List preserved and functional

## Version-Specific Migration Notes

### v2.4.0 Specific Improvements
```bash
# BEFORE (v2.4.0 - Issues):
# - ACL @ symbols caused script execution failures
# - Extension Attribute showed "Company: Your Company" fallback
# - Version detection required manual maintenance

# AFTER (v2.4.0 - Fixed):
# - Automatic ACL clearing eliminates permission issues
# - Enhanced parsing shows actual configured company names
# - Future-proof design works automatically with all v2.x+ versions
```

### v2.4.0 Foundation Features
- Initial Configuration Profile support
- Real-time monitoring capabilities
- JSON Schema for Jamf Pro deployment
- Enhanced notification templates

## Troubleshooting Migration Issues

### Common v1.x → v2.4.0 Issues

#### Extension Attribute Not Updating
```bash
# CRITICAL: Update Extension Attribute script in Jamf Pro for v2.4.0
# Navigate: Settings → Computer Management → Extension Attributes
# Edit script content with v2.4.0 enhanced version

# Force inventory update
sudo jamf recon

# Verify script permissions (should have no ACL @ symbols)
ls -la@ /usr/local/etc/jamf_ea_admin_violations.sh
```

#### Configuration Profile Not Showing Actual Company Name
```bash
# This is fixed automatically in v2.4.0
# Verify Configuration Profile deployment
sudo profiles list | grep jamfconnectmonitor

# Test enhanced parsing
sudo jamf_connect_monitor.sh test-config | grep "Company Name:"
# Should show actual configured name, not "Your Company"
```

#### Smart Groups Not Populating
- **Use flexible criteria:** "Version: 2." instead of "Version: 2.0.0"
- **Update Extension Attribute script** in Jamf Pro (CRITICAL for v2.4.0)
- **Check Extension Attribute data format:** Ensure it matches Smart Group criteria
- **Allow time for inventory updates:** Smart Groups update after inventory collection

### Common v2.4.0 → v2.4.0 Issues

#### Script Execution Permission Errors
This is exactly what v2.4.0 fixes automatically:
```bash
# v2.4.0 automatically clears ACLs during installation
# Verify fix applied:
ls -la@ /usr/local/bin/jamf_connect_monitor.sh
# Should show no @ symbol at end of permissions

# Manual fix if needed:
sudo xattr -c /usr/local/bin/jamf_connect_monitor.sh
sudo xattr -c /usr/local/etc/jamf_ea_admin_violations.sh
```

#### Company Name Shows "Your Company" Fallback
```bash
# v2.4.0 enhanced parsing fixes this automatically
# Deploy v2.4.0 package and verify:
sudo jamf_connect_monitor.sh test-config | grep "Company Name:"
# Should show actual configured company name

# Update Extension Attribute script in Jamf Pro for full fix
```

## Performance Considerations

### Resource Usage During Migration
- **v1.x → v2.4.0:** Minimal impact, mainly configuration enhancements
- **v2.4.0 → v2.4.0:** Zero impact, only parsing and permission improvements
- **Real-time monitoring:** Optional feature, enable gradually

### Network and Storage
- **Log retention:** Historical logs preserved with enhanced format
- **Configuration download:** Configuration Profiles work better with enhanced parsing
- **Package deployment:** Standard Jamf Pro package distribution

## Migration Timeline Recommendations

### Small Environment (< 100 devices)
- **Week 1:** Prepare and test v2.4.0 migration
- **Week 2:** Deploy to pilot group
- **Week 3:** Full deployment with production fixes
- **Week 4:** Validation and optimization

### Large Environment (> 1000 devices)
- **Month 1:** Planning and pilot testing with v2.4.0 fixes
- **Month 2:** Phased deployment (25% per week)
- **Month 3:** Full deployment completion
- **Month 4:** Optimization and advanced feature rollout

### Enterprise Environment (> 5000 devices)
- **Quarter 1:** Planning, testing, and initial rollout with production fixes
- **Quarter 2:** Full deployment with enhanced Configuration Profile integration
- **Quarter 3:** Advanced features and performance optimization
- **Quarter 4:** Integration with broader security infrastructure

## Best Practices for Migration

### Planning Phase
- **Document current configuration** before migration
- **Test v2.4.0 in isolated environment** first
- **Plan for automatic fixes** (ACL clearing, enhanced parsing)
- **Create future-proof Smart Groups** using flexible criteria
- **Communicate enhanced features** to stakeholders

### Execution Phase
- **Start with pilot group** of willing participants
- **Monitor system performance** during rollout
- **Verify v2.4.0 fixes applied** (ACL clearing, company names)
- **Update Extension Attribute script** in Jamf Pro (CRITICAL)
- **Document any environment-specific issues**

### Post-Migration Phase
- **Validate all functionality** with v2.4.0 enhancements
- **Train administrators** on enhanced Configuration Profile features
- **Optimize real-time monitoring** settings based on usage
- **Plan for future v2.x updates** using flexible Smart Groups

## Future Migration Planning

### Preparing for Future v2.x Updates
- **Use flexible Smart Group criteria** ("Version: 2." catches all 2.x automatically)
- **Keep Configuration Profiles generic** for forward compatibility
- **Leverage v2.4.0 future-proof design** for automatic version updates
- **Monitor release notes** for version-specific features
- **Plan regular update cycles** for patch releases

### Version Strategy Recommendations
- **Stay current** with latest v2.x for best production fixes
- **Test patches** in pilot environment before full deployment
- **Use semantic versioning** awareness for planning updates
- **Maintain documentation** of environment-specific configurations
- **Leverage future-proof architecture** for zero-maintenance upgrades

---

## Migration Support Resources

- **GitHub Issues:** [Report migration problems](https://github.com/MacJediWizard/jamf-connect-monitor/issues)
- **Documentation:** [Complete guides](https://github.com/MacJediWizard/jamf-connect-monitor/tree/main/docs)

---

**Created with ❤️ by MacJediWizard**

**Seamless migration paths with v2.4.0 production fixes, configuration preservation, and future-proof design.**