# hpg-room-value

Shows the total calculated value of a zone, broken down into floors, walls, and furniture.

## Usage

    hpg-room-value

## Requirements

Open the Zones screen (`z` key), click on a zone to select it, then run the script.

## Output

```
============================================
  Room Value Report
============================================
  Zone: (78,63) to (90,69), z=50
  Size: 13 x 7 = 91 tiles
--------------------------------------------
  Floors:         590
  Walls:          320
  Furniture:      910
--------------------------------------------
  TOTAL:         1820
============================================

  Furniture breakdown:
    Chair/Throne        silver          Finely crafted     300
    ...
```

## What is counted

- **Floors**: constructed floors and ramps (material value × 10); smoothed natural stone (material value × 10)
- **Walls**: constructed walls (material value × 10); smoothed natural stone (material value × 10)
- **Furniture**: beds, tables, chairs/thrones, cabinets, boxes/chests, coffins, statues, weapon racks, doors, windows, grates, bars — each as material value × quality multiplier × 10

Quality multipliers: Ordinary ×1, Well-crafted ×2, Finely crafted ×3, Superior ×4, Exceptional ×5, Masterwork ×12

## What is not counted

- Items placed on display furniture (pedestals, display cases) — DF does not include them in room value
- Rough unsmoothed natural floors and walls
- Workshops, furnaces, and other non-furniture buildings

## Notes

- Engraved tiles are treated the same as smoothed tiles (engraving quality bonus not yet implemented)
- The zone must be fully on one z-level; multi-level zones use only the zone's primary z-level
