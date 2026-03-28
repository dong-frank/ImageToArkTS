#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"
BUNDLE_NAME="$3"
ABILITY_NAME="$4"

if [ -n "${TARGET_SERIAL}" ]; then
  "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" shell aa start -b "${BUNDLE_NAME}" -a "${ABILITY_NAME}"
else
  "${HDC_EXECUTABLE}" shell aa start -b "${BUNDLE_NAME}" -a "${ABILITY_NAME}"
fi
