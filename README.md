# dotfiles

A macOS developer setup, managed with [chezmoi](https://www.chezmoi.io/) and a [Homebrew Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile).

One command on a fresh Mac installs Homebrew, every app and CLI tool, language runtimes (Node, Python) and puts all config files in place.

## Set up a new Mac

**Before you start**

1. Finish macOS setup and sign in to your Apple ID.
2. Open the **App Store** and sign in (App Store apps can't be installed otherwise).
3. **System Settings → Privacy & Security → App Management**: turn on **Terminal**. Quit and reopen Terminal.

**Install everything**

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --use-builtin-git=true mjurincic
```

Replace `mjurincic` with your GitHub username if you forked this repo.

- chezmoi first asks for your name, your personal GitHub email and public SSH key, and optionally a work email and key (press Enter at the work email to skip it). Public keys are in 1Password and at `github.com/<username>.keys`. For the email, use your GitHub noreply address (GitHub → Settings → Emails). Your answers are saved only on this Mac in `~/.config/chezmoi/chezmoi.toml`, not in the repo. To change them later: `chezmoi init --prompt`.
- You're asked for your Mac password at the start. Homebrew may ask once more for some apps; otherwise it runs unattended.
- It takes a while (Xcode alone is 20–40 minutes, with no progress shown in Terminal: watch Launchpad).
- If something fails, fix it and run `chezmoi apply -v` again. Anything already installed is skipped.

**After the install**

1. Open a new terminal window (or run `exec zsh`).
2. Open **1Password**, sign in, then in **Settings → Developer** turn on:
   - **Use the SSH agent**
   - **Integrate with 1Password CLI**
3. Test GitHub SSH for both accounts:
   ```sh
   ssh -T -i ~/.ssh/github_personal.pub -o IdentitiesOnly=yes git@github.com
   ssh -T -i ~/.ssh/github_work.pub -o IdentitiesOnly=yes git@github.com
   ```
4. Commits are signed with your SSH keys through 1Password. Add each public key to GitHub a second time as a **Signing Key** (GitHub → Settings → SSH and GPG keys → New SSH key → Key type: Signing Key), on both accounts, so commits show as Verified.
5. Open these apps once to sign in or activate them (licenses are in 1Password):
   WebStorm (JetBrains account), CleanShot X, Bartender, OrbStack, Raycast, Slack, Figma, Claude, SwiftBar, Little Snitch (approve its network extension when macOS asks).
6. `mkdir -p ~/work`: work repos go here (see Git below).

## What's in here

| File | Becomes / does |
|---|---|
| `Brewfile` | List of CLI tools (`brew`), apps (`cask`), App Store apps (`mas`) and VS Code extensions (`vscode`). Not copied to `~`. |
| `run_before_00-0-sudo-keepalive.sh` | Asks for the password once and keeps sudo alive while chezmoi runs. Nothing is stored. |
| `run_once_before_00-install-homebrew.sh` | Installs Homebrew if it's missing. |
| `run_onchange_after_10-brew-bundle.sh.tmpl` | Runs `brew bundle` whenever the Brewfile changes. |
| `run_onchange_after_20-mise-install.sh.tmpl` | Runs `mise install` whenever the mise config changes. |
| `dot_zshrc` | `~/.zshrc`: Homebrew, mise, starship prompt, zoxide, fzf, aliases, `ws` (open in WebStorm). |
| `dot_config/mise/config.toml` | `~/.config/mise/config.toml`: global Node, Python, pnpm and npm tools. |
| `dot_config/git/ignore` | Global gitignore for every repo: `.DS_Store`, `.idea/`, local `.vscode` files, `.env` files (but not `.env.example`), logs. |
| `dot_config/ghostty/config` | Ghostty: JetBrains Mono Nerd Font 14, Catppuccin light/dark following macOS, bar cursor, copy on select, restores windows, drop-down terminal on ⌥Space. Option stays Option (Norwegian keys). |
| `dot_config/starship.toml` | Starship prompt: folder, git, Node/Python version in projects, time for commands over 2 s; no cloud noise. |
| `dot_gitconfig.tmpl` | `~/.gitconfig`: personal identity and key (default). |
| `.chezmoi.toml.tmpl` | Asks for your name, emails and public SSH keys once at `chezmoi init`, so nothing personal is in this repo. |
| `dot_gitconfig-work.tmpl` | `~/.gitconfig-work`: work identity and key, used for repos under `~/work/`. |
| `dot_config/swiftbar/` | Menu bar weather from yr.no (MET Norway) with a "what to wear" hint. Uses your location if allowed, otherwise Trondheim. |
| `run_once_after_30-swiftbar.sh` | Points SwiftBar at `~/.config/swiftbar` and starts it. |
| `run_onchange_after_40-chrome-extensions.sh` | Asks Chrome to install extensions (currently 1Password). Chrome asks you to enable each once. To add one, add its Web Store ID to the list. |
| `run_onchange_after_50-macos-defaults.sh` | macOS settings: natural scrolling off, tap to click, fast key repeat, no autocorrect or smart quotes, Finder shows extensions and path bar, auto-hiding Dock without recents, expanded save dialogs, shorter animations, no click-wallpaper-to-show-desktop, no gaps around tiled windows, ⌘Space freed for Raycast. Each line is commented; edit and re-run `chezmoi apply`. |
| `run_onchange_after_55-dock.sh` | A minimal Dock (with `dockutil`): Chrome, Ghostty, WebStorm, VS Code, Claude, Slack, and Downloads. Edit the list and re-run `chezmoi apply`. |
| `run_onchange_after_60-touchid-sudo.sh` | Touch ID for `sudo`, via `/etc/pam.d/sudo_local` (survives macOS updates). |
| `run_onchange_after_70-security.sh` | Checks FileVault, Gatekeeper, System Integrity Protection and Little Snitch, and warns if any is off. Changes nothing. |
| `private_dot_ssh/` | `~/.ssh/config` (1Password SSH agent), the two **public** GitHub keys, and `allowed_signers` for verifying signed commits (filled in from your answers at init). |

## How things work

**Runtimes (mise).** Node and Python come from [mise](https://mise.jdx.dev/), not Homebrew. Projects with `.nvmrc`, `.node-version` or `.python-version` switch automatically. To pin a version in a project: `mise use node@22`.

**Git and GitHub accounts.** Private SSH keys live only in 1Password. Git picks the account by folder:
- anywhere → personal account
- under `~/work/` → work account

Check which one a repo uses: `git config user.email`.

**Menu bar weather.** SwiftBar runs `~/.config/swiftbar/yr-weather.10m.sh` every 10 minutes. To use your exact location, run `CoreLocationCLI` once in Terminal and allow Location access; otherwise it shows Trondheim (change `FALLBACK_*` at the top of the script).

**Terminal shortcuts.** `code .` opens VS Code, `ws .` opens WebStorm, `lg` opens lazygit, `z <dir>` jumps to a folder you've visited, Ctrl-R searches history.

## Everyday use

| Task | Command |
|---|---|
| Add an app | `chezmoi cd`, add a line to `Brewfile`, then `chezmoi apply` |
| Find an app's name | `brew search <name>` or `mas search <name>` |
| Edit a config file | `chezmoi edit ~/.zshrc`, then `chezmoi apply` |
| Start tracking a new file | `chezmoi add ~/.some-config` |
| Preview changes | `chezmoi diff` |
| Save to GitHub | `chezmoi git add .` then `chezmoi git -- commit -m "…"` then `chezmoi git push` |
| Pull changes on another Mac | `chezmoi update` |
| Remove apps not in the Brewfile | `brew bundle cleanup --file="$(chezmoi source-path)/Brewfile"` (add `--force` to actually remove) |

## Never commit

Private keys, tokens, passwords or license keys. This repo is public. Secrets belong in 1Password.
