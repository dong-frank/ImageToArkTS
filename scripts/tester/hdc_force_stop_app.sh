#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"
BUNDLE_NAME="$3"

if [ -n "${TARGET_SERIAL}" ]; then
  "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" shell aa force-stop "${BUNDLE_NAME}"
else
  "${HDC_EXECUTABLE}" shell aa force-stop "${BUNDLE_NAME}"
fi
