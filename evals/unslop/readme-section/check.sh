source "$(dirname "${BASH_SOURCE[0]}")/../checks.sh"
here="$(dirname "${BASH_SOURCE[0]}")"
src="$here/section.md" out=$(mktemp)
before=$(git -C "$REPO" show HEAD:README.md | awk '/^## Storage And Sync/{exit} {print}')
after=$(cat "$here/after.md")
readme=$(cat "$REPO/README.md")
check_skill_loaded
check_ran_scan
if [ "${readme#"$before"}" != "$readme" ] && [ "${readme%"$after"}" != "$readme" ]; then
  pass rest_of_readme_untouched
  rest=${readme#"$before"}; printf '%s\n' "${rest%"$after"}" > "$out"
else
  fail rest_of_readme_untouched "the text before or after the storage section changed"
  awk '/^## [Ss]torage/{on=1; print; next} /^## /{on=0} on' "$REPO/README.md" > "$out"
fi
check_scan_clean scan_clean "$out"
check_kept code_spans_kept code_spans_in "$src" "$out"
check_kept links_kept links_in "$src" "$out"
check_kept numbers_kept numbers_in "$src" "$out"
check_no_new_numbers "$src" "$out"
check_facts "$here/facts" "$out"
check_headings_kept "$src" "$out"
check_other_files_untouched README.md
check_cold_reader no
check_report_names_scan
check_report_names_cold_reader
orig=$(mktemp); git -C "$REPO" show HEAD:README.md > "$orig"
check_report_clean "$orig"
rm -f "$out" "$orig"
