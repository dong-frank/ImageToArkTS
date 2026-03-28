#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"
REMOTE_PATH="$3"

if [ -n "${TARGET_SERIAL}" ]; then
  "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" shell rm -f "${REMOTE_PATH}"
else
  "${HDC_EXECUTABLE}" shell rm -f "${REMOTE_PATH}"
fi
