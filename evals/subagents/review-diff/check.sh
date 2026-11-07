source "$EVAL_HERE/subagents/lib.sh"
check_skill_loaded
check_spawned
check_model_fits_role reviewer
check_not_above_session
hinted=$(top_spawns | jq -r '.prompt // ""' | grep -Eio "I (think|suspect|believe)|(it|this|the (code|diff|change|branch|fix)) (looks|seems) (fine|good|correct|right|wrong|broken|buggy)|LGTM|there('s| is) a bug|confirm (that|the bug)" | head -1 || true)
if [ -z "$hinted" ]; then pass brief_no_verdict; else fail brief_no_verdict "brief says '$hinted'"; fi
check_result_checked "read of the changed code or the diff" \
  '(.name=="Read" and (.input.file_path // "" | test("src/(tasks|cli)\\.mjs|test/tasks"))) or (.name=="Grep" and ((.input.path // "") + " " + (.input.pattern // "") | test("src|test|overdue|splice|due")))
   or (.name=="Bash" and (.input.command // "" | test("git (diff|show|log -p)|(cat|sed|grep|head|nl) .*src/")))'
if reply_names 'overdue' && reply_names '!t\.done|t\.done|done tasks|completed tasks|finished tasks|inverted|negat|already (done|completed)'; then pass found_done_bug; else fail found_done_bug "reply does not say overdueTasks keeps done tasks"; fi
if reply_names 'splice|--due.*(undefined|lost|dropped|never|missing|ignored)'; then pass found_due_flag_bug; else fail found_due_flag_bug "reply does not say add --due drops the date"; fi
if reply_names '(same|other|another|different|cross|second)[- ](model )?provider|OpenAI|Codex|GPT|non-Claude|outside Claude'; then pass said_same_provider; else fail said_same_provider "reply does not say the Reviewer ran on the same provider"; fi
if [ "$(session_family)" != opus ] && [ "$(session_family)" != fable ]; then
  if reply_names 'opus|larger (one|model)|capped|(at|to) (that|this|mid) ?size|mid-size|session.{0,20}sonnet|sonnet.{0,20}session'; then pass said_capped; else fail said_capped "reply does not say the Reviewer ran below Opus"; fi
fi
if [ -z "$(git -C "$REPO" status --porcelain)" ] && [ "$(git -C "$REPO" rev-list --count main..overdue-tasks)" = 1 ]; then pass no_edits; else fail no_edits "the tree or branch changed"; fi
