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
local generatorsCompleted = 0

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
                ["footer"] = { ["text"] = "Plopware Analytics Engine V4 | Cyclical Mode" },
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
-- SAFE DATA INITIALIZATION PIPELINE (Bug Fix)
-- ==========================================
-- We now explicitly check if the Value exists before indexing to prevent the 'nil' error.
local leaderstats = localPlayer:WaitForChild("leaderstats", 15)
local playerData = localPlayer:WaitForChild("PlayerData", 15)

if leaderstats then
    local moneyObj = leaderstats:WaitForChild("Money", 5)
    if moneyObj then initialMoney = moneyObj.Value end
end

local equippedSurvivor = "None"
if playerData then
    local equippedFolder = playerData:WaitForChild("Equipped", 5)
    if equippedFolder then
        local survivorObj = equippedFolder:WaitForChild("Survivor", 5)
        if survivorObj then equippedSurvivor = survivorObj.Value end
    end
end

if equippedSurvivor ~= "None" and playerData then
    pcall(function()
        local xpObj = playerData.Purchased.Survivors:FindFirstChild(equippedSurvivor)
        if xpObj then initialXP = xpObj.Value end
    end)
end

-- 🚀 TRIGGER: STARTUP WEBHOOK
sendWebhookNotification(
    "🚀 Autofarm Session Initiated",
    "A new server instance has been joined and the script has successfully attached.",
    4321431, -- Neon Green Color
    {
        { ["name"] = "Account Identity", ["value"] = "||`" .. localPlayer.Name .. "`||", ["inline"] = true },
        { ["name"] = "Target Quota", ["value"] = "`" .. tostring(TOTAL_TARGET) .. " Generators`", ["inline"] = true },
        { ["name"] = "Starting Cash", ["value"] = "`$" .. tostring(initialMoney) .. "`", ["inline"] = true },
        { ["name"] = "Active Profile", ["value"] = "`" .. equippedSurvivor .. "`", ["inline"] = true }
    }
)

-- ==========================================
-- CORE AUTOMATION MECHANICS
-- ==========================================

local function checkSpectatorState()
    local playersFolder = Workspace:FindFirstChild("Players")
    return playersFolder and playersFolder:FindFirstChild("Spectating") and playersFolder.Spectating:FindFirstChild(localPlayer.Name) ~= nil
end

local function getValidCharacterPart()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart", 10)
end

-- ==========================================
-- MAIN EXECUTION THREAD (Cyclical Logic)
-- ==========================================
task.spawn(function()
    print("[Plopware] Main execution loop thread established.")
    
    local cycleCount = 0

    while cycleCount < TARGET_CYCLES do
        local isSpectating = checkSpectatorState()
        local mapFolder = Workspace:FindFirstChild("Map")
        local ingameFolder = mapFolder and mapFolder:FindFirstChild("Ingame")
        
        if not isSpectating and ingameFolder then
            print("[DEBUG] Initiating Cycle " .. tostring(cycleCount + 1) .. " of " .. tostring(TARGET_CYCLES))
            
            -- Gather 5 Generators
            local cycleGenerators = {}
            for _, item in ipairs(ingameFolder:GetChildren()) do
                if item.Name == "Generator" and #cycleGenerators < GENERATORS_PER_CYCLE then
                    table.insert(cycleGenerators, item)
                end
            end

            if #cycleGenerators > 0 then
                for i, gen in ipairs(cycleGenerators) do
                    local rootPart = getValidCharacterPart()
                    if not rootPart then continue end

                    local centerPart = gen:FindFirstChild("Positions") and gen.Positions:FindFirstChild("Center")
                    local mainPart = gen:FindFirstChild("Main")
                    local prompt = mainPart and mainPart:FindFirstChild("Prompt")
                    local remoteEvent = gen:FindFirstChild("Remotes") and gen.Remotes:FindFirstChild("RE")

                    if centerPart and prompt and remoteEvent then
                        print("[DEBUG] Processing Generator " .. tostring(i) .. "/5 for Current Cycle.")
                        
                        -- Hard anchor and teleport. Added Y-offset to prevent getting stuck in the floor.
                        rootPart.Velocity = Vector3.new(0, 0, 0)
                        rootPart.CFrame = centerPart.CFrame + Vector3.new(0, 3, 0)
                        rootPart.Anchored = true 
                        
                        -- CRITICAL FIX: Wait 0.6s to let the server realize you moved to fix the "Move closer" error.
                        task.wait(0.6) 

                        pcall(function()
                            prompt.RequiresLineOfSight = false 
                            prompt.MaxActivationDistance = 50
                            fireproximityprompt(prompt)
                        end)
                        
                        task.wait(0.25) 
                        
                        pcall(function()
                            remoteEvent:FireServer()
                        end)
                        
                        rootPart.Anchored = false 
                        generatorsCompleted = generatorsCompleted + 1
                        task.wait(0.5) -- Small buffer between generators
                    end
                end
                
                cycleCount = cycleCount + 1
                print("[DEBUG] Cycle " .. tostring(cycleCount) .. " complete.")
                task.wait(1.5) -- Buffer before starting the next cycle
            else
                print("[DEBUG] Waiting for map assets to render...")
                task.wait(3)
            end
        else
            task.wait(3)
        end
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
            if xpObj then currentXP = xpObj.Value end
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
