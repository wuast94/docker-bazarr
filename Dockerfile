# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.18

# set version label
ARG UNRAR_VERSION=6.2.8
ARG BUILD_DATE
ARG VERSION
ARG BAZARR_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chbmb"
# hard set UTC in case the user does not define it
ENV TZ="Etc/UTC"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    cargo \
    libffi-dev \
    libpq-dev \
    libxml2-dev \
    libxslt-dev \
    python3-dev && \
  echo "**** install packages ****" && \
  apk add --no-cache \
    ffmpeg \
    libxml2 \
    libxslt \
    mediainfo \
    python3 && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" && \  
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  make && \
  install -v -m755 unrar /usr/local/bin && \
  echo "**** install bazarr ****" && \
  mkdir -p \
    /app/bazarr/bin && \
  if [ -z ${BAZARR_VERSION+x} ]; then \
    BAZARR_VERSION=$(curl -sX GET https://api.github.com/repos/morpheus65535/bazarr/releases \
    | jq -r '.[0] | .tag_name'); \
  fi && \
  curl -o \
    /tmp/bazarr.zip -L \
    "https://github.com/morpheus65535/bazarr/releases/download/${BAZARR_VERSION}/bazarr.zip" && \
  unzip \
    /tmp/bazarr.zip -d \
    /app/bazarr/bin && \
  rm -Rf /app/bazarr/bin/bin && \
  echo "UpdateMethod=docker\nBranch=development\nPackageVersion=${VERSION}\nPackageAuthor=linuxserver.io" > /app/bazarr/package_info && \
  curl -o \
    /app/bazarr/bin/postgres-requirements.txt -L \
    "https://raw.githubusercontent.com/morpheus65535/bazarr/${BAZARR_VERSION}/postgres-requirements.txt" && \
  echo "**** Install requirements ****" && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip \
    wheel && \
  pip3 install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.18/ \
    -r /app/bazarr/bin/requirements.txt \
    -r /app/bazarr/bin/postgres-requirements.txt && \
  echo "**** clean up ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    $HOME/.cache \
    $HOME/.cargo \
    /tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 6767

VOLUME /config
