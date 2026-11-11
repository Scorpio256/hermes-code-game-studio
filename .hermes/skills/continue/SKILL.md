---
name: continue
description: "Resume the project's active work from production/session-state/active.md — run its CHECK, do the next unchecked TODO item, update the file on the fly; ends with 'all done' when nothing remains. Use when the user says continue, resume, what's next, restarts after a crash, or assigns new work to checkpoint."
argument-hint: "[new task — starts a fresh checkpoint when none remains]"
user-invocable: true
---

# Continue

The single driver for active project work. The checkpoint file
`production/session-state/active.md` is the memory, not the conversation.
Every job in this project is tracked there (see AGENTS.md → Context
management); this skill is how it gets done, one session at a time,
crash-proof.

## Invocations

- **`continue`** (no args) — resume the existing checkpoint.
- **`continue <task>`** — if the checkpoint has no unchecked items, write a
  fresh one from the template, then resume. If unchecked items exist, append
  the new task to the TODO list (as a checkbox item) and resume at the first
  unchecked item.

## Resume loop (every invocation, in order)

1. **Read the whole checkpoint file.**
   - Header says `Status: COMPLETE` → respond exactly: `all done`
   - File missing and no task given → say there is no active work and ask
     for a task. Do not invent work.
2. **Run the CHECK section** (phase-specific: server/queue liveness, path
   verification, git state, references). If CHECK blocks (e.g. background job
   running, queue non-empty): follow wait rules — wait until resources are
   available before starting new heavy work. If a user decision is needed:
   ask, record it in the Progress log, end the turn.
3. **Do the first unchecked `- [ ]` TODO item** — all of its sub-steps, but
   never later items. Only start the next item once the current one is
   completely done AND the file is updated.
4. **Update the file on the fly, before ending the turn, after every
   meaningful milestone** (asset generated + verified on disk, code changed,
   tests run, evidence captured, decision made, blocker hit):
   - tick finished sub-items,
   - **add any newly discovered work** (failed assets to redo, new
     subtasks, blockers, scope additions) to the TODO as checkbox
     items/subtasks — the TODO is a living document; work must never exist
     only in the conversation,
   - append one newest-first Progress log line: date + what happened + next,
   - refresh `Last updated` in the header.
   A crashed session must lose nothing: the file always reflects reality.
5. **Show, don't tell** — visual milestones (generated images, contact
   sheets, in-game screenshots, recordings) go to the user as images/artifacts,
   not just plain text paths.
6. End the turn with: what got done, what's next, and one line: run
   `continue` again to resume.

## All done

When every TODO item is `- [x]` and verified: set `Status: COMPLETE` in the
header, append the final Progress log line, and respond exactly:

all done

## Hard rules (non-negotiable)

- Resource-intensive / GPU operations: wait for them to finish before
  launching competing heavy tasks. Never kill user server processes to force headroom.
- Live file updates after every milestone — never batched to session end.
- **The TODO is a living document:** new tasks/subtasks discovered mid-work
  are written into the file before the turn ends, so a failed session loses
  nothing.
- Act, don't over-think or ramble: milestone → file update → show result.
- No commits without explicit user instruction.
- The checkpoint's own phase-specific "Hard rules" section overrides
  defaults here.
- If the session may end (crash risk, budget, token limit): the file update
  comes first, every time.

## New checkpoint template

```markdown
# ACTIVE — <phase name>

> **Status: IN PROGRESS** · Last updated <date> (<one-line state>)

<!-- STATUS -->
Epic:
Feature:
Task: <active task>
<!-- /STATUS -->

<!-- CHECKPOINT -->
**Updated:** <YYYY-MM-DD>
**Branch:** `<branch>`
**Current task:** <one line — what is actively being worked on>
**Next step:** <one line — the very next action, concrete enough to resume cold>
**Blocked on:** nothing
**Files in progress:** none
<!-- /CHECKPOINT -->

## Project facts
- <paths, references, committed-through commit, current git state>

## Verified environment
- <tools/servers with live-verified paths, queue state, script locations>

## CHECK (run before acting)
1. <liveness/queue checks>
2. <path verification — re-resolve volatile paths from live state>
3. <view current state against references>

## TODO
- [ ] **1. <item>** — <acceptance criteria>
- [ ] **2. <item>**

## Progress log (newest first)
- <date> — checkpoint written; environment verified; next: TODO 1.

## Hard rules
- <phase-specific user corrections>
```
