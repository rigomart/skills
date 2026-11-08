source "$(dirname "${BASH_SOURCE[0]}")/../checks.sh"
here="$(dirname "${BASH_SOURCE[0]}")"
src=$(mktemp) reply=$(mktemp) out=$(mktemp) report=$(mktemp)
# The reply holds the rewrite and the report: a paragraph that talks about the edit (the scan, a cold
# reader, what was cut or kept, a suggestion) outside double quotes is the report, and the rest is
# the rewrite.
awk 'seen{print} /^$/{seen=1}' "$here/prompt.txt" > "$src"
final_text | grep -Ev '^[[:space:]]*(```|~~~)' > "$reply"
awk -v out="$out" -v report="$report" 'BEGIN{RS=""} {
  bare=$0; gsub(/"[^"]*"/, "", bare)
  if (tolower(bare) ~ /scan|subagent|cold[- ]?read|fresh[- ]?read|reread|unslop|what (i )?changed|changes:|(^|\n)[-*]? ?(cut|replaced|changed|split|kept|removed|dropped|rewrote|moved|turned) |ready to paste|saved (at|to|in) |paste this|slack-ready|here.s the|became|edits? (that )?(might|could|change)|you could|if you want|(^|[^a-z])i (cut|changed|kept|left|replaced|dropped|removed|rewrote|split|made|moved|also|did)/) print $0 "\n" > report
  else print $0 "\n" > out
}' "$reply"
check_skill_loaded
check_ran_scan
if grep -q '#41' "$out"; then pass rewrite_found; else fail rewrite_found "no paragraph of the reply reads as the rewrite"; fi
check_scan_clean scan_clean "$out"
check_kept code_spans_kept code_spans_in "$src" "$out"
check_kept links_kept links_in "$src" "$out"
check_kept numbers_kept numbers_in "$src" "$out"
check_no_new_numbers "$src" "$out"
check_facts "$here/facts" "$out"
check_other_files_untouched none
check_cold_reader no
check_report_names_scan
check_report_names_cold_reader
check_report_clean "$src" "$report"
rm -f "$src" "$reply" "$out" "$report"
