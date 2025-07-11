local menuOpen = false
local mouseCursorEnabled = false

-- Map mod type IDs to display names
local modNames = {
    [0] = "Spoiler",
    [1] = "Front Bumper",
    [2] = "Rear Bumper",
    [3] = "Side Skirt",
    [4] = "Exhaust",
    [5] = "Chassis",
    [6] = "Grille",
    [7] = "Hood",
    [8] = "Fender",
    [9] = "Right Fender",
    [10] = "Roof",
    [11] = "Engine",
    [12] = "Brakes",
    [13] = "Transmission",
    [14] = "Horns",
    [15] = "Suspension",
    [16] = "Armor",
    [18] = "Turbo",
    [22] = "Headlights",
    [23] = "Wheels",
    [24] = "Back Wheels",
    [25] = "Plateholders",
    [27] = "Trim Design",
    [28] = "Ornaments",
    [30] = "Dial Design",
    [33] = "Steering Wheel",
    [34] = "Shift Lever",
    [35] = "Plaques",
    [38] = "Hydraulics",
    [48] = "Livery"
}

-- Wheel types mapping
local wheelTypes = {
    [0] = "Sport",
    [1] = "Muscle",
    [2] = "Lowrider",
    [3] = "SUV",
    [4] = "Offroad",
    [5] = "Tuner",
    [6] = "Bike Wheels",
    [7] = "High End",
    [8] = "Benny's Original",
    [9] = "Benny's Bespoke",
    [10] = "Open Wheel",
    [11] = "Street",
    [12] = "Track"
}

-- Debug function to print in F8 console and chat
local function debugPrint(message)
    -- No-op: debug output disabled
end

-- Helper function to refresh vehicle after mod application
local function refreshVehicle(vehicle)
    local model = GetEntityModel(vehicle)
    SetVehicleModKit(vehicle, 0)
    -- More thorough vehicle refresh
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleLights(vehicle, 0)
    SetVehicleLights(vehicle, 1)
    SetVehicleLights(vehicle, 0)
    SetModelAsNoLongerNeeded(model)
end

RegisterCommand('bennys', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetVehicleModKit(veh, 0)
        Citizen.Wait(10)
        local mods = {}

        -- Livery (if available)
        local liveryCount = GetVehicleLiveryCount(veh)
        if liveryCount > 0 then
            table.insert(mods, "Livery")
        end
        -- Exterior mods (only if available)
        for _, modType in ipairs({0,1,2,3,4,5,6,7,8,9,10}) do
            if GetNumVehicleMods(veh, modType) > 0 then
                table.insert(mods, modNames[modType])
            end
        end

        -- Add Paint option
        table.insert(mods, "Paint")

        -- Headlights (always show if mod 22 exists, or if vehicle supports xenon)
        if GetNumVehicleMods(veh, 22) > 0 or true then
            table.insert(mods, "Headlights")
        end
        -- Neons (always available for menu)
        table.insert(mods, "Neons")

        -- Max Upgrade button (always available)
        table.insert(mods, "Max Upgrade")
        -- Performance mods (only if available)
        for _, modType in ipairs({11,12,13,15,16,18}) do
            if (modType == 18 and IsToggleModOn(veh, 18) ~= nil) or GetNumVehicleMods(veh, modType) > 0 then
                table.insert(mods, modNames[modType])
            end
        end

        -- Other/Interior mods (only if available)
        for _, modType in ipairs({14,24,25,27,28,30,33,34,35,38}) do
            if GetNumVehicleMods(veh, modType) > 0 then
                table.insert(mods, modNames[modType])
            end
        end
        -- Wheel Types (only if at least one type is available)
        local hasWheelType = false
        for typeId, _ in pairs(wheelTypes) do
            SetVehicleWheelType(veh, typeId)
            if GetNumVehicleMods(veh, 23) > 0 then
                hasWheelType = true
                break
            end
        end
        if hasWheelType then
            table.insert(mods, "Wheel Types")
        end
        -- Window Tint (only if available)
        if GetNumVehicleWindowTints and type(GetNumVehicleWindowTints) == "function" then
            if GetNumVehicleWindowTints(veh) and GetNumVehicleWindowTints(veh) > 0 then
                table.insert(mods, "Window Tint")
            end
        else
            table.insert(mods, "Window Tint") -- fallback: always show
        end

        -- Convert section objects to strings for NUI, mark as 'section' for UI
        local modsForNUI = {}
        for _, v in ipairs(mods) do
            if type(v) == 'table' and v.section then
                -- skip section headers
            else
                table.insert(modsForNUI, v)
            end
        end

        SendNUIMessage({
            type = "setMods",
            mods = modsForNUI
        })

        SetNuiFocus(true, false)
        menuOpen = true
        mouseCursorEnabled = false
    else
        TriggerEvent('chat:addMessage', { args = { '^1You are not in a vehicle!' } })
    end
end)

RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    menuOpen = false
    mouseCursorEnabled = false
    cb('ok')
end)

-- Helper to build Neons submenu options
local function buildNeonsOptions(veh)
    local options = {}
    local allOn = true
    for i = 0, 3 do
        if not IsVehicleNeonLightEnabled(veh, i) then
            allOn = false
            break
        end
    end
    table.insert(options, { name = "Enable All Neons", index = "enable_all", checked = allOn })
    -- GTA V neon color order and names
    local neonColors = {
        { name = "White", rgb = "255,255,255" },
        { name = "Blue", rgb = "2,21,255" },
        { name = "Electric Blue", rgb = "3,83,255" },
        { name = "Mint Green", rgb = "0,255,140" },
        { name = "Lime Green", rgb = "94,255,1" },
        { name = "Yellow", rgb = "255,255,0" },
        { name = "Golden Shower", rgb = "255,150,0" },
        { name = "Orange", rgb = "255,62,0" },
        { name = "Red", rgb = "255,1,1" },
        { name = "Pony Pink", rgb = "255,50,100" },
        { name = "Hot Pink", rgb = "255,5,190" },
        { name = "Purple", rgb = "35,1,255" },
        { name = "Blacklight", rgb = "15,3,255" }
    }
    for _, c in ipairs(neonColors) do
        table.insert(options, { name = "Set Color: " .. c.name, index = "color:" .. c.rgb })
    end
    return options
