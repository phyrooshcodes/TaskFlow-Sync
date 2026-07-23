# TaskFlow ⚡

> **A sleek, modern desktop widget that stores your data in your OWN GitHub Repository.**
> *No third-party servers. No proprietary databases. 100% privacy, full version control, and works seamlessly offline.*

---

## 🌟 Why TaskFlow?

Most task apps lock your data in proprietary clouds or require complex server setups. **TaskFlow** takes a different approach:
- **Your Own GitHub Repo as the Backend:** Every task added, completed, or reordered is committed and pushed directly to your personal GitHub repository.
- **100% Offline-First:** Works offline without delay. Changes are queued locally and pushed when connectivity returns.
- **Apple-Inspired Design:** Features squircle symmetric rounding, smooth animations, dark mode, subtasks, due dates, and drag-and-drop reordering.
- **Cross-Platform:** Native Quickshell widget for Linux (Hyprland, Sway, KDE, GNOME) and Rainmeter skin for Windows.

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
> 1. Detects your Linux distribution and verifies dependencies (`git`, `quickshell`).
> 2. Sets up your local task state directory.
> 3. Configures SSH keys for GitHub if needed.
> 4. Enables a background `systemd` user timer (`taskflow-backup.timer`) for silent auto-backups.
> 5. Prompts to clean up Windows-specific files.

---

### 🪟 Windows (Rainmeter)

1. Ensure **[Rainmeter](https://www.rainmeter.net/)** and **[Git for Windows](https://git-scm.com/)** are installed.
2. Clone or extract this repository to your computer.
3. Right-click `install.bat` and select **Run as Administrator**.

> **What `install.bat` does automatically:**
> 1. Copies the `TaskFlow` skin into `%USERPROFILE%\Documents\Rainmeter\Skins\TaskFlow`.
> 2. Configures a PowerShell background script (`backup.ps1`) for automatic GitHub commits.
> 3. Refreshes Rainmeter to display the TaskFlow widget.
> 4. Prompts to clean up Linux-specific files.

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
               │    Local Git Repository   │
               └─────────────┬─────────────┘
                             │ Auto-Push (Background Daemon)
                             ▼
               ┌───────────────────────────┐
               │   Your GitHub Repository  │
               └───────────────────────────┘
```

---

## 📜 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<p align="center">Made with ❤️ for the Open Source Community</p>
