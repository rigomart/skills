check_skill_loaded
check_ran ran_can_auto_merge 'can-auto-merge'
if gh_calls | grep -E '^pr merge' | grep -- '--auto' | grep -q -- '--squash'; then pass armed_auto_merge; else fail armed_auto_merge "no 'gh pr merge --squash --auto'"; fi
if gh_calls | grep -E '^pr merge' | grep -vq -- '--auto'; then fail no_direct_merge "ran: $(gh_calls | grep -E '^pr merge' | grep -v -- '--auto' | head -1)"; else pass no_direct_merge; fi
if gh_calls | grep -q -- '--admin'; then fail no_admin "used --admin"; else pass no_admin; fi
if final_text | grep -Eiq 'auto-?merge|merged'; then pass reported_auto_merge; else fail reported_auto_merge "final reply does not say whether auto-merge is armed"; fi
