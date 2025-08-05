# Migration Guide: v1.x to v2.x & Within v2.x Versions

## Overview
This guide covers migration paths for upgrading to and within the v2.x series of Jamf Connect Monitor, including automatic upgrades and configuration preservation.

## Migration Paths

### v1.x → v2.x (Major Upgrade)
- **From:** v1.0.0, v1.0.1, v1.0.2
- **To:** v2.0.1 (recommended) or latest v2.x
- **Type:** Major upgrade with new Configuration Profile features

### v2.x → v2.x (Patch Updates)
- **Within v2.x series:** v2.0.0 → v2.0.1 → v2.0.2, etc.
- **Type:** Seamless updates with configuration preservation

## Quick Migration Summary

### v1.x to v2.x Migration Steps
1. **Update Project Files** - Deploy v2.x components
2. **Build v2.x Package** - Create deployment package
3. **Deploy to Jamf Pro** - Upload and configure
4. **Add Configuration Profile** - Enable centralized management
5. **Test and Validate** - Verify functionality

### v2.0.0 to v2.0.1+ Migration Steps
1. **Upload new package** - Seamless upgrade capability
2. **Update Extension Attribute** - Enhanced Configuration Profile parsing
3. **Deploy to existing systems** - Automatic upgrade
4. **Verify Smart Groups** - Confirm proper population

## Detailed Migration Instructions

### From v1.x to v2.x

#### Phase 1: Preparation (30 minutes)
```bash
# 1. Backup current approved admin lists
sudo cp /usr/local/etc/approved_admins.txt /usr/local/etc/approved_admins.txt.v1_backup

# 2. Export current configuration
sudo jamf_connect_monitor.sh status > monitor_status_v1.txt

# 3. Note current admin violations (if any)
sudo tail -20 /var/log/jamf_connect_monitor/admin_violations.log
```

#### Phase 2: Deploy v2.x Package (1 hour)
```bash
# 1. Build v2.x package
sudo ./scripts/package_creation_script.sh build
# Creates: output/JamfConnectMonitor-2.0.1.pkg (or latest)

# 2. Upload to Jamf Pro
# - Upload package via Settings → Packages
# - Create deployment policy
# - Target existing v1.x installations
```

#### Phase 3: Configuration Profile Setup (2 hours)
```bash
# 1. Deploy Configuration Profile using JSON Schema
# 2. Configure centralized webhook/email settings
# 3. Update Extension Attribute script in Jamf Pro
# 4. Create v2.x Smart Groups with flexible criteria
```

#### Phase 4: Testing and Validation (2 hours)
```bash
# 1. Deploy to pilot group (5-10 machines)
# 2. Verify upgrade success
sudo jamf_connect_monitor.sh status | grep "Version: 2."

# 3. Test Configuration Profile integration
sudo jamf_connect_monitor.sh test-config

# 4. Verify Smart Group population
# Check Jamf Pro → Smart Groups → membership
```

### From v2.0.0 to v2.0.1+ (Patch Update)

#### Quick Upgrade Process (1 hour)
```bash
# 1. Upload v2.0.1+ package to Jamf Pro
# 2. Update Extension Attribute script (CRITICAL for v2.0.1)
# 3. Deploy via existing policy
# 4. Verify Smart Group population improvements
```

#### Enhanced Configuration Profile Parsing (v2.0.1)
The main improvement in v2.0.1 is enhanced Configuration Profile parsing:
- **Before:** Empty "Mode:" field in Extension Attribute
- **After:** Proper "Mode: periodic" (or realtime/hybrid) display
- **Impact:** Smart Groups populate correctly

## What's Preserved During Migration

### Automatic Preservation
- ✅ **Approved admin lists** - `/usr/local/etc/approved_admins.txt`
- ✅ **Historical violation logs** - All files in `/var/log/jamf_connect_monitor/`
- ✅ **Monitoring functionality** - Continues during upgrade
- ✅ **LaunchDaemon settings** - Maintained with enhancements

### Enhanced After Migration
- 🚀 **Configuration Profile management** - Centralized webhook/email
- 🚀 **Real-time monitoring** - Immediate violation detection
- 🚀 **Professional notifications** - Enhanced templates with branding
- 🚀 **Advanced Jamf Pro integration** - Better Smart Groups, Extension Attribute

## Migration Testing Checklist

### Pre-Migration Validation
- [ ] Current monitoring is functioning
- [ ] Approved admin list is documented
- [ ] Jamf Pro access confirmed
- [ ] Test environment prepared

### Post-Migration Verification
- [ ] **Version Check:** `sudo jamf_connect_monitor.sh status | grep "Version: 2."`
- [ ] **Configuration Profile:** `sudo jamf_connect_monitor.sh test-config`
- [ ] **Extension Attribute:** Manual run shows proper data format
- [ ] **Smart Groups:** Population with v2.x criteria
- [ ] **Notifications:** Test webhook/email delivery
- [ ] **Approved Admins:** List preserved and functional

