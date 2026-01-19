# Base image: The latest Megapack (CUDA 12.8, Python 3.12)
FROM yanwk/comfyui-boot:cu128-megapak

# 1. Install System Dependencies
# Includes rclone for Backblaze and aria2 for manual downloads
RUN zypper --gpg-auto-import-keys refresh \
    && zypper --gpg-auto-import-keys install -y rclone netcat-openbsd aria2 \
    && zypper clean -a

# 2. Optimized Arguments & Memory Management
# Removed --highvram to prevent OOM errors and added memory optimization
ENV CLI_ARGS="--fast --listen --preview-method auto"
ENV PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

# 3. Setup Pre-Start Script
COPY scripts/pre-start.sh /root/user-scripts/pre-start.sh
RUN chmod +x /root/user-scripts/pre-start.sh

WORKDIR /workspace
