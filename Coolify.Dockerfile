FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN <<EOS
set -ex
wget https://github.com/QingdaoU/OnlineJudgeFE/releases/download/oj_2.7.5/dist.zip
unzip dist.zip
rm -f dist.zip
EOS

FROM python:3.12-slim

ARG TARGETARCH
ARG TARGETVARIANT

ENV OJ_ENV=production \
    PYTHONUNBUFFERED=1 \
    PATH="/home/user/.local/bin:${PATH}"

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libjpeg62-turbo-dev \
    zlib1g-dev \
    libfreetype6-dev \
    supervisor \
    openssl \
    nginx \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r user && useradd -r -g user user
RUN mkdir -p /home/user/.local && chown -R user:user /home/user
USER user

COPY --chown=user:user ./deploy/requirements.txt /app/deploy/
RUN pip install --no-cache-dir -r /app/deploy/requirements.txt

COPY --chown=user:user ./ /app/
COPY --from=builder --chown=user:user /app/dist/ /app/dist/

USER root
RUN chmod -R u=rwX,go=rX ./ && \
    chmod +x ./deploy/entrypoint.sh && \
    mkdir -p /data && \
    chown -R user:user /data
USER user

HEALTHCHECK --interval=5s CMD [ "/usr/local/bin/python3", "/app/deploy/health_check.py" ]
EXPOSE 8000
ENTRYPOINT [ "/app/deploy/entrypoint.sh" ]
