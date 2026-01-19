#!/bin/bash
set -e

echo "### STARTING CUSTOM PRE-START SCRIPT ###"

# 1. CONFIGURE RCLONE
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
fi

# 2. DESTRUCTIVE LINK FUNCTION
# Wipes container defaults and links to persistent /workspace
force_link() {
    SRC="/workspace/comfy-sync/$1"
    DEST="/root/ComfyUI/$1"

    mkdir -p "$SRC"
    
    # Remove existing folder in the container to force link to workspace
    if [ -d "$DEST" ] || [ -L "$DEST" ]; then
        echo "Wiping default folder: $DEST"
        rm -rf "$DEST"
    fi

    ln -s "$SRC" "$DEST"
    echo "Linked: $SRC -> $DEST"
}

echo "Setting up Persistence..."

# Core Models (REMOVED: clip and text_encoders from main linking)
force_link "models/checkpoints"
force_link "models/diffusion_models"
force_link "models/vae"

# 3. SPECIAL HANDLING: TEXT ENCODER ADDITIONS
# Links a specific workspace folder into the container's text_encoder directory
ADDITIONS_SRC="/workspace/comfy-sync/models/text_encoder_additions"
ADDITIONS_DEST="/root/ComfyUI/models/text_encoders/text_encoder_additions"

mkdir -p "$ADDITIONS_SRC"
if [ ! -L "$ADDITIONS_DEST" ]; then
    ln -s "$ADDITIONS_SRC" "$ADDITIONS_DEST"
    echo "Linked text_encoder_additions"
fi

# Add-ons
force_link "models/loras"
force_link "models/controlnet"
force_link "models/upscale_models"
force_link "models/embeddings"

# User Data
force_link "input"
force_link "output"
force_link "user"

# 4. CREATE INTERACTIVE BACKUP & DOWNLOAD TOOL
mkdir -p /workspace/backup
cat <<EOF > /workspace/backup/sync.sh
#!/bin/bash
echo "--- Workspace Management Tool ---"
echo "1) UPLOAD to B2"
echo "2) DOWNLOAD from B2"
echo "3) DOWNLOAD via CURL (Civitai)"
echo "4) DOWNLOAD via ARIA2 (General)"
read -p "Option: " opt

case \$opt in
    1) rclone sync /workspace/comfy-sync "backblaze:\$B2_BUCKET/chromahd-essentials" --progress ;;
    2) rclone sync "backblaze:\$B2_BUCKET/chromahd-essentials" /workspace/comfy-sync --progress --size-only ;;
    3) 
        read -p "URL: " url
        read -p "Subfolder (e.g., models/checkpoints): " folder
        read -p "Filename: " fname
        curl -LJ -o "/workspace/comfy-sync/\$folder/\$fname" "\$url"
        ;;
    4)
        read -p "URL: " url
        read -p "Subfolder: " folder
        aria2c -x 16 -s 16 -d "/workspace/comfy-sync/\$folder" "\$url"
        ;;
esac
EOF
chmod +x /workspace/backup/sync.sh

echo "### CUSTOM PRE-START SCRIPT COMPLETE ###"
