#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${PROJECT_ROOT}/agent_workspace"
PROJECTS_DIR="${WORKSPACE_DIR}/projects"
DESIGNS_DIR="${WORKSPACE_DIR}/designs"

if [ ! -d "${WORKSPACE_DIR}" ]; then
  echo "agent_workspace not found: ${WORKSPACE_DIR}"
  exit 1
fi

mkdir -p "${PROJECTS_DIR}" "${DESIGNS_DIR}"

find "${PROJECTS_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
find "${DESIGNS_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

echo "Cleared:"
echo "- ${PROJECTS_DIR}"
echo "- ${DESIGNS_DIR}"
echo "Kept:"
echo "- ${WORKSPACE_DIR}/skills"
echo "- ${WORKSPACE_DIR}/user_input"
