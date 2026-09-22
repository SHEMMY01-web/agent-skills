#!/usr/bin/env bash
# ==============================================================================
# Cloud Keep-Alive & Cold-Start Endpoint Prober
# Reusable enterprise utility for CI cron jobs and container health checks
# ==============================================================================

set -euo pipefail

URL=""
MAX_RETRIES=4
RETRY_DELAY=10
CONNECT_TIMEOUT=10
MAX_TIME=60
AUTH_HEADER=""
API_KEY_HEADER=""

print_usage() {
  cat << EOF
Usage: $(basename "$0") --url <URL> [OPTIONS]

Options:
  --url <URL>              Target URL to probe (required)
  --retries <N>            Max retry attempts (default: 4)
  --delay <SECONDS>        Delay between retries in seconds (default: 10)
  --connect-timeout <SEC>  TCP handshake timeout in seconds (default: 10)
  --max-time <SEC>         Total request timeout in seconds (default: 60)
  --auth <TOKEN>           Bearer authorization token
  --apikey <KEY>           Custom apikey header (e.g. Supabase anon/service key)
  -h, --help               Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      URL="$2"; shift 2 ;;
    --retries)
      MAX_RETRIES="$2"; shift 2 ;;
    --delay)
      RETRY_DELAY="$2"; shift 2 ;;
    --connect-timeout)
      CONNECT_TIMEOUT="$2"; shift 2 ;;
    --max-time)
      MAX_TIME="$2"; shift 2 ;;
    --auth)
      AUTH_HEADER="Authorization: Bearer $2"; shift 2 ;;
    --apikey)
      API_KEY_HEADER="apikey: $2"; shift 2 ;;
    -h|--help)
      print_usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      print_usage
      exit 1
      ;;
  esac
done

if [[ -z "$URL" ]]; then
  echo "❌ Error: --url is required." >&2
  print_usage
  exit 1
fi

CURL_HEADERS=()
if [[ -n "$AUTH_HEADER" ]]; then
  CURL_HEADERS+=(-H "$AUTH_HEADER")
fi
if [[ -n "$API_KEY_HEADER" ]]; then
  CURL_HEADERS+=(-H "$API_KEY_HEADER")
fi

echo "===================================================="
echo "⚡ Probing Target: $URL"
echo "   Max Attempts: $MAX_RETRIES | Delay: ${RETRY_DELAY}s | Connect Timeout: ${CONNECT_TIMEOUT}s | Max Time: ${MAX_TIME}s"
echo "===================================================="

SUCCESS=false

for attempt in $(seq 1 "$MAX_RETRIES"); do
  echo "--- Attempt $attempt of $MAX_RETRIES ---"
  
  START_TIME=$(date +%s%N 2>/dev/null || date +%s)
  
  HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
    --connect-timeout "$CONNECT_TIMEOUT" \
    --max-time "$MAX_TIME" \
    "${CURL_HEADERS[@]}" \
    "$URL" || echo -e "\n000")

  STATUS_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)
  BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

  echo "HTTP Status Code: $STATUS_CODE"
  if [[ -n "$BODY" ]]; then
    echo "Response Snippet: $(echo "$BODY" | head -c 250)"
  fi

  if [[ "$STATUS_CODE" -ge 200 && "$STATUS_CODE" -lt 300 ]]; then
    echo "✅ Success! Endpoint responded with HTTP $STATUS_CODE."
    SUCCESS=true
    break
  fi

  if [[ "$attempt" -lt "$MAX_RETRIES" ]]; then
    echo "⏳ Sleeping ${RETRY_DELAY}s for cold-start initialization..."
    sleep "$RETRY_DELAY"
  fi
done

if [[ "$SUCCESS" = false ]]; then
  echo "❌ Failed to reach $URL with 2xx status after $MAX_RETRIES attempts." >&2
  exit 1
fi

exit 0
