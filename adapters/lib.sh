# Shared helpers for noodle backlog adapters. Sourced, not executed.
# Settings live in adapters/backlog.env (written by /noodle-init); env vars override them.

ADAPTER_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
[ -f "$ADAPTER_DIR/backlog.env" ] && . "$ADAPTER_DIR/backlog.env"

# Plans are linked by directory name, so any issue source works the same way:
#   brain/plans/<item-id>-<slug>/overview.md  ->  "plan" field on item <item-id>
plan_for_id() {
  for f in brain/plans/"$1"-*/overview.md; do
    [ -f "$f" ] && { printf '%s' "$f"; return 0; }
  done
  return 0
}

# Read NDJSON items on stdin; add "plan" to each item that has a plan directory.
attach_plans() {
  while IFS= read -r item || [ -n "$item" ]; do
    [ -n "$item" ] || continue
    id=$(printf '%s' "$item" | jq -r '.id')
    plan=$(plan_for_id "$id")
    if [ -n "$plan" ]; then
      printf '%s\n' "$item" | jq -c --arg p "$plan" '. + {plan: $p}'
    else
      printf '%s\n' "$item"
    fi
  done
}

# Parse the origin remote into host / owner / repo (works for https and ssh forms).
remote_parts() {
  url=$(git remote get-url "${REMOTE:-origin}" 2>/dev/null) || return 1
  url=${url%.git}
  case "$url" in
    *://*) rest=${url#*://}; rest=${rest#*@} ;;
    *@*:*) rest=${url#*@}; rest=$(printf '%s' "$rest" | sed 's#:#/#') ;;
    *) return 1 ;;
  esac
  REMOTE_HOST=${rest%%/*}
  path=${rest#*/}
  REMOTE_OWNER=${path%%/*}
  REMOTE_REPO=${path#*/}
}
