# Smart Groups Guide - v2.x

## Overview
Jamf Connect Monitor v2.x provides enhanced Extension Attribute data that enables powerful Smart Group automation for enterprise security monitoring workflows.

## Essential Smart Groups for v2.x (Flexible Criteria)

### Security Monitoring Groups

#### Jamf Connect Monitor - Installed v2.x
```
Name: Jamf Connect Monitor - Installed v2.x
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "Version: 2."
Purpose: Track all v2.x installations (2.0.0, 2.3.0, 2.0.2, etc.)
```

#### Jamf Connect Monitor - CRITICAL VIOLATIONS
```
Name: Jamf Connect Monitor - CRITICAL VIOLATIONS
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "Unauthorized:*"
AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" not like "*Unauthorized: 0*"
Purpose: Immediate security incident response
⚠️ CONFIGURE WEBHOOK ALERTS FOR THIS GROUP
```

#### Jamf Connect Monitor - Config Profile Active
```
Name: Jamf Connect Monitor - Config Profile Active
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Profile: Deployed*"
Purpose: Verify Configuration Profile deployment success across all v2.x installations
```

### Operational Groups

#### Jamf Connect Monitor - Real-time Active
```
Name: Jamf Connect Monitor - Real-time Active
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Real-time: Active*"
Purpose: Track real-time monitoring deployment and performance impact
```

#### Jamf Connect Monitor - Needs Attention
```
Name: Jamf Connect Monitor - Needs Attention
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Daemon: Not Running*"
OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Profile: Not Deployed*"
Purpose: Proactive maintenance and troubleshooting
```

#### Jamf Connect Monitor - Notifications Configured
```
Name: Jamf Connect Monitor - Notifications Configured
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Webhook: Configured*"
OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Email: Configured*"
Purpose: Verify notification system deployment
```

### Version-Specific Groups (Optional)

#### Jamf Connect Monitor - Latest Version (v2.3.0+)
```
Name: Jamf Connect Monitor - Latest Version
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Version: 2.3.0*"
OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Version: 2.0.2*"
Purpose: Track latest version deployments for specific features
```

#### Jamf Connect Monitor - Legacy v2.3.0
```
Name: Jamf Connect Monitor - Legacy v2.3.0
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Version: 2.0.0*"
Purpose: Identify systems needing upgrade to v2.3.0+ for enhanced parsing
```

### Monitoring Mode Groups

#### Jamf Connect Monitor - Periodic Mode
```
Name: Jamf Connect Monitor - Periodic Mode
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Mode: periodic*"
Purpose: Track traditional 5-minute interval monitoring
```

#### Jamf Connect Monitor - Real-time Mode
```
Name: Jamf Connect Monitor - Real-time Mode
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Mode: realtime*"
Purpose: Track immediate violation detection systems
```

#### Jamf Connect Monitor - Hybrid Mode
```
Name: Jamf Connect Monitor - Hybrid Mode
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Mode: hybrid*"
Purpose: Track systems with both periodic and real-time monitoring
```

## Automated Workflows

### Security Incident Response
1. **Critical Violations Smart Group** → **Policy Trigger** → **Immediate Investigation**
2. **Real-time Notification** → **Security Team Alert** → **User Contact**

### Deployment Tracking
1. **Configuration Profile Deployment** → **Smart Group Population** → **Compliance Reporting**
2. **Installation Progress** → **Automated Scoping** → **Next Phase Deployment**

### Maintenance Automation
1. **Needs Attention Group** → **Automated Remediation Policy** → **Health Restoration**
2. **Performance Monitoring** → **Resource Usage Tracking** → **Optimization Recommendations**

## Smart Group Best Practices

### Flexible Criteria Design
- **Use partial matches** like "Version: 2.*" instead of "Version: 2.0.0*" to catch all 2.x versions
- **Focus on status keywords** rather than exact version strings
- **Plan for future versions** by using broader matching criteria with wildcards

### Naming Convention
- **Include version range** (e.g., "v2.x") to indicate flexibility
- **Use descriptive action words** (Installed, Active, Configured, etc.)
- **Indicate urgency level** for security groups (CRITICAL, Needs Attention)

### Automation Guidelines
- **Monitor "CRITICAL VIOLATIONS" group daily** (should be 0)
- **Set up webhook alerts** for security incidents
- **Review "Needs Attention" group weekly**
- **Track deployment progress** via configuration groups

