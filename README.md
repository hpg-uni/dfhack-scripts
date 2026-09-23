# dfhack-scripts

Personal DFHack Lua scripts by [hpg-uni](https://github.com/hpg-uni).

## Requirements

- [Dwarf Fortress](https://store.steampowered.com/app/975370/Dwarf_Fortress/) (Steam edition, v50.x)
- [DFHack](https://github.com/DFHack/dfhack) 50.x or later

## Installation

1. Clone this repository somewhere on your system.
2. Register the repo's `scripts/` folder as a DFHack script path: open
   `dfhack-config/script-paths.txt` in your Dwarf Fortress folder and add a line

   ```
   +F:\DF-Hack\scripts
   ```

   (adjust the path; the leading `+` puts it first in the search order).
3. Restart DF (or run `script-paths` in the DFHack console to check). The scripts
   then appear in `gui/launcher` and are available as `hpg-<scriptname>`.

All scripts carry the prefix `hpg-` so they never collide with scripts shipped by
DFHack.

Do not use a symlink inside `hack/scripts/`: DFHack's recursive script scan skips
symlinked folders, so the scripts would run but not show up in the launcher.

## Scripts

| Script | Description |
|---|---|
| [hpg-room-value](docs/hpg-room-value.md) | Value breakdown (floors, walls, furniture) of the selected zone |
| [hpg-noble-needs](docs/hpg-noble-needs.md) | Which nobles have unmet room or furniture requirements |

## Manager orders and stockpile settings

`dfhack-config/orders/` and `dfhack-config/stockpiles/` hold my own manager orders
(`orders import <name>`) and stockpile settings (`stockpiles import <name>`). The game
reads them from its own `dfhack-config` folder, so they are synced with a script:

```
python tools/sync_dfhack_config.py pull [DF-PATH]   # game -> repo, after exporting in game
python tools/sync_dfhack_config.py push [DF-PATH]   # repo -> game, e.g. on another machine
python tools/sync_dfhack_config.py status [DF-PATH] # only list differences
```

`DF-PATH` defaults to the Steam install. The script only copies new or changed files,
lists them, and never deletes anything.

## License

MIT
