FROM alpine/git:2.36.2 AS download

COPY builder/clone.sh /clone.sh

RUN . /clone.sh sd-webui-segment-anything https://github.com/continue-revolution/sd-webui-segment-anything.git d0492ac6d586d32c04ccaeb7e720d023e60bd122
RUN . /clone.sh sd-webui-replacer https://github.com/light-and-ray/sd-webui-replacer.git c7f510c6917dfa93e3b2a7a441f4aecdfe6d047b
RUN . /clone.sh stable-diffusion-stability-ai https://github.com/Stability-AI/stablediffusion.git cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf
RUN . /clone.sh generative-models https://github.com/Stability-AI/generative-models.git 45c443b316737a4ab6e40413d7794a7f5657c19f
RUN . /clone.sh k-diffusion https://github.com/crowsonkb/k-diffusion.git 045515774882014cc14c1ba2668ab5bad9cbf7c0

FROM python:3.10.9-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    LD_PRELOAD=libtcmalloc.so \
    ROOT=/stable-diffusion-webui \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt install -y \
    fonts-dejavu-core rsync git jq moreutils aria2 wget libgoogle-perftools-dev procps && \
    apt-get autoremove -y && rm -rf /var/lib/apt/lists/* && apt-get clean -y

RUN --mount=type=cache,target=/cache --mount=type=cache,target=/root/.cache/pip \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

RUN --mount=type=cache,target=/root/.cache/pip \
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git && \
    cd stable-diffusion-webui && \
    git reset --hard c19d04436496ab29ddca4758a792831ae41b31de && \
    pip install -r requirements_versions.txt

COPY --from=download /repositories /stable-diffusion-webui/repositories

COPY models/sam_hq_vit_l.pth /stable-diffusion-webui/repositories/sd-webui-segment-anything/models/sam/sam_hq_vit_l.pth
COPY models/groundingdino_swint_ogc.pth /stable-diffusion-webui/repositories/sd-webui-segment-anything/models/grounding-dino/groundingdino_swint_ogc.pth
COPY models/lazymix.safetensors /lazymix.safetensors

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r /stable-diffusion-webui/repositories/sd-webui-segment-anything/requirements.txt

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install diskcache xformers open_clip_torch

COPY builder/cache.py /stable-diffusion-webui/cache.py
RUN cd /stable-diffusion-webui && python cache.py --use-cpu=all --ckpt /lazymix.safetensors

COPY config.json /stable-diffusion-webui/config.json
COPY ui_config.json /stable-diffusion-webui/ui_config.json

COPY src/rp_handler.py ./rp_handler.py
COPY src/start.sh ./start.sh
RUN chmod +x /start.sh