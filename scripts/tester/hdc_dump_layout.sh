#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"
REMOTE_LAYOUT_PATH="$3"

if [ -n "${TARGET_SERIAL}" ]; then
  "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" shell uitest dumpLayout -p "${REMOTE_LAYOUT_PATH}"
else
  "${HDC_EXECUTABLE}" shell uitest dumpLayout -p "${REMOTE_LAYOUT_PATH}"
fi
