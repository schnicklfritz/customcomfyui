#!/bin/bash
set -e

echo "### STARTING CUSTOM PRE-START SCRIPT ###"

# 1. PREVENT OOM / OPTIMIZE VRAM
# Forces ComfyUI to be more aggressive about moving models to CPU/System RAM
export COMFYUI_HIGH_VRAM=false
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# 2. CONFIGURE RCLONE
if [ -n "$B2_ID" ]; then
    echo "Configuring Rclone for Backblaze B2..."
    mkdir -p /root/.config/rclone
    cat <<EOF > /root/.config/rclone/rclone.conf
[backblaze]
type = b2
account = \$B2_ID
key = \$B2_KEY
hard_delete = true
EOF
[cite_start]fi [cite: 1, 2]

# 3. DESTRUCTIVE LINK FUNCTION
force_link() {
    SRC="/workspace/comfy-sync/\$1"
    DEST="/root/ComfyUI/\$1"
    mkdir -p "\$SRC"
    if [ -d "\$DEST" ] || [ -L "\$DEST" ]; then
        echo "Wiping ephemeral folder: \$DEST"
        rm -rf "\$DEST"
    fi
    ln -s "\$SRC" "\$DEST"
    echo "Linked: \$SRC -> \$DEST"
[cite_start]} [cite: 5, 6, 7]

echo "Setting up Persistence..."

# Core Models (Excluding 'clip')
force_link "models/checkpoints"
force_link "models/diffusion_models"
[cite_start]force_link "models/vae" [cite: 7]

# Special Handling: text_encoder (Keep original, link additions)
ADDITIONS_SRC="/workspace/comfy-sync/models/text_encoder_additions"
ADDITIONS_DEST="/root/ComfyUI/models/text_encoders/text_encoder_additions"
mkdir -p "\$ADDITIONS_SRC"
if [ ! -L "\$ADDITIONS_DEST" ]; then
    ln -s "\$ADDITIONS_SRC" "\$ADDITIONS_DEST"
fi

# Add-ons
force_link "models/loras"
force_link "models/controlnet"
force_link "models/upscale_models"
[cite_start]force_link "models/embeddings" [cite: 7]

# User Data
force_link "input"
force_link "output"
[cite_start]force_link "user" [cite: 7]

# 4. CREATE SYNC & DOWNLOAD HELPER
mkdir -p /workspace/backup
cat <<EOF > /workspace/backup/sync.sh
#!/bin/bash
echo "--- Workspace Management Tool ---"
echo "1) UPLOAD to B2"
echo "2) DOWNLOAD from B2"
echo "3) DOWNLOAD via CURL (Civitai/Cloudflare)"
echo "4) DOWNLOAD via ARIA2 (General)"
read -p "Option: " opt

case \\\$opt in
    1) rclone sync /workspace/comfy-sync "backblaze:\\\$B2_BUCKET/chromahd-essentials" --progress ;;
    2) rclone sync "backblaze:\\\$B2_BUCKET/chromahd-essentials" /workspace/comfy-sync --progress --size-only ;;
    3)
        read -p "URL: " url
        read -p "Subfolder (e.g., models/checkpoints): " folder
        read -p "Filename: " fname
        curl -LJ -o "/workspace/comfy-sync/\\\$folder/\\\$fname" "\\\$url"
        ;;
    4)
        read -p "URL: " url
        read -p "Subfolder: " folder
        aria2c -x 16 -s 16 -d "/workspace/comfy-sync/\\\$folder" "\\\$url"
        ;;
esac
EOF
chmod +x /workspace/backup/sync.sh

echo "### CUSTOM PRE-START SCRIPT COMPLETE ###"
