FROM alpine/git:2.36.2 as download2

COPY builder/clone.sh /clone.sh

RUN . /clone.sh sd-webui-segment-anything https://github.com/continue-revolution/sd-webui-segment-anything.git d0492ac6d586d32c04ccaeb7e720d023e60bd122 && \
    . /clone.sh sd-webui-replacer https://github.com/light-and-ray/sd-webui-replacer.git c7f510c6917dfa93e3b2a7a441f4aecdfe6d047b && \

RUN apk add --no-cache wget && \
    wget -q -O /lazymix.safetensors https://civitai.com/api/download/models/302254 && \
    wget -q -O /repositories/sd-webui-segment-anything/models/sam/sam_hq_vit_l.pth https://huggingface.co/lkeab/hq-sam/resolve/main/sam_hq_vit_l.pth

FROM runpod/ai-api-a1111:0.2.1

ENV STABLE_DIFFUSION_SHA=feee37d75f1b168768014e4634dcb156ee649c05
RUN cd stable-diffusion-webui && git reset --hard ${STABLE_DIFFUSION_SHA}

COPY --from=download2 /repositories/sd-webui-segment-anything /stable-diffusion-webui/repositories/sd-webui-segment-anything
COPY --from=download2 /repositories/sd-webui-replacer /stable-diffusion-webui/repositories/sd-webui-replacer

COPY --from=download2 /lazymix.safetensors /lazymix.safetensors
RUN cd /stable-diffusion-webui && python cache.py --use-cpu=all --ckpt /lazymix.safetensors
