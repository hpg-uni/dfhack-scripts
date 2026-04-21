-- room-value: Shows the total value of the currently selected zone.
-- Counts constructed/smooth/engraved floors and walls, plus furniture.
-- Items placed on display furniture are not included (DF does not count them).
-- Usage: heinrich/room-value

local QUALITY_MULT = { [0]=1, [1]=2, [2]=3, [3]=4, [4]=5, [5]=12 }
local QUALITY_NAME = {
    [0]="Ordinary",      [1]="Well-crafted",   [2]="Finely crafted",
    [3]="Superior",      [4]="Exceptional",     [5]="Masterwork",
}

-- Building types that contribute to room value.
-- Built dynamically so unknown type names in this DF version are silently skipped.
local FURNITURE = {}
for _, def in ipairs({
    {"Bed",          "Bed"},
    {"Chair",        "Chair/Throne"},
    {"Table",        "Table"},
    {"Cabinet",      "Cabinet"},
    {"Box",          "Box/Chest"},
    {"Coffin",       "Coffin"},
    {"Statue",       "Statue"},
    {"ArmorStand",   "Armor Stand"},
    {"WeaponRack",   "Weapon Rack"},
    {"Door",         "Door"},
    {"Window",       "Window"},
    {"GrateWall",    "Wall Grate"},
    {"GrateFloor",   "Floor Grate"},
    {"BarsVertical", "Vertical Bars"},
    {"BarsFloor",    "Floor Bars"},
}) do
    local btype = df.building_type[def[1]]
    if btype ~= nil then
        FURNITURE[btype] = def[2]
    end
end

-- Returns the quality (0-5) of a furniture building by finding the item
-- it was constructed from (items built into buildings have flags.in_building = true).
local function get_building_quality(b)
    -- Some building subtypes expose quality directly
    local ok, q = pcall(function() return b.quality end)
    if ok and type(q) == "number" then return q end

    -- Fall back: find the construction item at the building's tile
    local bx, by, bz = b.x1, b.y1, b.z
    for _, item in ipairs(df.global.world.items.all) do
        if item.flags.in_building and item.pos.z == bz
        and item.pos.x == bx and item.pos.y == by then
            local ok2, iq = pcall(function() return item.quality end)
            if ok2 and type(iq) == "number" then return iq end
        end
    end
    return 0
end

local function get_mat_value(mat_type, mat_index)
    if not mat_type or mat_type < 0 then return 1 end
    local info = dfhack.matinfo.decode(mat_type, mat_index)
    return (info and info.material and info.material.material_value) or 1
end

local function get_mat_name(mat_type, mat_index)
    local info = dfhack.matinfo.decode(mat_type, mat_index)
    return (info and info:toString()) or "unknown"
end

-- Require a zone to be selected in the Zones screen
local zone = dfhack.gui.getSelectedCivZone(true)
if not zone then
    qerror("No zone selected. Open the Zones screen (z key) and click a zone first.")
end

local x1 = zone.x1
local y1 = zone.y1
local x2 = zone.x2
local y2 = zone.y2
local z  = zone.z
if z == nil then z = zone.z1 end
if z == nil then qerror("Cannot determine z-level of this zone.") end

-- Scan tiles for floor and wall values
local floor_val = 0
local wall_val  = 0

for tx = x1, x2 do
    for ty = y1, y2 do
        local block = dfhack.maps.getTileBlock(tx, ty, z)
        if block then
            local lx     = tx % 16
            local ly     = ty % 16
            local attrs  = df.tiletype.attrs[block.tiletype[lx][ly]]
            local shape  = attrs.shape
            local special = attrs.special
            local con    = dfhack.constructions.findAtTile(tx, ty, z)

            local tile_val = 0

            if con then
                -- Constructed floor or wall: material value x 10.
                -- df.construction does not store build quality, so no multiplier.
                tile_val = get_mat_value(con.mat_type, con.mat_index) * 10
            elseif special == df.tiletype_special.SMOOTH then
                -- Smoothed or engraved natural stone.
                -- layerMaterial holds the INORGANIC index for the geological layer.
                -- Multiply by 10; engraving quality is not yet distinguished here.
                tile_val = get_mat_value(0, block.layerMaterial) * 10
            end

            if shape == df.tiletype_shape.FLOOR
            or shape == df.tiletype_shape.RAMP then
                floor_val = floor_val + tile_val
            elseif shape == df.tiletype_shape.WALL then
                wall_val = wall_val + tile_val
            end
        end
    end
end

-- Scan buildings for furniture values
local furn_val  = 0
local furn_list = {}

for _, b in ipairs(df.global.world.buildings.all) do
    if b.z == z then
        local cx = math.floor((b.x1 + b.x2) / 2)
        local cy = math.floor((b.y1 + b.y2) / 2)
        if cx >= x1 and cx <= x2 and cy >= y1 and cy <= y2 then
            local ok, btype = pcall(function() return b:getType() end)
            if ok then
                local fname = FURNITURE[btype]
                if fname then
                    local q = get_building_quality(b)
                    local mv  = get_mat_value(b.mat_type, b.mat_index)
                    local val = mv * (QUALITY_MULT[q] or 1) * 10
                    furn_val  = furn_val + val
                    table.insert(furn_list, {
                        name = fname,
                        mat  = get_mat_name(b.mat_type, b.mat_index),
                        q    = q,
                        val  = val,
                    })
                end
            end
        end
    end
end

-- Print the report
local total = floor_val + wall_val + furn_val
local SEP   = string.rep("-", 44)
local DBL   = string.rep("=", 44)

print("")
print(DBL)
print("  Room Value Report")
print(DBL)
print(string.format("  Zone: (%d,%d) to (%d,%d), z=%d",
    x1, y1, x2, y2, z))
print(string.format("  Size: %d x %d = %d tiles",
    x2-x1+1, y2-y1+1, (x2-x1+1)*(y2-y1+1)))
print(SEP)
print(string.format("  Floors:    %8d", floor_val))
print(string.format("  Walls:     %8d", wall_val))
print(string.format("  Furniture: %8d", furn_val))
print(SEP)
print(string.format("  TOTAL:     %8d", total))
print(DBL)

if #furn_list > 0 then
    print("")
    print("  Furniture breakdown:")
    for _, f in ipairs(furn_list) do
        print(string.format("    %-18s  %-14s  %-14s  %6d",
            f.name, f.mat, QUALITY_NAME[f.q] or "?", f.val))
    end
    print("")
end
