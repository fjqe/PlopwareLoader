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
local GENERATORS_PER_CYCLE = 5
local TARGET_CYCLES = 3
local TOTAL_TARGET = GENERATORS_PER_CYCLE * TARGET_CYCLES

-- Global Session Variables
local startTime = os.time()
local initialMoney = 0
local initialXP = 0
local totalGeneratorsCompleted = 0
local processedGenerators = {}

print("[DEBUG] Script initialized. Parsing game data tree...")

-- ==========================================
-- WEBHOOK TRANSMISSION ENGINE
-- ==========================================
local function sendWebhookNotification(title, description, colorCode, fields)
    local requestStr = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
    if not requestStr then return end

    local payload = HttpService:JSONEncode({
        ["embeds"] = {
            {
                ["title"] = title,
                ["description"] = description,
                ["color"] = colorCode, 
                ["fields"] = fields,
                ["footer"] = { ["text"] = "Plopware Analytics Engine V5.2" },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    })

    pcall(function()
        requestStr({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)
end

-- ==========================================
-- DATA EXTRACTION PIPELINE (Verified Structure)
-- ==========================================
pcall(function()
    local leaderstats = localPlayer:WaitForChild("leaderstats", 15)
    if leaderstats then
        local moneyObj = leaderstats:WaitForChild("Money", 5)
        if moneyObj then initialMoney = moneyObj.Value end
    end
end)

local equippedSurvivor = "None"
pcall(function()
    local playerData = localPlayer:WaitForChild("PlayerData", 15)
    if playerData then
        local equippedFolder = playerData:WaitForChild("Equipped", 5)
        local survivorObj = equippedFolder and equippedFolder:WaitForChild("Survivor", 5)
        if survivorObj then equippedSurvivor = survivorObj.Value end
        
        if equippedSurvivor ~= "None" then
            local purchasedFolder = playerData:WaitForChild("Purchased", 5)
            local survivorsFolder = purchasedFolder and purchasedFolder:WaitForChild("Survivors", 5)
            local xpObj = survivorsFolder and survivorsFolder:WaitForChild(equippedSurvivor, 5)
            if xpObj then initialXP = xpObj.Value end
        end
    end
end)

-- Send initial startup log
sendWebhookNotification(
    "🚀 Autofarm Session Initiated",
    "Connected to instance. Sequential round-farming engine activated.",
    4321431, -- Neon Green
    {
        { ["name"] = "Account Identity", ["value"] = "||`" .. localPlayer.Name .. "`||", ["inline"] = true },
        { ["name"] = "Target Target", ["value"] = "`" .. tostring(TARGET_CYCLES) .. " Rounds (" .. tostring(TOTAL_TARGET) .. " Nodes)`", ["inline"] = true },
        { ["name"] = "Starting Cash", ["value"] = "`$" .. tostring(initialMoney) .. "`", ["inline"] = true },
        { ["name"] = "Active Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true }
    }
)

-- ==========================================
-- CORE UTILITIES
-- ==========================================
local function checkSpectatorState()
    local playersFolder = Workspace:FindFirstChild("Players")
    return playersFolder and playersFolder:FindFirstChild("Spectating") and playersFolder.Spectating:FindFirstChild(localPlayer.Name) ~= nil
end

local function getValidCharacterPart()
    local character = localPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getUnprocessedGenerators()
    local mapFolder = Workspace:FindFirstChild("Map")
    local ingameFolder = mapFolder and mapFolder:FindFirstChild("Ingame")
    if not ingameFolder then return {} end
    
    local list = {}
    for _, item in ipairs(ingameFolder:GetDescendants()) do
        if item.Name == "Generator" and (item:IsA("Model") or item:IsA("Folder")) then
            if not processedGenerators[item] then
                table.insert(list, item)
            end
        end
    end
    return list
end

-- ==========================================
-- CYCLICALfarming ENGINE EXECUTION
-- ==========================================
task.spawn(function()
    local currentCycle = 1
    local completedInCurrentCycle = 0

    while currentCycle <= TARGET_CYCLES do
        local isSpectating = checkSpectatorState()
        local availableGenerators = getUnprocessedGenerators()
        
        if not isSpectating and #availableGenerators > 0 then
            local targetGen = availableGenerators[1]
            processedGenerators[targetGen] = true -- Lock target node memory
            
            local rootPart = getValidCharacterPart()
            if rootPart then
                local centerPart = targetGen:FindFirstChild("Positions") and targetGen.Positions:FindFirstChild("Center")
                local mainPart = targetGen:FindFirstChild("Main")
                local prompt = mainPart and mainPart:FindFirstChild("Prompt")
                local remoteEvent = targetGen:FindFirstChild("Remotes") and targetGen.Remotes:FindFirstChild("RE")

                if centerPart and prompt and remoteEvent then
                    completedInCurrentCycle = completedInCurrentCycle + 1
                    totalGeneratorsCompleted = totalGeneratorsCompleted + 1
                    print("[Plopware] Target Found: Node [" .. tostring(completedInCurrentCycle) .. "/5] | Round [" .. tostring(currentCycle) .. "/3]")
                    
                    -- Anti-Cheat Bypass: Teleport to a realistic interaction side location
                    rootPart.Velocity = Vector3.new(0, 0, 0)
                    local sideOffsetCFrame = centerPart.CFrame * CFrame.new(0, -0.5, 3.8)
                    rootPart.CFrame = CFrame.lookAt(sideOffsetCFrame.Position, centerPart.Position)
                    rootPart.Anchored = true
                    
                    -- Critical: Allow the physics state engine to register placement vectors
                    task.wait(0.6) 

                    -- Expand local client activation bounds
                    prompt.RequiresLineOfSight = false 
                    prompt.MaxActivationDistance = 100
                    
                    pcall(function()
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputBegan(Enum.UserInputType.Keyboard)
                            task.wait(prompt.HoldDuration + 0.05)
                            prompt:InputEnded(Enum.UserInputType.Keyboard)
                        end
                    end)
                    
                    task.wait(0.25)
                    pcall(function() remoteEvent:FireServer() end)
                    task.wait(0.25)
                    
                    rootPart.Anchored = false
                    
                    -- Cycle transition management
                    if completedInCurrentCycle >= GENERATORS_PER_CYCLE then
                        print("[Plopware] Round complete. Waiting for server to cycle maps...")
                        currentCycle = currentCycle + 1
                        completedInCurrentCycle = 0
                        
                        -- Wait dynamically for the current map instance to drop and reload
                        repeat task.wait(1) until not Workspace.Map:FindFirstChild("Ingame")
                        table.clear(processedGenerators) -- Clear past round references
                        repeat task.wait(1) until Workspace.Map:FindFirstChild("Ingame")
                        
                        print("[Plopware] Clean game round detected. Loading next target sequence...")
                        task.wait(3) -- Map initialization buffer delay
                    end
                end
            end
        else
            -- Maintain cache clearance if server resets objects prematurely
            if not Workspace.Map:FindFirstChild("Map") or not Workspace.Map.Map:FindFirstChild("Ingame") then
                table.clear(processedGenerators)
            end
            task.wait(1.5)
        end
        task.wait(0.5)
    end

    -- ==========================================
    -- DISPATCH TELEMETRY & SERVER HOP
    -- ==========================================
    print("[Plopware] Run requirements complete. Processing final tracking nodes...")

    local elapsedTime = os.time() - startTime
    local currentMoney = initialMoney
    pcall(function()
        local leaderstats = localPlayer:FindFirstChild("leaderstats")
        local moneyObj = leaderstats and leaderstats:FindFirstChild("Money")
        if moneyObj then currentMoney = moneyObj.Value end
    end)
    local moneyGained = currentMoney - initialMoney

    local currentXP = initialXP
    pcall(function()
        local playerData = localPlayer:FindFirstChild("PlayerData")
        local xpObj = playerData and playerData.Purchased.Survivors:FindFirstChild(equippedSurvivor)
        if xpObj then currentXP = xpObj.Value end
    end)
    local xpGained = currentXP - initialXP

    local runtimeString = string.format("%dm %ds", math.floor(elapsedTime / 60), elapsedTime % 60)

    sendWebhookNotification(
        "🏆 Session Performance Analytics Summary",
        "Target execution cycle threshold successfully logged and verified.",
        16728320, -- Vivid Orange-Red
        {
            { ["name"] = "Account Identity", ["value"] = "||`" .. localPlayer.Name .. "`||", ["inline"] = true },
            { ["name"] = "Duration Elapsed", ["value"] = "`" .. runtimeString .. "`", ["inline"] = true },
            { ["name"] = "Objective Total", ["value"] = "`" .. tostring(totalGeneratorsCompleted) .. " Generators (" .. tostring(TARGET_CYCLES) .. " Full Rounds)`", ["inline"] = true },
            { ["name"] = "Active Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true },
            { ["name"] = "Session Revenue", ["value"] = "`+$" .. tostring(moneyGained) .. " Cash`", ["inline"] = true },
            { ["name"] = "Experience Gained", ["value"] = "`+" .. tostring(xpGained) .. " XP`", ["inline"] = true }
        }
    )

    task.wait(2)
    print("[Plopware] Shifting server pipelines...")
    pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
end)
