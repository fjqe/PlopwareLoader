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
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

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

-- Cardinal Side Offsets (3.6 Studs Out, slightly lowered to perfectly align with character interaction height)
local CARDINAL_OFFSETS = {
    CFrame.new(0, -0.8, 3.6),   -- Side A (Back)
    CFrame.new(0, -0.8, -3.6),  -- Side B (Front)
    CFrame.new(3.6, -0.8, 0),   -- Side C (Right)
    CFrame.new(-3.6, -0.8, 0)   -- Side D (Left)
}

-- ==========================================
-- ACTIVE STATUS HUD GENERATOR
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlopwareHUD"
screenGui.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(screenGui) end
screenGui.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 45)
mainFrame.Position = UDim2.new(0.5, -120, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 6)
uiCorner.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 13
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 136)
statusLabel.Text = "PLOPWARE ACTIVE | ENGINE INITIALIZING"
statusLabel.Parent = mainFrame
mainFrame.Parent = screenGui

local function updateHUD(text, color)
    statusLabel.Text = text
    if color then statusLabel.TextColor3 = color end
end

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
                ["footer"] = { ["text"] = "Plopware Analytics Engine V5.4 | By Femini" },
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
-- DATA EXTRACTION PIPELINE (Error Guarded)
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

sendWebhookNotification(
    "🚀 Autofarm Session Initiated",
    "Target system connected. Linear sequencing engine fully calibrated.",
    4321431, 
    {
        { ["name"] = "Account Identity", ["value"] = "||`" .. localPlayer.Name .. "`||", ["inline"] = true },
        { ["name"] = "Target Configuration", ["value"] = "`" .. tostring(TARGET_CYCLES) .. " Rounds (" .. tostring(TOTAL_TARGET) .. " Nodes)`", ["inline"] = true },
        { ["name"] = "Starting Cash", ["value"] = "`$" .. tostring(initialMoney) .. "`", ["inline"] = true },
        { ["name"] = "Active Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true }
    }
)

-- ==========================================
-- SYSTEM UTILITIES
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
-- RECURSIVE FARMING SCHEDULER
-- ==========================================
task.spawn(function()
    local currentCycle = 1
    local completedInCurrentCycle = 0

    while currentCycle <= TARGET_CYCLES do
        local isSpectating = checkSpectatorState()
        local availableGenerators = getUnprocessedGenerators()
        
        if not isSpectating and #availableGenerators > 0 then
            local targetGen = availableGenerators[1]
            processedGenerators[targetGen] = true 
            
            local rootPart = getValidCharacterPart()
            if rootPart then
                local mainPart = targetGen:FindFirstChild("Main")
                local prompt = mainPart and mainPart:FindFirstChild("Prompt")
                local remoteEvent = targetGen:FindFirstChild("Remotes") and targetGen.Remotes:FindFirstChild("RE")

                if mainPart and prompt and remoteEvent then
                    completedInCurrentCycle = completedInCurrentCycle + 1
                    totalGeneratorsCompleted = totalGeneratorsCompleted + 1
                    
                    updateHUD(string.format("FARMING: NODE [%d/5] | CYCLE [%d/3]", completedInCurrentCycle, currentCycle), Color3.fromRGB(0, 210, 255))
                    
                    -- Dynamic Quadrant Sampling Loop
                    -- Switches positions safely if a wall blocks one of the sides
                    for offsetIndex, localOffset in ipairs(CARDINAL_OFFSETS) do
                        if not targetGen:Parent() or (prompt.Parent == nil) then break end
                        
                        rootPart.Velocity = Vector3.new(0, 0, 0)
                        if rootPart:IsA("BasePart") then rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
                        
                        -- Perfect Object-Space Alignment (Rotation Safe)
                        rootPart.CFrame = mainPart.CFrame * localOffset
                        rootPart.Anchored = true
                        
                        task.wait(0.2) 

                        prompt.RequiresLineOfSight = false 
                        prompt.MaxActivationDistance = 150
                        
                        pcall(function()
                            if fireproximityprompt then
                                fireproximityprompt(prompt)
                            else
                                prompt:InputBegan(Enum.UserInputType.Keyboard)
                                task.wait(prompt.HoldDuration + 0.05)
                                prompt:InputEnded(Enum.UserInputType.Keyboard)
                            end
                        end)
                        
                        pcall(function() remoteEvent:FireServer() end)
                        task.wait(0.2)
                    end
                    
                    rootPart.Anchored = false
                    
                    -- Clean arrays and update loops upon set completion
                    if completedInCurrentCycle >= GENERATORS_PER_CYCLE then
                        updateHUD("ROUND COMPLETE | WAITING FOR REFRESH", Color3.fromRGB(255, 190, 0))
                        currentCycle = currentCycle + 1
                        completedInCurrentCycle = 0
                        table.clear(processedGenerators) 
                        
                        local mapFolder = Workspace:FindFirstChild("Map")
                        if mapFolder and mapFolder:FindFirstChild("Ingame") then
                            task.wait(4)
                        end
                    end
                end
            end
        else
            local mapFolder = Workspace:FindFirstChild("Map")
            if not mapFolder or not mapFolder:FindFirstChild("Ingame") then
                table.clear(processedGenerators)
                updateHUD("WAITING FOR MAP LOADING...", Color3.fromRGB(180, 180, 180))
            end
            task.wait(1)
        end
        task.wait(0.2)
    end

    -- ==========================================
    -- TELEMETRY SHIPPING & TELEPORT PIPELINE
    -- ==========================================
    updateHUD("SESSION COMPLETE | SHIPPING LOGS", Color3.fromRGB(0, 255, 100))

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
        16728320, 
        {
            { ["name"] = "Account Identity", ["value"] = "||`" .. localPlayer.Name .. "`||", ["inline"] = true },
            { ["name"] = "Duration Elapsed", ["value"] = "`" .. runtimeString .. "`", ["inline"] = true },
            { ["name"] = "Objective Total", ["value"] = "`" .. tostring(totalGeneratorsCompleted) .. " Generators (" .. tostring(TARGET_CYCLES) .. " Completed Rounds)`", ["inline"] = true },
            { ["name"] = "Active Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true },
            { ["name"] = "Session Revenue", ["value"] = "`+$" .. tostring(moneyGained) .. " Cash`", ["inline"] = true },
            { ["name"] = "Experience Gained", ["value"] = "`+" .. tostring(xpGained) .. " XP`", ["inline"] = true }
        }
    )

    task.wait(1.5)
    updateHUD("SERVER ROTATION ROUTINE ACTIVE", Color3.fromRGB(255, 70, 70))
    pcall(function()
        TeleportService:Teleport(game.PlaceId, localPlayer)
    end)
end)
