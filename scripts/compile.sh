#!/bin/bash

PROJECT_PATH=${1:-output}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

log_step() {
    echo "[compile] $1"
}

run_step() {
    local step_name="$1"
    shift

    log_step "START ${step_name}"
    "$@"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_step "FAIL ${step_name} (exit=${exit_code})"
        exit $exit_code
    fi
    log_step "DONE ${step_name}"
}

if [ ! -d "${PROJECT_PATH}" ]; then
    echo "[compile] FAIL project directory not found: ${PROJECT_PATH}"
    exit 1
fi

cd "${PROJECT_PATH}" || exit 1

log_step "PROJECT $(pwd)"

log_step "START install-dependencies"
bash "${SCRIPT_DIR}/install_dependencies.sh" "$(pwd)"
install_exit_code=$?
if [ $install_exit_code -ne 0 ]; then
    log_step "FAIL install-dependencies (exit=${install_exit_code})"
    exit $install_exit_code
fi
log_step "DONE install-dependencies"

run_step "hvigor-clean" hvigorw clean --no-daemon
run_step "hvigor-assemble" hvigorw assembleHap --mode module -p product=default -p buildMode=debug --no-daemon

log_step "SUCCESS build completed"
