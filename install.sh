#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backup_root="${HOME}/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
dry_run=0
no_backup=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --no-backup)
      no_backup=1
      shift
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 1
      ;;
  esac
done

log() {
  printf '==> %s\n' "$1"
}

backup_file() {
  local target="$1"

  if [[ "$no_backup" -eq 1 || ! -e "$target" ]]; then
    return
  fi

  local backup_path="${backup_root}${target}"
  if [[ "$dry_run" -eq 1 ]]; then
    printf '[dry-run] backup: %s -> %s\n' "$target" "$backup_path"
    return
  fi

  mkdir -p "$(dirname "$backup_path")"
  cp -a "$target" "$backup_path"
}

install_file() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    printf 'skip missing source: %s\n' "$source" >&2
    return
  fi

  backup_file "$target"

  if [[ "$dry_run" -eq 1 ]]; then
    printf '[dry-run] copy: %s -> %s\n' "$source" "$target"
    return
  fi

  mkdir -p "$(dirname "$target")"
  cp -f "$source" "$target"
  printf 'installed: %s\n' "$target"
}

log "Install Linux/WSL dotfiles from ${repo_root}"
install_file "${repo_root}/wsl/.zshrc" "${HOME}/.zshrc"
log "Done"
