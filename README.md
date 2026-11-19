# QuickTerm

A simple, lightweight macOS terminal with top tabs and a left-hand command bookmark sidebar.

## Features
- **Top Tabs:** Open tabs with `+`, `⌘T`, or double-clicking the empty tab bar area; close with `⌘W` or `×`.
- **Command Sidebar (`⌘B` to toggle):**
  - Click `+` to save a command (automatically prefills the active tab's current directory).
  - Click a command row to edit or delete it (with confirmation).
  - Click the play button on a row to execute it in the active tab.
  - Drag to reorder, search when needed, and persisted divider width.
- **Terminal:** Blinking underline cursor, `⌘+` / `⌘-` font size adjustment.

## Build & Run
```bash
./scripts/build_app.sh
open dist/QuickTerm.app
```
