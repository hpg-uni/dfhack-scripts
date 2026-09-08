-- Shows which nobles have unmet room or furniture requirements.
--[====[
hpg-noble-needs
===============

Tags: fort | inspection | buildings | units

Lists every noble and administrator with room requirements and shows
which requirements are not met: rooms that are not assigned, rooms whose
value is too low, and missing chests, cabinets, weapon racks or armor
stands. Room values are DF's own numbers, the same as in the zone panel.

Usage
-----

    hpg-noble-needs [<options>]

Examples
--------

hpg-noble-needs
    Opens the window. Press f to show only positions with deficits,
    r to refresh.

hpg-noble-needs --print
    Prints the report to the DFHack console instead.

hpg-noble-needs --print --deficits
    Console report, only positions with deficits.

Options
-------

-p, --print
    Print to the console instead of opening the window.

-d, --deficits
    Show only positions with unmet requirements (console mode).
]====]

local argparse = require('argparse')
local gui      = require('gui')
local widgets  = require('gui.widgets')

------------------------------------------------------------------------
-- Static tables
------------------------------------------------------------------------

-- Room quality tiers (from DFHack df.dfhack.xml dfhack_room_quality_level)
local TIER_MIN = { 0, 100, 250, 500, 1000, 1500, 2500, 10000 }

-- Tier names per room type (from DFHack Buildings.cpp room_quality_names)
local TIER_NAMES = {
    Bedroom = { "Meager Quarters", "Modest Quarters", "Quarters",
                "Decent Quarters", "Fine Quarters", "Great Bedroom",
                "Grand Bedroom", "Royal Bedroom" },
    Dining  = { "Meager Dining Room", "Modest Dining Room", "Dining Room",
                "Decent Dining Room", "Fine Dining Room", "Great Dining Room",
                "Grand Dining Room", "Royal Dining Room" },
    Office  = { "Meager Office", "Modest Office", "Office", "Decent Office",
                "Splendid Office", "Throne Room", "Opulent Throne Room",
                "Royal Throne Room" },
    Tomb    = { "Grave", "Servant's Burial Chamber", "Burial Chamber", "Tomb",
                "Fine Tomb", "Mausoleum", "Grand Mausoleum", "Royal Mausoleum" },
}

-- Room types in display order: key, label, entity_position field, civzone_type name
local ROOM_TYPES = {
    { key = "Office",  label = "Office",  req = "required_office",  zone = "Office"     },
    { key = "Bedroom", label = "Bedroom", req = "required_bedroom", zone = "Bedroom"    },
    { key = "Dining",  label = "Dining",  req = "required_dining",  zone = "DiningHall" },
    { key = "Tomb",    label = "Tomb",    req = "required_tomb",    zone = "Tomb"       },
}

-- Furniture requirements: label, entity_position field, building_type name
local FURNITURE = {
    { label = "Chests",   req = "required_boxes",    btype = "Box"        },
    { label = "Cabinets", req = "required_cabinets", btype = "Cabinet"    },
    { label = "Racks",    req = "required_racks",    btype = "Weaponrack" },
    { label = "Stands",   req = "required_stands",   btype = "Armorstand" },
}

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------

local function tier_name(room_key, value)
    local names = TIER_NAMES[room_key]
    local idx = 1
    for i, min in ipairs(TIER_MIN) do
        if value >= min then idx = i end
    end
    return names[idx]
end

local function zone_type_of(key)
    return df.civzone_type[key]
end

local function is_civzone(b)
    return df.building_civzonest:is_instance(b)
end

-- DF vmethod that computes the room value for a unit. Named getPersonalValue
-- in current df-structures; older builds called it getRoomValue.
local function room_value(zone, unit)
    local ok, v = pcall(function() return zone:getPersonalValue(unit) end)
    if ok and type(v) == "number" then return v end
    ok, v = pcall(function() return zone:getRoomValue(unit) end)
    if ok and type(v) == "number" then return v end
    return nil
