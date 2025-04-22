#!/usr/bin/env bash

set -e

AINALYZER_DIR="$HOME/.ainalyzer"
CONFIG_FILE="$AINALYZER_DIR/config"
WRAPPER_SOURCE="wrapper/failwrap.sh"
WRAPPER_DEST="$AINALYZER_DIR/failwrap.sh"
PREEXEC_URL="https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh"
PREEXEC_DEST="$AINALYZER_DIR/bash-preexec.sh"
DEFAULT_MODEL="mistral:7b-instruct"
DEFAULT_LINES="10"
DEFAULT_MODE="onrequest"

echo "🧠 Installing AInalyzer..."

# 1. Create ~/.ainalyzer if not exists
mkdir -p "$AINALYZER_DIR"
echo "✅ Created $AINALYZER_DIR"

# 2. Copy the wrapper script
cp "$WRAPPER_SOURCE" "$WRAPPER_DEST"
chmod +x "$WRAPPER_DEST"
echo "✅ Copied wrapper to $WRAPPER_DEST"

# 3. Install bash-preexec
echo "🔧 Installing bash-preexec..."
curl -fsSL "$PREEXEC_URL" -o "$PREEXEC_DEST"
echo "✅ bash-preexec installed at $PREEXEC_DEST"

# 4. Install Ollama
echo "🔍 Checking for Ollama..."

if ! command -v ollama &> /dev/null; then
    echo "⚙️  Ollama not found. Installing..."

    case "$(uname -s)" in
        Linux)
            if command -v apt &> /dev/null; then
                echo "Detected Ubuntu/Debian"
                curl -fsSL https://ollama.com/install.sh | sh
            elif command -v dnf &> /dev/null || command -v yum &> /dev/null; then
                echo "Detected Fedora or RHEL-based system"
                curl -fsSL https://ollama.com/install.sh | sh
            else
                echo "Unsupported Linux distro. Please install Ollama manually."
                exit 1
            fi
            ;;
        Darwin)
            echo "Detected macOS"
            if command -v brew &> /dev/null; then
                brew install ollama
            else
                echo "Homebrew not found. Installing Ollama via script..."
                curl -fsSL https://ollama.com/install.sh | sh
            fi
            ;;
        *)
            echo "Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac
else
    echo "✅ Ollama already installed"
fi

# 5. Pull the model
echo "📦 Downloading model '$DEFAULT_MODEL'..."
ollama pull "$DEFAULT_MODEL"

# 6. Write config file
cat > "$CONFIG_FILE" <<EOF
model=$DEFAULT_MODEL
lines=$DEFAULT_LINES
mode=$DEFAULT_MODE
EOF
echo "✅ Wrote config to $CONFIG_FILE"

# 7. Add source lines to .bashrc if not already present
BASHRC="$HOME/.bashrc"
PREEXEC_LINE="source \"$PREEXEC_DEST\""
WRAPPER_LINE="source \"$WRAPPER_DEST\""

# Insert between markers to avoid duplication
START="# >>> AInalyzer >>>"
END="# <<< AInalyzer <<<"

if ! grep -q "$START" "$BASHRC"; then
  {
    echo "$START"
    echo "$PREEXEC_LINE"
    echo "$WRAPPER_LINE"
    echo "$END"
  } >> "$BASHRC"
  echo "✅ AInalyzer block added to $BASHRC"
else
  echo "ℹ️  AInalyzer block already in $BASHRC"
fi

echo "🎉 AInalyzer installed! Please restart your shell or run:"
echo "source ~/.bashrc"

echo "After that, run commands like:"
echo "    analyze_on_fail your_command_here"
echo ""
echo "💡 To turn on automatic error analysis, run this command:"
echo "    ainalyzer mode monitor"
