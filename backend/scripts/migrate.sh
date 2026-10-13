#!/usr/bin/env bash
# Applies backend/migrations/*.up.sql in order, once each, fail-fast.
# Usage: DATABASE_URL=postgresql://... ./scripts/migrate.sh
# Exits non-zero if any SQL fails, no migration files are found,
# or the expected schema is missing afterwards.
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL must be set}"
DIR="$(cd "$(dirname "$0")/../migrations" && pwd)"
PSQL=(psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1)

shopt -s nullglob
files=("$DIR"/*.up.sql)
if [ "${#files[@]}" -eq 0 ]; then
  echo "ERROR: no *.up.sql files found in $DIR" >&2
  exit 1
fi

"${PSQL[@]}" -c "CREATE TABLE IF NOT EXISTS schema_migrations (
  name TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)"

for f in "${files[@]}"; do
  name="$(basename "$f")"
  done_already="$("${PSQL[@]}" -At -c "SELECT 1 FROM schema_migrations WHERE name = '$name'")"
  if [ -n "$done_already" ]; then
    echo "skip   $name (already applied)"
    continue
  fi
  echo "apply  $name"
  # -1 = single transaction: a failure leaves no partial schema behind
  "${PSQL[@]}" -1 -f "$f" -c "INSERT INTO schema_migrations (name) VALUES ('$name')"
  echo "done   $name"
done

"$(dirname "$0")/verify-schema.sh"