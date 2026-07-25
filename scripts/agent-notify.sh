#!/usr/bin/env bash
# Entry point for coding-agent finish hooks:
#
#   agent-notify.sh <claude|codex> <stop|attention> [event-json]
#
# Resolves the nvim binary (hook processes inherit a bare PATH) and hands the
# event to agent-notify.lua inside a throwaway headless nvim, which notifies the
# nvim server you are currently looking at.
#
# Always exits 0: a notification is a courtesy, and must never fail the Stop
# hook it is attached to. Deliveries are logged to
# ~/.local/state/nvim/agent-notify.log.
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

nvim_bin="$(command -v nvim 2>/dev/null || true)"
if [ -z "$nvim_bin" ]; then
    for candidate in /opt/nvim-macos-arm64/bin/nvim /opt/homebrew/bin/nvim /usr/local/bin/nvim; do
        if [ -x "$candidate" ]; then
            nvim_bin="$candidate"
            break
        fi
    done
fi
[ -n "$nvim_bin" ] || exit 0

"$nvim_bin" -u NONE -l "$script_dir/agent-notify.lua" "$@" >/dev/null 2>&1 || true
exit 0
