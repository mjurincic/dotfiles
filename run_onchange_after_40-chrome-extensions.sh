#!/bin/bash
# Ask Chrome to install these extensions (it prompts once to enable each).
# A script instead of managed files, so chezmoi never touches the permissions of Chrome's folders.
# Extensions: aeblfdkhhhdcdjpifhhbdiojplfjncoa = 1Password
set -e
DIR="$HOME/Library/Application Support/Google/Chrome/External Extensions"
mkdir -p "$DIR"
for id in aeblfdkhhhdcdjpifhhbdiojplfjncoa; do
  printf '{\n  "external_update_url": "https://clients2.google.com/service/update2/crx"\n}\n' > "$DIR/$id.json"
done
