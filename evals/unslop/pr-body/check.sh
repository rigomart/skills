source "$(dirname "${BASH_SOURCE[0]}")/../checks.sh"
src="$(dirname "${BASH_SOURCE[0]}")/source.md" out="$REPO/pr-body.md"
check_skill_loaded
check_ran_scan
check_scan_clean scan_clean "$out"
check_kept code_spans_kept code_spans_in "$src" "$out"
check_kept links_kept links_in "$src" "$out"
check_kept numbers_kept numbers_in "$src" "$out"
check_no_new_numbers "$src" "$out"
check_facts "$(dirname "${BASH_SOURCE[0]}")/facts" "$out"
check_headings_kept "$src" "$out"
check_other_files_untouched pr-body.md
check_cold_reader no
check_report_names_scan
check_report_names_cold_reader
check_report_clean "$src"
