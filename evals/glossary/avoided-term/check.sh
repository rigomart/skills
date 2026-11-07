source "$EVAL_HERE/glossary/lib.sh"
# No skill_loaded: the skill leaves reading the glossary to the AGENTS.md line, so a
# session that only uses the terms needs GLOSSARY.md, not the skill.
check_read_glossary
check_challenged challenged_folder 'folder' '\bboards?\b'
check_challenged challenged_resolved 'resolve' '\bdone\b'
check_sketch_uses_terms
