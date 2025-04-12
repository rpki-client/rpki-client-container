#
# Copyright (c) 2020-2025 Robert Scheck <robert@fedoraproject.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

FROM alpine:latest

LABEL maintainer="Robert Scheck <https://github.com/rpki-client/rpki-client-container>" \
      description="OpenBSD RPKI validator to support BGP Origin Validation" \
      org.opencontainers.image.title="rpki-client" \
      org.opencontainers.image.description="OpenBSD RPKI validator to support BGP Origin Validation" \
      org.opencontainers.image.url="https://www.rpki-client.org/" \
      org.opencontainers.image.documentation="https://man.openbsd.org/rpki-client" \
      org.opencontainers.image.source="https://github.com/rpki-client" \
      org.opencontainers.image.licenses="ISC" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.name="rpki-client" \
      org.label-schema.description="OpenBSD RPKI validator to support BGP Origin Validation" \
      org.label-schema.url="https://www.rpki-client.org/" \
      org.label-schema.usage="https://man.openbsd.org/rpki-client" \
      org.label-schema.vcs-url="https://github.com/rpki-client"

ARG VERSION=9.5
ARG PORTABLE_GIT
ARG PORTABLE_COMMIT
ARG OPENBSD_GIT
ARG OPENBSD_COMMIT

COPY entrypoint.sh haproxy.cfg healthcheck.sh rpki-client.pub rpki-client.sh /
RUN set -x && \
  chmod 0755 /entrypoint.sh /healthcheck.sh /rpki-client.sh

RUN set -x && \
  export BUILDREQ="git autoconf automake libtool signify build-base musl-fts-dev openssl-dev libretls-dev expat-dev zlib-dev" && \
  apk --no-cache upgrade && \
  apk --no-cache add ${BUILDREQ} expat haproxy libretls multirun musl-fts netcat-openbsd openssl rsync tzdata zlib && \
  cd /tmp/ && \
  if [ -z "${PORTABLE_GIT}" -a -z "${PORTABLE_COMMIT}" -a -z "${OPENBSD_GIT}" -a -z "${OPENBSD_COMMIT}" ]; then \
    wget "https://ftp.openbsd.org/pub/OpenBSD/rpki-client/rpki-client-${VERSION}.tar.gz" && \
    wget https://ftp.openbsd.org/pub/OpenBSD/rpki-client/SHA256.sig && \
    signify -C -p /rpki-client.pub -x SHA256.sig "rpki-client-${VERSION}.tar.gz" && \
    tar xfz "rpki-client-${VERSION}.tar.gz" && \
    cd "rpki-client-${VERSION}/"; \
  else \
    git clone -b "${PORTABLE_COMMIT:-master}" --single-branch "${PORTABLE_GIT:-https://github.com/rpki-client/rpki-client-portable.git}" && \
    cd rpki-client-portable/ && \
    git clone -b "${OPENBSD_COMMIT:-master}" --single-branch "${OPENBSD_GIT:-https://github.com/rpki-client/rpki-client-openbsd.git}" openbsd/ && \
    rm -rf openbsd/.git/ && \
    ./autogen.sh; \
  fi && \
  ./configure \
    --prefix=/usr \
    --with-user=rpki-client \
    --with-tal-dir=/etc/tals \
    --with-base-dir=/var/cache/rpki-client \
    --with-output-dir=/var/lib/rpki-client && \
  make V=1 && \
  addgroup -g 900 -S rpki-client && \
  adduser -h /var/lib/rpki-client -g "OpenBSD RPKI validator" -G rpki-client -S -D -u 900 rpki-client && \
  make install-strip INSTALL='install -p' && \
  cd .. && \
  rm -rf rpki-client* /rpki-client.pub SHA256.sig && \
  apk --no-cache del ${BUILDREQ} && \
  mv -f /haproxy.cfg /etc/haproxy/haproxy.cfg && \
  rpki-client -V

ENV TZ=UTC
VOLUME ["/etc/tals/", "/var/cache/rpki-client/", "/var/lib/rpki-client/"]
EXPOSE 9099

ENTRYPOINT ["/entrypoint.sh"]
CMD ["rpki-client", "-B", "-c", "-j", "-m", "-o", "-v"]
HEALTHCHECK CMD ["/healthcheck.sh"]
