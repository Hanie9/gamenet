#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export XDG_DATA_DIRS="${DIR}/share${XDG_DATA_DIRS:+:${XDG_DATA_DIRS}}"
exec "${DIR}/gamenet" "$@"
