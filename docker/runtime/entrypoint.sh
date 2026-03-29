#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] Checking Harmony build toolchain..."

if ! command -v ohpm >/dev/null 2>&1; then
  echo "[entrypoint] ERROR: ohpm is not available in PATH" >&2
  exit 1
fi
if ! command -v hvigorw >/dev/null 2>&1; then
  echo "[entrypoint] ERROR: hvigorw is not available in PATH" >&2
  exit 1
fi

ohpm --version

if ! hvigorw --version >/dev/null 2>&1; then
  if ! hvigorw -v >/dev/null 2>&1; then
    if ! hvigorw --help >/dev/null 2>&1; then
      echo "[entrypoint] ERROR: hvigorw exists but cannot run commands" >&2
      exit 1
    fi
  fi
fi

echo "[entrypoint] Toolchain check passed."

HDC_AUTO_TCONN="${HDC_AUTO_TCONN:-1}"
HDC_TCP_TARGET="${HDC_TCP_TARGET:-}"

if [ "${HDC_AUTO_TCONN}" = "1" ] && [ -n "${HDC_TCP_TARGET}" ]; then
  host_part="${HDC_TCP_TARGET%:*}"
  port_part="${HDC_TCP_TARGET##*:}"
  resolved_host="${host_part}"

  if ! [[ "${host_part}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    resolved_host="$(getent ahostsv4 "${host_part}" | awk 'NR==1{print $1}')"
  fi

  if [ -n "${resolved_host}" ] && [ -n "${port_part}" ]; then
    echo "[entrypoint] Attempt hdc tconn ${resolved_host}:${port_part}"
    if ! hdc tconn "${resolved_host}:${port_part}"; then
      echo "[entrypoint] WARN: hdc tconn failed; runtime will continue." >&2
    fi
  else
    echo "[entrypoint] WARN: unable to resolve HDC_TCP_TARGET=${HDC_TCP_TARGET}" >&2
  fi
fi

echo "[entrypoint] Starting runtime: $*"
exec "$@"
