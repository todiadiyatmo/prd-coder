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
   b. Stale tasks marked `🔄 in-progress` whose dependencies are all `✅ done`
   c. Tasks marked `⏳ pending` whose dependencies are all `✅ done`
   d. If all tasks are done or blocked, report completion

   A `🔄 in-progress` task is stale when a previous `/prd-execute` run started it but stopped before marking it `✅ done`. Resume stale in-progress tasks before selecting a new pending task, and record the resume in `memory.md`.

6. **Display what you're about to do**:
   ```
   ─────────────────────────────────────────
   Executing Task {N}: {title}
   Status: {⏳ pending / 🔄 in-progress / 🔁 retry}
   Dependencies: {list, all ✅}
   Session ID: {session-id}
   ─────────────────────────────────────────
   ```

7. **Read the task file** `task-{N}.md` completely. If the task file contains a `## UI References` section, read/view each image file listed there using the Read tool before implementing. These images are the authoritative visual reference for the task's UI work.

8. **Re-read relevant memory entries** — look for notes from previous tasks that affect this one

9. **Mark the task as in-progress before implementation**:

   a. **Update task-{N}.md** — set status:
      ```markdown
      ## Status
      🔄 in-progress — started {timestamp}
      ```

   b. **Update status.md** — change the task row from `⏳ pending` or `🔁 retry` to `🔄 in-progress`. If the selected task was already stale `🔄 in-progress`, leave it as `🔄 in-progress`.

      Do **not** increment the progress counter at this step. Progress only changes when a task is marked `✅ done`.

   c. **If resuming a stale in-progress task**, append a short note to `memory.md` before implementation:
      ```markdown
      ---

      ## [Task {N} Resumed - {timestamp}]

      - Resuming stale `🔄 in-progress` task from a previous interrupted execution.
      ```

   d. **Print the updated session files before implementation begins**:
      - Print the full updated `task-{N}.md`
      - Print the full updated `status.md`
      - If `memory.md` was updated for a stale resume, print the full updated `memory.md`

      Use a header like `📄 {filename}:` followed by the file content in a fenced code block.

10. **Execute the task**:
   - Implement the code, create files, make changes as described
   - Follow the acceptance criteria precisely
   - Reference the PRD when making decisions
   - If you need to deviate from the plan, document WHY
   - If UI References are present, the implementation MUST match the layout, spacing, and component arrangement shown in the reference images. Use the Read tool to view image files.

11. **After completion, update files**:

    a. **Update task-{N}.md** — check off acceptance criteria, set status:
       ```markdown
       ## Status
       ✅ done — completed {timestamp}
       ```

    b. **Update status.md** — change task row from `🔄 in-progress` to `✅ done` and update progress counter:
       ```markdown
       ## Progress: {X}/{N} tasks complete ({percentage}%)
       ```
       Also update the `## Database Schema` table in status.md — change the status of any tables created by the completed task from ⏳ pending to ✅ done.

       Also update `## Mockup References` table in status.md — change mockups referenced by the completed task from `⏳ pending` to `✅ done`. If a mockup is referenced by multiple tasks, only mark it done when all referencing tasks are complete.

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

12. **Report results**:
    ```
    ✓ Task {N} complete: {title}

    Progress: {X}/{N} ({percentage}%)
    Files modified: {count}

    Next task: Task {M}: {title}
    Run: /prd-execute {session-id}
    Run: /prd-execute {session-id} -all  (execute all remaining)
    ```

13. **Continue or ask**:
    - If `-all` flag was set: automatically loop back to step 5 and execute the next available task. Continue until all tasks are done or a task fails with `❌ blocked`.
    - Otherwise: ask if the user wants to continue to the next task

## Error Handling

If a task fails during execution:

1. If the task is `🔄 in-progress`, mark it in `status.md` as `🔁 retry` on first failure or `❌ blocked` on repeated failure. Update `task-{N}.md` to the same terminal failure status.
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
- **UI fidelity matching**: When a task includes UI reference images, assess their fidelity level:
  - **Low fidelity** (black and white wireframes, sketches, grayscale mockups): Use the project's existing UI components, design system, styles, and patterns to implement the intended layout and functionality. Do NOT replicate the wireframe's visual style — instead, translate the wireframe's intent into the project's established look and feel.
  - **High fidelity** (polished designs with colors, typography, and styling): Match the design as closely as possible, including colors, spacing, typography, and visual details.
