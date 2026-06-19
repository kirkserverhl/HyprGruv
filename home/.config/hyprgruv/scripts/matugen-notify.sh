#!/usr/bin/env bash
# Fire-and-forget notification for matugen post_hooks.
# notify-send can block indefinitely when no daemon is listening — never wait on it.
timeout 1 notify-send "$@" 2>/dev/null </dev/null &
exit 0