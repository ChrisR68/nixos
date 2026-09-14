#!/usr/bin/env bash
set -e

SOURCE_DIR="/etc/nixos"
TARGET_DIR="$HOME/nixos-config"

# Optional: use a custom commit message passed as an argument, or fallback to timestamp
COMMIT_MSG="${1:-Update NixOS configuration on $(date '+%Y-%m-%d %H:%M:%S')}"

echo "==> Copying .nix files from $SOURCE_DIR to $TARGET_DIR..."
sudo cp -r "$SOURCE_DIR"/*.nix "$TARGET_DIR"/
sudo cp -r "$SOURCE_DIR"/*.lock "$TARGET_DIR"/

echo "==> Setting user ownership for copied files..."
sudo chown -R "$USER":"$GROUP" "$TARGET_DIR"

cd "$TARGET_DIR"

# Check if there are any actual changes
if [[ -z $(git status --porcelain) ]]; then
  echo "==> No changes detected. Nothing to commit."
  exit 0
fi

echo "==> Staging files..."
git add .

echo "==> Committing changes..."
git commit -m "$COMMIT_MSG"

echo "==> Pushing to GitHub..."
git push

echo "==> Done successfully!"
