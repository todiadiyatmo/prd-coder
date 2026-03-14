---
name: prd-execute
description: Execute the next pending task from a planned PRD implementation session. Reads memory for context continuity, implements the task, updates status and memory. Requires a session ID.
---

# /prd-execute — Task Execution Command

You are executing the `/prd-execute` command of the PRD Implementor system.

## What To Do

1. **Parse arguments**: The user should provide a session identifier and optional flags.
   - `$ARGUMENTS` contains the user's input after `/prd-execute`
   - Format: `/prd-execute {session-id-or-path} [-all]`
   - If `-all` flag is present, execute ALL pending tasks sequentially without stopping to ask between tasks (yolo mode)
   - If empty, list available sessions:
     ```bash
     ls ~/.claude/tasks/
     ```
     Then display them and ask the user to pick one.

2. **Resolve session directory**:
   - If the identifier contains `/`: treat it as a direct path to the session directory. Validate that `{path}/manifest.md` exists.
   - If the identifier has no `/`: treat it as a session-id and look in the default directory. Validate that `~/.claude/tasks/{session-id}/manifest.md` exists.
   - Set `{session-dir}` to the resolved path. Use `{session-dir}` for all subsequent file reads/writes instead of hardcoded paths.
   - If not found:
     ```
     ✗ Session '{session-id-or-path}' not found.
       Available sessions in ~/.claude/tasks/:
       {list from ~/.claude/tasks/}
       Usage: /prd-execute {session-id}
              /prd-execute /path/to/session-dir
     ```

3. **Display session banner**:
   ```
   ═══════════════════════════════════════════
     PRD Implementor v1.0
     Executing: {session-id}
   ═══════════════════════════════════════════
   ```

4. **Load context** — read these files IN ORDER:
   a. `manifest.md` — get PRD path and session metadata
   b. `memory.md` — **READ THIS COMPLETELY** — this is your continuity from previous runs
   c. `status.md` — find current progress
   d. The original PRD file (path from manifest) — re-read to stay aligned

5. **Find next task** — priority order:
   a. Tasks marked `🔁 retry` (failed previously, try again)
   b. Tasks marked `⏳ pending` whose dependencies are all `✅ done`
   c. If all tasks are done or blocked, report completion

6. **Display what you're about to do**:
   ```
   ─────────────────────────────────────────
   Executing Task {N}: {title}
   Status: {⏳ pending / 🔁 retry}
   Dependencies: {list, all ✅}
   Session ID: {session-id}
   ─────────────────────────────────────────
   ```

7. **Read the task file** `task-{N}.md` completely. If the task file contains a `## UI References` section, read/view each image file listed there using the Read tool before implementing. These images are the authoritative visual reference for the task's UI work.

8. **Re-read relevant memory entries** — look for notes from previous tasks that affect this one

9. **Execute the task**:
   - Implement the code, create files, make changes as described
   - Follow the acceptance criteria precisely
   - Reference the PRD when making decisions
   - If you need to deviate from the plan, document WHY
   - If UI References are present, the implementation MUST match the layout, spacing, and component arrangement shown in the reference images. Use the Read tool to view image files.

10. **After completion, update files**:

    a. **Update task-{N}.md** — check off acceptance criteria, set status:
       ```markdown
       ## Status
       ✅ done — completed {timestamp}
       ```

    b. **Update status.md** — change task row and update progress counter:
       ```markdown
       ## Progress: {X}/{N} tasks complete ({percentage}%)
       ```

    c. **Append to memory.md** — NEVER overwrite, always append:
       ```markdown
       ---

       ## [Task {N} Execution - {timestamp}]

       ### What Was Done
       - {description of changes made}

       ### Files Created/Modified
       - {filepath}: {what was done}

       ### Decisions Made
       - {any choices and rationale}

       ### Issues Encountered
       - {problems and how they were resolved, or "none"}

       ### Context for Next Tasks
       - {anything the next task execution needs to know}
       - {e.g., "created a shared util in src/utils/helpers.ts — task-4 should import from there"}
       ```

11. **Report results**:
    ```
    ✓ Task {N} complete: {title}

    Progress: {X}/{N} ({percentage}%)
    Files modified: {count}

    Next task: Task {M}: {title}
    Run: /prd-execute {session-id}
    Run: /prd-execute {session-id} -all  (execute all remaining)
    ```

12. **Continue or ask**:
    - If `-all` flag was set: automatically loop back to step 5 and execute the next available task. Continue until all tasks are done or a task fails with `❌ blocked`.
    - Otherwise: ask if the user wants to continue to the next task

## Error Handling

If a task fails during execution:

1. Mark in status.md as `🔁 retry` (first failure) or `❌ blocked` (second failure)
2. Log the failure details in memory.md:
   ```markdown
   ---

   ## [Task {N} FAILED - {timestamp}]

   ### Error
   - {what went wrong}

   ### Attempted Fix
   - {what was tried}

   ### State Left Behind
   - {partial files created, etc.}

   ### Retry Notes
   - {what should be done differently next time}
   ```
3. If blocked, check if any other tasks can proceed (no dependency on blocked task)
4. Report to user clearly

## Memory Is Sacred

The memory file is the ONLY way context survives between Claude Code sessions. Treat it like a senior engineer's handoff notes:
- Be specific about file paths and function names
- Note any patterns established that later tasks should follow
- Record environment setup or config that was done
- Document any PRD ambiguities and how you resolved them

## Important Rules

- ALWAYS read memory.md before executing anything
- ALWAYS append to memory.md after executing anything
- ALWAYS re-read the original PRD before implementing
- NEVER skip dependency checks
- NEVER overwrite memory — only append
- If the PRD file is missing, STOP and tell the user
- **After writing or updating each session file** (task-N.md, status.md, memory.md), print its full contents to the console so the user can review it. Use a header like `📄 {filename}:` followed by the file content in a fenced code block
