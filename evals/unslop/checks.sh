# Sourced by each scenario's check.sh after evals/lib/checks.sh.
# A scenario keeps its source text in source.md (or after the prompt's first blank line)
# and the facts that must survive in facts, one extended regex per line, matched case-insensitively.

UNSLOP_EVALS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SCAN="${SKILL_DIR:-$UNSLOP_EVALS/../../skills/unslop}/scripts/scan.sh"

# One token per line, sorted and unique, for comm.
numbers_in() { sed -E 's/^[[:space:]]*[0-9]+\.[[:space:]]//' "$1" | grep -oE '[0-9]+' | sort -u; }
code_spans_in() { grep -oE '`[^`]+`' "$1" | sort -u; }
links_in() { grep -oE 'https?://[^] )>"]+' "$1" | sed -E 's/[.,;:]+$//' | sort -u; }

check_kept() { # check_kept <name> <extractor> <source> <output>: every token in the source is in the output
  local missing
  missing=$(comm -23 <("$2" "$3") <("$2" "$4") | paste -sd, -)
  if [ -z "$missing" ]; then pass "$1"; else fail "$1" "lost $missing"; fi
}

check_no_new_numbers() { # check_no_new_numbers <source> <output>
  local added
  added=$(comm -13 <(numbers_in "$1") <(numbers_in "$2") | paste -sd, -)
  if [ -z "$added" ]; then pass no_new_numbers; else fail no_new_numbers "added $added"; fi
}

check_facts() { # check_facts <facts file> <output>: a line starting with ! must not match, such as a flipped condition
  local bad="" re
  while IFS= read -r re; do
    [ -n "$re" ] || continue
    case $re in
      !*) ! grep -Eiq -- "${re#!}" "$2" || bad="$bad | matched ${re#!}" ;;
      *) grep -Eiq -- "$re" "$2" || bad="$bad | no match for $re" ;;
    esac
  done < "$1"
  if [ -z "$bad" ]; then pass facts_kept; else fail facts_kept "${bad# | }"; fi
}

check_scan_clean() { # check_scan_clean <name> <file>: the bundled scan flags nothing
  local out
  if out=$(bash "$SCAN" "$2" 2>&1); then pass "$1"; else fail "$1" "$(printf '%s' "$out" | sed -E 's/^[^:]*:[0-9]+: //' | head -3 | paste -sd'|' -)"; fi
}

check_headings_kept() { # check_headings_kept <source> <output>: same headings, case aside
  local want got
  want=$(grep -E '^#+ ' "$1" | tr '[:upper:]' '[:lower:]')
  got=$(grep -E '^#+ ' "$2" | tr '[:upper:]' '[:lower:]')
  if [ "$want" = "$got" ]; then pass headings_kept; else fail headings_kept "headings were [$(printf '%s' "$got" | paste -sd, -)]"; fi
}

# The final reply with fence lines dropped, so a fenced rewrite is still scanned, and with
# double-quoted spans dropped, where the report quotes the draft's wording before an edit.
reply_for_scan() { final_text | grep -Ev '^[[:space:]]*(```|~~~)' | sed -E 's/"[^"]*"//g'; }

# uncite <source>: stdin with each dash or curly quote dropped where the 8 characters on one side of
# it, with it, appear in the source.
uncite() {
  perl -CSD -Mutf8 -e 'local $/; open my $fh, "<:encoding(UTF-8)", shift or die; my $src = <$fh>; local $/ = "\n";
    while (my $l = <STDIN>) {
      $l =~ s{(?<=(.{8}))([\x{2013}\x{2014}\x{2018}\x{2019}\x{201C}\x{201D}])}{index($src, "$1$2") >= 0 ? "" : $2}ge;
      $l =~ s{([\x{2013}\x{2014}\x{2018}\x{2019}\x{201C}\x{201D}])(?=(.{8}))}{index($src, "$1$2") >= 0 ? "" : $1}ge;
      print $l }' "$1"
}

check_report_clean() { # check_report_clean <source> [report file]: the report is prose too, so the scan flags
  # nothing in it outside quotes. Citing the source is fine: a word, phrase or emoji hit that appears in
  # the source passes, and so does a dash or curly quote copied with the words around it. Format hits
  # never pass. The report is the whole final reply unless a file holding it is given.
  local f hits; f=$(mktemp)
  if [ -n "${2:-}" ]; then sed -E 's/"[^"]*"//g' "$2"; else reply_for_scan; fi | uncite "$1" > "$f"
  hits=$(bash "$SCAN" "$f" 2>&1 | sed -E 's/^[^:]*:[0-9]+: //' | while IFS= read -r h; do
    if printf '%s' "$h" | grep -Eq '^(AI vocabulary|fancy|filler|stacked hedge|signposting|chat phrase|decorative emoji)' \
      && grep -Fiq -- "${h##*: }" "$1"; then continue; fi
    printf '%s\n' "$h"
  done)
  rm -f "$f"
  if [ -z "$hits" ]; then pass report_clean; else fail report_clean "$(printf '%s' "$hits" | head -3 | paste -sd'|' -)"; fi
}

check_ran_scan() { check_ran ran_scan 'scan\.sh'; }

check_report_names_scan() {
  if final_text | grep -Eiq 'scan'; then pass report_names_scan; else fail report_names_scan "final reply does not mention the scan"; fi
}

check_report_names_cold_reader() {
  if final_text | grep -Eiq '(cold|fresh|separate|second|independent)[- ]?read|fresh (sub)?agent|subagent'; then pass report_names_cold_reader
  else fail report_names_cold_reader "final reply does not say whether a cold reader ran"; fi
}

check_other_files_untouched() { # check_other_files_untouched <path in REPO>: no other tracked file changed
  local changed
  changed=$(git -C "$REPO" status --porcelain --untracked-files=no | awk '{print $NF}' | grep -vxF "$1" | paste -sd, -)
  if [ -z "$changed" ]; then pass other_files_untouched; else fail other_files_untouched "changed $changed"; fi
}
