#!/bin/bash
# shellcheck disable=SC2016  # single-quoted commands are meant to expand later, inside zsh or the VM
# Checks a Mac right after `chezmoi init --apply` (run inside the test VM or on a GitHub Actions runner).
# Exits non-zero if anything is missing. See test/README.md.
set -u
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"   # where get.chezmoi.io puts chezmoi before Homebrew's copy exists
SRC="$(chezmoi source-path)"
failures=0
pass() { printf '\033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '\033[31m✗\033[0m %s\n' "$1"; failures=$((failures + 1)); }
check() { local what="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$what"; else fail "$what"; fi; }

echo "== Files =="
check "every managed file matches the repo (chezmoi verify)" chezmoi verify --exclude=scripts
check "a second chezmoi apply runs cleanly" chezmoi apply --no-tty
for f in ~/.zshrc ~/.gitconfig ~/.config/mise/config.toml ~/.config/starship.toml ~/.config/ghostty/config ~/.ssh/config; do
  check "$f exists" test -f "$f"
done

echo "== Homebrew =="
installed_formulae="$(brew list -1 --formula)"
installed_casks="$(brew list -1 --cask)"
for f in $(brew bundle list --file="$SRC/Brewfile" --formula); do
  check "brew $f" grep -qx "${f##*/}" <<<"$installed_formulae"
done
for c in $(brew bundle list --file="$SRC/Brewfile" --cask); do
  check "cask $c" grep -qx "${c##*/}" <<<"$installed_casks"
done

echo "== Shell and runtimes (a fresh login zsh) =="
check "zsh starts without errors" zsh -lic 'exit 0'
check "starship" zsh -lic 'starship --version'
check "mise node" zsh -lic 'node --version'
check "mise python" zsh -lic 'python --version'
check "mise pnpm" zsh -lic 'pnpm --version'
check "git has a user.email" zsh -lic 'test -n "$(git config user.email)"'

echo "== macOS settings =="
check "key repeat set" test "$(defaults read NSGlobalDomain KeyRepeat 2>/dev/null)" = 2
check "Finder path bar on" test "$(defaults read com.apple.finder ShowPathbar 2>/dev/null)" = 1
check "SwiftBar plugin folder set" defaults read com.ameba.SwiftBar PluginDirectory

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; fi
exit "$failures"
