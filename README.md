# TaskFlow ⚡

> **A sleek, modern desktop widget that stores your data in your OWN private GitHub Repository.**
> *No third-party servers. No proprietary databases. 100% privacy, full version control, and works seamlessly offline.*

---

## 🌟 Why TaskFlow?

Most task apps lock your data in proprietary clouds or require complex server setups. **TaskFlow** takes a different approach:
- **Your Own Private Repo as the Backend:** Keep the source code public, but store your actual tasks in your private repository or secret Gist!
- **`tf-sync` CLI Tool:** Run `tf-sync` in your terminal to easily configure your private backup repository, view SSH keys, trigger instant pushes, or change backup intervals.
- **100% Offline-First:** Works offline without delay. Changes are queued locally and pushed when connectivity returns.
- **Apple-Inspired Design:** Features squircle symmetric rounding, smooth animations, dark mode, subtasks, due dates, and drag-and-drop reordering.
- **Cross-Platform:** Native Quickshell widget for Linux (Hyprland, Sway, KDE, GNOME) and Rainmeter skin for Windows.

---

## 💻 `tf-sync` Terminal Configuration Tool

TaskFlow comes with a CLI tool named `tf-sync` to manage your backup target and settings:

```bash
$ tf-sync
```

```text
 ⚡ TaskFlow Configuration & Backup CLI (tf-sync)
 ──────────────────────────────────────────────────
 [1] ⚙️ Configure Target Backup Repository
 [2] 🔑 View / Copy Public SSH Key
 [3] 🚀 Run Backup Now (Push)
 [4] 📊 Check Backup Status & History
 [5] ⏱️ Change Auto-Backup Interval
 [6] ❌ Exit
```

- **Instant Push:** Run `tf-sync push` anywhere in your terminal.
- **View History:** Run `tf-sync status` to view git commit history & systemd timer health.

---

## 📸 Features

- ✨ **Symmetric Apple-Style Card UI:** Smooth 20px rounded corners with Material 3 styling.
- 🎯 **Multiple Task Lists:** Switch seamlessly between work, personal, and project lists.
- 📅 **Due Dates & Overdue Warnings:** Visual tags for upcoming and overdue tasks.
- 🖐️ **Drag & Drop Reordering:** Intuitive handle for reordering items visually.
- 🗑️ **Multi-Select & Bulk Actions:** Select multiple tasks to complete or delete in bulk.
- 🔒 **Git Version Control:** View your entire task history or undo accidental deletions using Git commit logs.

---

## 🚀 One-Shot Installation

### 🐧 Linux (Arch, CachyOS, Ubuntu, Fedora, Debian, openSUSE)

Clone this repository and run the smart installer:

```bash
git clone https://github.com/phyrooshcodes/TaskFlow-Sync.git TaskFlow
cd TaskFlow
chmod +x install.sh
./install.sh
```

> **What `install.sh` does automatically:**
> 1. Detects your Linux distribution and verifies dependencies (`git`, `quickshell`, `python3`).
> 2. Installs the `tf-sync` CLI executable to `~/.local/bin/tf-sync`.
> 3. Sets up your local task state directory and symlinks `todo.json`.
> 4. Enables a background `systemd` user timer (`taskflow-backup.timer`) for silent auto-backups.
> 5. Prompts to clean up Windows-specific files.

---

### 🪟 Windows (Rainmeter)

1. Ensure **[Rainmeter](https://www.rainmeter.net/)** and **[Git for Windows](https://git-scm.com/)** are installed.
2. Clone or extract this repository to your computer.
3. Right-click `install.bat` and select **Run as Administrator**.

---

## ⚙️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    TaskFlow Widget                      │
│            (Linux Quickshell / Windows Rainmeter)       │
└────────────────────────────┬────────────────────────────┘
                             │ Local JSON write
                             ▼
               ┌───────────────────────────┐
               │   ~/.local/state/todo.json│
               └─────────────┬─────────────┘
                             │ Symlink
                             ▼
               ┌───────────────────────────┐
               │  tf-sync / Backup Script  │
               └─────────────┬─────────────┘
                             │ Auto-Push (Background Daemon)
                             ▼
               ┌───────────────────────────┐
               │ Your Private GitHub Repo  │
               └───────────────────────────┘
```

---

## 📜 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<p align="center">Made with ❤️ for the Open Source Community</p>
