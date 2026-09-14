#!/usr/bin/env bash
set -e

SOURCE_DIR="/etc/nixos"
TARGET_DIR="$HOME/nixos-config"

COMMIT_MSG="${1:-Update NixOS configuration on $(date '+%Y-%m-%d %H:%M:%S')}"

echo "==> Copying configuration files from $SOURCE_DIR to $TARGET_DIR..."
sudo cp -a "$SOURCE_DIR"/*.nix "$TARGET_DIR"/
if [ -f "$SOURCE_DIR"/flake.lock ]; then
  sudo cp -a "$SOURCE_DIR"/flake.lock "$TARGET_DIR"/
fi

echo "==> Setting user ownership for copied files..."
sudo chown -R "$USER":users "$TARGET_DIR"

cd "$TARGET_DIR"

# Check if there are any actual changes
if [[ -z $(git status --porcelain) ]]; then
  echo "==> No changes detected. Nothing to commit."
  exit 0
fi

echo "==> Staging files..."
git add -A

echo "==> Committing changes..."
git commit -m "$COMMIT_MSG"

echo "==> Pushing to GitHub..."
git push

echo "==> Done successfully!"

