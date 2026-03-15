---
name: prd-plan
description: Plan implementation tasks from a PRD document, update an existing session's plan, or add new tasks to an existing session. Provide a PRD filepath to create a new plan (or update an existing one), or a session-id/PRD-path plus a description to append tasks.
---

# /prd-plan — PRD Planning Command

You are executing the `/prd-plan` command of the PRD Implementor system.

This command is multi-purpose: it creates new plans from PRD documents, **updates** existing session plans, **or** appends new tasks to existing sessions.

## What To Do

1. **Detect intent** from `$ARGUMENTS`:

   First, check if `$ARGUMENTS` ends with `write to <path>`. If so, extract that path as `{base-dir}` and remove `write to <path>` from the arguments before further parsing. Otherwise, set `{base-dir}` to `~/.claude/tasks`.

   Parse the first token from the (possibly trimmed) `$ARGUMENTS`. Then determine the mode:

   a. **If `$ARGUMENTS` is empty**, show usage and refuse:
      ```
      ✗ Cannot proceed without arguments.
        Usage:
          /prd-plan /path/to/your-prd.md                          — create new plan (or update existing)
          /prd-plan /path/to/your-prd.md write to /custom/dir/    — create plan in custom directory
          /prd-plan {session-id} add {description}                 — add task to session
          /prd-plan /path/to/session-dir add {description}         — add task (path-based session)
          /prd-plan /path/to/prd.md add {description}              — add task (find session by PRD path)
      ```

   b. **Check if the first token matches an existing session**:
      - If the first token contains `/`: check if `{first-token}/manifest.md` exists on disk → it's a path-based session reference. Set `{session-dir}` to `{first-token}`.
      - If the first token has no `/`: check if `~/.claude/tasks/{first-token}/manifest.md` exists → default directory lookup. Set `{session-dir}` to `~/.claude/tasks/{first-token}`.
      - If the session exists **and there is extra text after the first token** → go to **[Append Mode]** (session resolved)
      - If the session exists **and there is no extra text** → show session info (read `status.md`), then ask the user what task they'd like to add. Stop here until the user responds.

   c. **Check if the first token is a filepath that exists on disk** (and is a regular file, not a directory)
      - If the file exists **and there IS extra text** → go to **[Append Mode]** (resolve session by scanning `{base-dir}/*/manifest.md` for a matching PRD path)
      - If the file exists **and there is no extra text** → check for existing sessions before planning:
        - Scan `{base-dir}/*/manifest.md` for any session whose `PRD:` line matches the given filepath (compare absolute paths)
        - If **one or more matches found** → present the user with a choice:
          ```
          Existing session(s) found for this PRD:
            1. {session-id} ({base-dir}/{session-id}/) — {X}/{N} tasks complete
            2. (create new session)

          Update existing session or create new? (enter number)
          ```
          Stop here until the user responds.
          - If user picks an existing session → go to **[Update Mode]**
          - If user picks "create new" → go to **[Planning Mode]** (step 2 below)
        - If **no matches** → go to **[Planning Mode]** (step 2 below)

   d. **Otherwise** → show error with usage help:
      ```
      ✗ "{first-token}" is not a valid session ID or file path.
        Usage:
          /prd-plan /path/to/your-prd.md                          — create new plan (or update existing)
          /prd-plan /path/to/your-prd.md write to /custom/dir/    — create plan in custom directory
          /prd-plan {session-id} add {description}                 — add task to session
          /prd-plan /path/to/session-dir add {description}         — add task (path-based session)
          /prd-plan /path/to/prd.md add {description}              — add task (find session by PRD path)
      ```

---

## [Append Mode] — Add tasks to an existing session

When you reach this mode, you have a session to target and a description of what to add.

### A1. Resolve the session

- **By path** (first token contains `/`): The session directory is the path itself (already resolved in step 1b as `{session-dir}`)
- **By session-id** (first token has no `/`): The session directory is `~/.claude/tasks/{session-id}/`
- **By PRD path**: Scan all `~/.claude/tasks/*/manifest.md` files. Find those whose `PRD:` line matches the given filepath (compare absolute paths).
  - If **no match** found → error: `✗ No session found for PRD: {path}`
  - If **multiple matches** found → list them and ask the user to pick:
    ```
    Multiple sessions found for this PRD:
      1. {session-id-1} (created {date}, {X}/{N} tasks complete)
      2. {session-id-2} (created {date}, {X}/{N} tasks complete)
    Which session? (enter number or session-id)
    ```
    Stop here until the user responds.
  - If **one match** → use that session

