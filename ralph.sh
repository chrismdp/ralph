#!/bin/bash

# Ralph Loop - Autonomous engineer relay
# Usage: ./ralph.sh [iterations]
# Default: runs until beads complete or max iterations

set -e

# ANSI colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m' # No colour

MAX_ITERATIONS=${1:-10}
ITERATION=0
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_DIR"

echo -e "${CYAN}>${NC} Starting Ralph Loop in $PROJECT_DIR"
echo "   Max iterations: $MAX_ITERATIONS"
echo ""

# Check beads are ready
if ! command -v bd &> /dev/null; then
    echo -e "${RED}x${NC} bd (beads) not found. Install it first."
    exit 1
fi

# Show initial state
echo -e "${BLUE}>${NC} Current beads status:"
bd ready 2>/dev/null || echo "   No beads ready or bd not initialised"
echo ""

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    # Check for dirty state - if dirty, skip fetch/pull (we're mid-work)
    if git diff --quiet && git diff --cached --quiet; then
        echo -e "${DIM}> Fetching latest changes...${NC}"
        git fetch --quiet
        git pull --rebase --quiet || true
        bd sync 2>/dev/null || true
    else
        echo -e "${YELLOW}> Dirty working tree detected - resuming previous work...${NC}"
    fi

    # Check if there are any beads to work on
    READY_COUNT=$(bd count --status open 2>/dev/null || echo "0")
    IN_PROGRESS=$(bd count --status in_progress 2>/dev/null || echo "0")

    if [ "$READY_COUNT" = "0" ] && [ "$IN_PROGRESS" = "0" ]; then
        echo -e "${DIM}o No beads available. Waiting 20s for new work...${NC}"
        sleep 20
        continue
    fi

    ITERATION=$((ITERATION + 1))
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${CYAN}>${NC} Ralph iteration ${GREEN}$ITERATION${NC} of $MAX_ITERATIONS"
    echo "   Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${CYAN}======================================================${NC}"
    echo ""

    echo -e "${BLUE}> Spawning Claude engineer...${NC}"
    echo ""

    # Stream output with clean formatting
    # Note: Most of this complexity is parsing Claude's streaming JSON
    # to show what Ralph is doing. The -p flag doesn't give verbose output.
    claude --permission-mode acceptEdits --verbose --print "Read @RALPH.md and follow the instructions. Pick up where the last engineer left off. Complete ONE bead." --output-format stream-json | while read -r line; do
        type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
        if [ "$type" = "assistant" ]; then
            # Show text
            echo "$line" | jq -r '.message.content[]? | select(.type == "text") | .text' 2>/dev/null | while IFS= read -r text; do
                [ -z "$text" ] && continue
                echo -e "${BLUE}>${NC} $text"
            done
            # Show tool calls concisely: > tool_name { inputs }
            echo "$line" | jq -c '.message.content[]? | select(.type == "tool_use")' 2>/dev/null | while read -r tool; do
                [ -z "$tool" ] && continue
                name=$(echo "$tool" | jq -r '.name' 2>/dev/null)
                input=$(echo "$tool" | jq -c '.input' 2>/dev/null)
                echo -e "${YELLOW}>${NC} ${CYAN}$name${NC} ${DIM}$input${NC}"
            done
        elif [ "$type" = "user" ]; then
            # Show tool results cleanly
            echo "$line" | jq -c '.message.content[]? | select(.type == "tool_result")' 2>/dev/null | while read -r result; do
                [ -z "$result" ] && continue
                is_error=$(echo "$result" | jq -r '.is_error // false' 2>/dev/null)
                # Extract and clean content
                content=$(echo "$result" | jq -r '
                    .content |
                    if type == "array" then
                        map(select(.type == "text") | .text) | join("\n")
                    elif type == "string" then
                        .
                    else
                        "..."
                    end
                ' 2>/dev/null | tr -d '\r' | head -n 20)
                # Truncate if contains base64 image data
                if echo "$content" | grep -q '/9j/4AAQ\|data:image'; then
                    content="[image captured]"
                fi
                # Format line numbers
                formatted=$(echo "$content" | sed -E "s/^([[:space:]]*[0-9]+)>/\x1b[2m\1\x1b[0m  /")
                if [ "$is_error" = "true" ]; then
                    echo ""
                    echo -e "${RED}x${NC}"
                    echo -e "$formatted"
                else
                    echo ""
                    echo -e "${DIM}o${NC}"
                    echo -e "$formatted"
                fi
            done
        elif [ "$type" != "system" ]; then
            echo -e "${DIM}? $line${NC}"
        fi
    done

    echo ""
    echo -e "${GREEN}ok${NC} Iteration $ITERATION complete"
    echo ""
    sleep 2
done

echo ""
echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}done${NC} Ralph loop finished"
echo "   Total iterations: $ITERATION"
echo "   Ended: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo -e "${BLUE}>${NC} Final beads status:"
bd ready 2>/dev/null || echo "   No beads ready"
echo -e "${CYAN}======================================================${NC}"
