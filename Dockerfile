#
# Copyright (c) 2020-2021 Robert Scheck <robert@fedoraproject.org>
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
      description="RPKI validator to support BGP Origin Validation" \
      org.opencontainers.image.title="rpki-client" \
      org.opencontainers.image.description="RPKI validator to support BGP Origin Validation" \
      org.opencontainers.image.url="https://www.rpki-client.org/" \
      org.opencontainers.image.documentation="https://man.openbsd.org/rpki-client" \
      org.opencontainers.image.source="https://github.com/rpki-client" \
      org.opencontainers.image.licenses="ISC" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.name="rpki-client" \
      org.label-schema.description="RPKI validator to support BGP Origin Validation" \
      org.label-schema.url="https://www.rpki-client.org/" \
      org.label-schema.usage="https://man.openbsd.org/rpki-client" \
      org.label-schema.vcs-url="https://github.com/rpki-client"

ARG VERSION
ENV VERSION ${VERSION:-6.8p1}
ARG PORTABLE_GIT
ENV PORTABLE_GIT ${PORTABLE_GIT:-https://github.com/rpki-client/rpki-client-portable.git}
ARG PORTABLE_COMMIT
ENV PORTABLE_COMMIT ${PORTABLE_COMMIT:-$VERSION}
ARG OPENBSD_GIT
ENV OPENBSD_GIT ${OPENBSD_GIT:-https://github.com/rpki-client/rpki-client-openbsd.git}
ARG OPENBSD_COMMIT
ENV OPENBSD_COMMIT ${OPENBSD_COMMIT}
ENV BUILDREQ="git autoconf automake expat-dev libtool build-base fts-dev libressl-dev"

RUN set -x && \
  echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
  apk add --no-cache ${BUILDREQ} expat fts libressl rsync tzdata tini && \
  cd /tmp && \
  git clone ${PORTABLE_GIT} && \
  cd rpki-client-portable && \
  git checkout ${PORTABLE_COMMIT} && \
  git clone ${OPENBSD_GIT} openbsd && \
  [ -n "${OPENBSD_COMMIT}" ] && { \
    cd openbsd && \
    git checkout ${OPENBSD_COMMIT} && \
    rm -rf .git && \
    cd ..; } || : && \
  ./autogen.sh && \
  ./configure \
    --prefix=/usr \
    --with-user=rpki-client \
    --with-tal-dir=/etc/tals \
    --with-base-dir=/var/cache/rpki-client \
    --with-output-dir=/var/lib/rpki-client && \
  make V=1 && \
  addgroup \
    -g 101 \
    -S \
    rpki-client && \
  adduser \
    -h /var/lib/rpki-client \
    -g "OpenBSD RPKI validator" \
    -G rpki-client \
    -S \
    -D \
    -u 100 \
    rpki-client && \
  make install-strip INSTALL='install -p' && \
  cd .. && \
  rm -rf rpki-client-portable && \
  apk del --no-cache ${BUILDREQ}

COPY entrypoint.sh healthcheck.sh /
RUN set -x && \
  chmod +x /entrypoint.sh /healthcheck.sh

ENV TZ=UTC
VOLUME ["/etc/tals/", "/var/cache/rpki-client/", "/var/lib/rpki-client/"]

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
CMD ["rpki-client", "-B", "-c", "-j", "-o", "-v"]
HEALTHCHECK CMD ["/healthcheck.sh"]
