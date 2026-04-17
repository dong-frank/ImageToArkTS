#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"
X="$3"
Y="$4"

if [ -n "${TARGET_SERIAL}" ]; then
  "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" shell uitest uiInput click "${X}" "${Y}"
else
  "${HDC_EXECUTABLE}" shell uitest uiInput click "${X}" "${Y}"
fi
