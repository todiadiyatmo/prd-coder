---
name: prd-status
description: Check the status of a PRD implementation session. Shows progress, completed tasks, next steps, and any blockers. Optionally provide a session ID to see a specific session.
---

# /prd-status — Session Status Command

You are executing the `/prd-status` command of the PRD Implementor system.

## What To Do

1. **Parse arguments**: Session identifier is optional.
   - `$ARGUMENTS` contains the user's input after `/prd-status`

2. **If no argument provided**, list all sessions in the default directory:
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

   > **Note on Database Schema**: When displaying detailed status (step 3), read the `## Database Schema` section from `status.md` to populate the Database Schema table. Only display this section if it exists in status.md.

3. **If argument provided**, resolve the session directory and show detailed status:

   - If the argument contains `/`: treat it as a direct path to the session directory. Set `{session-dir}` to that path.
   - If the argument has no `/`: treat it as a session-id and set `{session-dir}` to `~/.claude/tasks/{argument}`.

   Then read:
   a. `{session-dir}/manifest.md`
   b. `{session-dir}/status.md`
   c. `{session-dir}/memory.md` (latest entries only)

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

   Database Schema:
   ┌──────────────────────┬────────────┬───────────┬──────────────────┐
   │ Table                │ Created In │ Status    │ Notes            │
   ├──────────────────────┼────────────┼───────────┼──────────────────┤
   │ users                │ task-1     │ ✅ done    │ Auth tables      │
   │ items                │ task-3     │ ⏳ pending │ Core inventory   │
   └──────────────────────┴────────────┴───────────┴──────────────────┘

   Current Task: 3 — API endpoints
   Next Up:      4 — Frontend components

   Blockers: {from memory.md, or "none"}

   Recent Activity:
     {last 2-3 memory entries, summarized}

   Resume: /prd-execute {session-id}
   ```

4. **Handle missing session**:
   ```
   ✗ Session not found at '{session-dir}'.
     Available sessions in ~/.claude/tasks/:
     {list}
     Usage: /prd-status {session-id}
            /prd-status /path/to/session-dir
   ```

## Important Rules

- This is a READ-ONLY command — never modify any files
- Always check if the PRD file still exists and note if it's missing
- Summarize memory entries, don't dump the entire file
- Highlight any blockers or retry tasks prominently
