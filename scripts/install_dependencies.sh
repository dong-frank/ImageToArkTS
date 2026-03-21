#!/bin/bash

PROJECT_PATH=${1:-output}

log_step() {
    echo "[deps] $1"
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
    log_step "FAIL project directory not found: ${PROJECT_PATH}"
    exit 1
fi

cd "${PROJECT_PATH}" || exit 1

log_step "PROJECT $(pwd)"

run_step "npm-registry" npm config set registry https://repo.huaweicloud.com/repository/npm/
run_step "ohos-registry" npm config set "@ohos:registry" https://repo.harmonyos.com/npm/
run_step "ohpm-install" ohpm install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true

log_step "SUCCESS dependency install completed"
