-- Step 1: Pre-cache persistence script for seamless execution transitions
local queue_on_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
if queue_on_teleport then
    pcall(function()
        queue_on_teleport([[
            task.wait(6)
            print("[Plopware] Reloading loader execution script...")
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

-- Target Parameters
local TARGET_GENERATOR_COUNT = 15

-- Global Session Variables
local startTime = os.time()
local initialMoney = 0
local initialXP = 0
local generatorsCompleted = 0
local processedGenerators = {}

print("[DEBUG] Script initialized. Waiting for baseline game data components...")

-- ==========================================
-- WEBHOOK TRANSMISSION ENGINE
-- ==========================================
local function sendWebhookNotification(title, description, colorCode, fields)
    local requestStr = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not requestStr then 
        warn("[Webhook Warning] Executor lacks an HTTP request function.")
        return 
    end

    local payload = HttpService:JSONEncode({
        ["embeds"] = {
            {
                ["title"] = title,
                ["description"] = description,
                ["color"] = colorCode, 
                ["fields"] = fields,
                ["footer"] = { ["text"] = "Plopware Analytics Engine V3 | By Femini" },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
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
    
    if success then
        print("[DEBUG] Webhook payload successfully transmitted: " .. title)
    else
        warn("[Webhook Error] Transaction failure: " .. tostring(response))
    end
end

-- ==========================================
-- SAFE DATA INITIALIZATION PIPELINE
-- ==========================================
local leaderstats = localPlayer:WaitForChild("leaderstats", 25)
local playerData = localPlayer:WaitForChild("PlayerData", 25)

if leaderstats then
    local moneyObj = leaderstats:WaitForChild("Money", 10)
    initialMoney = moneyObj and moneyObj.Value or 0
    print("[DEBUG] Baseline Money logged: " .. tostring(initialMoney))
else
    warn("[DEBUG] leaderstats failed to load within time envelope.")
end

local equippedSurvivor = "None"
if playerData then
    local equippedFolder = playerData:WaitForChild("Equipped", 10)
    local survivorObj = equippedFolder and equippedFolder:WaitForChild("Survivor", 5)
    equippedSurvivor = survivorObj and survivorObj.Value or "None"
    print("[DEBUG] Baseline Active Profile: " .. tostring(equippedSurvivor))
end

if equippedSurvivor ~= "None" and playerData then
    pcall(function()
        local purchasedFolder = playerData:FindFirstChild("Purchased")
        local survivorsFolder = purchasedFolder and purchasedFolder:FindFirstChild("Survivors")
        local xpObj = survivorsFolder and survivorsFolder:FindFirstChild(equippedSurvivor)
        initialXP = xpObj and xpObj.Value or 0
        print("[DEBUG] Baseline XP logged: " .. tostring(initialXP))
    end)
end

-- 🚀 TRIGGER: STARTUP WEBHOOK
sendWebhookNotification(
    "🚀 Autofarm Session Initiated",
    "A new server instance has been joined and the script has successfully attached.",
    4321431, -- Neon Green Color
    {
        { ["name"] = "Account Identity", ["value"] = "||`" .. localPlayer.Name .. "`||", ["inline"] = true },
        { ["name"] = "Target Quota", ["value"] = "`" .. tostring(TARGET_GENERATOR_COUNT) .. " Generators`", ["inline"] = true },
        { ["name"] = "Starting Cash", ["value"] = "`$" .. tostring(initialMoney) .. "`", ["inline"] = true },
        { ["name"] = "Active Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true },
        { ["name"] = "Starting XP", ["value"] = "`" .. tostring(initialXP) .. " XP`", ["inline"] = true }
    }
)

-- ==========================================
-- CORE AUTOMATION MECHANICS
-- ==========================================

local function checkSpectatorState()
    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder and playersFolder:FindFirstChild("Spectating") then
        if playersFolder.Spectating:FindFirstChild(localPlayer.Name) then
            return true
        end
    end
    return false
end

local function getValidCharacterPart()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 10)
    return rootPart
end

local function sweepIngameGenerators()
    local mapFolder = Workspace:FindFirstChild("Map")
    local ingameFolder = mapFolder and mapFolder:FindFirstChild("Ingame")
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

        local rootPart = getValidCharacterPart()
        if not rootPart then continue end

        local positionsFolder = gen:FindFirstChild("Positions")
        local centerPart = positionsFolder and positionsFolder:FindFirstChild("Center")
        local mainPart = gen:FindFirstChild("Main")
        local prompt = mainPart and mainPart:FindFirstChild("Prompt")
        local remotesFolder = gen:FindFirstChild("Remotes")
        local remoteEvent = remotesFolder and remotesFolder:FindFirstChild("RE")

        if centerPart and mainPart and prompt and remoteEvent then
            processedGenerators[gen] = true 

            -- Hard anchor to bypass distance checks
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.CFrame = centerPart.CFrame
            rootPart.Anchored = true 
            task.wait(0.4) 

            pcall(function()
                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    prompt:InputBegan(Enum.UserInputType.Keyboard)
                    task.wait(prompt.HoldDuration + 0.05)
                    prompt:InputEnded(Enum.UserInputType.Keyboard)
                end
            end)
            
            task.wait(0.2) 
            
            pcall(function()
                remoteEvent:FireServer()
            end)
            
            rootPart.Anchored = false 
            generatorsCompleted = generatorsCompleted + 1
            print("[Plopware] Checked Task Node: " .. tostring(generatorsCompleted) .. "/" .. tostring(TARGET_GENERATOR_COUNT))
            task.wait(0.5)
        end
    end
end

-- ==========================================
-- MAIN EXECUTION THREAD
-- ==========================================
task.spawn(function()
    print("[Plopware] Main execution loop thread established.")
    
    while generatorsCompleted < TARGET_GENERATOR_COUNT do
        local isSpectating = checkSpectatorState()
        local mapFolder = Workspace:FindFirstChild("Map")
        local mapReady = mapFolder and mapFolder:FindFirstChild("Ingame")
        
        if not isSpectating and mapReady then
            sweepIngameGenerators()
        else
            if not mapReady then
                table.clear(processedGenerators)
            end
            task.wait(3)
        end
        task.wait(1)
    end

    print("[Plopware] Objective target numbers satisfied. Compiling metrics data structures...")

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

    -- 🏆 TRIGGER: COMPLETION WEBHOOK
    sendWebhookNotification(
        "🏆 Session Performance Analytics Summary",
        "Target execution cycle threshold successfully logged and verified.",
        16728320, -- Vivid Orange-Red Accent
        {
            { ["name"] = "Account Identity", ["value"] = "||`" .. localPlayer.Name .. "`||", ["inline"] = true },
            { ["name"] = "Duration Elapsed", ["value"] = "`" .. runtimeString .. "`", ["inline"] = true },
            { ["name"] = "Objective Total", ["value"] = "`" .. tostring(generatorsCompleted) .. " Generators`", ["inline"] = true },
            { ["name"] = "Active Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true },
            { ["name"] = "Session Revenue", ["value"] = "`+$" .. tostring(moneyGained) .. " Cash`", ["inline"] = true },
            { ["name"] = "Experience Gained", ["value"] = "`+" .. tostring(xpGained) .. " XP`", ["inline"] = true }
        }
    )

    -- Teleport Cycle Launch
    task.wait(2)
    print("[Plopware] Transferring current client session down a clean server pipeline.")
    pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
end)
