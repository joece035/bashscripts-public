#!/bin/bash
# ============================================================
# agent-pre-commit.sh — Agent Hook for SSOT/V4 Enforcement
# ============================================================
# Triggered by .github/hooks/pre-commit.json (PreToolUse)
# Reads JSON from stdin, extracts filePath, and runs checks.
# ============================================================

INPUT=$(cat)

# Extract toolName and filePath using grep/sed (avoids jq dependency)
TOOL_NAME=$(echo "$INPUT" | grep -o '"toolName"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"toolName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
FILE_PATH=$(echo "$INPUT" | grep -o '"filePath"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"filePath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

# Only check .sh files
if [[ "$FILE_PATH" != *.sh ]]; then
    echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
    exit 0
fi

# If it's a file creation tool and the file doesn't exist yet, allow it.
if [[ "$TOOL_NAME" == "create_file" && ! -f "$FILE_PATH" ]]; then
    echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
    exit 0
fi

# If the file doesn't exist (e.g. for other tools), allow it.
if [[ ! -f "$FILE_PATH" ]]; then
    echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
    exit 0
fi

# 1. Syntax Check
SYNTAX_OUTPUT=$(bash -n "$FILE_PATH" 2>&1)
SYNTAX_EXIT=$?

# 2. SSOT/V4 Check
SSOT_OUTPUT=$(bash tools/safe-edit.sh "$FILE_PATH" 2>&1)
SSOT_EXIT=$?

if [[ $SYNTAX_EXIT -eq 0 && $SSOT_EXIT -eq 0 ]]; then
    echo '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "allow"}}'
else
    # Combine error messages
    REASON="Hook failed for $FILE_PATH."
    [[ $SYNTAX_EXIT -ne 0 ]] && REASON="$REASON Syntax error: $SYNTAX_OUTPUT"
    [[ $SSOT_EXIT -ne 0 ]] && REASON="$REASON SSOT/V4 violation: $SSOT_OUTPUT"
    
    # Escape JSON special characters in REASON
    REASON_ESCAPED=$(echo "$REASON" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ')
    
    echo "{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"deny\", \"permissionDecisionReason\": \"$REASON_ESCAPED\"}}"
    exit 2
fi
