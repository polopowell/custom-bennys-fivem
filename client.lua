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
    print("^3[BENNYS DEBUG] ^7" .. message)
    TriggerEvent('chat:addMessage', { args = { '^3[BENNYS] ^7' .. message } })
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
        -- Always set mod kit at the very beginning to ensure we detect all mods
        SetVehicleModKit(veh, 0)
        Citizen.Wait(10) -- Small wait to ensure mod kit is applied
        
        -- Extra debug: print vehicle entity and model
        debugPrint("Opening Benny's for vehicle: " .. tostring(veh) .. ", model: " .. tostring(GetEntityModel(veh)))
        local mods = {}

        -- First, add wheel types selection
        table.insert(mods, "Wheel Types")

        -- Add all available mods for this specific vehicle
        for modType, modName in pairs(modNames) do
            if modType == 48 then -- Livery (special case)
                local liveryCount = GetVehicleLiveryCount(veh)
                if liveryCount > 0 then
                    table.insert(mods, modName)
                end
            elseif modType == 22 then -- Headlights/Xenons (special case)
                table.insert(mods, modName) -- Always available
            elseif modType == 23 then -- Wheels (special case)
                -- We handle wheels via the Wheel Types entry
                -- Don't add to menu directly
            elseif GetNumVehicleMods(veh, modType) > 0 then
                table.insert(mods, modName)
            end
        end

        -- Add window tint options (always available)
        table.insert(mods, "Window Tint")
        -- Add Neons to the menu
        table.insert(mods, "Neons")
        
        SendNUIMessage({
            type = "setMods",
            mods = mods
        })

        SetNuiFocus(true, false)
        menuOpen = true
        mouseCursorEnabled = false
        
        debugPrint("Opened Benny's with " .. #mods .. " available mod types")
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
    local neonColors = {
        { name = "White", rgb = "255,255,255" },
        { name = "Red", rgb = "255,0,0" },
        { name = "Blue", rgb = "0,0,255" },
        { name = "Green", rgb = "0,255,0" },
        { name = "Yellow", rgb = "255,255,0" },
        { name = "Orange", rgb = "255,128,0" },
        { name = "Purple", rgb = "128,0,255" },
        { name = "Pink", rgb = "255,0,255" },
        { name = "Mint", rgb = "50,255,155" },
        { name = "Golden Shower", rgb = "204,204,0" },
        { name = "Electric Blue", rgb = "0,150,255" },
        { name = "Lime Green", rgb = "128,255,0" },
        { name = "Hot Pink", rgb = "255,50,128" }
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
        -- Special case: Wheel Types menu
        if mod == "Wheel Types" then
            for typeId, typeName in pairs(wheelTypes) do
                -- Only add wheel types that actually have wheels for this vehicle
                SetVehicleWheelType(veh, typeId)
                if GetNumVehicleMods(veh, 23) > 0 then
                    table.insert(options, { name = typeName, index = typeId })
                end
            end
            
            -- Reset to Sport wheels after checking
            SetVehicleWheelType(veh, 0)
        -- Special case: Window Tint
        elseif mod == "Window Tint" then
            local tints = {
                { name = "None", index = 0 },
                { name = "Pure Black", index = 1 },
                { name = "Darksmoke", index = 2 },
                { name = "Lightsmoke", index = 3 },
                { name = "Limo", index = 4 },
                { name = "Green", index = 5 }
            }
            options = tints
        -- Special case: Headlights
        elseif mod == "Headlights" then
            table.insert(options, { name = "Stock Lights", index = -1 })
            table.insert(options, { name = "Xenon Lights", index = 1 })
            
            -- Add headlight colors if xenon is enabled
            local colors = {
                { name = "White", index = 0 },
                { name = "Blue", index = 1 },
                { name = "Electric Blue", index = 2 },
                { name = "Mint Green", index = 3 },
                { name = "Lime Green", index = 4 },
                { name = "Yellow", index = 5 },
                { name = "Golden Shower", index = 6 },
                { name = "Orange", index = 7 },
                { name = "Red", index = 8 },
                { name = "Pony Pink", index = 9 },
                { name = "Hot Pink", index = 10 },
                { name = "Purple", index = 11 },
                { name = "Blacklight", index = 12 }
            }
            
            for _, color in ipairs(colors) do
                table.insert(options, { name = color.name .. " Xenon", index = "color:" .. color.index })
            end
        -- Special case: Neons
        elseif mod == "Neons" then
            options = buildNeonsOptions(veh)
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
        -- Special case 1: Wheel Types (first level selection)
        if mod == "Wheel Types" then
            SetVehicleWheelType(veh, tonumber(optionIndex))
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
                SetVehicleWheelType(veh, wheelTypeId)
                Citizen.Wait(50) -- Ensure wheel type is set before applying mod
                -- Only apply if the label is valid
                local label = GetModTextLabel(veh, 23, tonumber(optionIndex))
                local display = label and GetLabelText(label)
                if tonumber(optionIndex) == -1 or (display and display ~= "NULL") then
                    -- Try with custom wheels first (true)
                    SetVehicleMod(veh, 23, tonumber(optionIndex), true)
                    -- Also try with non-custom wheels (false) as fallback
                    Citizen.Wait(10)
                    SetVehicleMod(veh, 23, tonumber(optionIndex), false)
                    
                    -- Force a more thorough refresh
                    refreshVehicle(veh)
                    -- Force refresh wheels specifically
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
            SetVehicleWindowTint(veh, tonumber(optionIndex))
            refreshVehicle(veh)
            -- Force refresh by rolling windows
            RollDownWindow(veh, 0)
            RollDownWindow(veh, 1)
            Citizen.Wait(50)
            RollUpWindow(veh, 0)
            RollUpWindow(veh, 1)
            debugPrint("Applied window tint: " .. optionIndex)
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
                debugPrint("Applied livery: " .. optionIndex)
            -- Special case: Turbo
            elseif modType == 18 then
                ToggleVehicleMod(veh, 18, tonumber(optionIndex) == 0)
                debugPrint("Toggled turbo: " .. tostring(tonumber(optionIndex) == 0))
            -- All other mods
            else
                SetVehicleMod(veh, modType, tonumber(optionIndex), false)
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

