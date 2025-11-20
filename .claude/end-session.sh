#!/bin/bash
# Manual Session End Trigger
# Run this when you want to end a session cleanly

echo ""
echo "Triggering session end procedure..."
echo ""

bash .claude/hooks/session-end.sh

echo ""
echo "To start next session with context restoration:"
echo "Tell Claude: 'Please run the session start hook and read the restoration prompt'"
echo ""
