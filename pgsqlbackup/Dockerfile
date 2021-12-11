ARG BUILD_FROM=ghcr.io/hassio-addons/base/amd64:10.2.0
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Overwrite labels
LABEL \
    org.opencontainers.image.title="Postgresql Backup Add-on for ${BUILD_ARCH}" \
    org.opencontainers.image.description="Postgresql Backup Add-on : ${BUILD_ARCH} image" \
    org.opencontainers.image.authors="guirem <guirem@gmail.com>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="guirem/hassos-addon-pgsqlbackup-${BUILD_ARCH}" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md"

COPY /rootfs /

RUN apk add --no-cache postgresql-client \
    && chmod a+x /addon/*.sh 