### A2. Load context

Read all files in the session directory to understand current state:
- `manifest.md` — session metadata
- `status.md` — current progress and task table
- `memory.md` — past decisions and context
- All existing `task-*.md` files — understand what's already planned

Determine the last task number N (from the highest-numbered `task-N.md` file).

### A3. Create the new task file

Write `task-{N+1}.md` in the session directory using the same format as existing task files:

```markdown
# Task {N+1}: {descriptive title}

## Session
{session-id}

## PRD Reference
Source: {absolute-path-to-prd}
Section: {relevant section, or "Added post-planning" if not from original PRD}

## Description
{clear description based on the user's input}

## Acceptance Criteria
- [ ] {specific, verifiable criterion}
- [ ] {another criterion}

## Dependencies
- {set dependencies based on what makes sense given the description and existing tasks}

## Files to Create/Modify
- {filepath}: {description of changes}

## Database Tables
- `{table_name}`: {brief role, e.g. "created in this task" or "read/queried" or "modified (add column)"}

## Estimated Complexity
{low / medium / high}

## Status
⏳ pending
```

### A4. Update status.md

- Add a new row to the task table for task {N+1}
- Update the `Progress:` line — change the total count from N to N+1
- Update `Last Updated:` timestamp

### A5. Update manifest.md

- Update the `Total Tasks:` count from N to N+1

### A6. Append to memory.md

Add a new section at the end:

```markdown
---

## [Plan Update - {ISO timestamp}]

### User Input
{the user's description text, verbatim}

### Tasks Added
- Task {N+1}: {title} (depends on: {deps})

### Notes
- {any context about how this fits into the existing plan}
```

### A7. Display confirmation

```
✓ Task added to session {session-id}

New task:
  {N+1}. {title} (→ {dependencies})

Files updated:
  - {session-dir}/task-{N+1}.md
  - {session-dir}/status.md
  - {session-dir}/manifest.md
  - {session-dir}/memory.md

Progress: {completed}/{N+1} ({percentage}%)
Next: /prd-execute {session-dir-or-session-id}
```

Where `{session-dir-or-session-id}` is the full path if the session is in a custom directory, or just the session-id if it's in the default `~/.claude/tasks/` directory.

After printing the confirmation, **print the full contents of the new `task-{N+1}.md` file** using a header like `📄 task-{N+1}.md:` followed by the file content in a fenced code block.

**Stop here — do not continue to Update Mode or Planning Mode.**

---

## [Update Mode] — Re-plan tasks in an existing session

When you reach this mode, you have a resolved `{session-dir}` and the PRD filepath.

### U1. Load full context

Read all files in the session directory:
- `manifest.md` — session metadata
- `status.md` — current progress and task table
- `memory.md` — past decisions and context
- All `task-*.md` files — full task details

Categorize each task by status: `✅ done`, `⏳ pending`, `🔄 in-progress`, `❌ failed`.

### U2. Collect focus instructions

Ask the user:
```
What should the updated plan focus on? (or press enter to re-plan all pending tasks)
```
Stop here until the user responds. The user can provide specific instructions (e.g., "focus on PG-012, PG-013, seeder data") or press enter to re-plan all pending tasks.

### U3. Re-read the PRD

Read the original PRD file completely (same as Planning Mode step 4) to catch any changes since the original plan was created.

### U4. Preserve completed work

- Tasks with status `✅ done` are **never modified or deleted**
- Tasks with status `🔄 in-progress` are preserved by default. If the user's focus instructions conflict with an in-progress task, warn the user and ask for confirmation before modifying it.

### U5. Regenerate pending tasks

