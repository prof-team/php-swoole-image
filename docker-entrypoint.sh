#!/bin/bash

set -e
set -o pipefail

_term() {
  echo "Got SIGTERM signal!"
   php bin/console swoole:server:stop
}

trap _term SIGTERM

sleep infinity &
