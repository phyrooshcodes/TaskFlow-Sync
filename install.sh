#!/usr/bin/env bash
# ─── TaskFlow Smart One-Shot Installer for Linux ─────────────────────────────
set -e

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${BLUE}${BOLD}⚡ TaskFlow One-Shot Linux Installer${RESET}\n"

# 1. Detect Distribution
DISTRO="Unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$NAME
fi
echo -e "${GREEN}✓ Detected OS:${RESET} $DISTRO"

# 2. Verify dependencies
for cmd in git curl python3; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${YELLOW}⚠️ Command '$cmd' not found. Installing dependencies may be required.${RESET}"
    fi
done

# 3. Setup Target Directories
QUICKSHELL_DIR="$HOME/.config/quickshell/ii"
STATE_DIR="$HOME/.local/state/quickshell/user"
REPO_DIR="$HOME/TaskFlow-Sync"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$QUICKSHELL_DIR/services"
mkdir -p "$QUICKSHELL_DIR/modules/ii/background/widgets/todo"
mkdir -p "$STATE_DIR"
mkdir -p "$REPO_DIR"
mkdir -p "$BIN_DIR"

# 4. Copy QML Files
if [ -d "linux/quickshell" ]; then
    cp -r linux/quickshell/services/* "$QUICKSHELL_DIR/services/" 2>/dev/null || true
    cp -r linux/quickshell/widgets/* "$QUICKSHELL_DIR/modules/ii/background/widgets/todo/" 2>/dev/null || true
fi

# 5. Install CLI tool tf-sync
if [ -f "bin/tf-sync" ]; then
    cp bin/tf-sync "$BIN_DIR/tf-sync"
    chmod +x "$BIN_DIR/tf-sync"
    echo -e "${GREEN}✓ Installed 'tf-sync' CLI to $BIN_DIR/tf-sync${RESET}"
fi

# 6. Initialize Git Repository & Symlink
cd "$REPO_DIR"
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# Link todo.json
if [ -f "$STATE_DIR/todo.json" ] && [ ! -L "$STATE_DIR/todo.json" ]; then
    cp "$STATE_DIR/todo.json" "$REPO_DIR/todo.json" 2>/dev/null || true
    rm -f "$STATE_DIR/todo.json"
fi
[ ! -f "$REPO_DIR/todo.json" ] && echo '{"lists":[],"currentListId":"","tasks":{}}' > "$REPO_DIR/todo.json"
ln -sf "$REPO_DIR/todo.json" "$STATE_DIR/todo.json"

# 7. Install Backup Script
cat << 'EOF' > "$REPO_DIR/backup.sh"
#!/usr/bin/env bash
REPO_DIR="$HOME/TaskFlow-Sync"
cd "$REPO_DIR" || exit 1

if [[ -f todo.json ]] && [[ -n $(git status --porcelain todo.json) ]]; then
    git add todo.json
    git commit -m "Auto-backup $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main >> "$REPO_DIR/backup.log" 2>&1
fi
EOF
chmod +x "$REPO_DIR/backup.sh"

# 8. Setup Systemd Timer
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

cat << EOF > "$SYSTEMD_USER_DIR/taskflow-backup.service"
[Unit]
Description=Auto-backup TaskFlow tasks to GitHub

[Service]
Type=oneshot
ExecStart=/bin/bash $REPO_DIR/backup.sh
EOF

cat << EOF > "$SYSTEMD_USER_DIR/taskflow-backup.timer"
[Unit]
Description=Periodically backup TaskFlow tasks to GitHub

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload || true
systemctl --user enable --now taskflow-backup.timer || true

# 9. Clean up Windows files on request
read -p "Do you want to clean up Windows-specific files (install.bat, windows/)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf install.bat windows/ 2>/dev/null || true
    echo -e "${GREEN}✓ Cleaned up Windows files.${RESET}"
fi

echo -e "\n${GREEN}${BOLD}🎉 TaskFlow installation complete!${RESET}"
echo -e "Type ${CYAN}tf-sync${RESET} in your terminal anytime to configure your private backup repository or manage settings.\n"
