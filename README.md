# PRD Implementor

A persistent, session-based agent for Claude Code that turns Product Requirements Documents into executed code through structured planning and iterative execution.

## The Problem

Claude Code loses context between sessions. If you're implementing a complex PRD, you have to re-explain context every time. Tasks get lost, decisions get forgotten, and you end up re-doing work.

## The Solution

PRD Implementor gives Claude Code **persistent memory on disk**. It:

1. Reads your PRD and decomposes it into sequenced, dependent tasks
2. Stores everything in `~/.claude/tasks/{session-id}/`
3. Maintains a memory file that carries context between executions
4. Tracks status, handles failures, and enables resumable workflows

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/todiadiyatmo/prd-coder/main/bootstrap.sh | bash -s -- install
```

### Manual install

```bash
git clone https://github.com/todiadiyatmo/prd-coder.git
cd prd-coder
./install.sh
```

## Usage

### 1. Plan from a PRD

```
/prd-plan /path/to/my-prd.md
```

This will:
- Generate a session ID (e.g., `vibrant-oak-42`)
- Read and analyze your PRD
- Decompose it into ordered, dependent tasks
- Save everything to `~/.claude/tasks/vibrant-oak-42/`

### 1a. Custom directory

By default, sessions are stored in `~/.claude/tasks/`. You can specify a custom base directory with `write to`:

```
/prd-plan /path/to/my-prd.md write to /tmp/
```

This creates the session at `/tmp/{session-id}/` instead. Reference it by path in all commands:

```
/prd-execute /tmp/vibrant-oak-42
/prd-status /tmp/vibrant-oak-42
/prd-plan /tmp/vibrant-oak-42 add update dockerfile
```

**Path resolution rule**: If an argument contains `/`, it's treated as a path. If it's a bare name like `vibrant-oak-42`, the default `~/.claude/tasks/` directory is used.

### 1b. Add tasks to an existing session

```
/prd-plan vibrant-oak-42 add set up docker compose for dev
/prd-plan /path/to/my-prd.md add integration tests for auth
```

This will:
- Resolve the session (by session-id or by finding a session that used that PRD)
- Read existing tasks and context
- Create a new `task-{N+1}.md` appended to the plan
- Update `status.md`, `manifest.md`, and `memory.md`

### 2. Execute tasks

```
/prd-execute vibrant-oak-42
```

This will:
- Load the session's memory (context from previous runs)
- Re-read the original PRD
- Find the next actionable task
- Implement it
- Update status and memory

Run this repeatedly across Claude Code sessions. Memory persists.

### 3. Check status

```
/prd-status                    # list all sessions
/prd-status vibrant-oak-42     # detailed status for a session
```

## Architecture

Sessions are stored in `~/.claude/tasks/` by default, or in a custom directory specified via `write to`. All commands accept both session-ids (bare names) and full paths.

```
{base-dir}/{session-id}/        # base-dir defaults to ~/.claude/tasks
├── manifest.md     # Session metadata, PRD path, creation date
├── task-1.md       # Individual task with criteria & dependencies
├── task-2.md
├── task-N.md
├── memory.md       # Append-only context log (the secret sauce)
└── status.md       # Progress table
```

### Memory File (the key innovation)

The `memory.md` file is append-only and timestamped. Every `/prd-execute` run:
1. **Reads** it first to load context
2. **Appends** after completing work

It records:
- Architectural decisions and rationale
- Files created/modified
- Issues encountered and resolutions
- Inter-task context ("task-2 created a helper that task-4 should reuse")
- Deviations from the plan

This is how continuity survives across separate Claude Code sessions.

### Error Recovery

- First failure: task marked `🔁 retry`, failure logged in memory
- Second failure: task marked `❌ blocked`, agent moves to next non-dependent task
- All failures are logged with context so retries have better information

## Task Decomposition Strategy

The planner follows this order:
1. **Foundation** — project setup, dependencies, config
2. **Data models** — types, schemas, database models
3. **Core logic** — main business functionality
4. **Interface layer** — API endpoints, UI components
5. **Integration** — connecting everything together
6. **Polish** — error handling, validation, edge cases
7. **Testing** — unit and integration tests

Each task targets 15-30 minutes of implementation work.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/todiadiyatmo/prd-coder/main/bootstrap.sh | bash -s -- uninstall
```

This removes agents, skills, and commands. Optionally deletes task data.

## Tips

- **Keep PRDs focused** — one feature/product per PRD works best
- **Don't move your PRD file** — tasks reference its absolute path
- **Run `/prd-status` often** — it's your dashboard
- **Memory is sacred** — don't manually edit `memory.md` unless you know what you're doing
- **One task per `/prd-execute`** — this keeps each session focused and memory clean
