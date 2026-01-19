# Base image: The latest Megapack (CUDA 12.8, Python 3.12)
FROM yanwk/comfyui-boot:cu128-megapak

# 1. Install System Dependencies
# 'netcat-openbsd' is required for Quickpod health checks.
# 'rclone' is required for Backblaze sync.
# Added 'aria2' for your general manual downloads.
RUN zypper --gpg-auto-import-keys refresh \
    && zypper --gpg-auto-import-keys install -y rclone netcat-openbsd aria2 \
    && zypper clean -a

# 2. Install Custom Nodes
# We install into the 'bundle' so the entrypoint script copies them to /root/ComfyUI on boot.
WORKDIR /default-comfyui-bundle/ComfyUI/custom_nodes

# Install WanVideoWrapper (Essential for Wan2.1/2.2)
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git

# 3. Optimized Arguments & OOM Fixes
# Removed --highvram to stop VRAM locking (helps with your LoRA OOM issues).
# Added PYTORCH_CUDA_ALLOC_CONF to manage memory fragmentation on the 5090.
ENV CLI_ARGS="--fast --listen --preview-method auto"
ENV PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

# 4. Setup Pre-Start Script
# The base image looks for this specific path to run before launching ComfyUI
COPY scripts/pre-start.sh /root/user-scripts/pre-start.sh
RUN chmod +x /root/user-scripts/pre-start.sh

# Reset workdir to workspace so your manual backup script is easily accessible
WORKDIR /workspace
