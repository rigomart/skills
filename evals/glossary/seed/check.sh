source "$EVAL_HERE/glossary/lib.sh"
check_skill_loaded
check_glossary_written
check_collision found_board_collision 'board' 'bucket' 'folder'
check_collision found_done_collision '\bdone\b' 'resolve'
check_archive_split
check_entries
check_agents_line
check_only_glossary_files
