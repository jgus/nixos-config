# Minimal ComfyUI Docker Image
FROM pytorch/pytorch:2.6.0-cuda12.6-cudnn9-devel

# Install git (needed to clone ComfyUI)
RUN apt-get update && \
    apt-get install -y git curl && \
    rm -rf /var/lib/apt/lists/*

# Clone ComfyUI to a specific commit for reproducibility
# Update the commit hash below to pin to a specific version
WORKDIR /app
RUN git clone -b v0.4.0 https://github.com/comfyanonymous/ComfyUI.git comfyui

WORKDIR /app/comfyui

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create volume mount points for persistence
# - models: Put your checkpoints, VAEs, etc. here
# - output: Generated images will be saved here
# - custom_nodes: Add custom nodes for extended functionality
VOLUME ["/app/comfyui/models", "/app/comfyui/output", "/app/comfyui/custom_nodes"]

EXPOSE 8188

# Run ComfyUI server
CMD ["python", "main.py", "--listen"]
