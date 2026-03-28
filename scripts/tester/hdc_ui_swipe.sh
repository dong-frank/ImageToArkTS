#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"
START_X="$3"
START_Y="$4"
END_X="$5"
END_Y="$6"

if [ -n "${TARGET_SERIAL}" ]; then
  "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" shell uitest uiInput swipe "${START_X}" "${START_Y}" "${END_X}" "${END_Y}"
else
  "${HDC_EXECUTABLE}" shell uitest uiInput swipe "${START_X}" "${START_Y}" "${END_X}" "${END_Y}"
fi
