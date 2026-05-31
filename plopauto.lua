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
local processedGenerators = {}

print("[DEBUG] Script initialized. Syncing data nodes...")

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
                ["footer"] = { ["text"] = "Plopware Analytics Engine V5" },
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
pcall(function()
    local leaderstats = localPlayer:WaitForChild("leaderstats", 10)
    local moneyObj = leaderstats and leaderstats:WaitForChild("Money", 5)
    if moneyObj then initialMoney = moneyObj.Value end
end)

local equippedSurvivor = "None"
pcall(function()
    local playerData = localPlayer:WaitForChild("PlayerData", 10)
    local equippedFolder = playerData and playerData:WaitForChild("Equipped", 5)
    local survivorObj = equippedFolder and equippedFolder:WaitForChild("Survivor", 5)
    if survivorObj then equippedSurvivor = survivorObj.Value end
    
    if equippedSurvivor ~= "None" and playerData then
        local xpObj = playerData.Purchased.Survivors:FindFirstChild(equippedSurvivor)
        if xpObj then initialXP = xpObj.Value end
    end
end)

-- Send startup notification
sendWebhookNotification(
    "🚀 Autofarm Session Initiated",
    "A new server instance has been joined and the script has successfully attached.",
    4321431, -- Neon Green
    {
        { ["name"] = "Account Identity", ["value"] = "||`" .. localPlayer.Name .. "`||", ["inline"] = true },
        { ["name"] = "Target Config", ["value"] = "`" .. tostring(TARGET_CYCLES) .. " Cycles of " .. tostring(GENERATORS_PER_CYCLE) .. "`", ["inline"] = true },
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
    local character = localPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

-- Scans deep into the Map folder structure to extract available nodes
local function getUnprocessedGenerators()
    local mapFolder = Workspace:FindFirstChild("Map")
