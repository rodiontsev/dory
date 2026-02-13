#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/script-torrent-done.env"

if [[ -f "${ENV_FILE}" ]]; then
  source "${ENV_FILE}"
else
  echo "Environment file not found: ${ENV_FILE}"
  exit 0
fi

# Required vars (safe with set -u)
if [[ -z "${TELEGRAM_API_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
  echo "Telegram variable are missing - exiting without sending the message"
  exit 0
fi

if [[ -z "${TR_TORRENT_NAME:-}" || -z "${TR_TIME_LOCALTIME:-}" ]]; then
  echo "Transmission variables are missing - exiting without sending the message"
  exit 0
fi

FMT_TR_TIME="$(date -d "${TR_TIME_LOCALTIME}" +"%-d %b, %-H:%M")"

# Escape the torrent name
escape_html() {
  local s="$1"
  s="${s//&/&amp;}"
  s="${s//</&lt;}"
  s="${s//>/&gt;}"
  printf '%s' "$s"
}

TORRENT_NAME_ESC="$(escape_html "${TR_TORRENT_NAME}")"

curl --silent --show-error --fail --output /dev/null \
  --retry 3 \
  --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=The torrent <b>${TORRENT_NAME_ESC}</b> was downloaded on ${FMT_TR_TIME}." \
  --data-urlencode "parse_mode=HTML" \
  "https://api.telegram.org/bot${TELEGRAM_API_TOKEN}/sendMessage"