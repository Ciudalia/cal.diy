#!/usr/bin/env bash
# Smoke checks locales contra app en 127.0.0.1:3000
set -euo pipefail
BASE="${1:-http://127.0.0.1:3000}"

login=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/auth/login")
setup=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/auth/setup")
step=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/auth/setup?step=1")

echo "login=$login setup=$setup setup_step1=$step"
ok=0
[[ "$login" =~ ^(200|302|307)$ ]] && [[ "$setup" =~ ^(200|302|307)$ ]] && [[ "$step" =~ ^(200|302|307)$ ]] && ok=1
if [[ "$ok" -eq 1 ]]; then
  echo "SMOKE_OK"
  exit 0
fi
echo "SMOKE_FAIL"
exit 1
