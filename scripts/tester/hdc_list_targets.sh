#!/bin/bash
set -u

HDC_EXECUTABLE="$1"
"${HDC_EXECUTABLE}" list targets
