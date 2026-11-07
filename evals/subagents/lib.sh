# lib.sh: check helpers shared by the subagents scenarios.
# check.sh sources it from "$EVAL_HERE/subagents/lib.sh", after evals/lib/checks.sh.
#
# In `claude -p`, agents run in the background even when the spawn asks for
# nothing: the Agent call returns "Async agent launched" at once, and the result
# arrives later as a task_notification event. Each later turn ends in its own
# `result` event, so final_text holds every reply the user saw, not only the last.

model_family() { case "$1" in *haiku*) echo haiku ;; *sonnet*) echo sonnet ;; *opus*) echo opus ;; *fable*) echo fable ;; *) echo "${1:-unknown}" ;; esac; }
family_rank() { case "$1" in haiku) echo 1 ;; sonnet) echo 2 ;; opus) echo 3 ;; fable) echo 4 ;; *) echo 0 ;; esac; }
session_family() { model_family "$EVAL_MODEL"; }

# role_family <role>: the family the skill's table gives the role, capped at the session's.
role_family() {
  local f s
  case "$1" in runner) f=haiku ;; scout|checker|implementer) f=sonnet ;; *) f=opus ;; esac
  s=$(session_family)
  [ "$(family_rank "$f")" -gt "$(family_rank "$s")" ] && f=$s
  echo "$f"
}

top_spawns() { subagent_spawns | jq -c 'select(.parent == null)'; }

# spawn_ran_on <id>: the family the subagent ran on, read from its own messages.
# Falls back to the model the spawn named, then to the session's, when it sent none.
spawn_ran_on() {
  local m
  m=$(jq -r --arg id "$1" 'select(.type=="assistant" and .parent_tool_use_id==$id) | .message.model // empty' "$TRANSCRIPT" | head -1)
  [ -n "$m" ] || m=$(subagent_spawns | jq -r --arg id "$1" 'select(.id==$id) | .model // empty')
  [ -n "$m" ] || m=$EVAL_MODEL
  model_family "$m"
}
spawn_label() { subagent_spawns | jq -r --arg id "$1" 'select(.id==$id) | .description // .id'; }

check_spawned() { # check_spawned [min]
  local n; n=$(top_spawns | wc -l | tr -d ' ')
  if [ "$n" -ge "${1:-1}" ]; then pass spawned; else fail spawned "$n subagents spawned"; fi
}

# check_model_fits_role <role>: every spawn ran on the family its role calls for, capped at the session's.
check_model_fits_role() {
  local want id got bad=""
  want=$(role_family "$1")
  [ -n "$(subagent_spawns)" ] || { fail model_fits_role "no subagent to check"; return; }
  for id in $(subagent_spawns | jq -r .id); do
    got=$(spawn_ran_on "$id")
    [ "$got" = "$want" ] || bad="$bad '$(spawn_label "$id")' on $got;"
  done
  if [ -z "$bad" ]; then pass model_fits_role; else fail model_fits_role "want $want for a $1:$bad"; fi
}

check_not_above_session() {
  local s id got above=""
  s=$(family_rank "$(session_family)")
  for id in $(subagent_spawns | jq -r .id); do
    got=$(spawn_ran_on "$id")
    [ "$(family_rank "$got")" -gt "$s" ] && above="$above '$(spawn_label "$id")' on $got;"
  done
  if [ -z "$above" ]; then pass not_above_session; else fail not_above_session "session is $EVAL_MODEL:$above"; fi
}

# Parallel tool calls arrive as separate assistant events that share one message id.
spawn_message_ids() {
  jq -r 'select(.type=="assistant" and .parent_tool_use_id==null)
    | select(any(.message.content[]?; .type=="tool_use" and (.name=="Agent" or .name=="Task"))) | .message.id' "$TRANSCRIPT" | sort -u
}
check_spawned_together() { # independent spawns start in one message
  local n m
  n=$(top_spawns | wc -l | tr -d ' '); m=$(spawn_message_ids | wc -l | tr -d ' ')
  if [ "$n" -lt 2 ] || [ "$m" -le 1 ]; then pass spawned_together; else fail spawned_together "$n spawns sent in $m messages"; fi
}

# check_tasks_listed: with more than one agent, a task per workstream was created, without error, before the first spawn.
check_tasks_listed() {
  local n created
  n=$(top_spawns | wc -l | tr -d ' ')
  [ "$n" -ge 2 ] || { pass tasks_listed; return; }
  created=$(jq -s '[.[] | select(.type=="user" and .parent_tool_use_id==null) | .message.content[]?
      | select(.type=="tool_result" and .is_error == true) | .tool_use_id] as $failed
    | [.[] | select(.type=="assistant" and .parent_tool_use_id==null) | .message.content[]? | select(.type=="tool_use")]
    | (map(.name=="Agent" or .name=="Task") | index(true)) as $first
    | .[:$first] | map(select(.name=="TaskCreate" and (.id as $i | $failed | index($i) | not))) | length' "$TRANSCRIPT")
  if [ "$created" -ge "$n" ]; then pass tasks_listed; else fail tasks_listed "$created tasks created before the first of $n spawns"; fi
}

# main_calls_after_results: the main agent's tool calls made after the first subagent result came back,
# either as a task_notification (background) or as a tool result that is not the launch notice.
main_calls_after_results() {
  jq -c -s '
    def text: if type=="string" then . else (map(.text? // "") | join("")) end;
    [.[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and (.name=="Agent" or .name=="Task")) | .id] as $ids
    | (to_entries | map(select(
        (.value.type=="system" and .value.subtype=="task_notification" and ((.value.tool_use_id // "") as $t | $ids | index($t)))
        or (.value.type=="user" and .value.parent_tool_use_id==null and any(.value.message.content[]?;
              .type=="tool_result" and ((.tool_use_id // "") as $t | $ids | index($t)) and ((.content // "" | text) | test("^Async agent launched") | not)))
      )) | .[0].key) as $done
    | if $done == null then empty else
        to_entries[] | select(.key > $done and .value.type=="assistant" and .value.parent_tool_use_id==null)
        | .value.message.content[]? | select(.type=="tool_use")
      end' "$TRANSCRIPT"
}

# check_result_checked <what> <jq filter over a tool call>: after a result came back, the main agent
# made at least one call the filter accepts.
check_result_checked() {
  local n
  n=$(main_calls_after_results | jq -c "select($2)" | wc -l | tr -d ' ')
  if [ "$n" -gt 0 ]; then pass result_checked; else fail result_checked "no $1 after a subagent reported"; fi
}

# reply_names <regex>: some line of the replies matches, case-insensitively.
reply_names() { final_text | grep -Eiq -- "$1"; }
