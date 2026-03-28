#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"

if [ -n "${TARGET_SERIAL}" ]; then
  "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" shell uitest uiInput keyEvent Back
else
  "${HDC_EXECUTABLE}" shell uitest uiInput keyEvent Back
fi
