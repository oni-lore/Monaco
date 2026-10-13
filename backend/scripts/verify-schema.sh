#!/usr/bin/env bash
# Fails (exit 1) unless the required tables and the authorization trigger exist.
set -euo pipefail:
: "${DATABASE_URL:?DATABASE_URL must be set}"

required_tables=(users connections direct_conversations conversation_participants messages)
missing=0
for t in "${required_tables[@]}"; do
  found="$(psql "$DATABASE_URL" -X -At -v ON_ERROR_STOP=1 -c "SELECT 1 FROM pg_catalog.pg_tables WHERE schemaname='public' AND tablename='$t'")"
  if [ -z "$found" ]; then echo "MISSING table: public.$t" >&2; missing=1; else echo "ok table: public.$t"; fi
done

trig="$(psql "$DATABASE_URL" -X -At -v ON_ERROR_STOP=1 -c "SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid WHERE t.tgname='trigger_enforce_direct_conversation_connection' AND c.relname='conversation_participants' AND NOT t.tgisinternal")"
if [ -z "$trig" ]; then echo "MISSING trigger: trigger_enforce_direct_conversation_connection" >&2; missing=1; else echo "ok trigger: trigger_enforce_direct_conversation_connection"; fi

[ "$missing" -eq 0 ] || { echo "Schema verification FAILED" >&2; exit 1; }
echo "Schema verification passed"