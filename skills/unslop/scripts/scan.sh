#!/usr/bin/env bash
# Flag the mechanical tells of AI writing in prose: em dashes, curly quotes, AI vocabulary,
# filler, chat phrases, title-case headings, inline-header bullets, decorative emoji.
# Usage: scan.sh <file>... (or - for stdin)
# Skips fenced code blocks and inline code spans. Prints one line per hit:
#   <file>:<line>: <rule>: <matched text>
# Exits 1 if anything was flagged, 0 if clean, 2 on bad input.

set -u

if [ $# -eq 0 ]; then
  echo "usage: scan.sh <file>... (or - for stdin)" >&2
  exit 2
fi

for f in "$@"; do
  [ "$f" = - ] || [ -r "$f" ] || { echo "scan.sh: cannot read $f" >&2; exit 2; }
done

exec perl -CSD -Mutf8 -e '
use strict;
use warnings;

my @rules = (
  ["em dash, use a period or a comma", qr/\x{2014}/],
  ["dash between words, use a period or a comma", qr/(?<=\S)\s[\x{2013}-]{1,2}\s(?=\S)/],
  ["curly quote, use a straight quote", qr/[\x{2018}\x{2019}\x{201C}\x{201D}]/],
  ["AI vocabulary, use the plain word", qr/\b(?:delv(?:e|es|ing)|tapestry|testament|pivotal|crucial|intricate|interplay|underscor(?:e|es|ed|ing)|showcas(?:e|es|ed|ing)|foster(?:s|ed|ing)?|garner(?:s|ed)?|vibrant|seamless(?:ly)?|leverag(?:e|es|ed|ing)|utiliz(?:e|es|ed|ing|ation)|facilitat(?:e|es|ed|ing)|holistic|realm|embark(?:s|ed)?|elevat(?:e|es|ed|ing)|empower(?:s|ed|ing)?|unlock(?:s|ed|ing)?|game[- ]chang\w*|cutting[- ]edge|ever[- ](?:evolving|changing)|landscape|paradigm|synerg\w+|robust|streamlin(?:e|es|ed|ing)|navigat(?:e|es|ing) the|meticulous(?:ly)?|commendable|noteworthy|additionally|furthermore|moreover)\b/i],
  ["fancy \"is\", say is or has", qr/\b(?:serves as|stands as|acts as a testament|boasts)\b/i],
  ["filler, cut it", qr/\b(?:in order to|due to the fact that|it is important to (?:note|remember)|it\x{27}s (?:important|worth) (?:to note|noting)|it should be noted|worth noting|at the end of the day|when it comes to|plays? an? (?:crucial|key|vital|pivotal|important) role|a wide (?:range|array|variety) of|in today\x{27}s|needless to say)\b/i],
  ["\"not just X but Y\", state Y", qr/\bnot (?:just|only|merely)\b.{0,60}\bbut\b|\bit\x{27}s not (?:about )?\w[^.]{0,40}, it\x{27}s\b/i],
  ["stacked hedge, pick one or none", qr/\b(?:could|might|may) (?:potentially|possibly|perhaps)\b|\bperhaps\b.{0,20}\bmight\b/i],
  ["signposting, say the point", qr/\b(?:let\x{27}s dive|dive into|here\x{27}s the (?:thing|kicker|catch)|the key (?:insight|takeaway) is|in conclusion|in summary|to sum up)\b/i],
  ["chat phrase, delete it", qr/\b(?:I hope this helps|let me know if|feel free to|happy to help|great question|you\x{27}re absolutely right|certainly!|absolutely!|of course!)/i],
  ["inline-header bullet, write the line as prose", qr/^\s*(?:[-*+]|\d+\.)\s+\*\*[^*]+:\*\*|^\s*(?:[-*+]|\d+\.)\s+\*\*[^*]+\*\*:/],
  ["decorative emoji, remove it", qr/[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}\x{2B50}\x{2705}]/],
);

my $small = qr/^(?:a|an|and|as|at|but|by|for|in|of|on|or|the|to|vs\.?|with)$/;
my $hits = 0;

for my $file (@ARGV) {
  my $fh;
  if ($file eq "-") { $fh = \*STDIN } else { open($fh, "<", $file) or die "scan.sh: cannot read $file\n" }
  my $fenced = 0;
  my $n = 0;
  while (my $line = <$fh>) {
    $n++;
    chomp $line;
    if ($line =~ /^\s*(?:```|~~~)/) { $fenced = !$fenced; next }
    next if $fenced;
    $line =~ s/`[^`]*`//g;
    $line =~ s/\]\([^)]*\)/]/g;
    my $name = $file eq "-" ? "stdin" : $file;
    for my $r (@rules) {
      my ($rule, $re) = @$r;
      while ($line =~ /$re/g) {
        my $m = $&;
        $m =~ s/^\s+|\s+$//g;
        print "$name:$n: $rule: $m\n";
        $hits++;
        last if $rule =~ /^(?:inline-header|\"not just)/;
      }
    }
    if ($line =~ /^#{1,6}\s+(.+?)\s*#*\s*$/) {
      my @words = grep { /^[A-Za-z]/ } split /\s+/, $1;
      my @rest = @words[1 .. $#words];
      my @big = grep { !/$small/i && /^[A-Z][a-z]/ } @rest;
      my @low = grep { !/$small/i && /^[a-z]/ } @rest;
      if (@big >= 2 && !@low) {
        print "$name:$n: title-case heading, use sentence case: $1\n";
        $hits++;
      }
    }
  }
}
exit($hits ? 1 : 0);
' "$@"
