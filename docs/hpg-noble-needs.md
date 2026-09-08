# hpg-noble-needs

Shows which nobles and administrators have unmet room requirements: rooms that
are not assigned, rooms whose value is too low, and missing furniture (chests,
cabinets, weapon racks, armor stands).

## Usage

    hpg-noble-needs              open the window
    hpg-noble-needs --print      print the report to the DFHack console
    hpg-noble-needs --print -d   console, only positions with deficits

In the window, `f` toggles "only deficits", `r` refreshes.

## Output

```
Urist McNoble, Mayor
  Office   Decent Office                 620 / 500    ok
  Bedroom  (none)                          - / 500    missing
  Dining   Meager Dining Room              80 / 500    too low
  Tomb     (none)                          - / -      -
  Chests 1/2   Cabinets 1/1   Racks 0/1!   Stands 1/1
```

Per room type: current tier name, best room value / required value, status.
Deficits are red, satisfied requirements green, requirements that do not apply
to the position grey.

## How it works

- Position holders: all citizens with a noble position
  (`dfhack.units.getNoblePositions`). Positions without any requirement
  (e.g. Militia Captain) are skipped. If one dwarf holds several positions,
  the highest requirement per field applies.
- Requirements come from the position definition in the entity raws
  (`REQUIRED_OFFICE`, `REQUIRED_BEDROOM`, `REQUIRED_DINING`, `REQUIRED_TOMB`,
  `REQUIRED_BOXES`, `REQUIRED_CABINETS`, `REQUIRED_RACKS`, `REQUIRED_STANDS`).
- Rooms: the unit's owned zones of type Bedroom, Office, Dining Hall, Tomb.
  If several rooms of one type are assigned, the best value counts.
- Room value: DF's own calculation (`getPersonalValue`), so it matches what
  the game shows for the zone. Tier names use DFHack's thresholds:
  0 / 100 / 250 / 500 / 1000 / 1500 / 2500 / 10000.
- Furniture: chests, cabinets, weapon racks and armor stands are counted
  across all of the noble's rooms.

## Requirements per position (vanilla dwarves)

| Position | Office | Bedroom | Dining | Tomb | Chests | Cabinets | Racks | Stands |
|---|---|---|---|---|---|---|---|---|
| Monarch | 10000 | 10000 | 10000 | 10000 | 5 | 3 | 3 | 3 |
| Duke/Duchess | 2500 | 2500 | 2500 | 2500 | 5 | 3 | 3 | 3 |
| Count/Countess | 1500 | 1500 | 1500 | 1500 | 3 | 2 | 2 | 2 |
| Baron/Baroness | 500 | 500 | 500 | 500 | 2 | 1 | 1 | 1 |
| Mayor | 500 | 500 | 500 | | 2 | 1 | 1 | 1 |
| Outpost Liaison, Diplomat | 1500 | 1500 | 1500 | | | | | |
| General | 500 | 250 | 250 | 1 | | | | |
| Captain of the Guard, Dungeon Master | 250 | 250 | 250 | | | | | |
| Lieutenant, Sheriff | 100 | 100 | 100 | | | | | |
| Captain | 1 | 1 | 1 | | | | | |
| Manager, Bookkeeper | 1 | | | | | | | |

Values read from `entity_default.txt`; furniture counts from the DF wiki. The
script reads the actual values from the game, so modded entities work too.

## Known limitations

- Whether DF counts furniture only in the bedroom or in all owned rooms is
  not documented; the script counts all owned rooms.
- No zoom-to-room yet.
