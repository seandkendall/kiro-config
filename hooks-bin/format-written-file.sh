#!/bin/bash
#
# Format ONLY the file a tool just wrote. Called from the `postToolUse` hook in the agent
# configs, which pipes Kiro's hook context to us as JSON on stdin.
#
# WHY THIS SCRIPT EXISTS (characterised 2026-09-14)
# ------------------------------------------------
# The hook used to be a one-liner:
#
#     npx prettier --write "$FILEPATH" 2>/dev/null || true
#
# `$FILEPATH` is not a variable Kiro sets — hook context arrives as JSON on STDIN — so it
# expanded to an empty string and the command became `prettier --write ""`. Proven by
# experiment, an empty argument makes prettier process EVERY eligible file in the working
# directory, and the working directory is the WORKSPACE ROOT regardless of what was written.
#
# Net effect: every single `fs_write`, anywhere, silently reformatted the whole repo. Writing a
# file in /tmp modified three tracked files in a git repo. It produced four false diffs in one
# session, it de-indented list continuations and stripped a blockquote marker in hand-written
# markdown (changing what the markdown MEANS), and it eventually broke the project's own format
# gate, which is the only reason it got attention. Until then it read as harmless noise, and it
# trained us to run `git checkout --` reflexively — which is exactly how a real accidental
# change gets waved through.
#
# DESIGN RULES
# ------------
#   1. FAIL CLOSED. If the written path cannot be determined, do NOTHING. Formatting "everything"
#      is never the safe interpretation of "I don't know which file changed".
#   2. Act on exactly one real file, never a directory, never a glob.
#   3. Never format MARKDOWN. Nothing in these projects gates markdown style, so a hook that
#      rewrites it is imposing a format no check asks for — and prose with deliberate layout
#      (tables, nested blockquotes) is what it damages.
#   4. Prefer the formatter the project actually gates on. A repo with a Biome config is checked
#      by Biome; running Prettier there fights the gate instead of helping it.
set -uo pipefail

payload=$(cat 2>/dev/null || true)
[ -z "$payload" ] && exit 0

# Pull the first string value, at any depth, under a key that plausibly names the written file,
# keeping only values that are an existing file. Tolerant of the context schema by design: it is
# undocumented, so matching several key spellings is cheaper than depending on one.
target=$(
  printf '%s' "$payload" | python3 -c '
import json, os, sys

KEYS = ("filepath", "file_path", "path", "file", "filename", "file_name", "abspath")


def walk(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if isinstance(value, str) and key.lower() in KEYS:
                yield value
        for value in node.values():
            yield from walk(value)
    elif isinstance(node, list):
        for value in node:
            yield from walk(value)


try:
    data = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)

for candidate in walk(data):
    if candidate and os.path.isfile(candidate):
        print(candidate)
        break
' 2>/dev/null || true
)

# Rule 1: unknown path means do nothing at all.
if [ -z "$target" ]; then
  # The hook context schema is undocumented, so path extraction above matches several key
  # spellings. If a future Kiro version uses a different one, this script silently stops
  # formatting rather than silently formatting everything — the right way round to fail.
  #
  # To find out which it is, run a session with KIRO_HOOK_DEBUG=1 and read the log: it records
  # the payloads this script could not interpret, which is exactly what is needed to add the key.
  if [ "${KIRO_HOOK_DEBUG:-0}" = "1" ]; then
    {
      echo "=== $(date -u +%FT%TZ) could not resolve a written path from the hook context ==="
      printf '%s\n' "$payload"
    } >>"${TMPDIR:-/tmp}/kiro-hook-unresolved.log" 2>/dev/null || true
  fi
  exit 0
fi
[ -f "$target" ] || exit 0

case "$target" in
  # Build output and dependencies are not ours to format, and reformatting them can invalidate
  # a build that already passed its gate.
  */node_modules/*|*/dist/*|*/build/*|*/.venv/*|*/__pycache__/*|*/.git/*|*/coverage*/*) exit 0 ;;
esac

ext="${target##*.}"

# Rule 3: markdown is hand-maintained prose here. This single line is what would have prevented
# every instance of the churn described above.
case "$ext" in
  md|markdown|mdx) exit 0 ;;
esac

# Python. ⚠️ Note the ruff/shfmt/swiftformat hooks this replaces were NOT destructive like the
# prettier one — verified: with an empty argument ruff exits with "a value is required for
# '[FILES]...'" and shfmt with "lstat : no such file or directory", both changing nothing. They
# had simply never formatted anything since the day they were written. Routing them through here
# makes them do the job they claimed to do.
if [ "$ext" = "py" ]; then
  if command -v ruff >/dev/null 2>&1; then
    ruff check --fix --quiet "$target" >/dev/null 2>&1
    ruff format --quiet "$target" >/dev/null 2>&1
  fi
  exit 0
fi

if [ "$ext" = "swift" ]; then
  command -v swiftformat >/dev/null 2>&1 && swiftformat --quiet "$target" >/dev/null 2>&1
  exit 0
fi

if [ "$ext" = "sh" ] || [ "$ext" = "bash" ]; then
  command -v shfmt >/dev/null 2>&1 && shfmt -w "$target" >/dev/null 2>&1
  exit 0
fi

# Rule 4: find the nearest project root and use whichever formatter it gates on.
dir=$(cd "$(dirname "$target")" && pwd)
root=""
while [ "$dir" != "/" ]; do
  if [ -f "$dir/biome.json" ] || [ -f "$dir/biome.jsonc" ] || [ -f "$dir/package.json" ]; then
    root="$dir"
    break
  fi
  dir=$(dirname "$dir")
done
[ -z "$root" ] && exit 0

case "$ext" in
  js|jsx|ts|tsx|mjs|cjs|json|jsonc|css|scss|html|yml|yaml) ;;
  *) exit 0 ;;
esac

if [ -f "$root/biome.json" ] || [ -f "$root/biome.jsonc" ]; then
  ( cd "$root" && npx --no-install biome check --write "$target" >/dev/null 2>&1 )
else
  ( cd "$root" && npx --no-install prettier --write "$target" >/dev/null 2>&1 )
fi
exit 0
