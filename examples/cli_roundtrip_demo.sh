#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OSS_ROOT="$(cd "$ROOT/.." && pwd)"
WORK="${TMPDIR:-/tmp}/koutendb-nif-cli-roundtrip-$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

cd "$ROOT"

nim c -d:release --nimcache:/tmp/nimcache_koutendb_nif_tool \
  -o:"$WORK/nif_file_tool" examples/nif_file_tool.nim

nim c -d:release --nimcache:/tmp/nimcache_koutendb_cli_for_nif \
  --path:"$OSS_ROOT/sodiumkit/src" \
  -o:"$WORK/kouten" "$OSS_ROOT/ceresdb/src/koutencli.nim"

printf '(record title "KoutenDB" kind cliRoundtrip)' > "$WORK/input.nif"
"$WORK/nif_file_tool" encode --in="$WORK/input.nif" --out="$WORK/input.bif"

put_output="$("$WORK/kouten" put --data="$WORK/data" --ring=artifacts/nif \
  --in="$WORK/input.bif" --codec=bif)"
id="$(printf '%s\n' "$put_output" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^rawId=/) {sub(/^rawId=/, "", $i); print $i}}')"
test -n "$id"

base64_output="$("$WORK/kouten" get --data="$WORK/data" --ring=artifacts/nif --id="$id" --view=base64)"
printf '%s\n' "$base64_output" | grep -q '^codec=bif encoding=base64$'
printf '%s\n' "$base64_output" | awk 'NR == 2 {print}' | base64 -d > "$WORK/output.bif"
"$WORK/nif_file_tool" decode --in="$WORK/output.bif" --out="$WORK/output.nif"

cmp "$WORK/input.nif" "$WORK/output.nif"

auto_output="$("$WORK/kouten" get --data="$WORK/data" --ring=artifacts/nif --id="$id" --view=auto)"
printf '%s\n' "$auto_output" | grep -q '^codec=bif encoding=base64$'

echo "koutendb-nif CLI roundtrip passed"
