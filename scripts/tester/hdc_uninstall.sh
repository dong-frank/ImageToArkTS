#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"
BUNDLE_NAME="$3"

if [ -n "${TARGET_SERIAL}" ]; then
  "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" uninstall "${BUNDLE_NAME}"
else
  "${HDC_EXECUTABLE}" uninstall "${BUNDLE_NAME}"
fi
