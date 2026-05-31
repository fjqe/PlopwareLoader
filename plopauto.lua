-- Ensure persistence on server rejoining
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport)
if queue_on_teleport then
    queue_on_teleport([[
        task.wait(5)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/fjqe/PlopwareLoader/refs/heads/main/plopauto.lua"))() -- Host this script on GitHub/Pastebin for seamless looping
    ]])
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local WEBHOOK_URL = "https://discord.com/api/webhooks/1510762145892012032/wznLPHIpfnc6Y4p523iM-C7ZHQCSxFQjk2f8V3m6-FNxJre46Ahw92hPLStyM8ahiYdp"

-- Target Threshold Config
local TARGET_GENERATOR_COUNT = 15

-- Tracking States
local startTime = os.time()
local initialMoney = 0
local initialXP = 0
local generatorsCompleted = 0
local processedGenerators = {} -- Prevents re-interacting with completed assets in the same round

-- Setup Core Stat Locations
local leaderstats = localPlayer:WaitForChild("leaderstats", 15)
local playerData = localPlayer:WaitForChild("PlayerData", 15)

if leaderstats and leaderstats:FindFirstChild("Money") then
    initialMoney = leaderstats.Money.Value
end

-- Determine currently active character profile
local equippedSurvivor = "None"
if playerData and playerData:FindFirstChild("Equipped") and playerData.Equipped:FindFirstChild("Survivor") then
    equippedSurvivor = playerData.Equipped.Survivor.Value
end

if equippedSurvivor ~= "None" and playerData:FindFirstChild("Purchased") and playerData.Purchased:FindFirstChild("Survivors") then
    local survivorXPInstance = playerData.Purchased.Survivors:FindFirstChild(equippedSurvivor)
    if survivorXPInstance then
        initialXP = survivorXPInstance.Value
    end
end

-- HTTP Request Helper
local function sendWebhookNotification(title, description, fields)
    local requestStr = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not requestStr then return end

    local embed = {
        ["title"] = title,
        ["description"] = description,
        ["color"] = 0x1F1F1F, 
        ["fields"] = fields,
        ["footer"] = { ["text"] = "Autofarm Status | By Femini" },
        ["timestamp"] = DateTime.now():ToIsoDate()
    }

    pcall(function()
        requestStr({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ embeds = { embed } })
        })
    end)
end

-- Validation State Checking Routine
local function checkSpectatorState()
    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder and playersFolder:FindFirstChild("Spectating") then
        if playersFolder.Spectating:FindFirstChild(localPlayer.Name) then
            return true
        end
    end
    return false
end

-- Generator Core Iteration Sequence (Restricted to Ingame folder)
local function sweepIngameGenerators()
    local ingameFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
    if not ingameFolder then return end

    local generators = {}
    for _, item in ipairs(ingameFolder:GetDescendants()) do
        if item.Name == "Generator" and (item:IsA("Model") or item:IsA("Folder")) then
            -- Only insert if it hasn't been handled already this match round
            if not processedGenerators[item] then
                table.insert(generators, item)
            end
        end
    end

    for _, gen in ipairs(generators) do
        -- Hard-stop execution instantly if target goal is met mid-sweep
        if generatorsCompleted >= TARGET_GENERATOR_COUNT then break end

        local character = localPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end

        local positionsFolder = gen:FindFirstChild("Positions")
        local centerPart = positionsFolder and positionsFolder:FindFirstChild("Center")
        local mainPart = gen:FindFirstChild("Main")
        local prompt = mainPart and mainPart:FindFirstChild("Prompt")
        local remotesFolder = gen:FindFirstChild("Remotes")
        local remoteEvent = remotesFolder and remotesFolder:FindFirstChild("RE")

        if centerPart and mainPart and prompt and remoteEvent then
            processedGenerators[gen] = true -- Lock target asset node
            
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.CFrame = centerPart.CFrame
            task.wait(0.25)

            if fireproximityprompt then
                fireproximityprompt(prompt)
            else
                prompt:InputBegan(Enum.UserInputType.Keyboard)
                task.wait(prompt.HoldDuration + 0.05)
                prompt:InputEnded(Enum.UserInputType.Keyboard)
            end
            
            task.wait(0.15)
            
            pcall(function()
                remoteEvent:FireServer()
            end)
            
            generatorsCompleted = generatorsCompleted + 1
            print("[By Femini] Generator progress: " .. tostring(generatorsCompleted) .. "/" .. tostring(TARGET_GENERATOR_COUNT))
            task.wait(0.5)
        end
    end
end

-- Main Loop Automation System
task.spawn(function()
    print("[By Femini] Gated counter engine deployed. Target quota set to: " .. tostring(TARGET_GENERATOR_COUNT))
    
    while generatorsCompleted < TARGET_GENERATOR_COUNT do
        local isSpectating = checkSpectatorState()
        local mapReady = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
        
        if not isSpectating and mapReady then
            sweepIngameGenerators()
        else
            -- If map unloads or disappears, clear our tracking history table for the upcoming round layout
            if not mapReady then
                table.clear(processedGenerators)
            end
            task.wait(2)
        end
        task.wait(1)
    end

    print("[By Femini] Target quota fulfilled. Compiling session metrics...")

    -- Phase 2: Compute final session statistics
    local elapsedTime = os.time() - startTime
    local currentMoney = leaderstats and leaderstats:FindFirstChild("Money") and leaderstats.Money.Value or initialMoney
    local moneyGained = currentMoney - initialMoney

    local currentXP = initialXP
    if equippedSurvivor ~= "None" and playerData:FindFirstChild("Purchased") then
        local xpInst = playerData.Purchased.Survivors:FindFirstChild(equippedSurvivor)
        if xpInst then currentXP = xpInst.Value end
    end
    local xpGained = currentXP - initialXP

    local minutes = math.floor(elapsedTime / 60)
    local seconds = elapsedTime % 60
    local runtimeString = string.format("%dm %ds", minutes, seconds)

    -- Dispatch Discord Metrics
    sendWebhookNotification(
        "🏆 Target Quota Reached — Cycling Server Instance",
        "Autofarm engine successfully hit the complete batch threshold requirement.",
        {
            { ["name"] = "User Profile", ["value"] = "`" .. localPlayer.Name .. "`", ["inline"] = true },
            { ["name"] = "Session Run Time", ["value"] = "`" .. runtimeString .. "`", ["inline"] = true },
            { ["name"] = "Generators Cleared", ["value"] = "`" .. tostring(generatorsCompleted) .. "/" .. tostring(TARGET_GENERATOR_COUNT) .. "`", ["inline"] = true },
            { ["name"] = "Active Character Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true },
            { ["name"] = "Currency Obtained", ["value"] = "`+" .. tostring(moneyGained) .. " Cash`", ["inline"] = true },
            { ["name"] = "Character Experience Gained", ["value"] = "`+" .. tostring(xpGained) .. " XP`", ["inline"] = true }
        }
    )

    -- Phase 3: Initiate Safe Server Jump Sequence
    task.wait(2)
    print("[By Femini] Jump parameters verified. Moving to clean server...")
    
    pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
end)
