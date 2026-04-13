#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <project-name>"
  exit 1
fi

PROJECT_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_BASE_DIR="${TARGET_BASE_DIR:-$PWD}"

TEMPLATE_DIR="$ROOT_DIR/template/uni-preset-vue-vite"
PROJECT_DIR="$TARGET_BASE_DIR/$PROJECT_NAME"
RUNTIME_SHELL_SRC="$ROOT_DIR/template/uni-harmony-shell-template"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "Template not found: $TEMPLATE_DIR"
  exit 1
fi

if [[ -e "$PROJECT_DIR" ]]; then
  echo "Target project already exists: $PROJECT_DIR"
  exit 1
fi

if [[ ! -d "$RUNTIME_SHELL_SRC" ]]; then
  echo "Runtime shell template not found: $RUNTIME_SHELL_SRC"
  echo "Please prepare a runnable Uni Harmony shell first."
  exit 1
fi

echo "[1/4] Creating project from local template..."
mkdir -p "$PROJECT_DIR"
rsync -a \
  --exclude '.git' \
  --exclude 'node_modules' \
  --exclude 'dist' \
  --exclude 'unpackage' \
  "$TEMPLATE_DIR/" "$PROJECT_DIR/"

echo "[2/4] Adding Harmony metadata sync script..."
mkdir -p "$PROJECT_DIR/scripts"
cat > "$PROJECT_DIR/scripts/sync-harmony-shell-assets.mjs" <<'EOF'
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');

const shellDir = process.env.HARMONY_SHELL_DIR || path.resolve(projectRoot, 'unpackage', 'dist', 'dev', 'app-harmony');
const distWwwDir = path.resolve(projectRoot, 'dist', 'build', 'app-harmony');
const rawfileWwwDir = path.join(shellDir, 'entry', 'src', 'main', 'resources', 'rawfile', 'www');
const resfileAppsDir = path.join(shellDir, 'entry', 'src', 'main', 'resources', 'resfile', 'apps');
const manifestPath = path.join(projectRoot, 'src', 'manifest.json');
const packageJsonPath = path.join(projectRoot, 'package.json');

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function extractManifestString(raw, key) {
  const reg = new RegExp(`"${key}"\\s*:\\s*"([^"]*)"`);
  const match = raw.match(reg);
  return match ? match[1].trim() : '';
}

function resolveAppId() {
  const manifestRaw = readText(manifestPath);
  const pkg = JSON.parse(readText(packageJsonPath));
  const fromManifest = extractManifestString(manifestRaw, 'appid');
  if (fromManifest) return fromManifest;
  if (pkg.name && String(pkg.name).trim()) return String(pkg.name).trim();
  return 'uni-app';
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function syncDir(srcDir, destDir) {
  ensureDir(destDir);
  fs.cpSync(srcDir, destDir, { recursive: true, force: true });

  for (const entry of fs.readdirSync(destDir)) {
    if (!fs.existsSync(path.join(srcDir, entry))) {
      fs.rmSync(path.join(destDir, entry), { recursive: true, force: true });
    }
  }
}

function main() {
  if (!fs.existsSync(distWwwDir)) {
    throw new Error(`Built app-harmony assets not found: ${distWwwDir}`);
  }

  const appId = resolveAppId();
  const appResDir = path.join(resfileAppsDir, appId, 'www');

  ensureDir(rawfileWwwDir);
  ensureDir(resfileAppsDir);
  syncDir(distWwwDir, rawfileWwwDir);
  syncDir(distWwwDir, appResDir);

  for (const entry of fs.readdirSync(resfileAppsDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (entry.name !== appId) {
      fs.rmSync(path.join(resfileAppsDir, entry.name), { recursive: true, force: true });
    }
  }

  console.log(`[sync-harmony-shell-assets] appid -> ${appId}`);
  console.log(`[sync-harmony-shell-assets] rawfile -> ${rawfileWwwDir}`);
  console.log(`[sync-harmony-shell-assets] resfile -> ${appResDir}`);
}

main();
EOF

cat > "$PROJECT_DIR/scripts/sync-harmony-shell-meta.mjs" <<'EOF'
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');

const shellDir = process.env.HARMONY_SHELL_DIR || path.resolve(projectRoot, 'unpackage', 'dist', 'dev', 'app-harmony');

const manifestPath = path.join(projectRoot, 'src', 'manifest.json');
const packageJsonPath = path.join(projectRoot, 'package.json');
const appScopeStringPath = path.join(shellDir, 'AppScope', 'resources', 'base', 'element', 'string.json');
const entryAbilityPath = path.join(shellDir, 'entry', 'src', 'main', 'ets', 'entryability', 'EntryAbility.ets');

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function extractManifestString(raw, key) {
  const reg = new RegExp(`"${key}"\\s*:\\s*"([^"]*)"`);
  const match = raw.match(reg);
  return match ? match[1].trim() : '';
}

function resolveAppName() {
  const manifestRaw = readText(manifestPath);
  const pkg = JSON.parse(readText(packageJsonPath));
  const fromManifest = extractManifestString(manifestRaw, 'name');
  if (fromManifest) return fromManifest;
  if (pkg.name && String(pkg.name).trim()) return String(pkg.name).trim();
  return 'uni-app';
}

function resolveAppId() {
  const manifestRaw = readText(manifestPath);
  const pkg = JSON.parse(readText(packageJsonPath));
  const fromManifest = extractManifestString(manifestRaw, 'appid');
  if (fromManifest) return fromManifest;
  if (pkg.name && String(pkg.name).trim()) return String(pkg.name).trim();
  return 'uni-app';
}

function updateAppNameInStringJson(filePath, appName) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Target file not found: ${filePath}`);
  }

  const doc = JSON.parse(readText(filePath));
  if (!Array.isArray(doc.string)) {
    throw new Error(`Invalid string resource format: ${filePath}`);
  }

  const existing = doc.string.find((item) => item && item.name === 'app_name');
  if (existing) {
    existing.value = appName;
  } else {
    doc.string.push({ name: 'app_name', value: appName });
  }

  fs.writeFileSync(filePath, `${JSON.stringify(doc, null, 2)}\n`, 'utf8');
}

function updateEntryAbilityAppId(filePath, appId) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Target file not found: ${filePath}`);
  }

  const raw = readText(filePath);
  const updated = raw.replace(/const UNI_APPID = ".*?";/, `const UNI_APPID = "${appId}";`);
  fs.writeFileSync(filePath, updated, 'utf8');
}

