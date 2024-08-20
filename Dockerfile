FROM alpine/git:2.36.2 AS download2

COPY builder/clone.sh /clone.sh

RUN . /clone.sh sd-webui-segment-anything https://github.com/continue-revolution/sd-webui-segment-anything.git d0492ac6d586d32c04ccaeb7e720d023e60bd122
RUN . /clone.sh sd-webui-replacer https://github.com/light-and-ray/sd-webui-replacer.git c7f510c6917dfa93e3b2a7a441f4aecdfe6d047b

RUN apk add --no-cache wget
RUN wget -q -O /lazymix.safetensors https://civitai.com/api/download/models/302254
RUN wget -q -O /repositories/sd-webui-segment-anything/models/sam/sam_hq_vit_l.pth https://huggingface.co/lkeab/hq-sam/resolve/main/sam_hq_vit_l.pth
RUN wget -q -O /repositories/sd-webui-segment-anything/models/grounding-dino/groundingdino_swint_ogc.pth https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/groundingdino_swint_ogc.pth

FROM runpod/ai-api-a1111:0.2.1

ENV STABLE_DIFFUSION_SHA="c19d04436496ab29ddca4758a792831ae41b31de"
RUN cd stable-diffusion-webui &&  git fetch origin ${STABLE_DIFFUSION_SHA} --depth=1 && git reset --hard ${STABLE_DIFFUSION_SHA}

COPY --from=download2 /repositories /stable-diffusion-webui/repositories
COPY --from=download2 /lazymix.safetensors /lazymix.safetensors

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --ignore-installed --upgrade pip && \
    pip install --ignore-installed diskcache xformers setuptools && \
    pip install --ignore-installed -r /stable-diffusion-webui/repositories/sd-webui-segment-anything/requirements.txt
    
RUN cd /stable-diffusion-webui && python cache.py --use-cpu=all --ckpt /lazymix.safetensors

COPY config.json /stable-diffusion-webui/config.json
COPY ui_config.json /stable-diffusion-webui/ui_config.json

COPY src/rp_handler.py ./rp_handler.py