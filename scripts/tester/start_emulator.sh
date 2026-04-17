#!/bin/bash
set -u

# Args kept for a consistent invocation contract with other tester scripts.
HDC_EXECUTABLE="$1"
TARGET_SERIAL="${2:-}"

START_CMD="${HARMONY_EMULATOR_START_CMD:-${DEVECO_EMULATOR_START_CMD:-}}"
if [ -z "${START_CMD}" ]; then
  echo "missing emulator start command; set HARMONY_EMULATOR_START_CMD or DEVECO_EMULATOR_START_CMD"
  exit 2
fi

bash -lc "${START_CMD}"
