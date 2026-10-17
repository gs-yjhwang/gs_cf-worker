#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUDFLARE_ENV_FILE="${CLOUDFLARE_ENV_FILE:-/home/gamess/infra_cloudflare/.env}"

if [[ ! -r "$CLOUDFLARE_ENV_FILE" ]]; then
  echo "Cloudflare 환경 파일을 읽을 수 없습니다: $CLOUDFLARE_ENV_FILE" >&2
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
done < "$CLOUDFLARE_ENV_FILE"

if [[ -z "$account_id" || -z "$api_token" ]]; then
  echo "필수 키 cloudflare-ID 또는 cloudflare-API-token이 없습니다." >&2
  exit 1
fi

export CLOUDFLARE_ACCOUNT_ID="$account_id"
export CLOUDFLARE_API_TOKEN="$api_token"

cd "$SCRIPT_DIR"
exec npx wrangler deploy "$@"
