#!/usr/bin/env bash

# --- Configuration ---
# List of repository URLs to clone
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
# Check if a target directory argument was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <target_directory>"
  echo "Please provide the absolute path where the repositories should be cloned."
  exit 1
fi

TARGET_DIR="$1"
SCRIPT_START_DIR=$(pwd) # Remember where we started

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
  # Extract the repository name from the URL to use as the subdirectory name
  subdir_name=$(basename "$repo_url" .git)

  echo "----------------------------------------"
  echo "Processing: $repo_url"

  if [ -d "$subdir_name" ]; then
    echo "Directory '$subdir_name' already exists. Skipping clone."
    # Optional: Add logic here to pull updates if the directory exists
    # echo "Pulling updates for '$subdir_name'..."
    # (cd "$subdir_name" && git pull)
  else
    echo "Cloning into '$subdir_name'..."
    if git clone --depth 1 "$repo_url" "$subdir_name"; then # Using --depth 1 for faster initial clone
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
  exit 1 # Exit with error if any clone failed
fi