end

-- All room zones owned by the unit, grouped by ROOM_TYPES key.
local function owned_rooms(unit)
    local rooms = {}
    for _, rt in ipairs(ROOM_TYPES) do rooms[rt.key] = {} end

    local seen = {}
    local function add(zone)
        if seen[zone.id] then return end
        for _, rt in ipairs(ROOM_TYPES) do
            if zone.type == zone_type_of(rt.zone) then
                seen[zone.id] = true
                table.insert(rooms[rt.key], zone)
                return
            end
        end
    end

    -- Primary source: what DF itself tracks for the unit
    local ok, list = pcall(function() return unit.owned_buildings end)
    if ok and list then
        for _, b in ipairs(list) do
            if is_civzone(b) then add(b) end
        end
    end

    -- Fallback / cross-check: zone vectors with assigned_unit_id
    local other = df.global.world.buildings.other
    for _, vec_name in ipairs({ "ZONE_OFFICE", "ZONE_BEDROOM", "ZONE_DINING_HALL", "ZONE_TOMB" }) do
        local ok2, vec = pcall(function() return other[vec_name] end)
        if ok2 and vec then
            for _, zone in ipairs(vec) do
                if zone.assigned_unit_id == unit.id then add(zone) end
            end
        end
    end

    return rooms
end

local function count_furniture(rooms)
    local counts = {}
    for _, f in ipairs(FURNITURE) do counts[f.btype] = 0 end
    for _, list in pairs(rooms) do
        for _, zone in ipairs(list) do
            for _, b in ipairs(zone.contained_buildings) do
                local ok, bt = pcall(function() return b:getType() end)
                if ok then
                    for _, f in ipairs(FURNITURE) do
                        if bt == df.building_type[f.btype] then
                            counts[f.btype] = counts[f.btype] + 1
                        end
                    end
                end
            end
        end
    end
    return counts
end

local function position_title(pos, unit)
    local name
    if unit.sex == df.pronoun_type.she and pos.name_female[0] ~= "" then
        name = pos.name_female[0]
    elseif unit.sex == df.pronoun_type.he and pos.name_male[0] ~= "" then
        name = pos.name_male[0]
    else
        name = pos.name[0]
    end
    if name == "" then name = pos.code end
    return name
end

local function unit_name(unit)
    local ok, name = pcall(function()
        return dfhack.translation.translateName(dfhack.units.getVisibleName(unit))
    end)
    if ok and name and name ~= "" then return name end
    return dfhack.units.getReadableName(unit)
end

------------------------------------------------------------------------
-- Data collection
------------------------------------------------------------------------

