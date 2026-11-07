#!/usr/bin/env bash
# guard.sh: keep a recall eval run away from the user's real chats.
#
# As a PreToolUse hook (installed by recall_isolate), it reads the hook's JSON on
# stdin, logs ALLOW or BLOCK to .claude/eval-guard.log, and exits 2 to block a call
# that:
# - names a path that resolves, from the call's working directory, to the home
#   directory, inside it or above it (`~/.claude`, `../../../Users/me`, `/`, `/Users/*`);
#   a `cd` moves the working directory for the rest of the command;
# - names a .claude or .codex path outside the run's temp dir;
# - unsets or sets RECALL_CLAUDE_PROJECTS or RECALL_CODEX_SESSIONS, which point
#   sessions.sh at the fixture chats;
# - runs sessions.sh while the hook's own environment lacks those overrides.
# check_no_real_chats runs it again over each tool call in the transcript with
# GUARD_REPLAY=1, from the repo as working directory and without the last rule.
set -u
proj=${CLAUDE_PROJECT_DIR:-$REPO}
work=$(cd "$(dirname "$proj")" && pwd -P)
input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // "?"')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
reason=$(printf '%s' "$input" | jq -r '[.tool_input | .. | strings] | join("\n")' \
  | WORK=$work HOME_DIR=$HOME PROJ=$proj START=${cwd:-$proj} TOOL=$tool perl -0777 -ne '
    sub norm { my @o; for my $c (split m{/+}, shift) { next if $c eq "" || $c eq "."; if ($c eq "..") { pop @o } else { push @o, $c } } "/" . join("/", @o) }
    my $home = norm($ENV{HOME_DIR}); my $proj = norm($ENV{PROJ}); my $cwd = norm($ENV{START});
    my @ok = (norm($ENV{WORK})); push @ok, "/private$ok[0]" if $ok[0] =~ m{^/var/}; push @ok, $1 if $ok[0] =~ m{^/private(/var/.*)};
    sub within { my ($p, $d) = @_; $d eq "/" || $p eq $d || index($p, "$d/") == 0 }
    sub inside { my $p = shift; scalar grep { within($p, $_) } @ok }
    sub resolve { my ($t, $cwd) = @_;
      $t =~ s{^~(?=/|$)}{$home}; $t =~ s{^\$\{?HOME\}?(?=/|$)}{$home};
      $t =~ s{^\$\{?CLAUDE_PROJECT_DIR\}?(?=/|$)}{$proj}; $t =~ s{^\$\{?PWD\}?(?=/|$)}{$cwd};
      return undef if $t =~ /^\$/;
      norm($t =~ m{^/} ? $t : "$cwd/$t") }
    my $text = $_;
    if ($text =~ /\benv\b[^;&|\n]*\s-[a-z]*[iu]\b|\bunset\b[^;&|\n]*RECALL_|\bRECALL_[A-Z_]+=|\bexport\s+[^;&|\n]*RECALL_/) { print "changes the RECALL_ overrides\n"; exit }
    my $sweep = qr/^(cd|pushd|find|ls|du|tree|grep|egrep|rg|ag|fd|cat|head|tail|less|xargs|stat|file|wc|tar|zip|cp|rsync)$/;
    for my $seg (split /;|&&|\|\||\||&|\n/, $text) {
      my @t = grep { $_ ne "" } split /[\s"'"'"'`=:(),<>]+/, $seg;
      shift @t while @t && $t[0] =~ /^(env|sudo|command|time|nohup|-\S*)$/;
      my $cmd = @t ? $t[0] : "";
      for my $i (0 .. $#t) {
        my $t = $t[$i];
        next unless $t =~ m{^(~|\$\{?(HOME|PWD|CLAUDE_PROJECT_DIR)\}?|\.\.?)(/|$)} || $t =~ m{/} || $t =~ m{(^|/)\.(claude|codex)([/._-]|$)};
        next if $t =~ m{^/+$} && $cmd !~ $sweep && $ENV{TOOL} =~ /^(Bash|Agent|Task)$/;
        my $r = resolve($t, $cwd); next unless defined $r;
        my @b; for (split m{/}, $r) { last if /[*?\[{]/; push @b, $_ } my $base = norm(join("/", @b));
        if (!inside($r) && (within($base, $home) || within($home, $base))) { print "reaches the home directory ($t)\n"; exit }
        if (!inside($r) && $r =~ m{/\.(claude|codex)([/._-]|$)}) { print "names $t\n"; exit }
        $cwd = $r if $i == 1 && $cmd =~ /^(cd|pushd)$/;
      }
    }')
if [ -z "$reason" ] && [ -z "${GUARD_REPLAY:-}" ] && printf '%s' "$input" | jq -e '.tool_input.command // "" | test("sessions\\.sh")' >/dev/null; then
  for v in RECALL_CLAUDE_PROJECTS RECALL_CODEX_SESSIONS; do
    d=${!v:-}
    case "$d" in "$work"/*|"${work#/private}"/*) ;; *) reason="sessions.sh would read real chats: $v is '${d}'"; break ;; esac
  done
fi
log=$proj/.claude/eval-guard.log
if [ -n "$reason" ]; then
  [ -n "${GUARD_REPLAY:-}" ] || echo "BLOCK $tool: $reason" >> "$log"
  echo "eval guard: this run may not read the user's real chat history ($reason)" >&2
  exit 2
fi
[ -n "${GUARD_REPLAY:-}" ] || echo "ALLOW $tool" >> "$log"
exit 0
