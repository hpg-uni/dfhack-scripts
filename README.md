# dfhack-scripts

Personal DFHack Lua scripts by [hpg-uni](https://github.com/hpg-uni).

## Requirements

- [Dwarf Fortress](https://store.steampowered.com/app/975370/Dwarf_Fortress/) (Steam edition, v50.x)
- [DFHack](https://github.com/DFHack/dfhack) 50.x or later

## Installation

1. Clone this repository somewhere on your system.
2. Create a symlink from your DFHack `scripts` folder into this repo's `scripts/` directory.

**Windows (Command Prompt as Administrator):**
```cmd
mklink /D "PATH_TO_DFHACK\hack\scripts\heinrich" "PATH_TO_THIS_REPO\scripts"
```
Replace `PATH_TO_DFHACK` with your actual DFHack path, e.g.:
`C:\Program Files (x86)\Steam\steamapps\common\Dwarf Fortress`

**Linux/macOS:**
```bash
ln -s /path/to/this/repo/scripts "/path/to/dfhack/hack/scripts/heinrich"
```

3. Scripts are then available in the DFHack console as `heinrich/<scriptname>`.

## Scripts

Scripts will be listed here as they are added.

## License

MIT
