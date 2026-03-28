#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"
REMOTE_PATH="$3"
LOCAL_PATH="$4"

if [ -n "${TARGET_SERIAL}" ]; then
  "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" file recv "${REMOTE_PATH}" "${LOCAL_PATH}"
else
  "${HDC_EXECUTABLE}" file recv "${REMOTE_PATH}" "${LOCAL_PATH}"
fi
