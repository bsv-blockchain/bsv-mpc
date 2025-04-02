# @bsv/mcp - MCP Server for Bitcoin SV Development

[![NPM Version](https://img.shields.io/npm/v/@bsv/mcp)](https://www.npmjs.com/package/@bsv/mcp)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This package provides a [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server designed to assist developers working with key Bitcoin SV (BSV) repositories. It offers specialized tools and prompts accessible through MCP-compatible clients (like Windsurf, Claude Desktop, Continue, etc.), enabling Large Language Models (LLMs) to understand and interact with the BSV codebase more effectively.

**Note:** This server provides the *actions* (tools) and *workflows* (prompts). It relies on a separate MCP server, specifically `@modelcontextprotocol/server-filesystem`, to provide the *file content* context from locally cloned repositories. **Both servers must be configured in your MCP client.**

## Features / Capabilities

This server exposes the following capabilities to your MCP client and LLM:

### Tools

Tools allow the LLM (with your approval) to perform actions:

* **`brc_lookup`**: Retrieves the content of a specific BRC (Bitcoin Request for Comment) Markdown file directly from the `bitcoin-sv/BRCs` GitHub repository (master branch).
* Input: `brc_identifier` (e.g., "0001", "token")
* **`code_search`**: Searches for code snippets or patterns within the locally cloned BSV repositories using `ripgrep` (rg) if available (recommended), falling back to `grep`.
* Input: `query`, optional `repository_name`, optional `file_extension` (e.g., `*.ts`, requires `rg`)
* **`find_function_definition`**: Attempts to locate potential definitions of functions or methods within the cloned repositories using basic search patterns.
* Input: `function_name`, optional `repository_name`

### Prompts

Prompts provide templates or starting points for common developer tasks:

* **`/summarize_brc`**: Instructs the LLM to summarize a specific BRC, suggesting the relevant resource URI for the client to attach.
* Input: `brc_identifier`
* **`/explain_code`**: Instructs the LLM to explain a piece of code identified by a file URI (typically provided by the `server-filesystem`).
* Input: `code_reference` (file URI, e.g., `file:///path/to/repo/file.ts#L10-L20`)
* **`/generate_usage_example`**: Asks the LLM to generate a code example for a specific BSV feature or function, optionally specifying a preferred SDK.
* Input: `feature_description`, optional `sdk_preference`
* **`/find_related_code`**: Instructs the LLM to use the `code_search` tool to find code snippets related to a given concept.
* Input: `concept`

## Prerequisites

Before configuring this server, ensure you have:

1. **Node.js and npm:** Required to run `npx`. Download from [nodejs.org](https://nodejs.org/).
2. **Git:** Required to clone the BSV repositories.
3. **Locally Cloned BSV Repositories:** You need local copies of the BSV repositories. Use the setup script provided below.
4. **An MCP Client:** An application that supports MCP, such as [Windsurf Editor](https://codeium.com/windsurf), [Claude Desktop](https://claude.ai/download), [Continue](https://github.com/continuedev/continue), etc.
5. **(Optional but Recommended) `ripgrep`:** For significantly better performance and features in the `code_search` tool. Install via your system's package manager (e.g., `brew install ripgrep`, `sudo apt install ripgrep`, `choco install ripgrep`).

## Setup Instructions

Follow these steps carefully:

### Step 1: Install Prerequisites

Ensure Node.js, npm, and Git are installed and accessible in your system's PATH. Install `ripgrep` if desired.

### Step 2: Clone BSV Repositories using the Setup Script

This script clones the necessary BSV repositories into a single directory you specify.

1. Save the following script content as `setup_bsv_repos.sh`:

```bash
#!/usr/bin/env bash

# --- Configuration ---
REPOS=(
  "https://github.com/bitcoin-sv/wallet-toolbox.git"
  "https://github.com/bitcoin-sv/wallet-toolbox-examples.git"
  "https://github.com/bitcoin-sv/wui.git"
  "https://github.com/bitcoin-sv/ts-sdk.git"
  "https://github.com/bitcoin-sv/BRCs.git"
  "https://github.com/bitcoin-sv/metanet-desktop.git"
  "https://github.com/bitcoin-sv/arc.git"
  "https://github.com/bitcoin-sv/bdk.git"
  "https://github.com/bitcoin-sv/py-sdk.git"
  "https://github.com/bitcoin-sv/p2p.git"
  "https://github.com/bitcoin-sv/authsocket.git"
  "https://github.com/bitcoin-sv/authsocket-client.git"
)

# --- Argument Handling ---
if [ -z "$1" ]; then
  echo "Usage: $0 <target_directory>"
  echo "Please provide the absolute path where the repositories should be cloned."
  exit 1
fi
TARGET_DIR="$1"
SCRIPT_START_DIR=$(pwd)

# --- Directory Creation ---
echo "Target directory: $TARGET_DIR"
echo "Creating directory (if it doesn't exist)..."
if ! mkdir -p "$TARGET_DIR"; then
  echo "ERROR: Failed to create directory '$TARGET_DIR'. Check permissions." >&2
  exit 1
fi
echo "Directory created or already exists."

# --- Change Directory ---
echo "Changing to target directory..."
if ! cd "$TARGET_DIR"; then
  echo "ERROR: Failed to change directory to '$TARGET_DIR'." >&2
  exit 1
fi

# --- Cloning Repositories ---
echo "Starting repository cloning..."
CLONE_FAILURES=0
for repo_url in "${REPOS[@]}"; do
  subdir_name=$(basename "$repo_url" .git)
  echo "----------------------------------------"
  echo "Processing: $repo_url"
  if [ -d "$subdir_name" ]; then
    echo "Directory '$subdir_name' already exists. Skipping clone. (Run 'git pull' manually inside to update)."
  else
    echo "Cloning into '$subdir_name'..."
    if git clone --depth 1 "$repo_url" "$subdir_name"; then
      echo "Successfully cloned '$subdir_name'."
    else
      echo "ERROR: Failed to clone '$repo_url'." >&2
      ((CLONE_FAILURES++))
    fi
  fi
done

# --- Return to Original Directory ---
echo "----------------------------------------"
echo "Returning to original directory: $SCRIPT_START_DIR"
if ! cd "$SCRIPT_START_DIR"; then
 echo "Warning: Failed to change back to the starting directory." >&2
fi

# --- Summary ---
if [ "$CLONE_FAILURES" -eq 0 ]; then
  echo "All repositories processed successfully."
  exit 0
else
  echo "WARNING: $CLONE_FAILURES repository clone(s) failed. Please check the output above." >&2
  exit 1
fi
```

2. Make the script executable:

```bash
chmod +x setup_bsv_repos.sh
```

3. Run the script, providing the **absolute path** where you want the clones stored:

```bash
./setup_bsv_repos.sh "/path/to/your/bsv-clones"
```

**Remember this exact path!**

### Step 3: Configure Your MCP Client

Edit your client's MCP configuration file (e.g., `mcp_config.json` for Windsurf, `claude_desktop_config.json` for Claude Desktop). Add **both** the `server-filesystem` and `@bsv/mcp` servers.

**IMPORTANT:**

* Replace `/path/to/your/bsv-clones` with the **exact, absolute path** you used when running `setup_bsv_repos.sh`.
* Ensure this path is used correctly for **both** server entries (`args` for filesystem, `env.BSV_REPOS_DIR` for `@bsv/mcp`).

```json
{
  "mcpServers": {

    "bsv-filesystem-context": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/your/bsv-clones"
      ]
    },

    "@bsv/mcp": {
      "command": "npx",
      "args": [
        "-y",
        "@bsv/mcp"
      ],
      "env": {
        "BSV_REPOS_DIR": "/path/to/your/bsv-clones"
      }
    }
  }
}
```

### Step 4: Restart Your MCP Client

Close and reopen your MCP client application (Windsurf, Claude, etc.) to apply the configuration changes. It should now launch both servers.

Usage

Once configured, you can interact with the server through your MCP client's LLM interface.

Ask questions: "Find where Transaction.sign is defined in the ts-sdk", "Explain the BRC-62 standard", "Show me examples of using the wallet-toolbox to derive keys".

Use prompts: Type / in your client (if supported) to see available prompts like /summarize_brc, /explain_code, etc.

Tool Invocation: The LLM may suggest using tools like code_search or brc_lookup. Your MCP client will typically ask for your approval before executing them.

Context: Remember to attach relevant files/resources from the bsv-filesystem-context server when asking questions about specific code (e.g., attach file:///path/to/your/bsv-clones/ts-sdk/src/transaction.ts when asking about that file).

Troubleshooting

Configuration Error / Request Failed:

Verify the absolute paths in your mcp_config.json are correct and point to the directory created by setup_bsv_repos.sh.

Ensure the BSV_REPOS_DIR environment variable is set correctly for the `@bsv/mcp` entry.

Make sure Node.js/npm are installed and in your PATH.

Try running each server command manually from your terminal (including setting export BSV_REPOS_DIR=... before running npx `@bsv/mcp`) to see detailed error messages.

Check your MCP client's specific logs for more detailed error information about server startup failures.

code_search / find_function_definition Issues:

These tools require the BSV_REPOS_DIR environment variable to be set correctly when the server launches.

code_search works best with ripgrep (rg) installed. If rg is not found, it falls back to grep, which might be slower or less accurate for some patterns/file types.

Ensure the repository names used in arguments match the directory names created by the setup script (e.g., ts-sdk, wallet-toolbox).

brc_lookup Fails:

Ensure the brc_identifier provided accurately maps to a filename in the bitcoin-sv/BRCs repository.

Check your internet connection, as this tool fetches directly from GitHub.

Development

To contribute or run locally:

Clone the repository containing this server's source code.

Navigate to the project directory.

Install dependencies: npm install

Build the TypeScript code: npm run build

Run locally (requires BSV_REPOS_DIR to be set):

export BSV_REPOS_DIR="/path/to/your/bsv-clones"
node build/index.js

You can then configure your MCP client to run this local node build/index.js command instead of using npx.

License

This project is licensed under the MIT License.

---

**Remember to replace `/path/to/your/bsv-clones` with the actual placeholder path users should modify, and ensure the `setup_bsv_repos.sh` script is either included in the repository or clearly linked. Add badges and repository/author details to `package.json` as needed before publishing.**
