# DFHack Scripts – Project Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up a fully working local development environment for DFHack Lua scripts, linked to GitHub and integrated into the running DFHack installation via symlink.

**Architecture:** `F:\DF-Hack` is a git repository containing scripts and docs. A Windows directory symlink makes scripts visible to DFHack at `hack/scripts/heinrich/`. The repo is pushed to `github.com/hpg-uni/dfhack-scripts` as the remote.

**Tech Stack:** Git, GitHub CLI (`gh`), Windows symlinks (mklink), Lua (DFHack scripting API)

---

### Task 1: Initialize Local Git Repository

**Files:**
- Create: `F:\DF-Hack\.gitignore`
- Create: `F:\DF-Hack\README.md`
- Create: `F:\DF-Hack\CHANGELOG.md`
- Create: `F:\DF-Hack\scripts\.gitkeep`
- Create: `F:\DF-Hack\docs\.gitkeep`

- [ ] **Step 1: Initialize git repo**

```bash
cd F:/DF-Hack
git init
```

Expected output: `Initialized empty Git repository in F:/DF-Hack/.git/`

- [ ] **Step 2: Create .gitignore**

Create `F:\DF-Hack\.gitignore` with this content:

```
*.bak
*.tmp
Thumbs.db
```

- [ ] **Step 3: Create README.md**

Create `F:\DF-Hack\README.md` with this content:

```markdown
# dfhack-scripts

Personal DFHack Lua scripts by [hpg-uni](https://github.com/hpg-uni).

## Installation

1. Clone this repository somewhere on your system.
2. Create a symlink inside your DFHack scripts folder:

```
mklink /D "C:\Program Files (x86)\Steam\steamapps\common\Dwarf Fortress\hack\scripts\heinrich" "PATH_TO_THIS_REPO\scripts"
```

3. Scripts are then available in the DFHack console as `heinrich/<scriptname>`.

## Scripts

| Script | Description |
|--------|-------------|
| *(none yet)* | *(more coming)* |

## License

MIT
```

- [ ] **Step 4: Create CHANGELOG.md**

Create `F:\DF-Hack\CHANGELOG.md` with this content:

```markdown
# Changelog

## Unreleased

- Initial project setup
```

- [ ] **Step 5: Create placeholder files to track empty directories**

```bash
touch F:/DF-Hack/scripts/.gitkeep
touch F:/DF-Hack/docs/.gitkeep
```

- [ ] **Step 6: Stage and commit everything**

```bash
cd F:/DF-Hack
git add .
git commit -m "chore: initial project setup"
```

Expected: commit succeeds, showing added files.

---

### Task 2: Create GitHub Repository and Push

**Files:** No new files. Remote connection only.

- [ ] **Step 1: Check if GitHub CLI is available**

```bash
gh --version
```

If not installed, download from https://cli.github.com/ and install, then run:
```bash
gh auth login
```
Follow the interactive prompts to authenticate with your `hpg-uni` account.

- [ ] **Step 2: Create the GitHub repository**

```bash
gh repo create hpg-uni/dfhack-scripts --public --description "Personal DFHack Lua scripts" --source F:/DF-Hack --remote origin --push
```

Expected output: Repository URL printed, e.g. `https://github.com/hpg-uni/dfhack-scripts`

> **If that command fails**, do it in two steps:
> ```bash
> gh repo create hpg-uni/dfhack-scripts --public --description "Personal DFHack Lua scripts"
> cd F:/DF-Hack
> git remote add origin https://github.com/hpg-uni/dfhack-scripts.git
> git push -u origin main
> ```

- [ ] **Step 3: Verify remote is set correctly**

```bash
cd F:/DF-Hack
git remote -v
```

Expected output:
```
origin  https://github.com/hpg-uni/dfhack-scripts.git (fetch)
origin  https://github.com/hpg-uni/dfhack-scripts.git (push)
```

---

### Task 3: Create DFHack Symlink

This links `F:\DF-Hack\scripts\` into the DFHack installation so scripts are available in-game.

**Files:** No files created here – a Windows directory symlink is created.

- [ ] **Step 1: Open a terminal as Administrator**

The symlink command requires admin rights. Right-click on the Windows Terminal or Command Prompt and choose "Run as Administrator".

- [ ] **Step 2: Create the symlink**

Run this in the Administrator terminal (CMD, not PowerShell or Git Bash):

```cmd
mklink /D "C:\Program Files (x86)\Steam\steamapps\common\Dwarf Fortress\hack\scripts\heinrich" "F:\DF-Hack\scripts"
```

Expected output:
```
symbolic link created for C:\Program Files (x86)\Steam\steamapps\common\Dwarf Fortress\hack\scripts\heinrich <<===>> F:\DF-Hack\scripts
```

- [ ] **Step 3: Verify the symlink exists**

```cmd
dir "C:\Program Files (x86)\Steam\steamapps\common\Dwarf Fortress\hack\scripts\" | findstr heinrich
```

Expected: a line showing `<SYMLINKD>` and `heinrich`.

---

### Task 4: Verify with a Hello-World Test Script

Write a minimal script to confirm the symlink and DFHack integration works end-to-end.

**Files:**
- Create: `F:\DF-Hack\scripts\hello.lua`

- [ ] **Step 1: Create the test script**

Create `F:\DF-Hack\scripts\hello.lua` with this content:

```lua
-- hello.lua
-- Simple test script to verify the DFHack integration works.
-- Usage: heinrich/hello
print("Hello from heinrich/hello! Setup is working.")
```

- [ ] **Step 2: Launch Dwarf Fortress with DFHack**

Start the game via Steam as usual. DFHack loads automatically.

- [ ] **Step 3: Run the script in the DFHack console**

Open the DFHack console (default key: `` ` `` or via the DFHack menu) and type:

```
heinrich/hello
```

Expected output in the console:
```
Hello from heinrich/hello! Setup is working.
```

If you see this message, the symlink and DFHack integration are working correctly.

- [ ] **Step 4: Remove the test script (it was only for verification)**

```bash
rm F:/DF-Hack/scripts/hello.lua
```

- [ ] **Step 5: Commit the design documents and push**

```bash
cd F:/DF-Hack
git add docs/
git commit -m "docs: add design spec and implementation plan"
git push
```

---

## Done

After completing all tasks:
- `F:\DF-Hack` is a git repo connected to `github.com/hpg-uni/dfhack-scripts`
- Scripts placed in `F:\DF-Hack\scripts\` are immediately available in DFHack as `heinrich/<scriptname>`
- The workflow for new scripts: describe idea → Claude writes script → test in-game → commit → push