### Performance Considerations
- **Limit complex criteria** to essential groups
- **Use efficient Extension Attribute criteria**
- **Monitor Smart Group population times**
- **Consider criteria caching impact**

## Advanced Smart Group Examples

### Multi-Criteria Security Groups

#### Jamf Connect Monitor - Security Compliant
```
Name: Jamf Connect Monitor - Security Compliant
Criteria: 
  - Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Version: 2.*"
  AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Profile: Deployed*"
  AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Unauthorized: 0*"
  AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Daemon: Healthy*"
Purpose: Identify fully compliant and secure systems
```

#### Jamf Connect Monitor - High Priority Issues
```
Name: Jamf Connect Monitor - High Priority Issues
Criteria:
  - Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Unauthorized:*"
  AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" not like "*Unauthorized: 0*"
  OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Daemon: Not Running*"
Purpose: Critical issues requiring immediate attention
```

### Department-Specific Groups

#### Jamf Connect Monitor - IT Department
```
Name: Jamf Connect Monitor - IT Department
Criteria:
  - Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Version: 2.*"
  AND Computer Group membership is "IT Department"
Purpose: IT-specific monitoring and configuration
```

### Performance Monitoring Groups

#### Jamf Connect Monitor - High Resource Usage
```
Name: Jamf Connect Monitor - High Resource Usage
Criteria:
  - Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Real-time: Active*"
  AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.x" like "*Logs: [5-9][0-9][0-9]MB*"
Purpose: Systems with high log volume for optimization
```

## Smart Group Maintenance

### Regular Review Schedule
- **Daily:** Check "CRITICAL VIOLATIONS" group (should be empty)
- **Weekly:** Review "Needs Attention" group for maintenance
- **Monthly:** Analyze "Latest Version" vs "Legacy" deployment progress
- **Quarterly:** Evaluate Smart Group performance and criteria efficiency

### Criteria Updates for New Versions
When new versions are released:
1. **Keep flexible criteria** (e.g., "Version: 2.") to automatically include new versions
2. **Create specific groups** only if new version has unique features
3. **Update deployment policies** to target appropriate Smart Groups
4. **Retire legacy version groups** when no longer needed

### Troubleshooting Smart Group Issues

#### Groups Not Populating
```bash
# Check Extension Attribute data format
sudo /usr/local/etc/jamf_ea_admin_violations.sh

# Verify inventory updates
sudo jamf recon

# Check Smart Group criteria matches
# Compare EA output with Smart Group criteria
```

#### Performance Issues
- **Simplify complex criteria** with multiple AND/OR conditions
- **Use more specific keywords** to reduce processing overhead
- **Consider criteria caching** by checking at optimal intervals
- **Monitor Jamf Pro database performance** during Smart Group updates

## Integration with Policies

### Automated Response Policies
Link Smart Groups to policies for automated responses:

```
Policy: Security Incident Response
Trigger: Smart Group membership change
Target: "Jamf Connect Monitor - CRITICAL VIOLATIONS"
Actions: 
  - Send immediate notification
  - Run security audit script
  - Update incident tracking system
```

### Maintenance Policies
```
Policy: Monitor Health Maintenance  
Trigger: Recurring check-in
Target: "Jamf Connect Monitor - Needs Attention"
Actions:
  - Restart monitoring daemon
  - Refresh Configuration Profile
  - Update inventory
```

### Deployment Policies
```
Policy: Deploy Configuration Profiles
Trigger: Enrollment complete
Target: "Jamf Connect Monitor - Installed v2.x"
Exclusions: "Jamf Connect Monitor - Config Profile Active"
Actions:
  - Install Configuration Profile
  - Update inventory
  - Send deployment confirmation
```

## Version Migration Strategy

### Smart Group Evolution
As versions evolve, maintain backward compatibility:

**v2.3.0 → v2.3.0 Migration:**
- ✅ Keep "Version: 2." criteria (catches both versions)
- ✅ No Smart Group updates needed
- ✅ Automatic inclusion of v2.3.0 systems

**Future v2.x Versions:**
- ✅ Flexible criteria continue to work
- ✅ Add version-specific groups only for unique features
- ✅ Maintain operational group consistency

---

**Created with ❤️ by MacJediWizard**

**Flexible Smart Group design for scalable enterprise security monitoring across all v2.x versions.**