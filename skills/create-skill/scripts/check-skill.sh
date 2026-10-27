#!/usr/bin/env bash
# Check skill folders: frontmatter, name, description and its length, and relative Markdown links.
# Usage: check-skill.sh <skill-dir> [<skill-dir>...]
# Prints one FAIL line per problem and exits 1 if any were found.

set -u

if [ $# -eq 0 ]; then
  echo "usage: check-skill.sh <skill-dir> [<skill-dir>...]" >&2
  exit 2
fi

failures=0
fail() {
  printf 'FAIL %s: %s\n' "$1" "$2"
  failures=$((failures + 1))
}

link_targets_outside_code() {
  awk '
    /^[[:space:]]*(```|~~~)/ { fenced = !fenced; next }
    fenced { next }
    {
      line = $0
      gsub(/`[^`]*`/, "", line)
      while (match(line, /\]\([^)]*\)/)) {
        target = substr(line, RSTART + 2, RLENGTH - 3)
        sub(/[[:space:]].*$/, "", target)
        print target
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$1"
}

for dir in "$@"; do
  dir=${dir%/}
  file="$dir/SKILL.md"
  if [ ! -f "$file" ]; then
    fail "$dir" "no SKILL.md"
    continue
  fi

  if [ "$(head -n 1 "$file")" != "---" ]; then
    fail "$file" "frontmatter must open with --- on line 1"
  elif ! tail -n +2 "$file" | grep -q '^---$'; then
    fail "$file" "frontmatter is never closed with ---"
  else
    front=$(awk 'NR == 1 { next } /^---$/ { exit } { print }' "$file")
    name=$(printf '%s\n' "$front" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)
    desc=$(printf '%s\n' "$front" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)
    folder=$(basename "$dir")

    if [ -z "$name" ]; then
      fail "$file" "missing name"
    elif [ "$name" != "$folder" ]; then
      fail "$file" "name '$name' does not match folder '$folder'"
    fi

    if [ -z "$desc" ]; then
      fail "$file" "missing description"
    else
      case $desc in
        \"* | \'* | \>* | \|*) ;;
        *': '*) fail "$file" "unquoted description contains ': '; quote it or use >-" ;;
      esac
      if [ ${#desc} -gt 250 ]; then
        fail "$file" "description is ${#desc} characters; keep it under 250"
      fi
    fi
  fi

  while IFS= read -r md; do
    while IFS= read -r target; do
      path=${target%%#*}
      case $path in
        '' | *://* | mailto:*) continue ;;
      esac
      [ -e "$(dirname "$md")/$path" ] || fail "$md" "broken link $target"
    done < <(link_targets_outside_code "$md")
  done < <(find "$dir" -name '*.md' -type f)
done

[ "$failures" -eq 0 ] || exit 1
