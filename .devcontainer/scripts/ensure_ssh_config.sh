#!/usr/bin/env bash
set -euo pipefail

SSH_DIR="$HOME/.ssh"
CONFIG_FILE="$SSH_DIR/config"
KNOWN_HOSTS="$SSH_DIR/known_hosts"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

grep -q "Host github.com" "$CONFIG_FILE" 2>/dev/null || {
  cat >> "$CONFIG_FILE" <<'EOF'
# Added by devcontainer postCreateCommand for persistent GitHub SSH handling
Host github.com
    StrictHostKeyChecking accept-new
    UserKnownHostsFile ~/.ssh/known_hosts
EOF
}

# Refresh github.com keys (avoid duplicates by removing existing lines first)
if [ -f "$KNOWN_HOSTS" ]; then
  grep -v 'github.com' "$KNOWN_HOSTS" > "$KNOWN_HOSTS.tmp" || true
  mv "$KNOWN_HOSTS.tmp" "$KNOWN_HOSTS"
fi

ssh-keyscan github.com >> "$KNOWN_HOSTS" 2>/dev/null || echo "[warn] ssh-keyscan failed"
chmod 600 "$CONFIG_FILE"
chmod 600 "$KNOWN_HOSTS"

echo "[info] SSH config for github.com ensured (accept-new host key policy)."
