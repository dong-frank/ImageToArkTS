#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${1:-output}"
MODE="${2:-device}"
HDC_BIN="${HDC_BIN:-/Users/dong/command-line-tools/sdk/default/openharmony/toolchains/hdc}"
HAP_RELATIVE_PATH="./unpackage/dist/dev/app-harmony/entry/build/default/outputs/default/entry-default-unsigned.hap"

log_step() {
  echo "[compile] $1"
}

ensure_npm_dependencies() {
  if [[ -x "./node_modules/.bin/uni" ]]; then
    log_step "SKIP npm-install (uni cli already available)"
    return 0
  fi

  run_step "npm-install" npm install
}

run_step() {
  local step_name="$1"
  shift

  log_step "START ${step_name}"
  "$@"
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    log_step "FAIL ${step_name} (exit=${exit_code})"
    exit "$exit_code"
  fi
  log_step "DONE ${step_name}"
}

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "[compile] FAIL project directory not found: ${PROJECT_PATH}"
  exit 1
fi

cd "$PROJECT_PATH"
log_step "PROJECT $(pwd)"

case "$MODE" in
  preview)
    log_step "MODE preview"
    ensure_npm_dependencies
    run_step "npm-dev-h5" npm run dev:h5
    ;;
  device)
    log_step "MODE device"
    ensure_npm_dependencies
    run_step "npm-build-harmony-cli" npm run build:harmony:cli

    if [[ ! -f "$HAP_RELATIVE_PATH" ]]; then
      log_step "FAIL hap-not-found ${HAP_RELATIVE_PATH}"
      exit 1
    fi

    run_step "hdc-install-hap" "$HDC_BIN" install -r "$HAP_RELATIVE_PATH"
    log_step "SUCCESS harmony build and install completed"
    ;;
  *)
    echo "[compile] FAIL unsupported mode: ${MODE}"
    echo "[compile] Supported modes: preview, device"
    exit 1
    ;;
esac
