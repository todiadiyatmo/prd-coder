---
name: prd-status
description: Check the status of a PRD implementation session. Shows progress, completed tasks, next steps, and any blockers. Optionally provide a session ID to see a specific session.
---

# /prd-status — Session Status Command

You are executing the `/prd-status` command of the PRD Implementor system.

## What To Do

1. **Parse arguments**: Session ID is optional.
   - `$ARGUMENTS` contains the user's input after `/prd-status`

2. **If no session ID provided**, list all sessions:
   ```bash
   ls ~/.claude/tasks/
   ```
   Display a summary of ALL sessions:
   ```
   ═══════════════════════════════════════════
     PRD Implementor — All Sessions
   ═══════════════════════════════════════════

   Session              PRD                    Progress
   ─────────────────────────────────────────────────────
   vibrant-oak-42       /path/to/prd.md        3/7 (43%)
   silent-peak-87       /path/to/other.md      done ✅
   golden-arc-13        /path/to/another.md    1/5 (20%) ⚠️ blocked

   View details: /prd-status {session-id}
   ```
   Read each session's `manifest.md` and `status.md` to build this table.

3. **If session ID provided**, show detailed status:

   a. Read `~/.claude/tasks/{session-id}/manifest.md`
   b. Read `~/.claude/tasks/{session-id}/status.md`
   c. Read `~/.claude/tasks/{session-id}/memory.md` (latest entries only)

   Display:
   ```
   ═══════════════════════════════════════════
     PRD Implementor — Session Status
     Session: {session-id}
   ═══════════════════════════════════════════

   PRD: {filepath}
   Created: {date}
   Progress: {X}/{N} tasks ({percentage}%)

   ┌───┬────────────────────────┬───────────┬──────────────┐
   │ # │ Task                   │ Status    │ Dependencies │
   ├───┼────────────────────────┼───────────┼──────────────┤
   │ 1 │ Project setup          │ ✅ done    │ none         │
   │ 2 │ Data models            │ ✅ done    │ task-1       │
   │ 3 │ API endpoints          │ 🔄 current │ task-2       │
   │ 4 │ Frontend components    │ ⏳ pending │ task-2       │
   │ 5 │ Integration            │ ⏳ pending │ task-3,4     │
   └───┴────────────────────────┴───────────┴──────────────┘

   Current Task: 3 — API endpoints
   Next Up:      4 — Frontend components

   Blockers: {from memory.md, or "none"}

   Recent Activity:
     {last 2-3 memory entries, summarized}

   Resume: /prd-execute {session-id}
   ```

4. **Handle missing session**:
   ```
   ✗ Session '{session-id}' not found.
     Available sessions:
     {list}
   ```

## Important Rules

- This is a READ-ONLY command — never modify any files
- Always check if the PRD file still exists and note if it's missing
- Summarize memory entries, don't dump the entire file
- Highlight any blockers or retry tasks prominently
