#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH_SCRIPT="${FETCH_SCRIPT:-/home/gamess/gs_gamedb/fetch_gcp_secret.py}"
GCP_SECRET_ID="${GCP_SECRET_ID:-infra-cloudflare}"
CLOUDFLARE_ENV_FILE="${CLOUDFLARE_ENV_FILE:-}"

env_data=""

if [[ -n "$CLOUDFLARE_ENV_FILE" ]]; then
  if [[ ! -r "$CLOUDFLARE_ENV_FILE" ]]; then
    echo "Cloudflare 환경 파일을 읽을 수 없습니다: $CLOUDFLARE_ENV_FILE" >&2
    exit 1
  fi
  env_data="$(cat "$CLOUDFLARE_ENV_FILE")"
elif [[ -f "$FETCH_SCRIPT" ]]; then
  env_data="$(python3 "$FETCH_SCRIPT" "$GCP_SECRET_ID")" || {
    echo "GCP Secret Manager($GCP_SECRET_ID)에서 Cloudflare 환경 정보를 가져오지 못했습니다." >&2
    exit 1
  }
else
  echo "GCP Secret 조회 스크립트($FETCH_SCRIPT)를 찾을 수 없습니다." >&2
  exit 1
fi

account_id=""
api_token=""

while IFS='=' read -r key value; do
  value="${value%$'\r'}"
  case "$key" in
    cloudflare-ID) account_id="$value" ;;
    cloudflare-API-token) api_token="$value" ;;
  esac
done <<< "$env_data"

if [[ -z "$account_id" || -z "$api_token" ]]; then
  echo "필수 키 cloudflare-ID 또는 cloudflare-API-token이 없습니다." >&2
  exit 1
fi

export CLOUDFLARE_ACCOUNT_ID="$account_id"
export CLOUDFLARE_API_TOKEN="$api_token"

cd "$SCRIPT_DIR"
exec npx wrangler deploy "$@"
