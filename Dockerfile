FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH

# ===== システム依存 =====
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    build-essential \
    cmake \
    ninja-build \
    git \
    git-lfs \
    wget \
    curl \
    unzip \
    aria2 \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    nodejs \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ===== Python venv =====
RUN python3.11 -m venv /opt/venv && \
    python -m pip install --upgrade pip setuptools wheel

# ===== PyTorch (CUDA 12.8系) =====
RUN python -m pip install \
    torch \
    torchvision \
    torchaudio \
    --extra-index-url https://download.pytorch.org/whl/cu128

# ===== Notebook / UI 系 =====
RUN python -m pip install \
    jupyterlab \
    jupyter-server-proxy \
    comfyui-manager \
    xformers \
    triton

# ===== ComfyUI 本体 requirements 相当 =====
RUN python -m pip install \
    "numpy>=1.25.0" \
    einops \
    "transformers>=4.50.3" \
    "tokenizers>=0.13.3" \
    sentencepiece \
    "safetensors>=0.4.2" \
    "aiohttp>=3.11.8" \
    "yarl>=1.18.0" \
    pyyaml \
    Pillow \
    scipy \
    tqdm \
    psutil \
    "kornia>=0.7.1" \
    alembic \
    SQLAlchemy \
    "av>=14.2.0" \
    "simpleeval>=1.0.0" \
    blake3 \
    spandrel \
    "pydantic~=2.0" \
    "pydantic-settings~=2.0" \
    PyOpenGL \
    glfw \
    torchsde \
    comfy-kitchen \
    comfy-aimdo

# ===== custom node 共通依存 =====
RUN python -m pip install \
    opencv-python-headless \
    colorama \
    diskcache \
    imageio-ffmpeg

# ===== llama-cpp-python 0.3.32+cu128 =====
# ここはあなたの実際の Release asset URL に合わせてください
ARG LLAMA_WHL_URL="https://github.com/yumi1129/paperspace-comfyui-qwen35-stable/releases/download/v1/llama_cpp_python-0.3.32+cu128.basic-cp311-cp311-linux_x86_64.whl"
ARG LLAMA_WHL_FILE="llama_cpp_python-0.3.32+cu128.basic-cp311-cp311-linux_x86_64.whl"

# URL疎通確認
RUN curl -I -L "${LLAMA_WHL_URL}"

# wheel ダウンロード
RUN curl -fL -o /tmp/${LLAMA_WHL_FILE} "${LLAMA_WHL_URL}"

# ダウンロード確認
RUN ls -lh /tmp/${LLAMA_WHL_FILE}

# インストール
RUN python -m pip install "/tmp/${LLAMA_WHL_FILE}"

# 後片付け
RUN rm -f /tmp/${LLAMA_WHL_FILE}

# ===== import確認 =====
RUN python - <<'PY'
import llama_cpp
print("llama_cpp version:", llama_cpp.__version__)
from llama_cpp.llama_chat_format import Qwen35ChatHandler
from llama_cpp.llama_chat_format import Qwen3VLChatHandler
print("Qwen35ChatHandler OK")
print("Qwen3VLChatHandler OK")
PY

# ===== 任意: llama-server がすでに配布バイナリである場合はここで COPY =====
# COPY llama-server /usr/local/bin/llama-server
# RUN chmod +x /usr/local/bin/llama-server

EXPOSE 8888 8188 6006 8000

WORKDIR /notebooks
