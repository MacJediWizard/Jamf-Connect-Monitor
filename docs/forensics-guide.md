# Forensics and Investigation Guide v2.4.0

## Overview
When Jamf Connect Monitor detects and remediates an unauthorized admin account, the account is preserved for forensic investigation. This guide explains how to investigate security incidents and why accounts are preserved rather than deleted.

## Remediation Behavior

### What Auto-Remediation Does
When `RemoveAdminPrivileges` is enabled (default: false), the monitor:
1. **Removes admin group membership** - User loses admin privileges immediately
2. **Preserves the user account** - Account remains for investigation
3. **Maintains all user data** - Files, logs, and history preserved
4. **Logs the remediation** - Creates audit trail in violation logs
5. **Sends notifications** - Alerts security team via webhook/email

### What Auto-Remediation Does NOT Do
- ❌ **Does NOT delete user accounts**
- ❌ **Does NOT remove user files**
- ❌ **Does NOT disable login** (unless configured separately)
- ❌ **Does NOT modify user data**

### Why Preserve Accounts?
1. **Forensic Investigation** - Need to understand what happened
2. **Evidence Preservation** - Required for security incidents
3. **Audit Compliance** - Regulatory requirements
4. **Reversibility** - Can restore if false positive
5. **Legal Requirements** - May need evidence for prosecution

## Forensic Investigation Commands

### 1. Check User Activity Timeline
```bash
# Last login times
last | grep <username>

# Authentication attempts
log show --predicate "process == 'loginwindow' AND eventMessage CONTAINS '<username>'" --last 7d

# Sudo usage (what admin commands they ran)
sudo log show --predicate "process == 'sudo' AND eventMessage CONTAINS '<username>'" --last 7d
```

### 2. Find Files Created/Modified by User
```bash
# Files modified in last 7 days
sudo find / -user <username> -type f -mtime -7 2>/dev/null

# Files created (if birth time available)
sudo find / -user <username> -type f -newerBt '7 days ago' 2>/dev/null

# Check Downloads folder
ls -la /Users/<username>/Downloads/

# Check Desktop
ls -la /Users/<username>/Desktop/
```

### 3. Review Command History
```bash
# Bash history
sudo cat /Users/<username>/.bash_history

# Zsh history
sudo cat /Users/<username>/.zsh_history

# Check for command aliases
sudo cat /Users/<username>/.bashrc
sudo cat /Users/<username>/.zshrc
```

### 4. Check Network Activity
```bash
# Network connections made by user
sudo lsof -u <username> -i

# Check for SSH keys
ls -la /Users/<username>/.ssh/

# Check known_hosts
sudo cat /Users/<username>/.ssh/known_hosts
```

### 5. Review System Modifications
```bash
# Check for LaunchAgents installed
ls -la /Users/<username>/Library/LaunchAgents/
ls -la /Library/LaunchAgents/ | grep -i <username>

# Check for installed applications
ls -la /Applications/ | grep -i <username>
mdfind -onlyin /Applications "kMDItemFSOwnerUserID == $(id -u <username>)"

# Check for system preference changes
defaults read > /tmp/current_defaults.txt
sudo -u <username> defaults read > /tmp/user_defaults.txt
```

### 6. Analyze Privilege Escalation
```bash
# When did they become admin?
sudo log show --predicate "eventMessage CONTAINS 'add' AND eventMessage CONTAINS '<username>' AND eventMessage CONTAINS 'admin'" --last 30d

# How did they elevate? (Jamf Connect or other)
grep "<username>" /var/log/jamf_connect_monitor/legitimate_elevations.log
grep "<username>" /Library/Logs/JamfConnect/UserElevationReasons.log

# Check violation history
grep "<username>" /var/log/jamf_connect_monitor/admin_violations.log
```

### 7. Create Forensic Report
```bash
#!/bin/bash
# Forensic report generator
USERNAME="$1"
REPORT_DIR="/var/log/jamf_connect_monitor/forensics"
REPORT_FILE="$REPORT_DIR/investigation_${USERNAME}_$(date +%Y%m%d_%H%M%S).txt"

mkdir -p "$REPORT_DIR"

{
    echo "=== FORENSIC INVESTIGATION REPORT ==="
    echo "User: $USERNAME"
    echo "Date: $(date)"
    echo "Investigator: $(whoami)"
    echo ""
    
    echo "=== USER STATUS ==="
    id "$USERNAME" 2>/dev/null || echo "User not found"
    echo ""
    
    echo "=== LAST LOGINS ==="
    last | grep "$USERNAME" | head -10
    echo ""
    
    echo "=== RECENT SUDO COMMANDS ==="
    sudo log show --predicate "process == 'sudo' AND eventMessage CONTAINS '$USERNAME'" --last 7d 2>/dev/null | head -20
    echo ""
    
    echo "=== FILES MODIFIED (Last 7 days) ==="
    sudo find /Users/"$USERNAME" -type f -mtime -7 2>/dev/null | head -20
    echo ""
    
    echo "=== COMMAND HISTORY (Last 20) ==="
    sudo tail -20 /Users/"$USERNAME"/.bash_history 2>/dev/null || echo "No bash history"
    sudo tail -20 /Users/"$USERNAME"/.zsh_history 2>/dev/null || echo "No zsh history"
    echo ""
    
    echo "=== NETWORK CONNECTIONS ==="
    sudo lsof -u "$USERNAME" -i 2>/dev/null | head -10
    echo ""
    
    echo "=== INSTALLED ITEMS ==="
    ls -la /Users/"$USERNAME"/Library/LaunchAgents/ 2>/dev/null || echo "No user LaunchAgents"
    echo ""
    
    echo "=== VIOLATION HISTORY ==="
    grep "$USERNAME" /var/log/jamf_connect_monitor/admin_violations.log 2>/dev/null | tail -10
    echo ""
    
    echo "=== END REPORT ==="
} > "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"
```

