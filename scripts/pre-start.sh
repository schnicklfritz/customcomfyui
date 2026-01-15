#!/bin/bash
set -e

echo "### STARTING CUSTOM PRE-START SCRIPT ###"

# ----------------------------------------------------------------
# 1. CONFIGURE RCLONE (Using Env Vars from Quickpod)
# ----------------------------------------------------------------
# This allows the repo to be public without leaking keys.
# Quickpod Env Vars needed: B2_ID, B2_KEY, B2_BUCKET
if [ -n "$B2_ID" ]; then
    echo "Configuring Rclone for Backblaze B2..."
    mkdir -p /root/.config/rclone
    cat <<EOF > /root/.config/rclone/rclone.conf
[backblaze]
type = b2
account = $B2_ID
key = $B2_KEY
hard_delete = true
EOF
else
    echo "WARNING: B2_ID environment variable not found. Skipping Rclone config."
fi

# ----------------------------------------------------------------
# 2. SYNC ESSENTIALS (ChromaHD)
# ----------------------------------------------------------------
# We sync from B2 -> /workspace (Persistent) -> Symlink to ComfyUI
# Assumes your B2 bucket has a folder 'comfy-sync' matching ComfyUI structure
if [ -n "$B2_BUCKET" ]; then
    echo "Syncing essential ChromaHD files from Backblaze..."
    # --transfers 16 speeds up small file downloads
    rclone sync "backblaze:$B2_BUCKET/chromahd-essentials" /workspace/comfy-sync --progress --transfers 16
else
    echo "Skipping Sync (No Bucket Name provided)."
fi

# ----------------------------------------------------------------
# 3. CREATE SYMLINKS
# ----------------------------------------------------------------
# Function to safely link a persistent folder to ComfyUI
safe_link() {
    SRC="/workspace/comfy-sync/$1"
    DEST="/root/ComfyUI/$1"

    # Ensure source exists (create if missing on workspace)
    mkdir -p "$SRC"
    
    # Remove default folder if it exists and is a directory (not a symlink)
    if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
        echo "Removing default folder: $DEST"
        rm -rf "$DEST"
    fi

    # Create the symlink
    if [ ! -L "$DEST" ]; then
        echo "Linking $SRC -> $DEST"
        ln -s "$SRC" "$DEST"
    else
        echo "Link already exists: $DEST"
    fi
}

echo "Setting up Symlinks..."

# Map the specific folders you want to persist/sync
safe_link "models/checkpoints"
safe_link "models/diffusion_models" # For Wan2.2 / Flux
safe_link "models/vae"
safe_link "models/clip"
safe_link "models/text_encoders"    # For T5
safe_link "output"                  # Persist your images
safe_link "user"                    # Persist your workflows/config

echo "### CUSTOM PRE-START SCRIPT COMPLETE ###"
