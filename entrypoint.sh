#!/bin/sh
#
# Copyright (c) 2020 Robert Scheck <robert@fedoraproject.org>
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

set -e
[ -n "$DEBUG" ] && set -x

# Catch container interruption signals to remove hint file for health script
cleanup() {
  rm -f /tmp/crond.not-started-yet
}
trap cleanup INT TERM

# Check if first argument is a flag, but only works if all arguments require
# a hyphenated flag: -v; -SL; -f arg; etc. will work, but not arg1 arg2
if [ "$#" -eq 0 -o "${1#-}" != "$1" ]; then
  set -- rpki-client "$@"
fi

# Check for the expected command
if [ "$1" = 'rpki-client' ]; then
  case "$ONESHOT" in
    1|y*|Y*|t*|T*)
      exec "$@"
      ;;
    *)
      echo "$(date +%M) * * * * $@ > /dev/stdout 2>&1" > /etc/crontabs/root
      touch /tmp/crond.not-started-yet
      "$@"
      cleanup
      exec crond -f -d 15
      ;;
  esac
fi

# Default to run whatever the user wanted, e.g. "sh"
exec "$@"
