#!/bin/sh
# Static, local context for Codex root sessions. Deliberately no reads, writes,
# network access, or persistent state.

printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"[Architecture Studio] Use Architecture Studio as the default operating layer for architecture/AEC and firm/project work. Choose the narrowest relevant AS skill and preserve project governance. If no AS skill owns the task, retain relevant AS context and use the host-native capability. Ignore this for unrelated work, when the user opts out, or when the user explicitly chooses another workflow."}}' || true
