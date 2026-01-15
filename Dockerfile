# Base image: The latest Megapack (CUDA 12.8, Python 3.12, OpenSUSE)
FROM yanwk/comfyui-boot:cu128-megapak

# 1. Install System Dependencies
# 'netcat-openbsd' is required for Quickpod/RunPod WebUI port detection.
# 'rclone' is required for your Backblaze sync.
RUN zypper --gpg-auto-import-keys refresh \
    && zypper --gpg-auto-import-keys install -y rclone netcat-openbsd \
    && zypper clean -a

# 2. Install Custom Nodes (Pre-loading code)
# Adding Kijai's WanVideoWrapper (popular for Wan2.2) so the nodes are ready
WORKDIR /root/ComfyUI/custom_nodes
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git

# 3. Copy your pre-start script
# The base image looks for this specific path to run before launching ComfyUI
COPY scripts/pre-start.sh /root/user-scripts/pre-start.sh
RUN chmod +x /root/user-scripts/pre-start.sh

# Reset workdir to root for the entrypoint
WORKDIR /root
