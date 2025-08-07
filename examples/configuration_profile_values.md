# Jamf Connect Monitor - Configuration Profile Values Template

## Quick Setup Guide

When configuring the Jamf Connect Monitor in Jamf Pro using the schema, use these example values:

### Notification Settings
```
Email Recipient: security-alerts@yourcompany.com
SMTP Provider: Gmail / Google Workspace
SMTP Server: smtp.gmail.com
SMTP Port: 587
SMTP Username: monitoring@yourcompany.com
SMTP Password: [Your App Password or regular password]
From Email Address: monitoring@yourcompany.com
Notification Style: Detailed Report
Notification Cooldown: 15 minutes
```

### Monitoring Behavior
```
Monitoring Mode: Real-time
Automatic Admin Removal: ✓ Enabled
Grace Period: 5 minutes
Monitor Jamf Connect Only: ✓ Enabled
```

### Security Settings
```
Require Confirmation: ✗ Disabled (enables auto-remediation)
Enable Violation Reporting: ✓ Enabled
Log Retention: 30 days
Excluded System Accounts: _mbsetupuser, root, daemon
```

### Jamf Pro Integration
```
Update Inventory on Violations: ✓ Enabled
Policy Trigger: [optional - e.g., security_incident]
Company Name: Your Company
IT Support Email: it-support@yourcompany.com
```

### Advanced Settings
```
Debug Logging: ✗ Disabled (enable only for troubleshooting)
Periodic Check Interval: 300 seconds
Max Notifications Per Hour: 10
Auto-populate Approved Admins: ✓ Enabled
```

---

## SMTP Configuration Examples by Provider

### Gmail / Google Workspace
```
SMTP Provider: Gmail / Google Workspace
SMTP Server: smtp.gmail.com
SMTP Port: 587 (recommended) or 465
SMTP Username: your-email@gmail.com
SMTP Password: [App Password if 2FA enabled, or regular password]
```

### Office 365 / Exchange Online
```
SMTP Provider: Office 365 / Exchange Online
SMTP Server: smtp.office365.com
SMTP Port: 587
SMTP Username: your-email@organization.com
SMTP Password: [Your password or app password if MFA enabled]
```

### SendGrid
```
SMTP Provider: SendGrid
SMTP Server: smtp.sendgrid.net
SMTP Port: 587 (recommended) or 465
SMTP Username: apikey
SMTP Password: [Your SendGrid API key]
```

### AWS SES
```
SMTP Provider: AWS SES
SMTP Server: email-smtp.[region].amazonaws.com
SMTP Port: 587 or 465
SMTP Username: [SMTP credentials from SES console]
SMTP Password: [SMTP password from SES console]
```

### Custom / Other SMTP Server
```
SMTP Provider: Custom / Other SMTP Server
SMTP Server: mail.yourcompany.com
SMTP Port: 587
SMTP Username: monitoring@yourcompany.com
SMTP Password: [Your email password]
```

---

## Gmail App Password Setup

1. Go to https://myaccount.google.com/security
2. Click "2-Step Verification" (enable if needed)
3. Scroll down to "App passwords"
4. Select app: "Mail"
5. Select device: "Mac" or "Other"
6. Copy the 16-character password
7. Use this password in the SMTP Password field

**Note**: Regular Gmail passwords won't work with SMTP authentication!

---

## Port Selection Guide

### When to use Port 465 (SSL):
- Gmail/Google Workspace recommended port
- When port 587 is blocked by firewall
- Direct SSL/TLS connection

### When to use Port 587 (STARTTLS):
- Office 365/Outlook default
- Most corporate SMTP servers
- When 465 is not available

### When to use Port 25:
- Internal SMTP relays only
- No authentication required
- Not recommended for external servers

---

## Testing Your Configuration

After deploying the Configuration Profile:

1. Check if profile is deployed:
```bash
sudo /usr/local/jamf_connect_monitor/jamf_connect_monitor.sh test-config
```

2. Test email delivery:
```bash
sudo /usr/local/jamf_connect_monitor/jamf_connect_monitor.sh test-email recipient@yourcompany.com
```

3. Run comprehensive test:
```bash
sudo ./tools/email_test.sh test recipient@yourcompany.com
```

---

## Troubleshooting

### Port Connectivity Issues
Test which ports are available:
```bash
nc -zv smtp.gmail.com 465  # Test SSL port
nc -zv smtp.gmail.com 587  # Test TLS port
```

### Common Solutions:
- If port 587 is blocked: Use port 465 with SSL
- If both ports blocked: Configure internal SMTP relay
- For Gmail: Always use App Password, not regular password
- For Office365: May need app-specific password with MFA

### Debug Mode
Enable debug logging temporarily in Advanced Settings to troubleshoot issues.