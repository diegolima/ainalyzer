# AInalyzer – Automatic CLI Failure Analyzer Using Local AI Models (LLMs)

[![Version](https://img.shields.io/badge/version-0.2.1-blue.svg?cacheSeconds=2592000)](https://github.com/diegolima/ainalyzer/releases/tag/v0.2.1)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![Supports Linux | macOS](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey)
![Requires Ollama](https://img.shields.io/badge/requires-Ollama-orange)
![Requires bash-preexec](https://img.shields.io/badge/requires-bash--preexec-brightgreen)

**Understand your command-line errors instantly with AInalyzer!**

AInalyzer is a bash script designed to automatically analyze failed command-line executions using the power of local Large Language Models (LLMs) via [Ollama](https://ollama.com/) and [bash-preexec](https://github.com/rcaloras/bash-preexec). It aims to provide you with clear explanations and potential solutions directly in your terminal, making debugging faster and less frustrating.

## Features

* **Automatic Analysis (Monitor Mode):** Automatically analyzes failed commands in your shell session using `bash-preexec` for reliable output capture.
* **On-Demand Analysis:** Explicitly analyze specific commands upon failure using the `analyze_on_fail` command.
* **Powered by Local LLMs:** Leverages the speed, privacy, and offline capabilities of locally running models through Ollama.
* **Configurable LLM:** Choose from various Ollama-compatible models to balance performance and analysis quality (defaults to `mistral:7b-instruct`).
* **Adjustable Output Context:** Control the number of lines of the failed command's output (both stdout and stderr) sent for analysis.
* **Simple Command-Line Interface:** Easily manage AInalyzer's settings (mode, model, lines) using the `ainalyzer` command.
* **Hassle-Free Installation:** Includes an automated installer for easy setup on Linux and macOS, including the installation of `bash-preexec`.

## Quick Start (for Impatient Hackers 😎)

```bash
git clone https://github.com/diegolima/ainalyzer.git
cd ainalyzer
./install.sh
source ~/.bashrc

# Test that it works:
analyze_on_fail ls /not/a/real/path
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
    * **Download the default language model (`mistral:7b-instruct`).**
    * **Download and install `bash-preexec` for robust command output capture.**
    * Create a default configuration file (`~/.ainalyzer/config`).
    * Add lines to your `~/.bashrc` to automatically load AInalyzer and `bash-preexec` in new terminal sessions.

3.  **Restart your terminal or source your `.bashrc`:**
    ```bash
    source ~/.bashrc
    ```

4. **Test that it works:**
    ```bash
    analyze_on_fail ls /not/a/real/path
    ls: cannot access '/not/a/real/path': No such file or directory

    [AInalyzer] Command failed with exit code 2
    [AInalyzer] Analyzing last 10 lines with mistral:7b-instruct...
    The error message indicates that the specified path `/not/a/real/path` does not exist on your system. To fix this issue, you need to provide a valid path or create the required directory. Here is an example of creating a new directory:

    mkdir /new/directory/path

    After creating the directory, you can run the `ls` command again to list its contents:

    ls /new/directory/path

    [AInalyzer] Done.
    ```

## Usage

AInalyzer offers two main modes of operation:

### 1. On-Demand Analysis (`analyze_on_fail`)

To analyze a specific command if it fails, simply prepend `analyze_on_fail` to your command:

```bash
analyze_on_fail your_command_that_might_fail
```

If `your_command_that_might_fail` exits with a non-zero status (excluding 130 for Ctrl+C), AInalyzer will analyze the last few lines of its output using the configured LLM and display the explanation and potential solutions in your terminal.

### 2. Automatic Analysis (`monitor` mode)

You can configure AInalyzer to automatically analyze every failed command in your shell session. This mode relies on `bash-preexec` to capture command output before execution. To enable this mode, use the `ainalyzer` command:

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
    ainalyzer model llama3.2:3b
    ainalyzer model mistral:7b-instruct
    ainalyzer model llama3.1:8b
    ainalyzer model # Lists suggested models and the current model
    ```

    AInalyzer uses [Ollama](https://ollama.com/) to run language models locally. You can choose any model supported by Ollama. The script provides suggestions for models with different resource requirements. If the specified model is not already downloaded, AInalyzer will attempt to pull it using `ollama pull`.

    AInalyzer recommends the following models based on your system's resources:

      - **For CPU or smaller GPUs (4–6GB VRAM):** `llama3.2:3b` – A fast and lightweight model offering a good balance of speed and reasonable understanding for basic error analysis.
      - **For larger GPUs (6–12GB VRAM):** `mistral:7b-instruct` – A more powerful model providing stronger reasoning capabilities and a good balance of power and speed for more complex errors. **This is the default model.**
      - **For high-end systems (12GB+ VRAM):** `llama3.1:8b` – A larger model that can offer the most comprehensive and nuanced analysis but requires significant resources.

  * **Set the number of output lines to analyze:**

    ```bash
    ainalyzer lines 20
    ainalyzer lines 5
    ```

    This command sets the number of lines from the failed command's output (both stdout and stderr) that will be sent to the LLM for analysis.

  * **View the current configuration:**

    ```bash
    ainalyzer config
    ```

    Displays the current settings from the `~/.ainalyzer/config` file.

  * **Check the AInalyzer version:**

    ```bash
    ainalyzer version
    ```

## How Automatic Analysis Works (`monitor` mode)

When "monitor" mode is enabled, AInalyzer utilizes the `bash-preexec` tool to capture the output (both stdout and stderr) of each command *before* it executes. After the command finishes, AInalyzer checks its exit code. If the command failed (exited with a non-zero status), the captured output is analyzed using the configured LLM, and the results are displayed in your terminal.

## Why Local LLMs?

AInalyzer utilizes local LLMs for several key benefits:

  * **Speed:** Faster analysis by avoiding network latency.
  * **Offline Use:** Ability to analyze errors even without an internet connection (after the model is downloaded).
  * **Privacy:** Your commands and their output are processed locally and never sent to a third-party service.
  * **No Service Fees:** Once set up, there are no recurring costs associated with using the analysis features.

## Uninstallation

To uninstall AInalyzer, you can use the built-in `uninstall` command:

```bash
ainalyzer uninstall
```

Running this command will:

* Remove the lines added to your `~/.bashrc` by the installer.
* Delete the `~/.ainalyzer` directory, which contains the configuration file and the AInalyzer script itself.

**Note:** This command will **not** automatically remove Ollama or any downloaded language models. To remove these, please follow the instructions provided by the `ainalyzer uninstall` command after it has completed the AInalyzer-specific cleanup. This typically involves using your system's package manager (e.g., `apt`, `dnf`, `brew`) or manually deleting the Ollama application and its data directories.

## Dependencies

  * **bash:** Currently supports **bash**. Zsh and Fish support coming soon. Stay tuned!
  * **Ollama:** [https://ollama.com/](https://ollama.com/) AInalyzer relies on Ollama to run language models locally. The installer attempts to install it if not found.
  * **bash-preexec:** [https://github.com/rcaloras/bash-preexec](https://github.com/rcaloras/bash-preexec) AInalyzer uses `bash-preexec` for reliable capture of command output in "monitor" mode. The installer automatically downloads and sources it.

## Contributing

Contributions are welcome! Feel free to open issues for bug reports or suggest enhancements.

## License

This project is licensed under the **GNU General Public License v3.0**. See [GPL v3 License](https://www.gnu.org/licenses/gpl-3.0.en.html) for more details.

-----

**Enjoy a smoother command-line experience with AInalyzer! 🚀**