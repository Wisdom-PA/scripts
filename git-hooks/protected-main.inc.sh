# Shared checks for Wisdom main-branch protection (sourced by hook scripts).
# One-time bypass: GIT_MAIN_PROTECTION=0
# Git bypass (emergencies only): --no-verify

wisdom_protection_enabled() {
  [ "${GIT_MAIN_PROTECTION:-1}" != "0" ]
}

wisdom_current_branch() {
  git symbolic-ref --short HEAD 2>/dev/null
}

wisdom_abort_if_protected_commit() {
  wisdom_protection_enabled || return 0
  # Allow the very first commit (empty repo); block further commits on main/master.
  if ! git rev-parse -q --verify HEAD >/dev/null 2>&1; then
    return 0
  fi
  branch=$(wisdom_current_branch)
  [ -z "$branch" ] && return 0
  case "$branch" in
  main | master)
    printf '%s\n' "Wisdom: commits and merge commits on '${branch}' are blocked. Use a feature branch and a PR into main." >&2
    exit 1
    ;;
  esac
}
