#!/bin/bash
# Tests for format-written-file.sh. Run: bash ~/.kiro/hooks-bin/test-format-written-file.sh
#
# The cases that matter are the NEGATIVE ones. The bug this script replaces was a hook that
# formatted everything when it knew nothing, so "does nothing when the path is unknown" and
# "never touches a sibling file" are the assertions with teeth.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/format-written-file.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
check() {
  local what="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass=$((pass + 1))
    echo "  ok    $what"
  else
    fail=$((fail + 1))
    echo "  FAIL  $what"
    echo "          expected: $expected"
    echo "          actual:   $actual"
  fi
}

# A scratch project that gates on Biome, plus a sibling file that must never be touched.
proj="$WORK/proj"
mkdir -p "$proj"
cat >"$proj/biome.json" <<'JSON'
{ "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json", "formatter": { "enabled": true } }
JSON
echo '{}' >"$proj/package.json"

reset_fixtures() {
  printf 'const a = {b:1,c:2}\n' >"$proj/target.js"
  printf 'const sibling = {x:1,y:2}\n' >"$proj/sibling.js"
  printf '# Doc\n\n* star bullet\n' >"$proj/notes.md"
  printf '> quote\n> continuation\n' >"$proj/prose.md"
}

run_hook() { printf '%s' "$1" | bash "$SCRIPT"; }

echo "format-written-file.sh"

# --- Rule 1: fail closed -------------------------------------------------------------------
reset_fixtures
before=$(cat "$proj/sibling.js")
run_hook '{}'
check "empty context formats nothing" "$before" "$(cat "$proj/sibling.js")"

reset_fixtures
before=$(cat "$proj/sibling.js")
run_hook 'not json at all'
check "non-JSON context formats nothing" "$before" "$(cat "$proj/sibling.js")"

reset_fixtures
before=$(cat "$proj/sibling.js")
run_hook "{\"filePath\": \"$proj/does-not-exist.js\"}"
check "a path that is not a file formats nothing" "$before" "$(cat "$proj/sibling.js")"

reset_fixtures
before=$(cat "$proj/sibling.js")
run_hook "{\"filePath\": \"$proj\"}"
check "a DIRECTORY path formats nothing" "$before" "$(cat "$proj/sibling.js")"

# --- Rule 2: only the named file ------------------------------------------------------------
# Several plausible schemas, since the real one is undocumented.
for key in filePath file_path path file filename; do
  reset_fixtures
  sibling_before=$(cat "$proj/sibling.js")
  run_hook "{\"$key\": \"$proj/target.js\"}"
  changed="no"
  [ "$(cat "$proj/target.js")" != 'const a = {b:1,c:2}' ] && changed="yes"
  check "key '$key' formats the target" "yes" "$changed"
  check "key '$key' leaves the sibling alone" "$sibling_before" "$(cat "$proj/sibling.js")"
done

reset_fixtures
sibling_before=$(cat "$proj/sibling.js")
run_hook "{\"tool\": \"fs_write\", \"toolInput\": {\"nested\": {\"path\": \"$proj/target.js\"}}}"
changed="no"
[ "$(cat "$proj/target.js")" != 'const a = {b:1,c:2}' ] && changed="yes"
check "a nested path is found" "yes" "$changed"
check "a nested path leaves the sibling alone" "$sibling_before" "$(cat "$proj/sibling.js")"

# --- Rule 3: never markdown ----------------------------------------------------------------
reset_fixtures
before=$(cat "$proj/notes.md")
run_hook "{\"filePath\": \"$proj/notes.md\"}"
check "markdown is never reformatted (star bullet survives)" "$before" "$(cat "$proj/notes.md")"

reset_fixtures
before=$(cat "$proj/prose.md")
run_hook "{\"filePath\": \"$proj/prose.md\"}"
check "a blockquote keeps its markers" "$before" "$(cat "$proj/prose.md")"

# --- Rule 2 again: excluded directories ----------------------------------------------------
mkdir -p "$proj/node_modules/pkg"
printf 'const dep = {q:1}\n' >"$proj/node_modules/pkg/index.js"
before=$(cat "$proj/node_modules/pkg/index.js")
run_hook "{\"filePath\": \"$proj/node_modules/pkg/index.js\"}"
check "node_modules is left alone" "$before" "$(cat "$proj/node_modules/pkg/index.js")"

# --- Python: the hook that had never formatted anything -------------------------------------
# With an empty argument ruff errors ("a value is required for '[FILES]...'") and changes
# nothing, so these hooks were silent no-ops rather than destructive. Now they should work.
if command -v ruff >/dev/null 2>&1; then
  printf 'x = {  "a" :1 }\n' >"$proj/thing.py"
  printf 'sibling = {  "b" :2 }\n' >"$proj/other.py"
  sibling_before=$(cat "$proj/other.py")
  run_hook "{\"filePath\": \"$proj/thing.py\"}"
  changed="no"
  [ "$(cat "$proj/thing.py")" != 'x = {  "a" :1 }' ] && changed="yes"
  check "python is formatted" "yes" "$changed"
  check "python leaves the sibling alone" "$sibling_before" "$(cat "$proj/other.py")"
else
  echo "  skip  python (ruff not installed)"
fi

# --- Shell ----------------------------------------------------------------------------------
if command -v shfmt >/dev/null 2>&1; then
  printf 'if true;then\necho hi\nfi\n' >"$proj/script.sh"
  printf 'if true;then\necho sibling\nfi\n' >"$proj/other.sh"
  sibling_before=$(cat "$proj/other.sh")
  run_hook "{\"filePath\": \"$proj/script.sh\"}"
  changed="no"
  [ "$(cat "$proj/script.sh")" != "$(printf 'if true;then\necho hi\nfi')" ] && changed="yes"
  check "shell is formatted" "yes" "$changed"
  check "shell leaves the sibling alone" "$sibling_before" "$(cat "$proj/other.sh")"
else
  echo "  skip  shell (shfmt not installed)"
fi

echo
echo "  $pass passed, $fail failed"
[ "$fail" -eq 0 ]
