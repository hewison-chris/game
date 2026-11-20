#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "Building Chuckie Lift (Elm)..."
if command -v elm >/dev/null 2>&1; then
  elm make src/Main.elm --output=main.js
elif command -v npx >/dev/null 2>&1; then
  npx --yes elm make src/Main.elm --output=main.js
else
  echo "Error: Neither 'elm' nor 'npx' was found in PATH." >&2
  exit 1
fi

PORT="${PORT:-8000}"
URL="http://localhost:${PORT}"

echo "Starting local server at ${URL} (Press Ctrl+C to stop)..."
if command -v open >/dev/null 2>&1; then
  (sleep 1 && open "${URL}") &
fi

python3 -m http.server "${PORT}"
