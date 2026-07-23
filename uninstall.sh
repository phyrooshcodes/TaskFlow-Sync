#!/usr/bin/env bash
# ─── TaskFlow Clean Uninstaller for Linux ─────────────────────────────────────
set -e

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
RED="\033[91m"
RESET="\033[0m"

echo -e "${RED}${BOLD}🗑️ TaskFlow Linux Uninstaller${RESET}\n"

# 1. Stop and disable systemd backup daemon
echo -e "${BLUE}[*] Stopping background backup timer...${RESET}"
systemctl --user stop taskflow-backup.timer 2>/dev/null || true
systemctl --user disable taskflow-backup.timer 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/taskflow-backup.service" "$HOME/.config/systemd/user/taskflow-backup.timer"
systemctl --user daemon-reload || true

# 2. Remove tf-sync CLI tool
echo -e "${BLUE}[*] Removing tf-sync CLI tool...${RESET}"
rm -f "$HOME/.local/bin/tf-sync"

# 3. Remove Symlinks
if [ -L "$HOME/.local/state/quickshell/user/todo.json" ]; then
    rm -f "$HOME/.local/state/quickshell/user/todo.json"
fi

# 4. Optional removal of task data
read -p "Do you also want to remove your local TaskFlow-Sync git repository (~/TaskFlow-Sync)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/TaskFlow-Sync"
    echo -e "${GREEN}✓ Removed ~/TaskFlow-Sync${RESET}"
else
    echo -e "${GREEN}✓ Preserved ~/TaskFlow-Sync repository to protect your task history.${RESET}"
fi

echo -e "\n${GREEN}${BOLD}✓ TaskFlow has been cleanly uninstalled.${RESET}\n"
