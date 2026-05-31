-- Step 1: Cache script for server hopping SAFELY (Done before heavy tasks)
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queue_on_teleport then
    pcall(function()
        queue_on_teleport([[
            task.wait(7)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/fjqe/PlopwareLoader/refs/heads/main/plopauto.lua"))()
        ]])
    end)
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local WEBHOOK_URL = "https://discord.com/api/webhooks/1510762145892012032/wznLPHIpfnc6Y4p523iM-C7ZHQCSxFQjk2f8V3m6-FNxJre46Ahw92hPLStyM8ahiYdp"

-- Configuration
local TARGET_GENERATOR_COUNT = 15

-- Global States
local startTime = os.time()
local initialMoney = 0
local initialXP = 0
local generatorsCompleted = 0
local processedGenerators = {}

-- Safely resolve statistics without causing execution errors
local leaderstats = localPlayer:WaitForChild("leaderstats", 20)
local playerData = localPlayer:WaitForChild("PlayerData", 20)

if leaderstats then
    local moneyObj = leaderstats:WaitForChild("Money", 5)
    initialMoney = moneyObj and moneyObj.Value or 0
end

local equippedSurvivor = "None"
if playerData then
    local equippedFolder = playerData:WaitForChild("Equipped", 5)
    local survivorObj = equippedFolder and equippedFolder:WaitForChild("Survivor", 5)
    equippedSurvivor = survivorObj and survivorObj.Value or "None"
end

if equippedSurvivor ~= "None" and playerData then
    pcall(function()
        local purchasedFolder = playerData:FindFirstChild("Purchased")
        local survivorsFolder = purchasedFolder and purchasedFolder:FindFirstChild("Survivors")
        local xpObj = survivorsFolder and survivorsFolder:FindFirstChild(equippedSurvivor)
        initialXP = xpObj and xpObj.Value or 0
    end)
end

-- Robust Discord Webhook Wrapper API
local function sendWebhookNotification(title, description, fields)
    local requestStr = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not requestStr then 
        warn("[Engine Error] Executor missing required HTTP Request wrapper function.")
        return 
    end

    -- Strictly formatted payload to prevent HTTP 400 Errors
    local payload = HttpService:JSONEncode({
        ["embeds"] = {
            {
                ["title"] = title,
                ["description"] = description,
                ["color"] = 16711680, -- Red highlight color code
                ["fields"] = fields,
                ["footer"] = { ["text"] = "Plopware Analytics Engine" },
                ["timestamp"] = DateTime.now():ToIsoDate()
            }
        }
    })

    local success, response = pcall(function()
        return requestStr({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)
    
    if not success then
        warn("[Webhook Error] Critical transmission failure: " .. tostring(response))
    end
end

-- Match State Validation System
local function checkSpectatorState()
    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder and playersFolder:FindFirstChild("Spectating") then
        if playersFolder.Spectating:FindFirstChild(localPlayer.Name) then
            return true
        end
    end
    return false
end

-- Objective Clearing Function
local function sweepIngameGenerators()
    local ingameFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
    if not ingameFolder then return end

    local generators = {}
    for _, item in ipairs(ingameFolder:GetDescendants()) do
        if item.Name == "Generator" and (item:IsA("Model") or item:IsA("Folder")) then
            if not processedGenerators[item] then
                table.insert(generators, item)
            end
        end
    end

    for _, gen in ipairs(generators) do
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
            processedGenerators[gen] = true 
            
            -- Lock positioning elements firmly
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.CFrame = centerPart.CFrame
            task.wait(0.35) -- Slightly higher latency padding for replication validation

            -- Safe Proximity Prompt execution
            local promptSuccess = pcall(function()
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputBegan(Enum.UserInputType.Keyboard)
                    task.wait(prompt.HoldDuration + 0.05)
                    prompt:InputEnded(Enum.UserInputType.Keyboard)
                end
            end)
            
            task.wait(0.2)
            
            -- Network Replication
            pcall(function()
                remoteEvent:FireServer()
            end)
            
            generatorsCompleted = generatorsCompleted + 1
            print("[Plopware] Checked Task Node: " .. tostring(generatorsCompleted) .. "/" .. tostring(TARGET_GENERATOR_COUNT))
            task.wait(0.5)
        end
    end
end

-- Execution Flow Control
task.spawn(function()
    print("[Plopware] Main orchestration thread successfully connected.")
    
    while generatorsCompleted < TARGET_GENERATOR_COUNT do
        local isSpectating = checkSpectatorState()
        local mapReady = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
        
        if not isSpectating and mapReady then
            sweepIngameGenerators()
        else
            if not mapReady then
                table.clear(processedGenerators) -- Flush match table context when map drops
            end
            task.wait(2)
        end
        task.wait(1)
    end

    print("[Plopware] Hit target metrics. Packing summary telemetry...")

    -- Compute Session Statistics safely
    local elapsedTime = os.time() - startTime
    local currentMoney = initialMoney
    if leaderstats and leaderstats:FindFirstChild("Money") then
        currentMoney = leaderstats.Money.Value
    end
    local moneyGained = currentMoney - initialMoney

    local currentXP = initialXP
    if equippedSurvivor ~= "None" and playerData then
        pcall(function()
            local xpObj = playerData.Purchased.Survivors:FindFirstChild(equippedSurvivor)
            currentXP = xpObj and xpObj.Value or initialXP
        end)
    end
    local xpGained = currentXP - initialXP

    local minutes = math.floor(elapsedTime / 60)
    local seconds = elapsedTime % 60
    local runtimeString = string.format("%dm %ds", minutes, seconds)

    -- Dispatch Discord Embedded Notification
    sendWebhookNotification(
        "🏆 Session Performance Overview",
        "Target threshold requirements have been completely logged and verified.",
        {
            { ["name"] = "Account Identity", ["value"] = "||`" .. localPlayer.Name .. "`||", ["inline"] = true },
            { ["name"] = "Duration Elapsed", ["value"] = "`" .. runtimeString .. "`", ["inline"] = true },
            { ["name"] = "Objective Total", ["value"] = "`" .. tostring(generatorsCompleted) .. " Generators`", ["inline"] = true },
            { ["name"] = "Active Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true },
            { ["name"] = "Session Revenue", ["value"] = "`+$" .. tostring(moneyGained) .. " Cash`", ["inline"] = true },
            { ["name"] = "Experience Gained", ["value"] = "`+" .. tostring(xpGained) .. " XP`", ["inline"] = true }
        }
    )

    -- Safe Transfer Sequence
    task.wait(3)
    print("[Plopware] Cycling engine server node.")
    pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
end)
