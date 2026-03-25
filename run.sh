#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
ENV_EXAMPLE_FILE="${ROOT_DIR}/.env.example"

if [[ ! -f "${ENV_FILE}" ]]; then
  if [[ -f "${ENV_EXAMPLE_FILE}" ]]; then
    cp "${ENV_EXAMPLE_FILE}" "${ENV_FILE}"
    echo "Created ${ENV_FILE} from .env.example"
  else
    echo ".env and .env.example were not found."
    exit 1
  fi
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

DEFAULT_APP_MODE="${APP_MODE:-DEV}"
DEFAULT_GATEWAY_PORT="${GATEWAY_PORT:-3120}"
DEFAULT_MARKETPLACE_AUTO_SEED="${MARKETPLACE_AUTO_SEED:-true}"
DEFAULT_MARKETPLACE_AUTO_MIGRATE="${MARKETPLACE_AUTO_MIGRATE:-true}"
DEFAULT_BUILD_IMAGES="yes"
DEFAULT_DETACH="no"
DEFAULT_RESET_STACK="yes"
DEFAULT_PERSIST="no"

prompt_value() {
  local prompt="$1"
  local default_value="$2"
  local result
  read -r -p "${prompt} [${default_value}]: " result
  if [[ -z "${result}" ]]; then
    result="${default_value}"
  fi
  printf '%s' "${result}"
}

normalize_bool() {
  local value
  value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "${value}" in
    y|yes|true|1) printf 'true' ;;
    n|no|false|0) printf 'false' ;;
    *)
      echo "Expected yes/no value, got: $1" >&2
      exit 1
      ;;
  esac
}

normalize_choice() {
  local value
  value="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
  case "${value}" in
    DEV|PROD) printf '%s' "${value}" ;;
    *)
      echo "Expected DEV or PROD, got: $1" >&2
      exit 1
      ;;
  esac
}

APP_MODE_SELECTED="$(normalize_choice "$(prompt_value "Run mode (DEV/PROD)" "${DEFAULT_APP_MODE}")")"
GATEWAY_PORT_SELECTED="$(prompt_value "External gateway port" "${DEFAULT_GATEWAY_PORT}")"
MARKETPLACE_AUTO_MIGRATE_SELECTED="$(normalize_bool "$(prompt_value "Run marketplace migrations? (yes/no)" "${DEFAULT_MARKETPLACE_AUTO_MIGRATE}")")"
MARKETPLACE_AUTO_SEED_SELECTED="$(normalize_bool "$(prompt_value "Seed marketplace demo data? (yes/no)" "${DEFAULT_MARKETPLACE_AUTO_SEED}")")"
BUILD_IMAGES_SELECTED="$(normalize_bool "$(prompt_value "Rebuild images before start? (yes/no)" "${DEFAULT_BUILD_IMAGES}")")"
DETACH_SELECTED="$(normalize_bool "$(prompt_value "Run in background (detached)? (yes/no)" "${DEFAULT_DETACH}")")"
RESET_STACK_SELECTED="$(normalize_bool "$(prompt_value "Stop current stack before start? (yes/no)" "${DEFAULT_RESET_STACK}")")"
PERSIST_SELECTED="$(normalize_bool "$(prompt_value "Save selected values into .env? (yes/no)" "${DEFAULT_PERSIST}")")"

PUBLIC_BASE_URL_SELECTED="http://localhost:${GATEWAY_PORT_SELECTED}"

export APP_MODE="${APP_MODE_SELECTED}"
export GATEWAY_PORT="${GATEWAY_PORT_SELECTED}"
export PUBLIC_BASE_URL="${PUBLIC_BASE_URL_SELECTED}"
export FRONTEND_URL="${PUBLIC_BASE_URL_SELECTED}"
export AUTH_ALLOWED_ORIGINS="${PUBLIC_BASE_URL_SELECTED}"
export MARKETPLACE_ALLOWED_ORIGINS="${PUBLIC_BASE_URL_SELECTED}"
export MARKETPLACE_AUTO_MIGRATE="${MARKETPLACE_AUTO_MIGRATE_SELECTED}"
export MARKETPLACE_AUTO_SEED="${MARKETPLACE_AUTO_SEED_SELECTED}"

if [[ -n "${GOOGLE_REDIRECT_URL:-}" ]]; then
  export GOOGLE_REDIRECT_URL="http://localhost:${GATEWAY_PORT_SELECTED}/auth/google/callback"
fi

echo
echo "Starting adm_superApp with:"
echo "  APP_MODE=${APP_MODE}"
echo "  GATEWAY_PORT=${GATEWAY_PORT}"
echo "  FRONTEND_URL=${FRONTEND_URL}"
echo "  MARKETPLACE_AUTO_MIGRATE=${MARKETPLACE_AUTO_MIGRATE}"
echo "  MARKETPLACE_AUTO_SEED=${MARKETPLACE_AUTO_SEED}"
echo

if [[ "${PERSIST_SELECTED}" == "true" ]]; then
  python3 - "${ENV_FILE}" <<'PY'
from pathlib import Path
import os
import sys

env_path = Path(sys.argv[1])
keys = {
    "APP_MODE": os.environ["APP_MODE"],
    "GATEWAY_PORT": os.environ["GATEWAY_PORT"],
    "PUBLIC_BASE_URL": os.environ["PUBLIC_BASE_URL"],
    "FRONTEND_URL": os.environ["FRONTEND_URL"],
    "AUTH_ALLOWED_ORIGINS": os.environ["AUTH_ALLOWED_ORIGINS"],
    "MARKETPLACE_ALLOWED_ORIGINS": os.environ["MARKETPLACE_ALLOWED_ORIGINS"],
    "MARKETPLACE_AUTO_MIGRATE": os.environ["MARKETPLACE_AUTO_MIGRATE"],
    "MARKETPLACE_AUTO_SEED": os.environ["MARKETPLACE_AUTO_SEED"],
}
if os.environ.get("GOOGLE_REDIRECT_URL"):
    keys["GOOGLE_REDIRECT_URL"] = os.environ["GOOGLE_REDIRECT_URL"]

lines = env_path.read_text().splitlines()
seen = set()
updated = []
for line in lines:
    if "=" in line and not line.lstrip().startswith("#"):
      key, _ = line.split("=", 1)
      if key in keys:
          updated.append(f"{key}={keys[key]}")
          seen.add(key)
          continue
    updated.append(line)

for key, value in keys.items():
    if key not in seen:
        updated.append(f"{key}={value}")

env_path.write_text("\n".join(updated) + "\n")
PY
  echo "Saved selected values into ${ENV_FILE}"
  echo
fi

if [[ "${RESET_STACK_SELECTED}" == "true" ]]; then
  docker compose down
fi

compose_args=(up)

if [[ "${BUILD_IMAGES_SELECTED}" == "true" ]]; then
  compose_args+=(--build)
fi

if [[ "${DETACH_SELECTED}" == "true" ]]; then
  compose_args+=(-d)
fi

(
  cd "${ROOT_DIR}"
  docker compose "${compose_args[@]}"
)

echo
echo "Gateway URL: ${PUBLIC_BASE_URL_SELECTED}"
echo "Auth health: ${PUBLIC_BASE_URL_SELECTED}/auth/healthz"
echo "Marketplace health: ${PUBLIC_BASE_URL_SELECTED}/api/marketplace/healthz"
if [[ -n "${GOOGLE_REDIRECT_URL:-}" ]]; then
  echo "Google redirect URI: ${GOOGLE_REDIRECT_URL}"
fi
