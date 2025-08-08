#!/bin/bash

# Documentation Verification Script for v2.3.0
# Run this to verify documentation consistency and accuracy

echo "🔍 DOCUMENTATION VERIFICATION FOR v2.3.0"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}$message${NC}"
}

# Initialize counters
issues_found=0
checks_passed=0

# 1. Package Identifier Consistency Check
echo
print_status "$BLUE" "1. 🔍 Checking Package Identifier Consistency..."
expected_identifier="com.macjediwizard.jamfconnectmonitor"

# Check for correct identifier
correct_refs=$(grep -r "$expected_identifier" docs/ README.md CHANGELOG.md 2>/dev/null | wc -l)
print_status "$GREEN" "   ✅ Found $correct_refs references to correct identifier: $expected_identifier"

# Check for old/incorrect identifiers (FIXED - these are the actual old ones)
old_identifiers=("com.company.jamfconnectmonitor" "com.yourcompany.jamfconnectmonitor")
for old_id in "${old_identifiers[@]}"; do
    old_refs=$(grep -r "$old_id" docs/ README.md CHANGELOG.md 2>/dev/null | wc -l)
    if [[ $old_refs -gt 0 ]]; then
        print_status "$RED" "   ❌ Found $old_refs references to old identifier: $old_id"
        grep -r "$old_id" docs/ README.md CHANGELOG.md 2>/dev/null
        ((issues_found++))
    else
        print_status "$GREEN" "   ✅ No references to old identifier: $old_id"
        ((checks_passed++))
    fi
done

# 2. Version Number Consistency
echo
print_status "$BLUE" "2. 🔍 Checking Version Number Consistency..."

# Check for v2.0.0 references
v2_refs=$(grep -r "2.0.0\|v2.0.0" docs/ README.md CHANGELOG.md 2>/dev/null | wc -l)
print_status "$GREEN" "   ✅ Found $v2_refs references to version 2.0.0"

# Check for old version references that shouldn't be there
old_versions=("1.0.0" "1.0.1" "1.0.2")
for old_ver in "${old_versions[@]}"; do
    # Exclude CHANGELOG.md as it legitimately contains old versions
    old_refs=$(grep -r "$old_ver" docs/ README.md 2>/dev/null | grep -v "CHANGELOG\|changelog" | wc -l)
    if [[ $old_refs -gt 0 ]]; then
        print_status "$RED" "   ❌ Found $old_refs references to old version: $old_ver (outside changelog)"
        grep -r "$old_ver" docs/ README.md 2>/dev/null | grep -v "CHANGELOG\|changelog"
        ((issues_found++))
    else
        print_status "$GREEN" "   ✅ No inappropriate references to old version: $old_ver"
        ((checks_passed++))
    fi
done

# 3. File Path Accuracy
echo
print_status "$BLUE" "3. 🔍 Checking File Path Accuracy..."

# Key file paths that should be referenced in documentation
file_paths=(
    "/usr/local/bin/jamf_connect_monitor.sh"
    "/usr/local/etc/jamf_ea_admin_violations.sh"
    "/Library/LaunchDaemons/com.macjediwizard.jamfconnectmonitor.plist"
    "/var/log/jamf_connect_monitor"
    "/usr/local/etc/approved_admins.txt"
)

for file_path in "${file_paths[@]}"; do
    refs=$(grep -r "$file_path" docs/ README.md 2>/dev/null | wc -l)
    if [[ $refs -gt 0 ]]; then
        print_status "$GREEN" "   ✅ Found $refs references to: $file_path"
        ((checks_passed++))
    else
        print_status "$YELLOW" "   ⚠️  No references found to: $file_path (may be OK)"
    fi
done

# 4. Configuration Domain Consistency
echo
print_status "$BLUE" "4. 🔍 Checking Configuration Domain Consistency..."
config_domain="com.macjediwizard.jamfconnectmonitor"

domain_refs=$(grep -r "$config_domain" docs/ README.md CHANGELOG.md 2>/dev/null | wc -l)
print_status "$GREEN" "   ✅ Found $domain_refs references to configuration domain: $config_domain"
((checks_passed++))

# 5. Feature Claims Verification
echo
print_status "$BLUE" "5. 🔍 Checking v2.0.0 Feature Claims..."

# Key v2.0.0 features that should be mentioned in documentation
v2_features=(
    "Configuration Profile"
    "JSON Schema"
    "real-time monitoring"
    "enhanced notification"
    "webhook"
    "email notification"
)

for feature in "${v2_features[@]}"; do
    refs=$(grep -ri "$feature" docs/ README.md 2>/dev/null | wc -l)
    if [[ $refs -gt 0 ]]; then
        print_status "$GREEN" "   ✅ Found $refs references to: $feature"
        ((checks_passed++))
    else
        print_status "$RED" "   ❌ No references found to key feature: $feature"
        ((issues_found++))
    fi
done

