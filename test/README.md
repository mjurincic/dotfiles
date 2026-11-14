# Testing a fresh install

Two ways to check that `chezmoi init --apply` still sets up a brand-new Mac:

| | Where | When to use |
|---|---|---|
| `test/vm-test.sh` | A throwaway macOS VM on this Mac (Tart) | Before pushing a bigger change. Tests uncommitted changes too, and you can watch it or log in afterwards. |
| `.github/workflows/fresh-install.yml` | A GitHub-hosted Mac | Runs on every pull request and push to `main`, or by hand from the Actions tab. |

Both run `test/smoke.sh` at the end: every file matches, a second `chezmoi apply` is clean, every Brewfile formula and cask is installed, a login zsh starts, Node/Python/pnpm come from mise, and a few macOS settings stuck.

## Local VM with Tart

[Tart](https://tart.run) runs macOS VMs on Apple Silicon with Apple's Virtualization framework. It's free for personal use.

**One-time setup**

```sh
brew trust openai/tools          # Tart's Homebrew tap (it moved from cirruslabs/cli)
brew install openai/tools/tart
```

**Run it**

```sh
test/vm-test.sh                  # this folder as it is now, uncommitted changes included
test/vm-test.sh --branch main    # a branch on GitHub, exactly like the README one-liner
test/vm-test.sh --keep           # leave the VM running afterwards; log in with ssh admin@<ip>, password admin
test/vm-test.sh --headless       # no VM window
```

- The first run downloads the macOS 27 image (about 30 GB, kept in `~/.tart`). Later runs start in about a minute and only spend time on the install itself.
- The VM is deleted at the end unless you pass `--keep`. The log is saved to `$TMPDIR/dotfiles-vm-test.log`.
- To free the disk space: `tart prune --entries=caches` (the image) and `tart list` / `tart delete <name>` (VMs).
- Another macOS version: `DOTFILES_VM_IMAGE=ghcr.io/cirruslabs/macos-tahoe-vanilla:latest test/vm-test.sh`.

## What a test run does differently

Test runs set `CHEZMOI_CI=1` (GitHub Actions also sets `CI=true`). `.chezmoi.toml.tmpl` then stores `ci = true` and:

| Step | On your Mac | In a test run |
|---|---|---|
| Name, emails, SSH keys at `chezmoi init` | Asked once | Placeholder values (`test@example.com`, a dummy key), with the work account on so both git setups are tested |
| Mac password (`run_before_00-0-sudo-keepalive.sh`) | Asked once | Not asked: the VM image and GitHub's Macs have passwordless sudo |
| App Store apps (`mas` lines in the Brewfile) | Installed | Skipped: they need a signed-in Apple ID |
| Touch ID for sudo | Turned on | The PAM line is still written, but a VM has no Touch ID, so sudo uses the password (or no password) as before |
| Security checks | Warns if anything is off | Warns that FileVault and Gatekeeper are off; that's expected in a VM and doesn't fail the run |
| Little Snitch, Chrome extensions | You approve them | Installed, but nobody approves the network extension or enables the Chrome extension |

To skip more in a test run, put `{{ if index . "ci" }}` ... `{{ end }}` in a `.tmpl` script (as `run_onchange_after_10-brew-bundle.sh.tmpl` does), or set Homebrew's skip lists, such as `HOMEBREW_BUNDLE_CASK_SKIP="figma slack"`.
