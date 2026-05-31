-- Ensure persistence on server rejoining
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport)
if queue_on_teleport then
    queue_on_teleport([[
        task.wait(5)
        loadstring(game:HttpGet("YOUR_HOSTED_SCRIPT_URL_HERE"))() -- Recommendation: Host this script on GitHub/Pastebin for seamless looping
    ]])
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local WEBHOOK_URL = "https://discord.com/api/webhooks/1510751060816302154/v8PSzGnoD5tAXfSdoWL8wc5uKKVfuH9TjPXBIOskEOzNFYjr4ew9Bdl-yp-fLZSeCSF7"

-- Tracking States
local startTime = os.time()
local initialMoney = 0
local initialXP = 0
local generatorsCompleted = 0

-- Setup Core Stat Locations (Referencing image_6d4ab7.png, image_6d4b37.png, image_6d527d.png)
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
        ["color"] = 0x1F1F1F, -- Sleek charcoal tone
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

-- Validation State Checking Routine (Referencing image_6d4e7a.png)
local function checkSpectatorState()
    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder and playersFolder:FindFirstChild("Spectating") then
        if playersFolder.Spectating:FindFirstChild(localPlayer.Name) then
            return true
        end
    end
    return false
end

-- Generator Core Iteration Sequence (Restricted to Ingame folder via image_6d4a3b.png)
local function sweepIngameGenerators()
    -- Confines discovery purely within Workspace.Map.Ingame per image_6d4a3b.png
    local ingameFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
    if not ingameFolder then return end

    local generators = {}
    for _, item in ipairs(ingameFolder:GetDescendants()) do
        if item.Name == "Generator" and (item:IsA("Model") or item:IsA("Folder")) then
            table.insert(generators, item)
        end
    end

    for _, gen in ipairs(generators) do
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
            -- Execution adjustments to handle physics replication safely
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.CFrame = centerPart.CFrame
            task.wait(0.2)

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
            task.wait(0.4)
        end
    end
end

-- Main Loop Automation System
task.spawn(function()
    print("[By Femini] Monitoring system deployed.")
    
    -- Phase 1: Wait until you are out of spectators and loaded inside the round map
    while checkSpectatorState() or not (Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")) do
        print("[By Femini] Awaiting round initialization / Currently spectating...")
        task.wait(2)
    end

    print("[By Femini] Ingame match discovered. Commencing objective sweep.")
    task.wait(1) -- Safety buffer for environment rendering
    
    sweepIngameGenerators()

    -- Phase 2: Compute session statistics to report data via Discord
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
        "✨ Cycle Complete — Match Summary",
        "Autofarm successfully cleared active tasks inside the `Ingame` folder layout.",
        {
            { ["name"] = "User Profile", ["value"] = "`" .. localPlayer.Name .. "`", ["inline"] = true },
            { ["name"] = "Session Elapsed Time", ["value"] = "`" .. runtimeString .. "`", ["inline"] = true },
            { ["name"] = "Generators Cleared", ["value"] = "`" .. tostring(generatorsCompleted) .. "`", ["inline"] = true },
            { ["name"] = "Active Character Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true },
            { ["name"] = "Currency Obtained", ["value"] = "`+" .. tostring(moneyGained) .. " Cash`", ["inline"] = true },
            { ["name"] = "Character Experience Gained", ["value"] = "`+" .. tostring(xpGained) .. " XP`", ["inline"] = true }
        }
    )

    -- Phase 3: Paced Rejoin Automation Loop
    task.wait(3)
    print("[By Femini] Cycling servers to begin next farm run...")
    
    pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
end)
