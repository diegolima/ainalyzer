#!/usr/bin/env bash

set -e

AINALYZER_DIR="$HOME/.ainalyzer"
CONFIG_FILE="$AINALYZER_DIR/config"
WRAPPER_SOURCE="wrapper/failwrap.sh"
WRAPPER_DEST="$AINALYZER_DIR/failwrap.sh"
DEFAULT_MODEL="mistral"

echo "🧠 Installing AInalyzer..."

# 1. Create ~/.ainalyzer if not exists
mkdir -p "$AINALYZER_DIR"
echo "✅ Created $AINALYZER_DIR"

# 2. Copy the wrapper script
cp "$WRAPPER_SOURCE" "$WRAPPER_DEST"
chmod +x "$WRAPPER_DEST"
echo "✅ Copied wrapper to $WRAPPER_DEST"

# 3. Install Ollama
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

# 4. Pull the model
echo "📦 Downloading model '$DEFAULT_MODEL'..."
ollama pull "$DEFAULT_MODEL"

# 5. Write config file
cat > "$CONFIG_FILE" <<EOF
model=$DEFAULT_MODEL
lines=100
EOF
echo "✅ Wrote config to $CONFIG_FILE"

# 6. Add source line to .bashrc if not already present
BASHRC="$HOME/.bashrc"
SOURCE_LINE="source \"$WRAPPER_DEST\""

if ! grep -Fxq "$SOURCE_LINE" "$BASHRC"; then
    echo "$SOURCE_LINE" >> "$BASHRC"
    echo "✅ Added AInalyzer wrapper to $BASHRC"
else
    echo "ℹ️  Wrapper already sourced in $BASHRC"
fi

echo "🎉 AInalyzer installed! Run commands like:"
echo "    analyze_on_fail your_command_here"