function main() {
  const appName = resolveAppName();
  const appId = resolveAppId();
  updateAppNameInStringJson(appScopeStringPath, appName);
  updateEntryAbilityAppId(entryAbilityPath, appId);
  console.log(`[sync-harmony-shell-meta] app_name -> ${appName}`);
  console.log(`[sync-harmony-shell-meta] appid -> ${appId}`);
}

main();
EOF

echo "[3/4] Wiring package scripts and app name..."
PROJECT_NAME_ENV="$PROJECT_NAME" PROJECT_DIR_ENV="$PROJECT_DIR" RUNTIME_SHELL_SRC_ENV="$RUNTIME_SHELL_SRC" node <<'EOF'
const fs = require('fs');
const path = require('path');

const projectName = process.env.PROJECT_NAME_ENV;
const projectDir = process.env.PROJECT_DIR_ENV;
const runtimeShellSrc = process.env.RUNTIME_SHELL_SRC_ENV;

const packagePath = path.join(projectDir, 'package.json');
const manifestPath = path.join(projectDir, 'src', 'manifest.json');

const pkg = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
pkg.scripts = pkg.scripts || {};

pkg.scripts['build:app-harmony'] = 'uni build -p app-harmony';
pkg.scripts['prepare:harmony-runtime-shell'] = `mkdir -p unpackage/dist/dev && rsync -a --delete ${JSON.stringify(`${runtimeShellSrc}/`)} unpackage/dist/dev/app-harmony/`;
pkg.scripts['sync:app-harmony-shell'] = 'node scripts/sync-harmony-shell-assets.mjs';
pkg.scripts['sync:harmony-shell-meta'] = 'node scripts/sync-harmony-shell-meta.mjs';
pkg.scripts['build:hap:cli'] = 'cd unpackage/dist/dev/app-harmony && ohpm install && hvigorw assembleHap';
pkg.scripts['build:harmony:cli'] = 'npm run prepare:harmony-runtime-shell && npm run build:app-harmony && npm run sync:app-harmony-shell && npm run sync:harmony-shell-meta && npm run build:hap:cli';

if (!pkg.name || pkg.name === 'uni-preset-vue' || pkg.name === 'uni-preset-vite') {
  pkg.name = projectName;
}

fs.writeFileSync(packagePath, JSON.stringify(pkg, null, 2) + '\n', 'utf8');

if (fs.existsSync(manifestPath)) {
  let manifestRaw = fs.readFileSync(manifestPath, 'utf8');
  const safeName = projectName.replace(/"/g, '\\"');
  const safeAppId = projectName.replace(/"/g, '\\"');
  if (/"name"\s*:\s*"[^"]*"/.test(manifestRaw)) {
    manifestRaw = manifestRaw.replace(/"name"\s*:\s*"[^"]*"/, `"name" : "${safeName}"`);
  }
  if (/"appid"\s*:\s*"[^"]*"/.test(manifestRaw)) {
    manifestRaw = manifestRaw.replace(/"appid"\s*:\s*"[^"]*"/, `"appid" : "${safeAppId}"`);
  }
  fs.writeFileSync(manifestPath, manifestRaw, 'utf8');
}
EOF

echo "[4/4] Done."
echo
echo "Project created: $PROJECT_DIR"
echo "Runtime shell template (immutable): $RUNTIME_SHELL_SRC"
echo "Runtime shell output            : $PROJECT_DIR/unpackage/dist/dev/app-harmony"
echo
echo "Next steps:"
echo "  cd $PROJECT_DIR"
echo "  npm install"
echo "  npm run build:harmony:cli"
echo "  hdc install -r $PROJECT_DIR/unpackage/dist/dev/app-harmony/entry/build/default/outputs/default/entry-default-unsigned.hap"
