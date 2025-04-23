#!/usr/bin/env bash

# -------------------------------
# AInalyzer: Automatic CLI Failure Analyzer
# -------------------------------

AINALYZER_CONFIG="$HOME/.ainalyzer/config"
AINALYZER_VERSION="0.2.1"

AINALYZER_MODEL=""
AINALYZER_LINE_COUNT=10
AINALYZER_MODE="onrequest"

AINALYZER_LAST_CMD=""
AINALYZER_TMP_OUTPUT=""
AINALYZER_OUTPUT_LINE_OFFSET=0

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
                echo "  llama3.2:3b         - A fast and lightweight model offering a good balance of speed and reasonable understanding for basic error analysis."
                echo "  mistral:7b-instruct - A more powerful model providing stronger reasoning capabilities and a good balance of power and speed for more complex errors."
                echo "  llama3.1:8b         - A larger model that can offer the most comprehensive and nuanced analysis but requires significant resources."
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
                uninstall)
            echo "[AInalyzer] Uninstall requested."

            read -p "⚠️  Are you sure you want to uninstall AInalyzer? [y/N] " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo "[AInalyzer] Uninstall cancelled."
                return 0
            fi

            # Remove sourced lines from .bashrc
            BASHRC="$HOME/.bashrc"
            START="# >>> AInalyzer >>>"
            END="# <<< AInalyzer <<<"

            if grep -q "$START" "$BASHRC"; then
                sed -i.bak "/$START/,/$END/d" "$BASHRC"
                echo "[AInalyzer] Removed lines from .bashrc"
            else
                echo "[AInalyzer] No AInalyzer block found in .bashrc"
            fi

            # Delete config + wrapper directory
            if [[ -d "$HOME/.ainalyzer" ]]; then
                rm -rf "$HOME/.ainalyzer"
                echo "[AInalyzer] Deleted ~/.ainalyzer directory"
            else
                echo "[AInalyzer] ~/.ainalyzer not found"
            fi

            echo "[AInalyzer] Uninstallation complete."
            echo "💡 You may want to run: source ~/.bashrc"
            echo ""
            echo "⚠️  Note: Ollama and any downloaded models were not removed."
            echo "         These may still be using disk space."
            echo ""
            echo "💡 To remove the default model and free up space, you can run:"
            echo "   ollama rm mistral:7b-instruct"
            echo ""
            echo "🧼 To list all Ollama models and remove others, run:"
            echo "   ollama list"
            echo "   ollama rm <model-name>"

            # Detect OS and suggest Ollama uninstall command
            OS_TYPE="$(uname -s)"
            echo ""

            case "$OS_TYPE" in
                Linux)
                    if command -v apt &>/dev/null; then
                        echo "💣 To completely uninstall Ollama on Ubuntu/Debian, run:"
                        echo "   sudo apt remove ollama"
                    elif command -v dnf &>/dev/null; then
                        echo "💣 To completely uninstall Ollama on Fedora, run:"
                        echo "   sudo dnf remove ollama"
                    elif command -v yum &>/dev/null; then
                        echo "💣 To completely uninstall Ollama on CentOS/RHEL, run:"
                        echo "   sudo yum remove ollama"
                    else
                        echo "💣 To remove Ollama manually, delete its files and binaries from:"
                        echo "   ~/.ollama and /usr/local/bin/ollama (if applicable)"
                    fi
                    ;;
                Darwin)
                    if command -v brew &>/dev/null; then
                        echo "💣 To completely uninstall Ollama on macOS (with Homebrew), run:"
                        echo "   brew uninstall ollama"
                    else
                        echo "💣 To remove Ollama manually, delete:"
                        echo "   /Applications/Ollama.app and /usr/local/bin/ollama"
                    fi
                    ;;
                *)
                    echo "💣 Unknown OS: $OS_TYPE. Please uninstall Ollama manually if needed."
                    ;;
            esac
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
    output=$(sed -e 's/[[:space:]]*$//' <<< "$output")

    if [[ -z "$output" ]]; then
        output="[no output captured from the failed command]"
        return 0
    else
        if [[ $AINALYZER_DEBUG == "true" ]]; then
            echo ""
            echo "========= [AInalyzer - DEBUG] Sending the following output to the LLM: ========="
            echo $output
            echo "========= [AInalyzer - DEBUG] End of output ===================================="
        fi
    fi

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

    local response
    response=$(echo "$prompt" | ollama run "$AINALYZER_MODEL")

    # Print AI output in cyan
    echo -e "\e[36m$response\e[0m"

    echo "[AInalyzer] Done."
}

# -------------------------------
# Explicit Call Mode
# -------------------------------
analyze_on_fail() {
    __ainalyzer_load_config

    local tmp_output
    tmp_output=$(mktemp)

    (
        trap '' SIGINT
        "$@" > >(tee -a "$tmp_output") 2> >(tee -a "$tmp_output" >&2)
    )
    local exit_code=$?

    if [ $exit_code -ne 0 ] && [ $exit_code -ne 130 ]; then
        __ainalyzer_analyze "$*" "$tmp_output" "$exit_code"
    fi

    rm -f "$tmp_output"
    return $exit_code
}

# -------------------------------
# bash-preexec Hook Integration
# -------------------------------
preexec() {
    __ainalyzer_load_config
    [[ "$AINALYZER_MODE" != "monitor" ]] && return

    AINALYZER_LAST_CMD="$1"
    AINALYZER_TMP_OUTPUT=$(mktemp)

    # Save original FDs
    exec 3>&1 4>&2
    exec > >(tee -a "$AINALYZER_TMP_OUTPUT") 2>&1

    # Record how many lines exist in the file before the command runs
    AINALYZER_OUTPUT_LINE_OFFSET=$(wc -l < "$AINALYZER_TMP_OUTPUT")
}

precmd() {
    local exit_code=$?
    __ainalyzer_load_config
    [[ "$AINALYZER_MODE" != "monitor" ]] && return
    [[ $exit_code -eq 0 || $exit_code -eq 130 ]] && return

    # Restore stdout/stderr
    exec 1>&3 2>&4

    if [[ -n "$AINALYZER_LAST_CMD" && -f "$AINALYZER_TMP_OUTPUT" ]]; then
        # Extract only output from the last command
        local sliced_output
        sliced_output=$(mktemp)
        tail -n +"$((AINALYZER_OUTPUT_LINE_OFFSET + 1))" "$AINALYZER_TMP_OUTPUT" \
            | tail -n "$AINALYZER_LINE_COUNT" > "$sliced_output"

        __ainalyzer_analyze "$AINALYZER_LAST_CMD" "$sliced_output" "$exit_code"
        rm -f "$sliced_output"
        rm -f "$AINALYZER_TMP_OUTPUT"
    fi

    AINALYZER_LAST_CMD=""
    AINALYZER_TMP_OUTPUT=""
    AINALYZER_OUTPUT_LINE_OFFSET=0
}
