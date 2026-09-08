# noble-needs – Design

**Date:** 2026-09-08

## Goal

Show at a glance which noble/administrator positions in the fortress have unmet
room requirements: missing rooms, rooms whose value is too low, and missing
furniture (chests, cabinets, weapon racks, armor stands).

## Scope

- `scripts/hpg-noble-needs.lua`, command `hpg-noble-needs` (prefix `hpg-` keeps names unique against DFHack scripts)
- Opens a DFHack window (`gui.ZScreen` + `widgets.Window` + `widgets.List`),
  same pattern as `gui/petitions`.
- `--print` writes the same report to the DFHack console instead (test path
  that does not depend on GUI layout).
- No interaction beyond scrolling, a "only deficits" toggle (`f`) and close.
  Zooming to rooms is out of scope for v1.

## Data sources (all DF/DFHack, no own value formula)

| What | Source |
|---|---|
| Position holders | `dfhack.units.getCitizens()` + `dfhack.units.getNoblePositions(unit)` |
| Required room values | `entity_position.required_office/bedroom/dining/tomb` |
| Required furniture | `entity_position.required_boxes/cabinets/racks/stands` |
| Owned rooms | `unit.owned_buildings` filtered to civzones of type Bedroom/Office/DiningHall/Tomb; fallback scan of `world.buildings.other.ZONE_*` with `assigned_unit_id` |
| Room value | `zone:getPersonalValue(unit)` (DF vmethod, formerly `getRoomValue`) |
| Tier name | Own table copied from DFHack `Buildings.cpp` `room_quality_names` + `dfhack_room_quality_level` min values (DFHack's `getRoomDescription` returns "" in v50) |
| Furniture in room | `zone.contained_buildings`, counted by `building_type` Box/Cabinet/WeaponRack/ArmorStand |

Rules:
- Positions with no requirement at all are skipped.
- One unit with several positions: per field the maximum requirement applies;
  title lists all positions.
- Several rooms of the same type: the best value counts.
- Furniture is counted across all owned rooms (assumption, see below).
- Sorted by position precedence (most important first).

## Output

```
Urist McNoble, Mayor
  Office     Decent Office            620 / 500   ok
  Bedroom    (none)                     - / 500   missing
  Dining     Meager Dining Room        80 / 500   too low
  Chests 1/2   Cabinets 1/1   Racks 0/1   Stands 1/1
```

Deficits red, satisfied green, not required grey.

## Assumptions to verify in game

1. Furniture requirements count across all of the noble's rooms, not only
   the bedroom. Compare with the vanilla Nobles screen.
2. `getPersonalValue(unit)` returns the value DF shows for the zone.
3. `world.buildings.other.ZONE_BEDROOM/ZONE_OFFICE/ZONE_DINING_HALL/ZONE_TOMB`
   exist in this DFHack build (used by `preserve-rooms`, so very likely).

## Testing

Claude cannot run DFHack. Heinrich tests in game: first `--print`, then the
window. Compare with the vanilla Nobles screen and the zone panel values.
