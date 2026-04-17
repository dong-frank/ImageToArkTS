#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
TARGET_SERIAL="$2"
HAP_PATH="$3"
REINSTALL_FLAG="${4:-1}"

if [ "${REINSTALL_FLAG}" = "1" ]; then
  if [ -n "${TARGET_SERIAL}" ]; then
    "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" install -r "${HAP_PATH}"
  else
    "${HDC_EXECUTABLE}" install -r "${HAP_PATH}"
  fi
else
  if [ -n "${TARGET_SERIAL}" ]; then
    "${HDC_EXECUTABLE}" -t "${TARGET_SERIAL}" install "${HAP_PATH}"
  else
    "${HDC_EXECUTABLE}" install "${HAP_PATH}"
  fi
fi
