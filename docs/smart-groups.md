# Smart Groups Guide

## Overview
Jamf Connect Monitor v2.0.0 provides enhanced Extension Attribute data that enables powerful Smart Group automation for enterprise security monitoring workflows.

## Essential Smart Groups for v2.0.0

### Security Monitoring Groups

#### Jamf Connect Monitor - Installed v2.0
```
Name: Jamf Connect Monitor - Installed v2.0
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Version: 2.0.0"
Purpose: Track v2.0.0 installations and scope Configuration Profiles
```

#### Jamf Connect Monitor - CRITICAL VIOLATIONS
```
Name: Jamf Connect Monitor - CRITICAL VIOLATIONS
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Unauthorized:"
AND Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" does not contain "Unauthorized: 0"
Purpose: Immediate security incident response
⚠️ CONFIGURE WEBHOOK ALERTS FOR THIS GROUP
```

#### Jamf Connect Monitor - Config Profile Active
```
Name: Jamf Connect Monitor - Config Profile Active
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Profile: Deployed"
Purpose: Verify Configuration Profile deployment success
```

### Operational Groups

#### Jamf Connect Monitor - Real-time Active
```
Name: Jamf Connect Monitor - Real-time Active
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Real-time: Active"
Purpose: Track real-time monitoring deployment and performance impact
```

#### Jamf Connect Monitor - Needs Attention
```
Name: Jamf Connect Monitor - Needs Attention
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Daemon: Not Running"
OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Profile: Not Deployed"
Purpose: Proactive maintenance and troubleshooting
```

#### Jamf Connect Monitor - Notifications Configured
```
Name: Jamf Connect Monitor - Notifications Configured
Criteria: Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Webhook: Configured"
OR Extension Attribute "[ Jamf Connect ] - Monitor Status v2.0" contains "Email: Configured"
Purpose: Verify notification system deployment
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

## Best Practices

### Smart Group Naming
- Use descriptive, consistent naming convention
- Include project name for easy identification
- Indicate urgency level for security groups

### Automation Guidelines
- Monitor "CRITICAL VIOLATIONS" group daily (should be 0)
- Set up webhook alerts for security incidents
- Review "Needs Attention" group weekly
- Track deployment progress via configuration groups

### Performance Considerations
- Limit complex criteria to essential groups
- Use efficient Extension Attribute criteria
- Monitor Smart Group population times
- Consider criteria caching impact

---

**Created with ❤️ by MacJediWizard**