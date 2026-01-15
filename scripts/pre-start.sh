#!/bin/bash
set -e

echo "### STARTING CUSTOM PRE-START SCRIPT ###"

# ----------------------------------------------------------------
# 1. CONFIGURE RCLONE
# ----------------------------------------------------------------
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
    echo "WARNING: B2_ID not found. Rclone will not work."
fi

# ----------------------------------------------------------------
# 2. SYNC ESSENTIALS
# ----------------------------------------------------------------
# Syncs B2 -> /workspace (Persistent)
# We use --size-only for speed on startup
if [ -n "$B2_BUCKET" ]; then
    echo "Syncing essential files from Backblaze..."
    rclone sync "backblaze:$B2_BUCKET/chromahd-essentials" /workspace/comfy-sync --progress --transfers 16 --size-only
else
    echo "Skipping Sync (No Bucket Name provided)."
fi

# ----------------------------------------------------------------
# 3. CREATE SYMLINKS
# ----------------------------------------------------------------
# Function: Delete the empty default folder, Link to the Workspace folder
safe_link() {
    SRC="/workspace/comfy-sync/$1"
    DEST="/root/ComfyUI/$1"

    # Ensure source exists on the persistent volume
    mkdir -p "$SRC"
    
    # Remove the default folder inside the container (if it's not already a link)
    if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
        echo "Replacing default folder: $DEST"
        rm -rf "$DEST"
    fi

    # Create the symlink
    if [ ! -L "$DEST" ]; then
        ln -s "$SRC" "$DEST"
        echo "Linked: $SRC -> $DEST"
    fi
}

echo "Setting up Persistence..."

# Core Models
safe_link "models/checkpoints"
safe_link "models/diffusion_models"
safe_link "models/vae"
safe_link "models/clip"
safe_link "models/text_encoders"

# Add-ons (Added based on your request)
safe_link "models/loras"
safe_link "models/controlnet"
safe_link "models/upscale_models"
safe_link "models/embeddings"

# User Data
safe_link "input"
safe_link "output"
safe_link "user"

echo "### CUSTOM PRE-START SCRIPT COMPLETE ###"