-- Returns a list of entries:
-- { name, titles, precedence, rooms = { [key] = {required, value, tier, count} },
--   furniture = { {label, required, have} }, has_deficit }
local function collect()
    local entries = {}

    for _, unit in ipairs(dfhack.units.getCitizens(true)) do
        local positions = dfhack.units.getNoblePositions(unit)
        if positions and #positions > 0 then
            -- Merge requirements of all positions this unit holds
            local req = {}
            local titles = {}
            local precedence = math.huge
            local any = false
            for _, np in ipairs(positions) do
                local pos = np.position
                table.insert(titles, position_title(pos, unit))
                if pos.precedence < precedence then precedence = pos.precedence end
                for _, rt in ipairs(ROOM_TYPES) do
                    local v = pos[rt.req]
                    if v > (req[rt.req] or 0) then req[rt.req] = v end
                    if v > 0 then any = true end
                end
                for _, f in ipairs(FURNITURE) do
                    local v = pos[f.req]
                    if v > (req[f.req] or 0) then req[f.req] = v end
                    if v > 0 then any = true end
                end
            end

            if any then
                local rooms = owned_rooms(unit)
                local counts = count_furniture(rooms)
                local entry = {
                    name = unit_name(unit),
                    titles = table.concat(titles, ", "),
                    precedence = precedence,
                    rooms = {},
                    furniture = {},
                    has_deficit = false,
                }

                for _, rt in ipairs(ROOM_TYPES) do
                    local required = req[rt.req] or 0
                    local best, best_zone = nil, nil
                    for _, zone in ipairs(rooms[rt.key]) do
                        local v = room_value(zone, unit)
                        if v and (not best or v > best) then
                            best, best_zone = v, zone
                        end
                    end
                    local r = {
                        required = required,
                        value = best,
                        count = #rooms[rt.key],
                        tier = best and tier_name(rt.key, best) or nil,
                        zone = best_zone,
                    }
                    if required > 0 then
                        if r.count == 0 then
                            r.status = "missing"
                        elseif best == nil then
                            r.status = "unknown"
                        elseif best < required then
                            r.status = "too low"
                        else
                            r.status = "ok"
                        end
                        if r.status ~= "ok" then entry.has_deficit = true end
                    else
                        r.status = "-"
                    end
                    entry.rooms[rt.key] = r
                end

                for _, f in ipairs(FURNITURE) do
                    local required = req[f.req] or 0
                    local have = counts[f.btype]
                    table.insert(entry.furniture, {
                        label = f.label, required = required, have = have,
                        ok = have >= required,
                    })
                    if have < required then entry.has_deficit = true end
                end

                table.insert(entries, entry)
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.precedence ~= b.precedence then return a.precedence < b.precedence end
        return a.name < b.name
    end)
    return entries
end

------------------------------------------------------------------------
-- Formatting
------------------------------------------------------------------------

local STATUS_PEN = {
    ok        = COLOR_GREEN,
    missing   = COLOR_LIGHTRED,
    ["too low"] = COLOR_LIGHTRED,
    unknown   = COLOR_YELLOW,
    ["-"]     = COLOR_GREY,
}

-- Builds the text tokens for one entry (multi-line, for widgets.List)
local function entry_tokens(entry)
    local t = {}
    table.insert(t, { text = entry.name, pen = COLOR_WHITE })
    table.insert(t, { text = ", " .. entry.titles, pen = COLOR_CYAN })
    table.insert(t, NEWLINE)

    for _, rt in ipairs(ROOM_TYPES) do
        local r = entry.rooms[rt.key]
        local pen = STATUS_PEN[r.status] or COLOR_WHITE
        local desc
        if r.count == 0 then
            desc = "(none)"
        else
            desc = r.tier or "?"
            if r.count > 1 then desc = desc .. string.format(" (x%d)", r.count) end
        end
        local val = r.value and tostring(r.value) or "-"
        local reqs = r.required > 0 and tostring(r.required) or "-"
        table.insert(t, { gap = 2, text = string.format("%-8s", rt.label), pen = COLOR_GREY })
        table.insert(t, { text = string.format("%-26s", desc), pen = pen })
        table.insert(t, { text = string.format("%6s / %-6s", val, reqs), pen = pen })
        table.insert(t, { text = r.status, pen = pen })
        table.insert(t, NEWLINE)
    end

    local first = true
    for _, f in ipairs(entry.furniture) do
        local pen = f.required == 0 and COLOR_GREY or (f.ok and COLOR_GREEN or COLOR_LIGHTRED)
        table.insert(t, { gap = first and 2 or 3,
                          text = string.format("%s %d/%d", f.label, f.have, f.required),
                          pen = pen })
        first = false
    end
    table.insert(t, NEWLINE)
    return t
end

