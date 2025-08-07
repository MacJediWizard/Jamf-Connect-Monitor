# 🧪 Jamf Connect Monitor v2.2.0 - Email Testing Guide

## 📦 Package Ready for Deployment

**Package Location:** `/scripts/output/JamfConnectMonitor-2.2.0.pkg`  
**Schema Location:** `/scripts/output/jamf_connect_monitor_schema.json`

## ⚠️ Breaking Change in v2.2.0

**SMTP Configuration is now REQUIRED for email notifications**
- System mail fallback has been removed due to reliability issues
- You must configure SMTP settings in the Configuration Profile
- Supports Gmail, Office365, or corporate SMTP servers

## ✅ What's Been Fixed

1. **Port 465 Support**
   - Default port changed from 587 to 465 everywhere
   - Proper SSL/TLS detection (port 465 uses SSL, 587 uses STARTTLS)
   - Works with networks that block port 587

2. **Enhanced SMTP Authentication**
   - `swaks` with --tlsc for port 465
   - `mailx` with proper SSL configuration
   - Multiple fallback methods
   - **No system mail fallback** - SMTP only

3. **Email Reliability**
   - Removed unreliable system mail that caused silent failures
   - Clear error messages when SMTP is not configured
   - No more stuck emails in local mail queues

## 🚀 Deployment Steps

### Step 1: Upload Package to Jamf Pro
1. Log into Jamf Pro
2. Navigate to: **Settings → Computer Management → Packages**
3. Click **New**
4. Upload `JamfConnectMonitor-2.2.0.pkg`
5. Set Category: Security or Utilities

### Step 2: Create Configuration Profile
1. Navigate to: **Computers → Configuration Profiles → New**
2. Name: "Jamf Connect Monitor - Email Settings"
3. Add Payload: **Application & Custom Settings**
4. Configure:
   - Source: **Custom Schema**
   - Preference Domain: `com.macjediwizard.jamfconnectmonitor`
   - Upload Schema: Use `jamf_connect_monitor_schema.json` from output folder
5. Configure Settings in GUI:
   ```
   Email Recipient: your-email@domain.com
   SMTP Server: smtp.gmail.com
   SMTP Port: 465  ← IMPORTANT: Use 465, not 587
   SMTP Username: your-email@domain.com
   SMTP Password: [Gmail App Password - 16 characters]
   SMTP From Address: your-email@domain.com
   Company Name: Your Organization
   ```

### Step 3: Create Policy for Installation
1. Navigate to: **Computers → Policies → New**
2. General:
   - Display Name: "Install Jamf Connect Monitor"
   - Trigger: Recurring Check-in (or Self Service)
3. Packages:
   - Add `JamfConnectMonitor-2.2.0.pkg`
   - Action: Install
4. Scope:
   - Target test computers first

### Step 4: Gmail App Password Setup
1. Go to: https://myaccount.google.com/security
2. Enable 2-Step Verification (if not already)
3. Click "App passwords"
4. Generate new app password for "Mail"
5. Copy the 16-character password
6. Use this in the Configuration Profile SMTP Password field

## 🧪 Testing Commands

After deployment, SSH into the test Mac and run:

### 1. Check Installation
```bash
# Verify files installed
ls -la /usr/local/bin/jamf_connect_monitor.sh
ls -la /Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist

# Check if daemon is running
sudo launchctl list | grep jamfconnectmonitor
```

### 2. Test Configuration Profile
```bash
# Check if Configuration Profile is applied
sudo defaults read /Library/Managed\ Preferences/com.macjediwizard.jamfconnectmonitor

# Test configuration reading
sudo /usr/local/bin/jamf_connect_monitor.sh test-config
```

### 3. Test Email Delivery
```bash
# Send test email
sudo /usr/local/bin/jamf_connect_monitor.sh test-email your-email@domain.com

# Check logs if issues
tail -f /var/log/jamf_connect_monitor/monitor.log
```

### 4. Network Connectivity Test
```bash
# Test port 465 (should work)
nc -zv smtp.gmail.com 465

# Test port 587 (may be blocked)
nc -zv smtp.gmail.com 587
```

### 5. Comprehensive Email Test
```bash
# If you have the source code on the test machine
sudo /path/to/tools/email_test.sh test your-email@domain.com

# Or run diagnostics
sudo /path/to/tools/email_test.sh diagnostics
```

## 🔍 Troubleshooting

### Email Not Sending?

1. **Check logs:**
   ```bash
   tail -f /var/log/jamf_connect_monitor/monitor.log
   ```

2. **Verify Configuration Profile:**
   ```bash
   sudo defaults read /Library/Managed\ Preferences/com.macjediwizard.jamfconnectmonitor | grep SMTP
   ```

3. **Test network connectivity:**
   ```bash
   nc -zv smtp.gmail.com 465
   ```

4. **Common Issues:**
   - **Port 587 blocked**: Make sure Configuration Profile uses port 465
   - **Authentication failed**: Use Gmail App Password, not regular password
   - **No SMTP configured**: Email notifications will be disabled (no system mail fallback)

### Expected Success Output

When email test succeeds, you should see:
```
✅ Test email sent successfully!
Please check your inbox for the test message.
```

The test email will have subject: "🧪 Jamf Connect Monitor Test Email - [hostname]"

## 📝 Final Verification

After successful testing:

1. **Check email received** with proper formatting
2. **Verify logs** show successful SMTP authentication
3. **Test a real violation** (optional):
   ```bash
   # Add a test admin user
   sudo dseditgroup -o edit -a testuser admin
   # Wait for monitoring to detect (up to 5 minutes)
   # Check if notification sent
   ```

## 🎯 Ready for Production

Once testing succeeds:
1. Expand scope to production computers
2. Monitor logs for first 24 hours
3. Adjust notification settings as needed

## 📞 Support

- Check logs: `/var/log/jamf_connect_monitor/`
- Run diagnostics: `sudo jamf_connect_monitor.sh test-config`
- Email test: `sudo jamf_connect_monitor.sh test-email`

---

**Version:** 2.2.0  
**Port Configuration:** 465 (SSL) recommended  
**Default Fallback:** Port 465 if not configured