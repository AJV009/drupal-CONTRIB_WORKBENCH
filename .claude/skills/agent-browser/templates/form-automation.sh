#!/bin/bash
# Template: Form Automation Workflow
# Purpose: Fill and submit web forms with validation
# Usage: ./form-automation.sh <form-url>
#
# Demonstrates the snapshot-interact-verify pattern:
# 1. Navigate to form
# 2. Snapshot to get element refs
# 3. Fill fields using refs
# 4. Submit and verify result

set -euo pipefail

FORM_URL="${1:?Usage: $0 <form-url>}"

echo "Form automation: $FORM_URL"

# Step 1: Navigate to form
agent-browser open "$FORM_URL"
agent-browser wait --load networkidle

# Step 2: Snapshot to discover form elements
echo ""
echo "Form structure:"
agent-browser snapshot -i

# Step 3: Fill form fields (customize refs based on snapshot output)
#
# Common field types:
#   agent-browser fill @e1 "John Doe"           # Text input
#   agent-browser fill @e2 "user@example.com"   # Email input
#   agent-browser fill @e3 "SecureP@ss123"      # Password input
#   agent-browser select @e4 "Option Value"     # Dropdown
#   agent-browser check @e5                     # Checkbox
#   agent-browser click @e6                     # Radio button
#   agent-browser fill @e7 "Multi-line text"    # Textarea
#   agent-browser upload @e8 /path/to/file.pdf  # File upload

# Step 4: Submit and verify
# agent-browser click @e3  # Submit button
# agent-browser wait --load networkidle

echo ""
echo "Result:"
agent-browser get url
agent-browser snapshot -i

# Capture evidence
agent-browser screenshot /tmp/form-result.png
echo "Screenshot saved: /tmp/form-result.png"

agent-browser close
echo "Done"
