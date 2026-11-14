#!/bin/bash
# shellcheck disable=SC2016  # single-quoted commands are meant to expand later, inside zsh or the VM
# Test these dotfiles on a brand-new Mac: a throwaway macOS VM made with Tart.
# Boots a clean VM, runs `chezmoi init --apply` in it, then test/smoke.sh. See test/README.md.
#
#   test/vm-test.sh                 test this folder as it is now, uncommitted changes included
#   test/vm-test.sh --branch main   test a branch on GitHub instead, exactly like the README one-liner
#   test/vm-test.sh --keep          leave the VM running afterwards, to look around
#   test/vm-test.sh --headless      no VM window
#
# First run downloads the macOS image (about 30 GB) to ~/.tart; later runs reuse it.
set -euo pipefail

IMAGE="${DOTFILES_VM_IMAGE:-ghcr.io/cirruslabs/macos-golden-gate-vanilla:latest}"   # macOS 27, user admin / admin
VM="${DOTFILES_VM_NAME:-dotfiles-test}"
GITHUB_USER="${DOTFILES_GITHUB_USER:-mjurincic}"
SRC="$(cd "$(dirname "$0")/.." && pwd)"
BRANCH="" KEEP=0 GRAPHICS=1 IP=""

while [ $# -gt 0 ]; do
  case "$1" in
    --branch) BRANCH="$2"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    --headless) GRAPHICS=0; shift ;;
    -h|--help) sed -n '3,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1 (try --help)"; exit 2 ;;
  esac
done

command -v tart >/dev/null || { echo "Tart is missing: brew install openai/tools/tart (see test/README.md)"; exit 1; }

# Log in with the image's password without sshpass, and ignore ~/.ssh/config (1Password agent).
ASKPASS="$(mktemp -t vm-askpass)"
printf '#!/bin/sh\necho admin\n' > "$ASKPASS"; chmod 700 "$ASKPASS"
vm_ssh() {
  SSH_ASKPASS="$ASKPASS" SSH_ASKPASS_REQUIRE=force DISPLAY=none \
    ssh -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
        -o PubkeyAuthentication=no -o ConnectTimeout=5 "admin@$IP" "$@"
}

TART_PID=""
cleanup() {
  rm -f "$ASKPASS"
  if [ "$KEEP" = 1 ] && [ -n "$TART_PID" ]; then
    echo "VM '$VM' is still running. Log in with: ssh admin@$IP (password: admin)"
    echo "Delete it when done: tart stop $VM; tart delete $VM"
    return
  fi
  [ -n "$TART_PID" ] && { tart stop "$VM" >/dev/null 2>&1 || true; wait "$TART_PID" 2>/dev/null || true; }
  tart delete "$VM" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Fresh VM '$VM' from $IMAGE"
tart delete "$VM" >/dev/null 2>&1 || true
tart clone "$IMAGE" "$VM"   # pulls the image the first time
tart set "$VM" --cpu 4 --memory 8192

run_args=(--dir="dotfiles:$SRC:ro")
[ "$GRAPHICS" = 0 ] && run_args+=(--no-graphics)
tart run "$VM" "${run_args[@]}" >/dev/null 2>&1 &
TART_PID=$!

IP="$(tart ip "$VM" --wait 180)"
echo "==> VM is at $IP, waiting for SSH"
for _ in $(seq 60); do vm_ssh true 2>/dev/null && break; sleep 5; done
vm_ssh true

# What a new Mac runs, plus CHEZMOI_CI=1 so chezmoi asks nothing and skips App Store apps.
if [ -n "$BRANCH" ]; then
  echo "==> chezmoi init --apply from github.com/$GITHUB_USER/dotfiles, branch $BRANCH"
  INSTALL="init --apply --use-builtin-git=true --branch '$BRANCH' '$GITHUB_USER'"
else
  echo "==> chezmoi init --apply from this folder ($SRC)"
  vm_ssh "mkdir -p ~/.local/share/chezmoi && rsync -a --exclude .git --exclude .claude '/Volumes/My Shared Files/dotfiles/' ~/.local/share/chezmoi/"
  INSTALL="init --apply --use-builtin-git=true"
fi

LOG="${TMPDIR:-/tmp}/dotfiles-vm-test.log"
status=0
vm_ssh "export CHEZMOI_CI=1; sh -c \"\$(curl -fsLS get.chezmoi.io)\" -- -b \"\$HOME/.local/bin\" $INSTALL" 2>&1 | tee "$LOG" || status=$?
if [ "$status" -ne 0 ]; then
  echo "chezmoi init --apply failed (exit $status). Full log: $LOG"
  exit "$status"
fi

echo "==> Smoke test"
vm_ssh 'bash "$HOME/.local/share/chezmoi/test/smoke.sh"' 2>&1 | tee -a "$LOG"
echo "Full log: $LOG"
