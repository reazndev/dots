#!/usr/bin/env bash

set -euo pipefail

output="$HOME/Videos/record-$(date +%Y%m%d-%H%M%S).mp4"
mkdir -p "$HOME/Videos"

if pgrep -x wf-recorder >/dev/null; then
    pkill -x wf-recorder
    notify-send "Recording saved" "$output"
    exit 0
fi

notify-send "Select a region to record"
geometry="$(slurp)"

if [[ -z "$geometry" ]]; then
    exit 0
fi

wf-recorder -g "$geometry" -f "$output"
notify-send "Recording saved" "$output"