- Delete all `⏳ pending` task files from the session directory
- Re-decompose the PRD (guided by the user's focus instructions) into new tasks
- New tasks are numbered starting from the highest existing task number + 1 (across all preserved tasks)
- Apply the same planning rules as Planning Mode: dependency order, ~15-30 min chunks, image extraction
- Reference completed tasks as satisfied dependencies where relevant

### U6. Update session files

**Update `status.md`:**
- Rebuild the task table with all preserved tasks (done, in-progress, failed) plus the new tasks
- Rebuild the `## Database Schema` table based on the new task set (if applicable)
- Rebuild the `## Mockup References` table based on the new task set (if applicable)
- Update the `Progress:` line with new counts
- Update `Last Updated:` timestamp

**Update `manifest.md`:**
- Update the `Total Tasks:` count to reflect the new total

**Append to `memory.md`:**
```markdown
---
## [Plan Update - {ISO timestamp}]

### User Focus
{the user's focus instructions, verbatim — or "Re-plan all pending tasks" if no specific focus}

### Tasks Preserved
- Task {N}: {title} (✅ done)
- ...

### Tasks Removed
- Task {N}: {title} (was ⏳ pending — replaced)
- ...

### Tasks Added
- Task {N}: {title} (depends on: {deps})
- ...

### Notes
- {context about why the plan was updated}
```

### U7. Display confirmation

```
✓ Session {session-id} updated!

Preserved: {X} completed tasks
Removed:   {Y} pending tasks
Added:     {Z} new tasks
Total:     {T} tasks ({X}/{T} complete)

Updated task overview:
  1. ✅ {title}
  ...
  N. ⏳ {title} (→ deps)

Files updated:
  - {session-dir}/status.md
  - {session-dir}/manifest.md
  - {session-dir}/memory.md
  - {session-dir}/task-{N+1}.md
  - ...

Next: /prd-execute {session-dir-or-session-id}
```

Where `{session-dir-or-session-id}` is the full path if the session is in a custom directory, or just the session-id if it's in the default `~/.claude/tasks/` directory.

After printing the confirmation, **print the full contents of each new task file** using a header like `📄 task-{N}.md:` followed by the file content in a fenced code block.

**Stop here — do not continue to Planning Mode.**

---

## [Planning Mode] — Create a new plan from a PRD

2. **Generate a session ID** (Planning Mode only): Run this shell command to generate a random session ID:
   ```bash
   python3 -c "import random; adj=['vibrant','silent','golden','swift','cosmic','amber','lucid','bold','crisp','vivid','radiant','steady','bright','noble','keen','calm','sharp','prime','grand','lush']; noun=['oak','fox','wave','peak','arc','elm','ray','orb','gem','spark','reef','tide','dawn','vale','helm','forge','cliff','ridge','mesa','grove']; print(f'{random.choice(adj)}-{random.choice(noun)}-{random.randint(10,99)}')"
   ```
   - Use the output as `{session-id}`
   - Check `{base-dir}` to ensure no collision (where `{base-dir}` was resolved in step 1); if collision, re-run

3. **Display session banner**:
   ```
   ═══════════════════════════════════════════
     PRD Implementor v1.0
     Session: {session-id}
   ═══════════════════════════════════════════
     Planning from: {prd-filepath}
   ═══════════════════════════════════════════
   ```

4. **Read the PRD** file completely

5. **Create directory**: `mkdir -p {base-dir}/{session-id}`

6. **Write manifest.md** in the session directory:
   ```markdown
   # Session: {session-id}
   - PRD: {absolute-path-to-prd}
   - Created: {ISO timestamp}
   - Status: planned
   - Total Tasks: {N}
   - Base Directory: {base-dir}
   ```
   The `Base Directory` line may be omitted if `{base-dir}` is the default `~/.claude/tasks`.

7. **Decompose into tasks** — think carefully about:
   - What is the logical build order?
   - What are the dependencies between tasks?
   - Each task should be completable in ~15-30 min
   - Start with setup/foundation, then models, then logic, then UI, then integration, then testing
   - **Extract image references**: Scan the PRD for all markdown image references matching `![...](path)` or `![...](<path>)`. First resolve each image path to an **absolute path** (by resolving it relative to the PRD file's directory). Then, when writing the image into a task file, convert the absolute path to a **relative path from the task file's directory** (the session directory, e.g. `~/.claude/tasks/{session-id}/`). This ensures images render correctly when viewed from the task file's location. When creating each task, associate the relevant images (from the same PRD section the task implements) with that task.
   - **Extract database schema**: Scan the PRD for database schema definitions (tables, models, entities). Collect all table/model names and their associated fields. If no database schema section is found in the PRD, warn the user: `⚠️  No database schema found in PRD. Consider adding a schema section or run a schema generation tool before planning.`

   Write the image in the task using this format `![...](<path>)` for best compatibility with markdown editors. The `path` must be relative to the task file's directory — use Python `os.path.relpath(absolute_image_path, task_dir)` mentally to compute the correct relative path.

8. **Write each task file** `task-{N}.md`:
   ```markdown
   # Task {N}: {descriptive title}

   ## Session
   {session-id}

   ## PRD Reference
   Source: {absolute-path-to-prd}
   Section: {which PRD section this implements}

   ## Description
   {clear description of what this task accomplishes}

   ## Acceptance Criteria
   - [ ] {specific, verifiable criterion}
   - [ ] {another criterion}

   ## Dependencies
   - {e.g., "task-1 must be complete" or "none"}

   ## Files to Create/Modify
   - {filepath}: {description of changes}

   ## Database Tables
   - `{table_name}`: {brief role, e.g. "created in this task" or "read/queried" or "modified (add column)"}

   ## UI References
   ![{description}](<{relative-path-to-image-from-task-dir}>)

   ## Estimated Complexity
   {low / medium / high}

   ## Status
   ⏳ pending
   ```

   > **Note on UI References**: Only include the `## UI References` section if the task has associated images from the PRD. If a task has no relevant images, omit this section entirely.

   > **Note on Database Tables**: Only include the `## Database Tables` section if the task involves database tables (creating, reading, or modifying). Omit if not applicable.

9. **Write status.md**:
   ```markdown
   # Implementation Status: {session-id}
   PRD: {absolute-path-to-prd}
   Created: {timestamp}
   Last Updated: {timestamp}

   ## Progress: 0/{N} tasks complete (0%)

   | # | Task | Status | Depends On | Complexity |
   |---|------|--------|------------|------------|
   | 1 | {title} | ⏳ pending | none | {low/med/high} |
   | 2 | {title} | ⏳ pending | task-1 | {low/med/high} |

   ## Database Schema

   | Table | Created In | Status | Notes |
   |-------|-----------|--------|-------|
   | {table_name} | task-{N} | ⏳ pending | {brief description} |

   ## Mockup References

   | Mockup Link | Status | Notes |
   |-------------|--------|-------|
   | {image_path} | ⏳ pending | Used in task-{N}: {brief description} |
   ```

   > **Note on Database Schema**: Only include the `## Database Schema` section in status.md if the PRD contains database tables. Status mirrors the task that creates the table (⏳ pending, ✅ done, etc.). Tables only referenced (not created) are excluded from this table.

   > **Note on Mockup References**: Only include `## Mockup References` if the PRD contains image references. Status: `⏳ pending` → `✅ done` (when the task referencing the mockup is completed) or `❌ cancel` (mockup determined not relevant). If a mockup is referenced by multiple tasks, mark it done only when all referencing tasks are complete.

10. **Write memory.md**:
    ```markdown
    # Memory: {session-id}
    PRD: {absolute-path-to-prd}

    ---

    ## [Planning Phase - {timestamp}]

    ### Decisions
    - {any architectural decisions made during planning}

    ### Context
    - Session created with {N} tasks
    - PRD analyzed: {brief summary of what the PRD describes}
    - Tech stack: {if mentioned in PRD}
    - Key constraints: {if any}

    ### PRD Images
    - {absolute-path-to-image} — {description/context, e.g. which section it appeared in}
    - (list all images found in the PRD, or "none" if no images were found)

    ### Blockers
    (none)

    ### Notes
    - {anything useful for future execution}
    ```

11. **Display summary** to the user:
    ```
    ✓ Planning complete!

    Session: {session-id}
    Tasks:   {N} tasks generated
    PRD:     {filepath}

    Task Overview:
      1. {title} (no deps)
      2. {title} (→ task-1)
      ...

    Files Written:
      - {base-dir}/{session-id}/manifest.md
      - {base-dir}/{session-id}/status.md
      - {base-dir}/{session-id}/memory.md
      - {base-dir}/{session-id}/task-1.md
      - {base-dir}/{session-id}/task-2.md
      - ... (list all task files)

    Next steps:
      /prd-execute {session-dir-or-session-id}        — execute next task
      /prd-execute {session-dir-or-session-id} -all   — execute all tasks sequentially
    ```

## Important Rules

- In **Planning Mode**, the PRD filepath is **mandatory** — never proceed without it
- In **Append Mode**, the session must be resolvable (by session-id or PRD path)
- In **Update Mode**, completed tasks (`✅ done`) are **never modified or deleted**
- When updating, always re-read the original PRD to catch any changes
- Always use **absolute paths** when storing the PRD reference
- Every task file must reference the original PRD location
- Tasks should be ordered so dependencies flow forward (task-3 can depend on task-1 but not on task-5)
- Keep task descriptions actionable and specific — not vague
- **After writing each file**, print its full contents to the console so the user can review it. Use a header like `📄 {filename}:` followed by the file content in a fenced code block
- When appending tasks, preserve the existing task numbering — always increment from the highest existing task number
- The word "add" between the session identifier and the description is optional — any extra text after a valid session-id or PRD path triggers append mode
