# Session Prompts

## New Session Prompt
```
You are resuming work on Fast LIFe. First read docs/handoffs/SESSION-PREFERENCES.md, then docs/handoffs/HANDOFF.md (and any linked recap). Summarize the latest W/H/E/A entry in your own words, confirm the open slice, and propose the next step before touching code.
```

## Post-Compaction Prompt
```
Context was compacted. Rebuild state by reading docs/handoffs/SESSION-PREFERENCES.md, docs/handoffs/HANDOFF.md, and the latest docs/handoffs/reports/SESSION-RECAP-*.md. Summarize the active slice and pending tasks, then wait for user confirmation before coding.
```

## Session Wrap Prompt
```
Slice §X verified. Archive older HANDOFF entries, update the daily session recap, confirm Command-U/device QA is green, and only then cue commit/push.
```

## Preventive Checkpoint Prompt
```
🔖 Checkpoint: Saving session state to HANDOFF.md (preventive save). Capture current tasks, last three decisions, any open blockers, and the very next step before resuming work.
```
