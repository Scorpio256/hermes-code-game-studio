#!/bin/bash

# --- work from the project root ----------------------------------------------
# Every path below is repo-relative, so a hook invoked with a working directory
# that is not the repo root would silently read and write the WRONG TREE --
# returning a near-empty result instead of the session-recovery block, and
# creating stray trees such as docs/production/session-logs/ on write.
#
# PRECEDENCE IS LOAD-BEARING. A cwd that IS a project root carries real
# information and must win: a caller sitting inside another project means that
# project, not this one. Resolving to the script's own location first would
# override them. So, in order:
#   1. cwd holds project.yaml   -> cwd   (a project root)
#   2. cwd holds .hermes/       -> cwd   (a project root not yet configured),
#      unless cwd is itself named .hermes: a stray .hermes/.hermes/ would
#      make .hermes/ a root, and the hooks would write .hermes/production/
#   3. HERMES_PROJECT_DIR       -> that  (populated in the hook environment),
#      unless it names a .hermes folder, for the same reason as rule 2
#   4. this script's location   -> <root>/.hermes/hooks/../.. by construction
# Rule 4 always works and needs no environment at all; rules 1-2 stop it from
# overriding a caller that legitimately means somewhere else.
#
# NOT an upward search: that resolves a nested project to its parent's config.
if [ -f "project.yaml" ] || { [ -d ".hermes" ] && [ "${PWD##*/}" != ".hermes" ]; }; then
  CCGS_ROOT="$PWD"
elif [ -n "${HERMES_PROJECT_DIR:-}" ] && [ -d "${HERMES_PROJECT_DIR}" ] && case "${HERMES_PROJECT_DIR%/}" in */.hermes|*\\.hermes) false ;; *) true ;; esac; then
  CCGS_ROOT="$HERMES_PROJECT_DIR"
else
  CCGS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
fi
[ -n "$CCGS_ROOT" ] && cd "$CCGS_ROOT" 2>/dev/null || true

# Claude Code PreCompact hook: log the compaction. Nothing else.
#
# PRINTS NOTHING, ON PURPOSE. Claude Code writes PreCompact stdout to the debug
# log and discards its systemMessage (hooks documentation), so a state summary
# printed here reached no one -- and gathering it cost git and grep spawns on
# every compaction. What survives a compaction is the file on disk:
# SessionStart fires again with source `compact`, and session-start.sh shows
# the CHECKPOINT from production/session-state/active.md then.

# features.session_state: off => this hook is a no-op. Default `on`; see
# session_state_enabled() in yaml-helper.sh.
if [ -f .hermes/hooks/yaml-helper.sh ]; then
    . .hermes/hooks/yaml-helper.sh
    session_state_enabled || exit 0
fi

SESSION_LOG_DIR="production/session-logs"
mkdir -p "$SESSION_LOG_DIR" 2>/dev/null
echo "Context compaction occurred at $(date)." \
    >> "$SESSION_LOG_DIR/compaction-log.txt" 2>/dev/null

exit 0