end

-- Submenu logic: handle getModOptions and selectModOption from NUI
RegisterNUICallback('getModOptions', function(data, cb)
    local mod = data.mod
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetVehicleModKit(veh, 0)
    end
    local options = {} -- Always reset options here!
    -- ...existing code...
    if veh ~= 0 then
        -- Paint submenu
        if mod == "Paint" then
            table.insert(options, { name = "Primary Color", index = "primary" })
            table.insert(options, { name = "Secondary Color", index = "secondary" })
            table.insert(options, { name = "Pearlescent", index = "pearlescent" })
        elseif mod == "Primary Color" or mod == "Secondary Color" then
            -- Full GTA V color palette (Metallic, Matte, Classic, Utility, Worn, Chrome, etc.)
            local paintColors = {
                { name = "Metallic Black", id = 0 },
                { name = "Metallic Graphite Black", id = 1 },
                { name = "Metallic Black Steel", id = 2 },
                { name = "Metallic Dark Silver", id = 3 },
                { name = "Metallic Silver", id = 4 },
                { name = "Metallic Blue Silver", id = 5 },
                { name = "Metallic Steel Gray", id = 6 },
                { name = "Metallic Shadow Silver", id = 7 },
                { name = "Metallic Stone Silver", id = 8 },
                { name = "Metallic Midnight Silver", id = 9 },
                { name = "Metallic Gun Metal", id = 10 },
                { name = "Metallic Anthracite Grey", id = 11 },
                { name = "Matte Black", id = 12 },
                { name = "Matte Gray", id = 13 },
                { name = "Matte Light Grey", id = 14 },
                { name = "Util Black", id = 15 },
                { name = "Util Black Poly", id = 16 },
                { name = "Util Dark Silver", id = 17 },
                { name = "Util Silver", id = 18 },
                { name = "Util Gun Metal", id = 19 },
                { name = "Util Shadow Silver", id = 20 },
                { name = "Worn Black", id = 21 },
                { name = "Worn Graphite", id = 22 },
                { name = "Worn Silver Grey", id = 23 },
                { name = "Worn Silver", id = 24 },
                { name = "Worn Blue Silver", id = 25 },
                { name = "Worn Shadow Silver", id = 26 },
                { name = "Metallic Red", id = 27 },
                { name = "Metallic Torino Red", id = 28 },
                { name = "Metallic Formula Red", id = 29 },
                { name = "Metallic Blaze Red", id = 30 },
                { name = "Metallic Graceful Red", id = 31 },
                { name = "Metallic Garnet Red", id = 32 },
                { name = "Metallic Desert Red", id = 33 },
                { name = "Metallic Cabernet Red", id = 34 },
                { name = "Metallic Candy Red", id = 35 },
                { name = "Metallic Sunrise Orange", id = 36 },
                { name = "Metallic Classic Gold", id = 37 },
                { name = "Metallic Orange", id = 38 },
                { name = "Matte Red", id = 39 },
                { name = "Matte Dark Red", id = 40 },
                { name = "Matte Orange", id = 41 },
                { name = "Matte Yellow", id = 42 },
                { name = "Util Red", id = 43 },
                { name = "Util Bright Red", id = 44 },
                { name = "Util Garnet Red", id = 45 },
                { name = "Worn Red", id = 46 },
                { name = "Worn Golden Red", id = 47 },
                { name = "Worn Dark Red", id = 48 },
                { name = "Metallic Dark Green", id = 49 },
                { name = "Metallic Racing Green", id = 50 },
                { name = "Metallic Sea Green", id = 51 },
                { name = "Metallic Olive Green", id = 52 },
                { name = "Metallic Green", id = 53 },
                { name = "Metallic Gasoline Blue Green", id = 54 },
                { name = "Matte Lime Green", id = 55 },
                { name = "Util Dark Green", id = 56 },
                { name = "Util Green", id = 57 },
                { name = "Worn Dark Green", id = 58 },
                { name = "Worn Green", id = 59 },
                { name = "Worn Sea Wash", id = 60 },
                { name = "Metallic Midnight Blue", id = 61 },
                { name = "Metallic Dark Blue", id = 62 },
                { name = "Metallic Saxony Blue", id = 63 },
                { name = "Metallic Blue", id = 64 },
                { name = "Metallic Mariner Blue", id = 65 },
                { name = "Metallic Harbor Blue", id = 66 },
                { name = "Metallic Diamond Blue", id = 67 },
                { name = "Metallic Surf Blue", id = 68 },
                { name = "Metallic Nautical Blue", id = 69 },
                { name = "Metallic Bright Blue", id = 70 },
                { name = "Metallic Purple Blue", id = 71 },
                { name = "Metallic Spinnaker Blue", id = 72 },
                { name = "Metallic Ultra Blue", id = 73 },
                { name = "Metallic Bright Blue 2", id = 74 },
                { name = "Util Dark Blue", id = 75 },
                { name = "Util Midnight Blue", id = 76 },
                { name = "Util Blue", id = 77 },
                { name = "Util Sea Foam Blue", id = 78 },
                { name = "Util Lightning Blue", id = 79 },
                { name = "Util Maui Blue Poly", id = 80 },
                { name = "Util Bright Blue", id = 81 },
                { name = "Matte Dark Blue", id = 82 },
                { name = "Matte Blue", id = 83 },
                { name = "Matte Midnight Blue", id = 84 },
                { name = "Worn Dark Blue", id = 85 },
                { name = "Worn Blue", id = 86 },
                { name = "Worn Light Blue", id = 87 },
                { name = "Metallic Taxi Yellow", id = 88 },
                { name = "Metallic Race Yellow", id = 89 },
                { name = "Metallic Bronze", id = 90 },
                { name = "Metallic Yellow Bird", id = 91 },
                { name = "Metallic Lime", id = 92 },
                { name = "Metallic Champagne", id = 93 },
                { name = "Metallic Pueblo Beige", id = 94 },
                { name = "Metallic Dark Ivory", id = 95 },
                { name = "Metallic Choco Brown", id = 96 },
                { name = "Metallic Golden Brown", id = 97 },
                { name = "Metallic Light Brown", id = 98 },
                { name = "Metallic Straw Beige", id = 99 },
                { name = "Metallic Moss Brown", id = 100 },
                { name = "Metallic Biston Brown", id = 101 },
                { name = "Metallic Beechwood", id = 102 },
                { name = "Metallic Dark Beechwood", id = 103 },
                { name = "Metallic Choco Orange", id = 104 },
                { name = "Metallic Beach Sand", id = 105 },
                { name = "Metallic Sun Bleeched Sand", id = 106 },
                { name = "Metallic Cream", id = 107 },
                { name = "Util Brown", id = 108 },
                { name = "Util Medium Brown", id = 109 },
                { name = "Util Light Brown", id = 110 },
                { name = "Metallic White", id = 111 },
                { name = "Metallic Frost White", id = 112 },
                { name = "Worn Honey Beige", id = 113 },
                { name = "Worn Brown", id = 114 },
                { name = "Worn Dark Brown", id = 115 },
                { name = "Worn Straw Beige", id = 116 },
                { name = "Brushed Steel", id = 117 },
                { name = "Brushed Black Steel", id = 118 },
                { name = "Brushed Aluminum", id = 119 },
                { name = "Chrome", id = 120 },
                { name = "Worn Off White", id = 121 },
                { name = "Util Off White", id = 122 },
                { name = "Worn Orange", id = 123 },
                { name = "Worn Light Orange", id = 124 },
                { name = "Metallic Securicor Green", id = 125 },
                { name = "Worn Taxi Yellow", id = 126 },
                { name = "Police Car Blue", id = 127 },
                { name = "Matte Green", id = 128 },
                { name = "Matte Brown", id = 129 },
                { name = "Worn Orange 2", id = 130 },
                { name = "Matte White", id = 131 },
                { name = "Worn White", id = 132 },
                { name = "Worn Olive Army Green", id = 133 },
                { name = "Pure White", id = 134 },
                { name = "Hot Pink", id = 135 },
                { name = "Salmon Pink", id = 136 },
                { name = "Metallic Vermillion Pink", id = 137 },
                { name = "Orange", id = 138 },
                { name = "Green", id = 139 },
                { name = "Blue", id = 140 },
                { name = "Metallic Black Blue", id = 141 },
                { name = "Metallic Black Purple", id = 142 },
                { name = "Metallic Black Red", id = 143 },
                { name = "Hunter Green", id = 144 },
                { name = "Metallic Purple", id = 145 },
                { name = "Metalic V Dark Blue", id = 146 },
                { name = "Modshop Black1", id = 147 },
                { name = "Matte Purple", id = 148 },
                { name = "Matte Dark Purple", id = 149 },
                { name = "Metallic Lava Red", id = 150 },
                { name = "Matte Forest Green", id = 151 },
                { name = "Matte Olive Drab", id = 152 },
                { name = "Matte Desert Brown", id = 153 },
                { name = "Matte Desert Tan", id = 154 },
                { name = "Matte Foliage Green", id = 155 },
                { name = "Default Alloy Color", id = 156 },
                { name = "Epsilon Blue", id = 157 },
                { name = "Pure Gold", id = 158 },
                { name = "Brushed Gold", id = 159 }
            }
            for _, c in ipairs(paintColors) do
                table.insert(options, { name = c.name, index = c.id })
            end
        elseif mod == "Pearlescent" then
            -- Pearlescent overlay options (using GTA V color IDs)
            local pearls = {
                { name = "White", id = 111 },
                { name = "Black", id = 0 },
                { name = "Silver", id = 4 },
                { name = "Blue Silver", id = 5 },
                { name = "Red", id = 27 },
                { name = "Torino Red", id = 28 },
                { name = "Formula Red", id = 29 },
                { name = "Blaze Red", id = 30 },
                { name = "Orange", id = 38 },
                { name = "Sunrise Orange", id = 36 },
                { name = "Yellow", id = 42 },
                { name = "Race Yellow", id = 89 },
                { name = "Lime Green", id = 92 },
                { name = "Green", id = 53 },
                { name = "Dark Green", id = 49 },
                { name = "Sea Green", id = 51 },
                { name = "Blue", id = 64 },
                { name = "Mariner Blue", id = 65 },
                { name = "Harbor Blue", id = 66 },
                { name = "Diamond Blue", id = 67 },
                { name = "Surf Blue", id = 68 },
                { name = "Ultra Blue", id = 73 },
                { name = "Bright Blue", id = 70 },
                { name = "Purple Blue", id = 71 },
                { name = "Spinnaker Blue", id = 72 },
                { name = "Purple", id = 145 },
                { name = "Dark Purple", id = 149 },
                { name = "Pony Pink", id = 137 },
                { name = "Hot Pink", id = 135 },
                { name = "Brown", id = 98 },
                { name = "Golden Brown", id = 97 },
                { name = "Dark Ivory", id = 95 },
                { name = "Straw Beige", id = 99 },
                { name = "Cream", id = 107 }
            }
            for _, c in ipairs(pearls) do
                table.insert(options, { name = c.name, index = c.id })
            end
        -- Special case: Headlights
        elseif mod == "Headlights" then
            table.insert(options, { name = "Stock", index = 0 })
            table.insert(options, { name = "Xenon", index = 1 })
            -- Always show colors
            local colors = {
                { name = "White", id = "color:0" },
                { name = "Blue", id = "color:1" },
                { name = "Electric Blue", id = "color:2" },
                { name = "Mint Green", id = "color:3" },
                { name = "Lime Green", id = "color:4" },
                { name = "Yellow", id = "color:5" },
                { name = "Golden Shower", id = "color:6" },
                { name = "Orange", id = "color:7" },
                { name = "Red", id = "color:8" },
                { name = "Pony Pink", id = "color:9" },
                { name = "Hot Pink", id = "color:10" },
                { name = "Purple", id = "color:11" },
                { name = "Blacklight", id = "color:12" }
            }
            for _, c in ipairs(colors) do
                table.insert(options, { name = c.name, index = c.id })
            end
        -- Special case: Neons
        elseif mod == "Neons" then
            -- Use existing helper function to build neon options
            options = buildNeonsOptions(veh)
        -- Special case: Max Upgrade
        elseif mod == "Max Upgrade" then
            table.insert(options, { name = "Apply All Performance Upgrades", index = "max_upgrade", checked = false })
        -- Special case: Wheel Types
        elseif mod == "Wheel Types" then
            local wheelTypeOptions = {}
            for id, name in pairs(wheelTypes) do
                table.insert(wheelTypeOptions, { name = name, index = id })
            end
            SendNUIMessage({ type = "setModOptions", modName = "Wheel Types", options = wheelTypeOptions })
            return cb('ok')
        -- Special case: Window Tint
        elseif mod == "Window Tint" then
            local tints = {
                { name = "None", id = 0 },
                { name = "Pure Black", id = 1 },
                { name = "Darksmoke", id = 2 },
                { name = "Lightsmoke", id = 3 },
                { name = "Limo", id = 4 },
                { name = "Green", id = 5 }
            }
            for _, t in ipairs(tints) do
                table.insert(options, { name = t.name, index = t.id })
            end
            SendNUIMessage({ type = "setModOptions", modName = "Window Tint", options = options })
            return cb('ok')
        -- Special case: Headlights
        elseif mod == "Headlights" then
            table.insert(options, { name = "Stock", index = 0 })
            table.insert(options, { name = "Xenon", index = 1 })
            -- Always show colors
            local colors = {
                { name = "White", id = "color:0" },
                { name = "Blue", id = "color:1" },
                { name = "Electric Blue", id = "color:2" },
                { name = "Mint Green", id = "color:3" },
                { name = "Lime Green", id = "color:4" },
                { name = "Yellow", id = "color:5" },
                { name = "Golden Shower", id = "color:6" },
                { name = "Orange", id = "color:7" },
                { name = "Red", id = "color:8" },
                { name = "Pony Pink", id = "color:9" },
                { name = "Hot Pink", id = "color:10" },
                { name = "Purple", id = "color:11" },
                { name = "Blacklight", id = "color:12" }
            }
            for _, c in ipairs(colors) do
                table.insert(options, { name = c.name, index = c.id })
            end
        -- Special case: Neons
        elseif mod == "Neons" then
            -- Use existing helper function to build neon options
            options = buildNeonsOptions(veh)
        -- Special case: Max Upgrade
        elseif mod == "Max Upgrade" then
            table.insert(options, { name = "Apply All Performance Upgrades", index = "max_upgrade", checked = false })
        -- Regular case: Standard vehicle mods
        else
            local modType = nil
            for k, v in pairs(modNames) do
                if v == mod then
                    modType = k
                    break
                end
            end
            
            if modType and veh ~= 0 then
                -- Special case: Livery
                if modType == 48 then
                    local liveryCount = GetVehicleLiveryCount(veh)
                    table.insert(options, { name = "None", index = -1 })
                    for i = 0, liveryCount - 1 do
                        table.insert(options, { name = "Livery #" .. (i + 1), index = i })
                    end
                -- Special case: Turbo
                elseif modType == 18 then
                    table.insert(options, { name = "None", index = -1 })
                    table.insert(options, { name = "Turbo", index = 0 })
                -- All other mods
                else
                    local count = GetNumVehicleMods(veh, modType)
                    table.insert(options, { name = "Stock", index = -1 })
                    
                    -- For wheels, we need to set wheel type first
                    if modType == 23 then -- Wheels
                        -- Use current wheel type (default is Sport - 0)
                        local wheelType = GetVehicleWheelType(veh)
                        SetVehicleWheelType(veh, wheelType)
                    end
                    
                    for i = 0, count - 1 do
                        local label = GetModTextLabel(veh, modType, i)
                        local display = label and GetLabelText(label)
                        if display and display ~= "NULL" then
                            table.insert(options, { name = display, index = i })
                        else
                            table.insert(options, { name = mod .. " #" .. (i + 1), index = i })
                        end
                    end
                end
            end
        end
    end
    
    SendNUIMessage({
        type = "setModOptions",
        modName = mod,
        options = options
    })
    
    debugPrint("Sent " .. #options .. " options for " .. mod)
    cb('ok')
end)

RegisterNUICallback('selectModOption', function(data, cb)
    local mod = data.mod
    local optionIndex = data.index or data.optionIndex or -1
    debugPrint("selectModOption: mod="..tostring(mod)..", optionIndex="..tostring(optionIndex))
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetVehicleModKit(veh, 0)
    end
    -- ...existing code...
    if veh ~= 0 then
        -- Paint submenu navigation (send options directly)
        if mod == "Paint" and (optionIndex == "primary" or optionIndex == "secondary" or optionIndex == "pearlescent") then
            local submenu = (optionIndex == "primary" and "Primary Color") or (optionIndex == "secondary" and "Secondary Color") or "Pearlescent"
            local options = {}
            if submenu == "Primary Color" or submenu == "Secondary Color" then
                local paintColors = {
                    { name = "Metallic Black", id = 0 }, { name = "Metallic Graphite Black", id = 1 }, { name = "Metallic Black Steel", id = 2 }, { name = "Metallic Dark Silver", id = 3 }, { name = "Metallic Silver", id = 4 }, { name = "Metallic Blue Silver", id = 5 }, { name = "Metallic Steel Gray", id = 6 }, { name = "Metallic Shadow Silver", id = 7 }, { name = "Metallic Stone Silver", id = 8 }, { name = "Metallic Midnight Silver", id = 9 }, { name = "Metallic Gun Metal", id = 10 }, { name = "Metallic Anthracite Grey", id = 11 }, { name = "Matte Black", id = 12 }, { name = "Matte Gray", id = 13 }, { name = "Matte Light Grey", id = 14 }, { name = "Util Black", id = 15 }, { name = "Util Black Poly", id = 16 }, { name = "Util Dark Silver", id = 17 }, { name = "Util Silver", id = 18 }, { name = "Util Gun Metal", id = 19 }, { name = "Util Shadow Silver", id = 20 }, { name = "Worn Black", id = 21 }, { name = "Worn Graphite", id = 22 }, { name = "Worn Silver Grey", id = 23 }, { name = "Worn Silver", id = 24 }, { name = "Worn Blue Silver", id = 25 }, { name = "Worn Shadow Silver", id = 26 }, { name = "Metallic Red", id = 27 }, { name = "Metallic Torino Red", id = 28 }, { name = "Metallic Formula Red", id = 29 }, { name = "Metallic Blaze Red", id = 30 }, { name = "Metallic Graceful Red", id = 31 }, { name = "Metallic Garnet Red", id = 32 }, { name = "Metallic Desert Red", id = 33 }, { name = "Metallic Cabernet Red", id = 34 }, { name = "Metallic Candy Red", id = 35 }, { name = "Metallic Sunrise Orange", id = 36 }, { name = "Metallic Classic Gold", id = 37 }, { name = "Metallic Orange", id = 38 }, { name = "Matte Red", id = 39 }, { name = "Matte Dark Red", id = 40 }, { name = "Matte Orange", id = 41 }, { name = "Matte Yellow", id = 42 }, { name = "Util Red", id = 43 }, { name = "Util Bright Red", id = 44 }, { name = "Util Garnet Red", id = 45 }, { name = "Worn Red", id = 46 }, { name = "Worn Golden Red", id = 47 }, { name = "Worn Dark Red", id = 48 }, { name = "Metallic Dark Green", id = 49 }, { name = "Metallic Racing Green", id = 50 }, { name = "Metallic Sea Green", id = 51 }, { name = "Metallic Olive Green", id = 52 }, { name = "Metallic Green", id = 53 }, { name = "Metallic Gasoline Blue Green", id = 54 }, { name = "Matte Lime Green", id = 55 }, { name = "Util Dark Green", id = 56 }, { name = "Util Green", id = 57 }, { name = "Worn Dark Green", id = 58 }, { name = "Worn Green", id = 59 }, { name = "Worn Sea Wash", id = 60 }, { name = "Metallic Midnight Blue", id = 61 }, { name = "Metallic Dark Blue", id = 62 },
                { name = "Metallic Saxony Blue", id = 63 }, { name = "Metallic Blue", id = 64 }, { name = "Metallic Mariner Blue", id = 65 }, { name = "Metallic Harbor Blue", id = 66 }, { name = "Metallic Diamond Blue", id = 67 }, { name = "Metallic Surf Blue", id = 68 }, { name = "Metallic Nautical Blue", id = 69 }, { name = "Metallic Bright Blue", id = 70 }, { name = "Metallic Purple Blue", id = 71 }, { name = "Metallic Spinnaker Blue", id = 72 }, { name = "Metallic Ultra Blue", id = 73 }, { name = "Metallic Bright Blue 2", id = 74 }, { name = "Util Dark Blue", id = 75 }, { name = "Util Midnight Blue", id = 76 }, { name = "Util Blue", id = 77 }, { name = "Util Sea Foam Blue", id = 78 }, { name = "Util Lightning Blue", id = 79 }, { name = "Util Maui Blue Poly", id = 80 }, { name = "Util Bright Blue", id = 81 }, { name = "Matte Dark Blue", id = 82 }, { name = "Matte Blue", id = 83 }, { name = "Matte Midnight Blue", id = 84 }, { name = "Worn Dark Blue", id = 85 }, { name = "Worn Blue", id = 86 }, { name = "Worn Light Blue", id = 87 }, { name = "Metallic Taxi Yellow", id = 88 }, { name = "Metallic Race Yellow", id = 89 }, { name = "Metallic Bronze", id = 90 }, { name = "Metallic Yellow Bird", id = 91 }, { name = "Metallic Lime", id = 92 }, { name = "Metallic Champagne", id = 93 }, { name = "Metallic Pueblo Beige", id = 94 }, { name = "Metallic Dark Ivory", id = 95 }, { name = "Metallic Choco Brown", id = 96 }, { name = "Metallic Golden Brown", id = 97 }, { name = "Metallic Light Brown", id = 98 }, { name = "Metallic Straw Beige", id = 99 }, { name = "Metallic Moss Brown", id = 100 },
                { name = "Metallic Biston Brown", id = 101 }, { name = "Metallic Beechwood", id = 102 }, { name = "Metallic Dark Beechwood", id = 103 }, { name = "Metallic Choco Orange", id = 104 }, { name = "Metallic Beach Sand", id = 105 }, { name = "Metallic Sun Bleeched Sand", id = 106 }, { name = "Metallic Cream", id = 107 }, { name = "Util Brown", id = 108 }, { name = "Util Medium Brown", id = 109 }, { name = "Util Light Brown", id = 110 }, { name = "Metallic White", id = 111 }, { name = "Metallic Frost White", id = 112 }, { name = "Worn Honey Beige", id = 113 }, { name = "Worn Brown", id = 114 }, { name = "Worn Dark Brown", id = 115 }, { name = "Worn Straw Beige", id = 116 }, { name = "Brushed Steel", id = 117 }, { name = "Brushed Black Steel", id = 118 }, { name = "Brushed Aluminum", id = 119 }, { name = "Chrome", id = 120 }, { name = "Worn Off White", id = 121 }, { name = "Util Off White", id = 122 }, { name = "Worn Orange", id = 123 }, { name = "Worn Light Orange", id = 124 }, { name = "Metallic Securicor Green", id = 125 }, { name = "Worn Taxi Yellow", id = 126 }, { name = "Police Car Blue", id = 127 }, { name = "Matte Green", id = 128 }, { name = "Matte Brown", id = 129 }, { name = "Worn Orange 2", id = 130 }, { name = "Matte White", id = 131 }, { name = "Worn White", id = 132 }, { name = "Worn Olive Army Green", id = 133 }, { name = "Pure White", id = 134 }, { name = "Hot Pink", id = 135 }, { name = "Salmon Pink", id = 136 }, { name = "Metallic Vermillion Pink", id = 137 }, { name = "Orange", id = 138 }, { name = "Green", id = 139 }, { name = "Blue", id = 140 }, { name = "Metallic Black Blue", id = 141 }, { name = "Metallic Black Purple", id = 142 }, { name = "Metallic Black Red", id = 143 },
                { name = "Hunter Green", id = 144 }, { name = "Metallic Purple", id = 145 }, { name = "Metalic V Dark Blue", id = 146 }, { name = "Modshop Black1", id = 147 }, { name = "Matte Purple", id = 148 }, { name = "Matte Dark Purple", id = 149 }, { name = "Metallic Lava Red", id = 150 }, { name = "Matte Forest Green", id = 151 }, { name = "Matte Olive Drab", id = 152 }, { name = "Matte Desert Brown", id = 153 }, { name = "Matte Desert Tan", id = 154 }, { name = "Matte Foliage Green", id = 155 }, { name = "Default Alloy Color", id = 156 }, { name = "Epsilon Blue", id = 157 }, { name = "Pure Gold", id = 158 }, { name = "Brushed Gold", id = 159 }
                }
                for _, c in ipairs(paintColors) do
                    table.insert(options, { name = c.name, index = c.id })
                end
            elseif submenu == "Pearlescent" then
                local pearls = {
                    { name = "White", id = 111 }, { name = "Black", id = 0 }, { name = "Silver", id = 4 }, { name = "Blue Silver", id = 5 }, { name = "Red", id = 27 }, { name = "Torino Red", id = 28 }, { name = "Formula Red", id = 29 }, { name = "Blaze Red", id = 30 }, { name = "Orange", id = 38 }, { name = "Sunrise Orange", id = 36 }, { name = "Yellow", id = 42 }, { name = "Race Yellow", id = 89 }, { name = "Lime Green", id = 92 }, { name = "Green", id = 53 }, { name = "Dark Green", id = 49 }, { name = "Sea Green", id = 51 }, { name = "Blue", id = 64 }, { name = "Mariner Blue", id = 65 }, { name = "Harbor Blue", id = 66 }, { name = "Diamond Blue", id = 67 }, { name = "Surf Blue", id = 68 }, { name = "Ultra Blue", id = 73 }, { name = "Bright Blue", id = 70 }, { name = "Purple Blue", id = 71 }, { name = "Spinnaker Blue", id = 72 }, { name = "Purple", id = 145 }, { name = "Dark Purple", id = 149 }, { name = "Pony Pink", id = 137 }, { name = "Hot Pink", id = 135 }, { name = "Brown", id = 98 }, { name = "Golden Brown", id = 97 }, { name = "Dark Ivory", id = 95 }, { name = "Straw Beige", id = 99 }, { name = "Cream", id = 107 }
                }
                for _, c in ipairs(pearls) do
                    table.insert(options, { name = c.name, index = c.id })
                end
            end
            SendNUIMessage({
                type = "setModOptions",
                modName = submenu,
                options = options
            })
            return cb('ok')
        end
        -- Paint color application
        if mod == "Primary Color" then
            local _, sec, pearl = GetVehicleColours(veh)
            SetVehicleColours(veh, tonumber(optionIndex), sec)
            refreshVehicle(veh)
            return cb('ok')
        end
        if mod == "Secondary Color" then
            local pri, _, pearl = GetVehicleColours(veh)
            SetVehicleColours(veh, pri, tonumber(optionIndex))
            refreshVehicle(veh)
            return cb('ok')
        end
        if mod == "Pearlescent" then
            local pri, sec, _ = GetVehicleColours(veh)
            SetVehicleExtraColours(veh, tonumber(optionIndex), GetVehicleExtraColours(veh))
            refreshVehicle(veh)
            return cb('ok')
        end
        -- Max Upgrade Button logic
        if mod == "Max Upgrade" and optionIndex == "max_upgrade" then
            -- Apply all max upgrades
            for _, modType in ipairs({11,12,13,15,16,18}) do
                local numMods = GetNumVehicleMods(veh, modType)
                if modType == 18 then
                    ToggleVehicleMod(veh, 18, true) -- Turbo
                elseif numMods > 0 then
                    SetVehicleMod(veh, modType, numMods - 1, false)
                end
            end
            -- Also max armor if available
            if GetNumVehicleMods(veh, 16) > 0 then
                SetVehicleMod(veh, 16, GetNumVehicleMods(veh, 16) - 1, false)
            end
            -- Max engine upgrades
            if GetNumVehicleMods(veh, 11) > 0 then
                SetVehicleMod(veh, 11, GetNumVehicleMods(veh, 11) - 1, false)
            end
            refreshVehicle(veh)
            debugPrint("Applied max upgrades to vehicle!")
            return cb('ok')
        end
        -- Special case 1: Wheel Types (first level selection)
        if mod == "Wheel Types" then
            SetVehicleModKit(veh, 0)
            SetVehicleWheelType(veh, tonumber(optionIndex))
            Citizen.Wait(50)
            local wheelOptions = {}
            local wheelCount = GetNumVehicleMods(veh, 23)
            table.insert(wheelOptions, { name = "Stock", index = -1 })
            for i = 0, wheelCount - 1 do
                local label = GetModTextLabel(veh, 23, i)
                local display = label and GetLabelText(label)
                if display and display ~= "NULL" then
                    table.insert(wheelOptions, { name = display, index = i })
                end
            end
            SendNUIMessage({
                type = "setModOptions",
                modName = "Wheels (" .. wheelTypes[tonumber(optionIndex)] .. ")",
                options = wheelOptions
            })
            debugPrint("Set wheel type to " .. wheelTypes[tonumber(optionIndex)] .. " with " .. #wheelOptions .. " options")
            return cb('ok')
        end
        -- Special case 2: Wheels submenu (second level selection)
        if mod:sub(1, 7) == "Wheels (" or mod:lower():sub(1, 7) == "wheels (" then
            debugPrint("Wheel submenu logic entered for mod: " .. tostring(mod))
            local wheelTypeName = mod:match('%((.-)%)')
            local wheelTypeId = nil
            for id, name in pairs(wheelTypes) do
                if name:lower() == tostring(wheelTypeName):lower() then
                    wheelTypeId = id
                    break
                end
            end
            debugPrint("Trying to apply wheel: wheelTypeName="..tostring(wheelTypeName)..", wheelTypeId="..tostring(wheelTypeId)..", optionIndex="..tostring(optionIndex))
            if wheelTypeId then
                SetVehicleModKit(veh, 0)
                SetVehicleWheelType(veh, wheelTypeId)
                Citizen.Wait(50)
                -- Only apply if the label is valid
                local label = GetModTextLabel(veh, 23, tonumber(optionIndex))
                local display = label and GetLabelText(label)
                if tonumber(optionIndex) == -1 or (display and display ~= "NULL") then
                    SetVehicleMod(veh, 23, tonumber(optionIndex), true)
                    Citizen.Wait(10)
                    SetVehicleMod(veh, 23, tonumber(optionIndex), false)
                    -- Force a more thorough refresh
                    refreshVehicle(veh)
                    -- Force wheel type and mod to reapply after refresh
                    SetVehicleModKit(veh, 0)
                    SetVehicleWheelType(veh, wheelTypeId)
                    SetVehicleMod(veh, 23, tonumber(optionIndex), true)
                    debugPrint("Applied wheel type " .. tostring(wheelTypeName) .. " (" .. tostring(wheelTypeId) .. ") and wheel mod: " .. tostring(optionIndex))
                else
                    debugPrint("Attempted to apply invalid wheel index: " .. tostring(optionIndex) .. ", label: " .. tostring(label) .. ", display: " .. tostring(display))
                end
            else
                debugPrint("Could not resolve wheelTypeId for " .. tostring(wheelTypeName))
            end
            return cb('ok')
        end
        -- Special case 3: Window Tint
        if mod == "Window Tint" then
            -- Apply selected window tint to vehicle
            local tintIndex = tonumber(optionIndex)
            if veh ~= 0 then
                SetVehicleWindowTint(veh, tintIndex)
                refreshVehicle(veh)
                debugPrint("Applied window tint: " .. tostring(tintIndex))
            end
            return cb('ok')
        end
        -- Special case 4: Headlights
        if mod == "Headlights" then
            if type(optionIndex) == "string" and optionIndex:sub(1, 6) == "color:" then
                -- Apply xenon first
                ToggleVehicleMod(veh, 22, true)
                -- Then apply color
                local colorIndex = tonumber(optionIndex:sub(7))
                SetVehicleXenonLightsColor(veh, colorIndex)
                debugPrint("Applied xenon lights with color: " .. colorIndex)
            else
                -- Toggle xenon on/off
                ToggleVehicleMod(veh, 22, tonumber(optionIndex) == 1)
                debugPrint("Toggled xenon lights: " .. tostring(tonumber(optionIndex) == 1))
            end
            -- Refresh vehicle to apply headlight changes
            refreshVehicle(veh)
            return cb('ok')
        end
        -- Special case: Neons
        if mod == "Neons" then
            if optionIndex == "enable_all" then
                local allOn = true
                for i = 0, 3 do
                    if not IsVehicleNeonLightEnabled(veh, i) then
                        allOn = false
                        break
                    end
                end
                local newState = not allOn
                for i = 0, 3 do
                    SetVehicleNeonLightEnabled(veh, i, newState)
                end
                debugPrint((newState and "Enabled" or "Disabled") .. " all neons")
            elseif type(optionIndex) == "string" and optionIndex:sub(1,6) == "color:" then
                local r,g,b = optionIndex:match("color:(%d+),(%d+),(%d+)")
                SetVehicleNeonLightsColour(veh, tonumber(r), tonumber(g), tonumber(b))
                debugPrint("Set neon color to: " .. r .. "," .. g .. "," .. b)
            end
            -- Refresh vehicle to apply neon changes
            refreshVehicle(veh)
            -- Always rebuild and resend the Neons submenu after any neon action
            local options = buildNeonsOptions(veh)
            SendNUIMessage({
                type = "setModOptions",
                modName = "Neons",
                options = options
            })
            debugPrint("Refreshed Neons submenu with " .. #options .. " options")
            return cb('ok')
        end
        -- Regular mods (all other cases)
         local modType = nil
         for k, v in pairs(modNames) do
             if v == mod then
                 modType = k
                 break
             end
         end
        if modType then
            -- Special case: Livery
            if modType == 48 then
                SetVehicleLivery(veh, tonumber(optionIndex))
                refreshVehicle(veh)
                debugPrint("Applied livery: " .. optionIndex)
            -- Special case: Turbo
            elseif modType == 18 then
                ToggleVehicleMod(veh, 18, tonumber(optionIndex) == 0)
                refreshVehicle(veh)
                debugPrint("Toggled turbo: " .. tostring(tonumber(optionIndex) == 0))
            -- All other mods
            else
                SetVehicleMod(veh, modType, tonumber(optionIndex), false)
                refreshVehicle(veh)
                debugPrint("Applied " .. mod .. " mod: " .. optionIndex)
            end
        end
    end
    cb('ok')
end)

-- Monitor if player leaves vehicle and close menu if open
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if menuOpen then
            local ped = PlayerPedId()
            if GetVehiclePedIsIn(ped, false) == 0 then
                SetNuiFocus(false, false)
                SendNUIMessage({ type = "closeMenu" })
                menuOpen = false
                mouseCursorEnabled = false
            end
            -- Force disable cinematic cam while menu is open
            if IsCinematicCamActive() then
                SetCinematicModeActive(false)
            end
        end
    end
end)

-- Controller input to NUI navigation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if menuOpen then
            -- Only handle controller inputs, let NUI handle keyboard/mouse
            
            -- D-Pad Up (controller only)
            if IsControlJustPressed(0, 172) then -- INPUT_CELLPHONE_UP
                SendNUIMessage({ type = 'navigate', direction = 'up' })
            end
            -- D-Pad Down (controller only)
            if IsControlJustPressed(0, 173) then -- INPUT_CELLPHONE_DOWN
                SendNUIMessage({ type = 'navigate', direction = 'down' })
            end
            -- A (Accept) - controller only
            if IsControlJustPressed(0, 191) then -- INPUT_FRONTEND_ACCEPT
                SendNUIMessage({ type = 'navigate', direction = 'accept' })
            end
            -- B (Back) - controller only
            if IsControlJustPressed(0, 194) then -- INPUT_FRONTEND_CANCEL
                SendNUIMessage({ type = 'navigate', direction = 'back' })
                -- Force disable cinematic cam if it gets triggered
                if IsCinematicCamActive() then
                    SetCinematicModeActive(false)
                end
            end
            
            -- Toggle mouse cursor mode with Right Bumper (RB)
            if IsControlJustPressed(0, 45) then -- INPUT_RELOAD (RB)
                mouseCursorEnabled = not mouseCursorEnabled
                SetNuiFocus(true, mouseCursorEnabled)
                local status = mouseCursorEnabled and "enabled" or "disabled"
                TriggerEvent('chat:addMessage', { args = { '^3Mouse cursor '..status..' (RB to toggle)' } })
            end
            
            -- Disable problematic controls while menu is open
            DisableControlAction(0, 199, true) -- INPUT_CINEMATIC_CAM
            DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE
            DisableControlAction(0, 85, true)  -- INPUT_SPECIAL_ABILITY_SECONDARY
            DisableControlAction(0, 37, true)  -- INPUT_SELECT_WEAPON (LB)
            DisableControlAction(0, 25, true)  -- INPUT_AIM
            DisableControlAction(0, 47, true)  -- INPUT_DETONATE
            DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
            DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY
            DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
            DisableControlAction(0, 143, true) -- INPUT_MELEE_BLOCK
            DisableControlAction(0, 75, true)  -- INPUT_VEH_EXIT (F to exit vehicle)
            DisableControlAction(0, 20, true)  -- INPUT_MULTIPLAYER_INFO (Z key)
            DisableControlAction(0, 289, true) -- INPUT_INTERACTION_MENU (M key)
            DisableControlAction(0, 170, true) -- INPUT_REPLAY_MARKER_DELETE
            DisableControlAction(0, 167, true) -- INPUT_PHONE
            DisableControlAction(0, 311, true) -- INPUT_SAVE_REPLAY_CLIP
            DisableControlAction(0, 19, true)  -- INPUT_CHARACTER_WHEEL (Alt)
            
            -- Additional cinematic cam controls to disable
            DisableControlAction(0, 80, true)  -- INPUT_VEH_CIN_CAM
            DisableControlAction(0, 73, true)  -- INPUT_DETONATE (X button - can trigger cinematic)
            
            -- Disable keyboard navigation controls to prevent conflicts
            DisableControlAction(0, 27, true)  -- INPUT_PHONE_UP (Arrow Up)
            DisableControlAction(0, 28, true)  -- INPUT_PHONE_DOWN (Arrow Down)
            DisableControlAction(0, 201, true) -- INPUT_FRONTEND_ACCEPT (Enter)
            DisableControlAction(0, 202, true) -- INPUT_FRONTEND_CANCEL (Escape)
            DisableControlAction(0, 177, true) -- INPUT_FRONTEND_CANCEL (Backspace)
            
            -- Always allow left click for menu navigation
            -- DisableControlAction(0, 24, true)  -- INPUT_ATTACK (Left click) - Keep enabled for menu
            
            -- Don't disable mouse wheel when cursor is disabled (for navigation)
            -- DisableControlAction(0, 14, true)  -- INPUT_WEAPON_WHEEL_NEXT (Mouse wheel up)
            -- DisableControlAction(0, 15, true)  -- INPUT_WEAPON_WHEEL_PREV (Mouse wheel down)
            
            -- Enable camera movement controls (don't disable these)
            -- INPUT_LOOK_LR (1) and INPUT_LOOK_UD (2) are intentionally NOT disabled
            -- INPUT_NEXT_CAMERA (0) is intentionally NOT disabled to allow camera switching
        end
    end
end)

