FROM debian:10-slim

# Use archive mirrors for Debian 10 (Buster) since it's end-of-life
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's|/debian-security |/debian-security |g' /etc/apt/sources.list

# Provide a sensible default Racket version and installer URL so builds don't fail
# when the build-arg is not supplied (the CI run used `set -u`, which fails on
# unset parameters).
ARG RACKET_VERSION=8.8
ARG RACKET_INSTALLER_URL=https://mirror.racket-lang.org/installers/${RACKET_VERSION}/racket-${RACKET_VERSION}-x86_64-linux-buster-cs.sh
ENV RACKET_INSTALLER_URL=${RACKET_INSTALLER_URL}
ENV RACKET_VERSION=${RACKET_VERSION}

# Ensure curl, bash and CA certs are available before trying to download the installer
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates bash \
    && rm -rf /var/lib/apt/lists/* \
    && curl --retry 5 -fLs "${RACKET_INSTALLER_URL}" -o racket-install.sh \
    && printf 'yes\n1\n' | bash racket-install.sh --create-dir --unix-style --dest /usr/ \
    && rm -f racket-install.sh

ENV SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
ENV SSL_CERT_DIR="/etc/ssl/certs"

RUN raco setup
RUN raco pkg config --set catalogs \
    "https://download.racket-lang.org/releases/${RACKET_VERSION}/catalog/" \
    "https://pkg-build.racket-lang.org/server/built/catalog/" \
    "https://pkgs.racket-lang.org" \
    "https://planet-compats.racket-lang.org"

CMD ["racket"]
