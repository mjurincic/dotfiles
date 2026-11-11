#!/bin/bash
# Ask Chrome to install these extensions (it prompts once to enable each).
# Uses Chrome's machine-wide folder in /Library, because macOS blocks writes into
# ~/Library/Application Support/Google/Chrome from other apps. Needs sudo (chezmoi already asked).
# Extensions: aeblfdkhhhdcdjpifhhbdiojplfjncoa = 1Password
set -e
DIR="/Library/Application Support/Google/Chrome/External Extensions"
sudo mkdir -p "$DIR"
for id in aeblfdkhhhdcdjpifhhbdiojplfjncoa; do
  printf '{\n  "external_update_url": "https://clients2.google.com/service/update2/crx"\n}\n' | sudo tee "$DIR/$id.json" >/dev/null
  sudo chmod 644 "$DIR/$id.json"
done
