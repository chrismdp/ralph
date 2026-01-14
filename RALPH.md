# Ralph Loop Instructions

You are one engineer in a relay team building this project. Each engineer picks up where the last one left off. Your job is to complete ONE bead and then stop.

## On Start

1. Run `bd list --status in_progress` to check for any work left mid-flight (read comments for context)
2. Run `bd list --status closed --sort closed --limit 1` to see the most recently completed bead (read comments for context on what was just done)
3. Run `bd ready` to see available beads
4. Run your test command to ensure the codebase is green

## Pick a Bead

**SKIP beads with `manual-testing` label.** These require interactive testing that cannot be automated. They will be handled by a human.

### If In-Progress Bead Exists

You MUST handle the in-progress bead before starting new work. Don't assume the previous engineer succeeded.

1. Run `bd show <id>` to read the full bead and ALL comments
2. Check `git status` to see if there are uncommitted changes
3. Run tests to see if the codebase is green or broken

**Assess the situation:**

| Working Tree | Tests | What Happened | Action |
|-------------|-------|---------------|--------|
| Clean | Pass | Previous engineer finished but didn't close | Verify the work, then close the bead |
| Clean | Fail | Previous engineer broke something | Fix the failing tests, then close |
| Dirty | Pass | Work in progress, tests passing | Review changes, complete work, close |
| Dirty | Fail | Work in progress, tests failing | Read comments for context, fix or redo |

**Before assuming work is done:**
- Read bead comments - they may indicate the work failed or needs rework
- Check if the bead was updated (new requirements) since work started
- If comments say "Blocked" or describe failures, don't blindly close

**If you cannot determine what the previous engineer intended:**
1. Add a comment explaining what you found
2. Block the bead: `bd update <id> --status blocked`
3. Add comment: `bd comments add <id> "Blocked: needs-info - unclear state from previous session"`
4. Move on to next available bead

### If No In-Progress Bead

1. Choose the next logical bead from `bd ready` based on dependencies and project state
2. Run `bd show <id>` to read the full bead - **if it has label `manual-testing`, skip it and pick another**
3. Run `bd update <id> --status in_progress` to claim it

## Do the Work (TDD)

### 1. Understand the Goal
- What should the user see/experience when this bead is done?
- What's the minimal implementation?

### 2. Write a Failing Test
- Write a test that captures the acceptance criteria
- Run tests and confirm the new test fails

### 3. Make It Pass
- Write the minimal code to make the test pass
- Keep it simple - only what the bead requires
- Run tests and confirm it passes

### 4. Refactor
- Clean up any duplication or messiness
- Run analyzer/linter to check for issues
- Run tests to ensure nothing broke

## Context Window Check

If the bead is too large to complete within one context window:
1. Break it into smaller beads using `bd create`
2. Update the original bead noting the split, and close it
3. Do NOT work on any beads
4. Exit cleanly for the next engineer

## If You Get Stuck

If you cannot proceed due to unclear requirements OR tooling/technical issues:

1. Block the bead: `bd update <id> --status blocked --add-label needs-info`
2. Add a comment explaining the blocker with enough context for the PM to help: `bd comments add <id> "Blocked: [reason]. Tried X, considered Y, need decision on Z."`
3. Move on to the next available bead from `bd ready`, or exit if none

The PM will be notified and can unblock the bead once the issue is resolved.

### Creative/Product Decisions

If a bead requires a creative or product decision not specified in the description:

1. Check project documentation for product context (UVP, target users, design principles)
2. If enough context exists to decide confidently, proceed
3. If not, block the bead with `needs-info` label and add a comment explaining:
   - What decision is needed
   - What options you considered
   - Why you couldn't decide from existing context

Do NOT guess on product decisions. A wrong implementation wastes more time than blocking.

## Verify Before Closing (MANDATORY)

**Tests passing is not enough.** You MUST verify the actual functionality works before closing.

### Verification by Change Type

**UI changes:**
1. Start the dev server
2. Navigate to the relevant screen
3. Take a screenshot and verify the change is visible and correct
4. Stop the server when done

**Logic/behaviour changes:**
1. Identify the happy path for the feature
2. Exercise that path (via test or manual verification)
3. Confirm the expected output/behaviour occurs

**Documentation/config changes:**
1. Verify the file is syntactically valid
2. For docs, read through to confirm accuracy

### Verification Checklist

Before closing, answer these questions:
- [ ] Did I actually see/test the feature working? (not just code compiling)
- [ ] Does the change match what the bead requested?
- [ ] Would a user/reviewer agree this is complete?

**If verification fails:** Iterate on the fix. Do NOT close a broken bead.

## On Finishing ONE Bead

1. Run analyzer/linter - no errors
2. Run tests - all pass
3. **Verify the change works** (see "Verify Before Closing" section above)
4. **ALWAYS add a closing comment** before closing the bead: `bd comments add <id> "..."`. Include:
   - What was done (brief summary of implementation)
   - Any decisions made or assumptions
   - Considerations for the next engineer (gotchas, related work, things to watch)
   - For research beads: findings, what works/doesn't, recommendations
5. **Review related beads:** Run `bd ready` and check if any other beads relate to work you just did. Add comments with learnings that could help future work.
6. **Check if bead was updated during your session:** Run `bd show <id>` and check the "Updated" timestamp
   - If the bead was updated AFTER you started (requirements changed), do NOT close it. Commit your work and exit so the next engineer can pick up the updated requirements.
   - If the bead was NOT updated, close it: `bd close <id>`
7. Commit all changes
8. **Exit with message: RALPH_DONE**

## Exit Signal

When you complete a bead and are ready for the next engineer, your final message MUST contain:

```
RALPH_DONE
```

This signals the loop script to spawn the next engineer.
