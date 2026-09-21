#!/bin/bash
# Backup script for Omni-Pan Hub

COMMIT_MSG=${1:-"Auto backup"}

echo "1. Committing to Local Git..."
git add .
git commit -m "$COMMIT_MSG" || echo "No changes to commit"

echo "2. Pushing to GitHub..."
git push origin master

echo "3. Backing up to Google Drive (rclone)..."
rclone sync /home/unkown/gemini/nft_platform gdrive:nft_platform --exclude ".git/**" --exclude "node_modules/**" --exclude ".next/**"
echo "Backup complete!"