## Version-Specific Migration Notes

### v2.0.1 Specific Improvements
```bash
# Enhanced Configuration Profile parsing
# BEFORE (v2.0.0 - BROKEN):
# Mode: (empty field)

# AFTER (v2.0.1 - FIXED):  
# Mode: periodic (proper display enables Smart Group automation)
```

### v2.0.0 Major Features
- Initial Configuration Profile support
- Real-time monitoring capabilities
- JSON Schema for Jamf Pro deployment
- Enhanced notification templates

## Troubleshooting Migration Issues

### Common v1.x → v2.x Issues

#### Extension Attribute Not Updating
```bash
# Update Extension Attribute script in Jamf Pro
# Force inventory update
sudo jamf recon

# Verify script permissions
ls -la /usr/local/etc/jamf_ea_admin_violations.sh
```

#### Configuration Profile Not Applying
```bash
# Force profile renewal
sudo profiles renew -type=config

# Check profile status
sudo profiles list | grep jamfconnectmonitor

# Test configuration reading
sudo defaults read com.macjediwizard.jamfconnectmonitor
```

#### Smart Groups Not Populating
- **Use flexible criteria:** "Version: 2." instead of "Version: 2.0.0"
- **Check Extension Attribute data format:** Ensure it matches Smart Group criteria
- **Allow time for inventory updates:** Smart Groups update after inventory collection

### Common v2.0.0 → v2.0.1 Issues

#### Empty Monitoring Mode Field
This is exactly what v2.0.1 fixes:
```bash
# Deploy v2.0.1 package
# Update Extension Attribute script in Jamf Pro (CRITICAL)
# Force inventory update: sudo jamf recon
```

## Performance Considerations

### Resource Usage During Migration
- **v1.x → v2.x:** Minimal impact, mainly configuration changes
- **v2.0.0 → v2.0.1:** Zero impact, only parsing improvements
- **Real-time monitoring:** Optional feature, enable gradually

### Network and Storage
- **Log retention:** Historical logs preserved during migration
- **Configuration download:** Configuration Profiles are small
- **Package deployment:** Standard Jamf Pro package distribution

## Migration Timeline Recommendations

### Small Environment (< 100 devices)
- **Week 1:** Prepare and test migration
- **Week 2:** Deploy to pilot group
- **Week 3:** Full deployment
- **Week 4:** Validation and optimization

### Large Environment (> 1000 devices)
- **Month 1:** Planning and pilot testing
- **Month 2:** Phased deployment (25% per week)
- **Month 3:** Full deployment completion
- **Month 4:** Optimization and advanced feature rollout

### Enterprise Environment (> 5000 devices)
- **Quarter 1:** Planning, testing, and initial rollout
- **Quarter 2:** Full deployment with department-specific configurations
- **Quarter 3:** Advanced features and optimization
- **Quarter 4:** Integration with broader security infrastructure

## Best Practices for Migration

### Planning Phase
- **Document current configuration** before migration
- **Test in isolated environment** first
- **Plan rollback procedures** (though v2.x upgrades are seamless)
- **Communicate with stakeholders** about enhanced features

### Execution Phase
- **Start with pilot group** of willing participants
- **Monitor system performance** during rollout
- **Gather feedback** on new Configuration Profile features
- **Document any environment-specific issues**

### Post-Migration Phase
- **Validate all functionality** is working
- **Train administrators** on Configuration Profile management
- **Optimize real-time monitoring** settings based on usage
- **Plan for future v2.x updates** using flexible Smart Groups

## Rollback Considerations

### v2.x → v1.x Rollback (Not Recommended)
- **Configuration Profiles** won't work with v1.x
- **Enhanced features** will be lost
- **Approved admin lists** can be restored from backups

### v2.0.1 → v2.0.0 Rollback (Unnecessary)
- **No breaking changes** in v2.0.1
- **Only improvements** to Configuration Profile parsing
- **No functionality removed**

## Future Migration Planning

### Preparing for Future v2.x Updates
- **Use flexible Smart Group criteria** ("Version: 2." catches all 2.x)
- **Keep Configuration Profiles generic** for forward compatibility
- **Monitor release notes** for version-specific features
- **Plan regular update cycles** for patch releases

### Version Strategy Recommendations
- **Stay current** with latest v2.x for best Configuration Profile parsing
- **Test patches** in pilot environment before full deployment
- **Use semantic versioning** awareness for planning updates
- **Maintain documentation** of environment-specific configurations

---

## Migration Support Resources

- **GitHub Issues:** [Report migration problems](https://github.com/MacJediWizard/jamf-connect-monitor/issues)
- **Documentation:** [Complete guides](https://github.com/MacJediWizard/jamf-connect-monitor/tree/main/docs)
- **Discussions:** [Community migration experiences](https://github.com/MacJediWizard/jamf-connect-monitor/discussions)

---

**Created with ❤️ by MacJediWizard**

**Seamless migration paths with configuration preservation and enhanced enterprise features.**