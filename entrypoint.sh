#!/bin/sh
#
# Copyright (c) 2020-2023 Robert Scheck <robert@fedoraproject.org>
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

# Size of HAProxy "http-response return" must be smaller than "tune.bufsize"
reconfigure() {
  bufsize=$(($(stat -c %s /var/lib/rpki-client/metrics 2> /dev/null) + 16384))
  sed -e "s/^\(\stune\.bufsize\) .*/\1 ${bufsize}/" -i /etc/haproxy/haproxy.cfg
}
[ "$0" = "/rpki-client.sh" ] && return

# Catch container interruption signals to remove hint file for health script
cleanup() {
  rm -f /tmp/rpki-client.client-expected
}
trap cleanup INT TERM

# Check if first argument is a flag, but only works if all arguments require
# a hyphenated flag: -v; -SL; -f arg; etc. will work, but not arg1 arg2
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
  set -- rpki-client "$@"
fi

# Check for the expected command
if [ "$1" = 'rpki-client' ]; then
  [ "$2" = '-V' ] && ONESHOT=1
  chown -R rpki-client:rpki-client /var/cache/rpki-client/ \
    /var/lib/rpki-client/ 2> /dev/null || :
  case "${ONESHOT}" in
    1|y*|Y*|t*|T*)
      exec "$@"
      ;;
    *)
      # Create empty file for HAProxy "http-response return" feature
      touch /var/lib/rpki-client/metrics
      chown rpki-client:rpki-client /var/lib/rpki-client/metrics
      reconfigure

      # Remove IPv6 bind if host system disabled IPv6 support completely
      [ -f /proc/net/if_inet6 ] || sed -e '/^[[:space:]]bind \[::\]:/d' \
                                       -i /etc/haproxy/haproxy.cfg

      exec multirun ${DEBUG:+-v} "/rpki-client.sh $*" \
        'haproxy -f /etc/haproxy/haproxy.cfg -q -W -S /run/haproxy.sock'
       ;;
  esac
fi

# Default to run whatever the user wanted, e.g. "sh"
exec "$@"
