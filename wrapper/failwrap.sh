#!/usr/bin/env bash

# Default number of lines to send to the model
AINALYZER_LINE_COUNT=100
AINALYZER_CONFIG="$HOME/.ainalyzer/config"

# Load model from config
if [[ -f "$AINALYZER_CONFIG" ]]; then
    AINALYZER_MODEL=$(grep "^model=" "$AINALYZER_CONFIG" | cut -d= -f2)
else
    echo "AInalyzer config not found at $AINALYZER_CONFIG"
    echo "Please run the installer to set up your model."
    return 1
fi

analyze_on_fail() {
    local tmp_output
    tmp_output=$(mktemp)

    # Run the command, saving stdout and stderr
    "$@" > >(tee -a "$tmp_output") 2> >(tee -a "$tmp_output" >&2)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo ""
        echo "[AInalyzer] Command '$*' failed with exit code $exit_code"
        echo "[AInalyzer] Analyzing the last $AINALYZER_LINE_COUNT lines of output with '$AINALYZER_MODEL'..."

        tail -n "$AINALYZER_LINE_COUNT" "$tmp_output" | ollama run "$AINALYZER_MODEL" --system "You're an AI assistant that helps debug failed command-line programs. Be concise and helpful." --prompt "The following command failed:\n\n$*\n\nHere is the output:\n\n{{input}}\n\nWhat likely went wrong, and how can it be fixed?"

        echo "[AInalyzer] Done."
    fi

    rm -f "$tmp_output"
    return $exit_code
}
