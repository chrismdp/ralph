# Ralph

A simple autonomous engineering loop for Claude Code. Named after Ralph Wiggum because [dumber methods win](https://www.chrismdp.com/your-agent-orchestrator-is-too-clever/).

Ralph treats each Claude session as one engineer in a relay team. Each picks up where the last left off, completes ONE task, commits, and exits. The bash loop spawns the next engineer.

## Why Ralph?

Complex agent orchestrators encode assumptions about how work should flow. Ralph encodes almost nothing. It just runs Claude in a loop and lets the model figure out what to do next.

This works because:
- Modern models (Opus 4.5, GPT 5.2) are good enough to handle reasonable tasks without elaborate guardrails
- Files and git commits carry state between sessions, not conversation history
- Failures are predictable because the prompt never changes
- The model can break large tasks into smaller ones when needed

Read more: [Ralph Loops: Your Agent Orchestrator Is Too Clever](https://www.chrismdp.com/your-agent-orchestrator-is-too-clever/)

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed and authenticated
- [Beads](https://github.com/steveyegge/beads) for task management (`cargo install beads`)
- `jq` for JSON parsing (`brew install jq` on macOS)

## Setup

### Step 1: Initialise your project

```bash
cd your-project
bd init
```

### Step 2: Copy Ralph files

Copy `ralph.sh` and `RALPH.md` to your project root:

```bash
curl -O https://raw.githubusercontent.com/chrismdp/ralph/main/ralph.sh
curl -O https://raw.githubusercontent.com/chrismdp/ralph/main/RALPH.md
chmod +x ralph.sh
```

### Step 3: Customise RALPH.md

Edit `RALPH.md` to match your project:

- Update the test command (line 10) to match your stack
- Add any project-specific verification steps
- Link to your project documentation for context

### Step 4: Create some beads

```bash
bd create "Implement user login form"
bd create "Add password validation"
bd create "Create logout endpoint"
```

### Step 5: Run Ralph

```bash
./ralph.sh        # Run up to 10 iterations (default)
./ralph.sh 5      # Run up to 5 iterations
./ralph.sh 100    # Run up to 100 iterations
```

Ralph will:
1. Check for in-progress or ready beads
2. Spawn a Claude session to work on one bead
3. Wait for `RALPH_DONE` signal
4. Repeat until max iterations or no work remains

## The Two-Layer Setup

For longer sessions, run Ralph PM alongside the build loop:

**Terminal 1 (Ralph Loop):**
```bash
./ralph.sh 100
```

**Terminal 2 (Ralph PM):**
```bash
claude
# Then interactively add beads, discuss priorities, handle blocked items
```

The PM can feed work into the system while Ralph keeps building. Use git worktrees to prevent commit conflicts:

```bash
# In .beads/config.toml
[sync]
branch = "beads-sync"
```

## Token Usage

Ralph burns through tokens. Running this setup continuously requires a Max20 plan or higher. The value is worth it if you're building something real.

## Tips from Production Use

**Context is investment.** When Ralph blocks on a decision, treat it as a context failure. Add more documentation so future sessions can decide autonomously.

**Manual testing labels.** Some things can't be automated (microphone input, complex gestures). Tag these beads with `manual-testing` and handle them in interactive sessions.

**Symlink your notes.** If you have a second brain or documentation vault, symlink relevant files into the repo so Ralph can look things up.

**The output parsing is ugly.** Most of `ralph.sh` is parsing Claude's streaming JSON to show what's happening. The `-p` flag doesn't give verbose output, so you construct your own display. It's not perfect but it works.

## Files

- `ralph.sh` - The outer loop that spawns Claude sessions
- `RALPH.md` - Instructions for each "engineer" session

## Related

- [Beads](https://github.com/steveyegge/beads) - Task management for agents
- [ralph-kit](https://github.com/joshski/ralph-kit) - Josh Chisholm's ready-to-use template
- [Gas Town](https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04) - Steve Yegge's more elaborate (too elaborate?) system

## Licence

MIT