## Post-Remediation Actions

### Immediate Steps
1. **Review forensic report** - Understand what happened
2. **Check for persistence** - LaunchAgents, cron jobs, etc.
3. **Verify remediation** - Confirm admin privileges removed
4. **Document incident** - Create security incident report

### Decision Tree
```
Unauthorized Admin Detected
├── Auto-Remediation (Admin Removed)
├── Forensic Investigation
│   ├── Legitimate User?
│   │   ├── Yes → Update approved_admins.txt
│   │   └── No → Continue investigation
│   └── Malicious Activity?
│       ├── Yes → Disable account → Delete after investigation
│       └── No → Monitor account → Remove after review period
└── Update Security Policies
```

### Manual Account Actions

#### Disable Account (Preserve for Investigation)
```bash
# Disable login (preserves account/data)
sudo pwpolicy -u <username> -setpolicy "isDisabled=1"

# Or prevent shell access
sudo dscl . -create /Users/<username> UserShell /usr/bin/false
```

#### Delete Account (After Investigation Complete)
```bash
# Only after forensic investigation is complete
sudo sysadminctl -deleteUser <username>

# Or force delete
sudo dscl . -delete /Users/<username>
sudo rm -rf /Users/<username>
```

## Known Issues

### macOS System Settings UI Cache
After auto-remediation removes admin privileges, the user may still appear as admin in System Settings. This is a cosmetic UI cache issue.

#### Verification
```bash
# This is the authoritative check
dsmemberutil checkmembership -U <username> -G admin
# Should show: "user is not a member of the group"
```

#### Fix UI Display
```bash
# Force UI refresh
sudo killall -9 "System Settings" 2>/dev/null || true
sudo killall -9 UserManagementAgent 2>/dev/null || true
sudo dscacheutil -flushcache
sudo killall -HUP opendirectoryd

# Then reopen System Settings
```

If the UI still shows incorrectly, a logout/login or reboot will clear the cache. The important point is the user has NO actual admin privileges regardless of UI display.

## Best Practices

### Investigation Process
1. **Don't rush** - Take time to understand the incident
2. **Preserve evidence** - Don't delete accounts immediately
3. **Document everything** - Keep detailed investigation notes
4. **Check for patterns** - Look for similar incidents
5. **Update policies** - Prevent future occurrences

### Security Recommendations
- Enable auto-remediation for immediate threat mitigation
- Keep accounts for minimum 30 days after incident
- Archive forensic reports for compliance
- Regular review of approved_admins.txt
- Monitor for repeat offenders

### Compliance Considerations
- Many regulations require evidence preservation
- Document retention policies apply to security incidents
- Forensic data may be required for legal proceedings
- Maintain chain of custody for evidence

## Integration with Security Tools

### SIEM Integration
```bash
# Export violation data for SIEM
cat /var/log/jamf_connect_monitor/admin_violations.log | \
    jq -R 'split("|") | {timestamp:.[0], event:.[1], user:.[2], host:.[3]}' > violations.json
```

### Incident Response
```bash
# Create incident ticket
curl -X POST https://your-ticketing-system/api/incidents \
    -H "Content-Type: application/json" \
    -d "{
        \"title\": \"Unauthorized Admin: $USERNAME\",
        \"severity\": \"high\",
        \"description\": \"Auto-remediated unauthorized admin detected\",
        \"evidence\": \"$REPORT_FILE\"
    }"
```

## Conclusion
The Jamf Connect Monitor's approach of removing admin privileges while preserving accounts provides the best balance of:
- **Immediate security** - Threat neutralized instantly
- **Investigation capability** - Full forensic data available
- **Compliance** - Meets evidence preservation requirements
- **Reversibility** - Can undo if false positive

This design follows security best practices and provides flexibility for different organizational policies.

---

**Created with ❤️ by MacJediWizard**