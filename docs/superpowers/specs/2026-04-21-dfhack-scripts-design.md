# DFHack Scripts – Project Design

**Date:** 2026-04-21
**Author:** hpg-uni

## Goal

Develop personal DFHack Lua scripts over time, with the possibility of sharing them with the DFHack community later. Scripts are written by Claude Code based on ideas provided by the user.

## Repository Structure

```
F:\DF-Hack\
├── scripts/          ← Lua scripts (symlinked into DFHack)
├── docs/             ← Per-script Markdown documentation
│   └── superpowers/
│       └── specs/    ← Design documents
├── CHANGELOG.md      ← Version history
└── README.md         ← Overview and installation instructions
```

Each script consists of:
- `scripts/<scriptname>.lua` — the Lua script itself
- `docs/<scriptname>.md` — usage documentation in DFHack format

## GitHub

- Local repo: `F:\DF-Hack`
- Remote repo: `github.com/hpg-uni/dfhack-scripts`
- Visibility: Public (to allow community sharing later)

## DFHack Integration

A Windows symlink connects the DFHack installation to this repo:

```
<Steam DFHack>/hack/scripts/heinrich/  →  F:\DF-Hack\scripts\
```

Scripts are accessible in-game via the DFHack console as `heinrich/<scriptname>`.

## Development Workflow

1. User describes an idea (in German or English)
2. Claude Code asks clarifying questions if needed
3. Claude Code writes the Lua script with English comments
4. User tests the script in Dwarf Fortress (available immediately via symlink)
5. User provides feedback; Claude Code iterates
6. Commit to git when satisfied

## Code Style

- Language: Lua (DFHack API)
- Comments: English
- Commit messages: English
- Documentation: English, following DFHack's official script doc format

## Documentation Format (per script)

```markdown
# scriptname
Short description of what it does.

## Usage
    heinrich/scriptname [arguments]

## Examples
    ...

## Notes
    ...
```

## Community Sharing

When a script is mature enough, it can be submitted as a Pull Request to the official `github.com/DFHack/scripts` repository. The documentation format and English comments are chosen from the start to make this transition easy.
