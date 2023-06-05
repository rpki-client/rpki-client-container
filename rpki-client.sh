#!/bin/sh
#
# Copyright (c) 2023 Robert Scheck <robert@fedoraproject.org>
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

set -e ${DEBUG:+-x}

# Create empty file for HAProxy "http-response return" feature
touch /var/lib/rpki-client/metrics
chown rpki-client:rpki-client /var/lib/rpki-client/metrics

while true; do
  # Actually run rpki-client and handle health script
  touch /tmp/rpki-client.client-expected
  "$@"
  rm -f /tmp/rpki-client.client-expected

  # Size of HAProxy "http-response return" must be smaller than "tune.bufsize"
  bufsize=$(($(stat -c %s /var/lib/rpki-client/metrics 2> /dev/null) + 16384))
  sed -e "s/^\(\stune\.bufsize\) .*/\1 ${bufsize}/" -i /etc/haproxy/haproxy.cfg

  # Reload HAProxy using "master CLI" (primarily for caching new metrics file)
  echo 'reload' | nc -U /run/haproxy.sock

  # Wait before running rpki-client again
  sleep "${WAIT:-600}"
done