-- Plain-text version for the console
local function entry_lines(entry)
    local lines = {}
    table.insert(lines, string.format("%s, %s", entry.name, entry.titles))
    for _, rt in ipairs(ROOM_TYPES) do
        local r = entry.rooms[rt.key]
        local desc
        if r.count == 0 then
            desc = "(none)"
        else
            desc = r.tier or "?"
            if r.count > 1 then desc = desc .. string.format(" (x%d)", r.count) end
        end
        local val = r.value and tostring(r.value) or "-"
        local reqs = r.required > 0 and tostring(r.required) or "-"
        table.insert(lines, string.format("  %-8s %-26s %6s / %-6s %s",
            rt.label, desc, val, reqs, r.status))
    end
    local parts = {}
    for _, f in ipairs(entry.furniture) do
        table.insert(parts, string.format("%s %d/%d%s", f.label, f.have, f.required,
            (f.required > 0 and not f.ok) and "!" or ""))
    end
    table.insert(lines, "  " .. table.concat(parts, "   "))
    return lines
end

------------------------------------------------------------------------
-- Console output
------------------------------------------------------------------------

local function print_report(only_deficits)
    local entries = collect()
    local shown = 0
    print("")
    for _, e in ipairs(entries) do
        if e.has_deficit or not only_deficits then
            for _, line in ipairs(entry_lines(e)) do print(line) end
            print("")
            shown = shown + 1
        end
    end
    if shown == 0 then
        print(only_deficits and "All noble requirements are met."
                            or "No nobles with room requirements found.")
    end
end

------------------------------------------------------------------------
-- GUI
------------------------------------------------------------------------

NobleNeeds = defclass(NobleNeeds, widgets.Window)
NobleNeeds.ATTRS {
    frame_title = 'Noble needs',
    frame = { w = 70, h = 30 },
    resizable = true,
    resize_min = { w = 60, h = 12 },
}

function NobleNeeds:init()
    self:addviews{
        widgets.List{
            view_id = 'list',
            frame = { t = 0, l = 0, r = 0, b = 2 },
            row_height = 7,
        },
        widgets.ToggleHotkeyLabel{
            view_id = 'only_deficits',
            frame = { b = 0, l = 0, w = 30 },
            key = 'CUSTOM_F',
            label = 'Only deficits:',
            initial_option = false,
            on_change = function() self:refresh() end,
        },
        widgets.HotkeyLabel{
            frame = { b = 0, l = 32, w = 14 },
            key = 'CUSTOM_R',
            label = 'Refresh',
            on_activate = function() self:refresh() end,
        },
        widgets.HotkeyLabel{
            frame = { b = 0, l = 48, w = 12 },
            key = 'LEAVESCREEN',
            label = 'Close',
            on_activate = function() self.parent_view:dismiss() end,
        },
    }
    self:refresh()
end

function NobleNeeds:refresh()
    local only = self.subviews.only_deficits:getOptionValue()
    local entries = collect()
    local choices = {}
    for _, e in ipairs(entries) do
        if e.has_deficit or not only then
            table.insert(choices, { text = entry_tokens(e) })
        end
    end
    if #choices == 0 then
        table.insert(choices, { text = only and 'All noble requirements are met.'
                                          or 'No nobles with room requirements found.' })
    end
    self.subviews.list:setChoices(choices)
end

NobleNeedsScreen = defclass(NobleNeedsScreen, gui.ZScreen)
NobleNeedsScreen.ATTRS {
    focus_path = 'hpg-noble-needs',
}

function NobleNeedsScreen:init()
    self:addviews{ NobleNeeds{} }
end

function NobleNeedsScreen:onDismiss()
    view = nil
end

------------------------------------------------------------------------
-- Entry point
------------------------------------------------------------------------

if not dfhack.world.isFortressMode() or not dfhack.isMapLoaded() then
    qerror('hpg-noble-needs requires a fortress map to be loaded')
end

local print_only = false
local only_deficits = false
argparse.processArgsGetopt({...}, {
    { 'p', 'print',    handler = function() print_only = true end },
    { 'd', 'deficits', handler = function() only_deficits = true end },
})

if print_only then
    print_report(only_deficits)
else
    view = view and view:raise() or NobleNeedsScreen{}:show()
end