# 6. Command Line Interface Documentation
echo
print_status "$BLUE" "6. 🔍 Checking CLI Command Documentation..."

# Key CLI commands that should be documented
cli_commands=(
    "jamf_connect_monitor.sh status"
    "jamf_connect_monitor.sh test-config"
    "jamf_connect_monitor.sh add-admin"
    "jamf_connect_monitor.sh remove-admin"
    "jamf_connect_monitor.sh force-check"
)

for cmd in "${cli_commands[@]}"; do
    refs=$(grep -r "$cmd" docs/ README.md 2>/dev/null | wc -l)
    if [[ $refs -gt 0 ]]; then
        print_status "$GREEN" "   ✅ Found $refs references to command: $cmd"
        ((checks_passed++))
    else
        print_status "$YELLOW" "   ⚠️  No references found to command: $cmd"
    fi
done

# 7. Check for broken internal links
echo
print_status "$BLUE" "7. 🔍 Checking Internal Documentation Links..."

# Find markdown links in documentation (IMPROVED regex)
internal_links=$(grep -r "\[.*\](docs/[^)]*\.md)" docs/ README.md 2>/dev/null | grep -o "docs/[^)]*\.md" | sort | uniq)

if [[ -n "$internal_links" ]]; then
    echo "$internal_links" | while read -r link; do
        if [[ -f "$link" ]]; then
            print_status "$GREEN" "   ✅ Link target exists: $link"
        else
            print_status "$RED" "   ❌ Broken link: $link"
        fi
    done
else
    print_status "$YELLOW" "   ⚠️  No internal markdown links found to verify"
fi

# Check for malformed markdown links (ADDED)
echo
print_status "$BLUE" "7b. 🔍 Checking for Malformed Markdown Links..."
malformed_links=$(grep -n "\[.*\]([^)]*$" README.md docs/*.md 2>/dev/null || true)
if [[ -n "$malformed_links" ]]; then
    print_status "$RED" "   ❌ Found malformed markdown links:"
    echo "$malformed_links" | sed 's/^/      /'
    ((issues_found++))
else
    print_status "$GREEN" "   ✅ No malformed markdown links found"
    ((checks_passed++))
fi

# 8. JSON Schema Reference Check
echo
print_status "$BLUE" "8. 🔍 Checking JSON Schema References..."

schema_file="jamf_connect_monitor_schema.json"
if [[ -f "$schema_file" ]]; then
    print_status "$GREEN" "   ✅ JSON Schema file exists: $schema_file"
    
    # Check if schema is referenced in docs
    schema_refs=$(grep -r "$schema_file" docs/ README.md 2>/dev/null | wc -l)
    if [[ $schema_refs -gt 0 ]]; then
        print_status "$GREEN" "   ✅ Found $schema_refs references to schema file in documentation"
        ((checks_passed++))
    else
        print_status "$RED" "   ❌ Schema file not referenced in documentation"
        ((issues_found++))
    fi
    
    # Validate JSON syntax
    if python3 -m json.tool "$schema_file" >/dev/null 2>&1; then
        print_status "$GREEN" "   ✅ JSON Schema syntax is valid"
        ((checks_passed++))
    else
        print_status "$RED" "   ❌ JSON Schema has syntax errors"
        ((issues_found++))
    fi
else
    print_status "$RED" "   ❌ JSON Schema file missing: $schema_file"
    ((issues_found++))
fi

# 9. Installation Instructions Validation
echo
print_status "$BLUE" "9. 🔍 Checking Installation Instructions..."

# Check if package creation is mentioned
if grep -r "package_creation_script.sh" docs/ README.md >/dev/null 2>&1; then
    print_status "$GREEN" "   ✅ Package creation instructions found"
    ((checks_passed++))
else
    print_status "$RED" "   ❌ Package creation instructions missing"
    ((issues_found++))
fi

# Check if Jamf Pro deployment is covered
if grep -r "Jamf Pro" docs/ README.md >/dev/null 2>&1; then
    print_status "$GREEN" "   ✅ Jamf Pro deployment instructions found"
    ((checks_passed++))
else
    print_status "$RED" "   ❌ Jamf Pro deployment instructions missing"
    ((issues_found++))
fi

# 10. Final Summary
echo
print_status "$BLUE" "=========================================="
print_status "$BLUE" "📊 DOCUMENTATION VERIFICATION SUMMARY"
print_status "$BLUE" "=========================================="

print_status "$GREEN" "✅ Checks Passed: $checks_passed"
if [[ $issues_found -gt 0 ]]; then
    print_status "$RED" "❌ Issues Found: $issues_found"
    echo
    print_status "$YELLOW" "🔧 Action Required: Fix the issues above before release"
    exit 1
else
    print_status "$GREEN" "❌ Issues Found: 0"
    echo
    print_status "$GREEN" "🎉 DOCUMENTATION VERIFICATION PASSED!"
    print_status "$GREEN" "📋 All documentation appears accurate and ready for v2.0.0 release"
    exit 0
fi
