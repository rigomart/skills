# On main, no glossary yet. A group of tasks is a board in the CLI, a Bucket in
# the code and a folder in the README; a finished task is done in the CLI and
# resolved in the code; "archive" is both hiding done tasks and the export file.
# The first time the agent stops (to ask about the collisions, or done), the user
# says to go with its defaults.
source "$EVAL_HERE/glossary/lib.sh"
make_boards_repo
followup_hook "New message from the user: Go with your defaults."
