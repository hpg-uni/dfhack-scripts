"""Sync own manager orders and stockpile settings between the game and this repo.

Usage:
    python tools/sync_dfhack_config.py pull [DF-PATH]   game -> repo (after exporting in game)
    python tools/sync_dfhack_config.py push [DF-PATH]   repo -> game (e.g. on another machine)
    python tools/sync_dfhack_config.py status [DF-PATH] only list differences, copy nothing

DF-PATH is the Dwarf Fortress folder, default is the Steam install below.
Only copies new or changed files, never deletes. Changed files are listed before copying.
"""
import filecmp
import os
import shutil
import sys

DEFAULT_DF = r"C:\Program Files (x86)\Steam\steamapps\common\Dwarf Fortress"
REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dfhack-config")
FOLDERS = {"orders": ".json", "stockpiles": ".dfstock"}


def sync(src_root, dst_root, dry_run=False):
    copied = 0
    for folder, ext in FOLDERS.items():
        src, dst = os.path.join(src_root, folder), os.path.join(dst_root, folder)
        if not os.path.isdir(src):
            continue
        if not dry_run:
            os.makedirs(dst, exist_ok=True)
        for name in sorted(os.listdir(src)):
            s, d = os.path.join(src, name), os.path.join(dst, name)
            if not name.endswith(ext) or not os.path.isfile(s):
                continue
            if not os.path.exists(d):
                print(f"  new      {folder}/{name}")
            elif not filecmp.cmp(s, d, shallow=False):
                print(f"  changed  {folder}/{name}")
            else:
                continue
            if not dry_run:
                shutil.copy2(s, d)
            copied += 1
    print(f"{copied} file(s) {'differ' if dry_run else 'copied'}")


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in ("pull", "push", "status"):
        sys.exit(__doc__)
    game = os.path.join(sys.argv[2] if len(sys.argv) > 2 else DEFAULT_DF, "dfhack-config")
    if not os.path.isdir(game):
        sys.exit(f"not found: {game}")
    if sys.argv[1] == "status":
        print("game -> repo (pull would copy):")
        sync(game, REPO, dry_run=True)
        print("repo -> game (push would copy):")
        sync(REPO, game, dry_run=True)
    elif sys.argv[1] == "pull":
        sync(game, REPO)
    else:
        sync(REPO, game)


if __name__ == "__main__":
    main()
