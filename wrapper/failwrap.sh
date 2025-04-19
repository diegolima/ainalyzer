#!/usr/bin/env bash

# -------------------------------
# AInalyzer: Automatic CLI Failure Analyzer
# -------------------------------

AINALYZER_CONFIG="$HOME/.ainalyzer/config"
AINALYZER_TMP_OUTPUT="/tmp/ainalyzer_output.$$"
AINALYZER_VERSION="0.1.0"

# Redirect all shell session output (stdout + stderr) to temporary file
exec 3>&1 4>&2
exec > >(tee "$AINALYZER_TMP_OUTPUT") 2>&1

# Defaults
AINALYZER_MODEL=""
AINALYZER_LINE_COUNT=10
AINALYZER_MODE="onrequest"

# -------------------------------
# Load Config Function
# -------------------------------
__ainalyzer_load_config() {
    AINALYZER_MODEL=""
    AINALYZER_LINE_COUNT=10
    AINALYZER_MODE="onrequest"

    if [[ -f "$AINALYZER_CONFIG" ]]; then
        while IFS="=" read -r key value; do
            case "$key" in
                model) AINALYZER_MODEL="$value" ;;
                lines) AINALYZER_LINE_COUNT="$value" ;;
                mode) AINALYZER_MODE="$value" ;;
            esac
        done < "$AINALYZER_CONFIG"
    fi
}

# -------------------------------
# AInalyzer CLI Helper
# -------------------------------
ainalyzer() {
    case "$1" in
        mode)
            if [[ "$2" == "monitor" || "$2" == "onrequest" ]]; then
                sed -i.bak '/^mode=/d' "$AINALYZER_CONFIG"
                echo "mode=$2" >> "$AINALYZER_CONFIG"
                echo "[AInalyzer] Mode set to '$2'"
            else
                echo "[AInalyzer] Invalid mode. Use 'monitor' or 'onrequest'."
                echo "Usage:"
                echo "  ainalyzer mode [monitor|onrequest]"
                return 1
            fi
            ;;
        model)
            if [[ -z "$2" ]]; then
                echo "[AInalyzer] Suggested models:"
                echo "  phi3.5   - phi3.5   - Lightweight, fast, and ideal for users without a GPU or with 4–6GB VRAM."
                echo "  mistral  - Stronger 7B model for users with 6–8GB VRAM (e.g., RTX 4060+), best balance of power and speed."
                echo "  llama3   - Advanced 8B model; requires 10–12GB VRAM or strong CPU setup."
                echo ""
                echo "Current model: $AINALYZER_MODEL"
                echo ""
                echo "Usage:"
                echo "  ainalyzer model <name>"
                
                return 0
            fi

            sed -i.bak '/^model=/d' "$AINALYZER_CONFIG"

            if ! ollama list | grep -q "^$2"; then
                echo "[AInalyzer] Pulling model '$2'..."
                if ! ollama pull "$2"; then
                    echo "[AInalyzer] Failed to pull model '$2'"
                    return 1
                fi
            fi

            printf 'model=%q\n' "$2" >> "$AINALYZER_CONFIG"
            echo "[AInalyzer] Model set to '$2'"
            ;;
        lines)
            if [[ "$2" =~ ^[0-9]+$ ]]; then
                sed -i.bak '/^lines=/d' "$AINALYZER_CONFIG"
                echo "lines=$2" >> "$AINALYZER_CONFIG"
                echo "[AInalyzer] Line count set to '$2'"
            else
                echo "[AInalyzer] Usage: ainalyzer lines <number>"
                return 1
            fi
            ;;
        config|"")
            echo "[AInalyzer] Current configuration:"
            if [[ -f "$AINALYZER_CONFIG" ]]; then
                cat "$AINALYZER_CONFIG"
            else
                echo "(no config found)"
            fi
            ;;
        version)
            echo "AInalyzer version $AINALYZER_VERSION"
            ;;
        *)
            echo "[AInalyzer] Unknown command: $1"
            echo "Usage:"
            echo "  ainalyzer mode monitor      # Automatically check all failed commands"
            echo "  ainalyzer mode onrequest    # Only check when using analyze_on_fail"
            echo "  ainalyzer model <name>      # Set model used by Ollama"
            echo "  ainalyzer lines <number>    # Set number of output lines to analyze"
            echo "  ainalyzer config            # Show current config"
            echo "  ainalyzer version           # Show version"
            ;;
    esac
}

# -------------------------------
# Shared Analysis Function
# -------------------------------
__ainalyzer_analyze() {
    local command="$1"
    local tmp_file="$2"
    local exit_code="$3"

    echo ""
    echo "[AInalyzer] Command failed with exit code $exit_code"
    echo "[AInalyzer] Analyzing last $AINALYZER_LINE_COUNT lines with $AINALYZER_MODEL..."

    local output
    output=$(tail -n "$AINALYZER_LINE_COUNT" "$tmp_file" 2>/dev/null)

    local prompt
    prompt=$(cat <<EOF
You're a helpful command-line assistant.

The user ran the following command (which failed):

$command

Here is the output:

$output

If there are multiple commands, consider only the last. What likely went wrong, and how can it be fixed? 

Keep the explanation short and to the point. 
If you suggest the user to run a command, make sure its in its own line.
Format the message in a way that's appropriate to be displayed on a text-only terminal.
Aim for a message of at most 10 lines (exceed only if absolutely necessary for clarity).
EOF
    )

    echo "$prompt" | ollama run "$AINALYZER_MODEL"
    echo "[AInalyzer] Done."
}

# -------------------------------
# Explicit Call Mode
# -------------------------------
analyze_on_fail() {
    __ainalyzer_load_config

    local tmp_output
    tmp_output=$(mktemp)

    "$@" > >(tee -a "$tmp_output") 2> >(tee -a "$tmp_output" >&2)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        __ainalyzer_analyze "$*" "$tmp_output" "$exit_code"
    fi

    rm -f "$tmp_output"
    return $exit_code
}

# -------------------------------
# Monitor Mode (automatic)
# -------------------------------
__ainalyzer_preexec() {
    __ainalyzer_load_config
}

__ainalyzer_postexec() {
    local exit_code=$?
    __ainalyzer_load_config
    [[ "$AINALYZER_MODE" != "monitor" ]] && return

    if [ $exit_code -ne 0 ]; then
        __ainalyzer_analyze "$(history 1)" "$AINALYZER_TMP_OUTPUT" "$exit_code"
    fi
}

# -------------------------------
# Shell Hook
# -------------------------------
trap '__ainalyzer_preexec' DEBUG
PROMPT_COMMAND='__ainalyzer_postexec'
