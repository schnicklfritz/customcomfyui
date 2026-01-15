# Base image: The latest Megapack (CUDA 12.8, Python 3.12)
FROM yanwk/comfyui-boot:cu128-megapak

# 1. Install System Dependencies
# 'netcat-openbsd' is required for Quickpod health checks.
# 'rclone' is required for Backblaze sync.
RUN zypper --gpg-auto-import-keys refresh \
    && zypper --gpg-auto-import-keys install -y rclone netcat-openbsd \
    && zypper clean -a

# 2. Install Custom Nodes (The Correct Way)
# We install into the 'bundle' so the entrypoint script copies them to /root/ComfyUI on boot.
WORKDIR /default-comfyui-bundle/ComfyUI/custom_nodes

# Install WanVideoWrapper (Essential for Wan2.1/2.2)
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git

# 3. Bake in Default Arguments
# Saves you from typing this in QuickPod every time.
# --highvram: Keeps models loaded (Crucial for Wan2.2)
# --fast: Enables Torch optimizations
# --listen: Required for WebUI access
ENV CLI_ARGS="--fast --highvram --listen --preview-method auto"

# 4. Setup Pre-Start Script
# The base image looks for this specific path to run before launching ComfyUI
COPY scripts/pre-start.sh /root/user-scripts/pre-start.sh
RUN chmod +x /root/user-scripts/pre-start.sh

# Reset workdir to root for the runtime entrypoint
WORKDIR /root
