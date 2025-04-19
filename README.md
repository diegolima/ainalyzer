# AInalyzer: Automatic CLI Failure Analyzer

[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg?cacheSeconds=2592000)](https://github.com/diegolima/ainalyzer/releases/tag/v0.1.0)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![Supports Linux | macOS](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey)
![Requires Ollama](https://img.shields.io/badge/requires-Ollama-orange)

**Understand your command-line errors instantly with AInalyzer!**

AInalyzer is a bash script designed to automatically analyze failed command-line executions using the power of local Large Language Models (LLMs) via [Ollama](https://ollama.com/). It aims to provide you with clear explanations and potential solutions directly in your terminal, making debugging faster and less frustrating.

## Features

* **Automatic Analysis (Monitor Mode):** Optionally analyze every failed command automatically in your shell session.
* **On-Demand Analysis:** Use the `analyze_on_fail` command to explicitly analyze specific commands upon failure.
* **Powered by Local LLMs:** Leverages the speed, privacy, and offline capabilities of locally running models through Ollama.
* **Configurable LLM:** Choose from various Ollama-compatible models to balance performance and analysis quality (defaults to `mistral`).
* **Adjustable Output Context:** Control the number of previous command output lines sent for analysis.
* **Simple Command-Line Interface:** Easily manage AInalyzer's settings (mode, model, lines) using the `ainalyzer` command.
* **Hassle-Free Installation:** Includes an automated installer for easy setup on Linux and macOS.

## Quick Start (for Impatient Hackers 😎)

```bash
git clone https://github.com/diegolima/ainalyzer.git
cd ainalyzer
./install.sh
source ~/.bashrc
analyze_on_fail ls /this/does/not/exist
```

## Installation

Follow these steps to install AInalyzer:

1.  **Clone the repository (if you haven't already):**
    ```bash
    git clone https://github.com/diegolima/ainalyzer.git
    cd ainalyzer
    ```

2.  **Run the installer script:**
    ```bash
    ./install.sh
    ```
    The installer will:
    * Create the necessary directory (`~/.ainalyzer`).
    * Copy the AInalyzer script.
    * **Check for and optionally install Ollama.**
    * **Download the default language model (`mistral`).**
    * Create a default configuration file (`~/.ainalyzer/config`).
    * Add a line to your `~/.bashrc` to automatically load AInalyzer in new terminal sessions.

3.  **Restart your terminal or source your `.bashrc`:**
    ```bash
    source ~/.bashrc
    ```

## Usage

AInalyzer offers two main modes of operation:

### 1. On-Demand Analysis (`analyze_on_fail`)

To analyze a specific command if it fails, simply prepend `analyze_on_fail` to your command:

```bash
analyze_on_fail your_command_that_might_fail
```

If `your_command_that_might_fail` exits with a non-zero status, AInalyzer will analyze the last few lines of its output using the configured LLM and display the explanation and potential solutions in your terminal.

### 2. Automatic Analysis (`monitor` mode)

You can configure AInalyzer to automatically analyze every failed command in your shell session. To enable this mode, use the `ainalyzer` command:

```bash
ainalyzer mode monitor
```

To switch back to on-demand analysis:

```bash
ainalyzer mode onrequest
```

### Managing Configuration

The `ainalyzer` command also allows you to manage other settings:

  * **Set the LLM model:**

    ```bash
    ainalyzer model llama3
    ainalyzer model phi3.5
    ainalyzer model # Lists suggested models and the current model
    ```

    AInalyzer uses [Ollama](https://ollama.com/) to run language models locally. You can choose any model supported by Ollama. The script provides suggestions for models with different resource requirements. If the specified model is not already downloaded, AInalyzer will attempt to pull it using `ollama pull`.

    AInalyzer recommends:
      - `phi3.5` – Fast and lightweight for CPU users or smaller GPUs (4–6GB VRAM)
      - `mistral` – More powerful 7B model for larger GPUs (6–12GB VRAM)
      - `llama3` – Large model for users with 12GB+ VRAM (optional)

  * **Set the number of output lines to analyze:**

    ```bash
    ainalyzer lines 20
    ainalyzer lines 5
    ```

    This command sets the number of lines of the failed command's output that will be sent to the LLM for analysis.

  * **View the current configuration:**

    ```bash
    ainalyzer config
    ```

    Displays the current settings from the `~/.ainalyzer/config` file.

  * **Check the AInalyzer version:**

    ```bash
    ainalyzer version
    ```

## Why Local LLMs?

AInalyzer utilizes local LLMs for several key benefits:

  * **Speed:** Faster analysis by avoiding network latency.
  * **Offline Use:** Ability to analyze errors even without an internet connection (after the model is downloaded).
  * **Privacy:** Your commands and their output are processed locally and never sent to a third-party service.
  * **No Service Fees:** Once set up, there are no recurring costs associated with using the analysis features.

## Dependencies

  * **bash:** Currently supports **bash**. Zsh and Fish support coming soon. Stay tuned!
  * **Ollama:** [https://ollama.com/](https://ollama.com/) AInalyzer relies on Ollama to run language models locally. The installer attempts to install it if not found.

## Contributing

Contributions are welcome! Feel free to open issues for bug reports or suggest enhancements.

## License

This project is licensed under the **GNU General Public License v3.0**. See [GPL v3 License](https://www.gnu.org/licenses/gpl-3.0.en.html) for more details.

-----

**Enjoy a smoother command-line experience with AInalyzer! 🚀**