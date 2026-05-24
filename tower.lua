-- ==========================================
-- UI CACHE WIPE (Fixes the disappearing UI bug)
-- ==========================================
for _, interface in ipairs(game:GetService("CoreGui"):GetChildren()) do
    if interface:IsA("ScreenGui") and (interface.Name:match("Rayfield") or interface:FindFirstChild("Main")) then
        interface:Destroy()
    end
end
pcall(function()
    for _, interface in ipairs(game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
        if interface:IsA("ScreenGui") and (interface.Name:match("Rayfield") or interface:FindFirstChild("Main")) then
            interface:Destroy()
        end
    end
end)
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Universal System | By Femini",
   LoadingTitle = "Loading Optimized Framework...",
   LoadingSubtitle = "by Femini",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false
})

-- Dynamic Parameters
local TweenSpeed = 60
local AutoTweenEnabled = false
local AutoJumpEnabled = false
local InfJumpEnabled = false
local AutoDeleteEnemies = false
local AutoRemoteCollect = false 
local AutoStatuePickup = false 
local AutoPromptStatue = false 
local AutoRejoinOnDeath = false
local AutoRejoinOnComplete = false

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Player = game.Players.LocalPlayer

-- Secure Remote Verification
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local CollectRemote = RemotesFolder:WaitForChild("Collect")
local PickupRemote = RemotesFolder:WaitForChild("Pickup")

-- ==========================================
-- REJOIN & QUEUE-ON-TELEPORT LOGIC
-- ==========================================
local isRejoining = false
local autoRejoinCode = [[
loadstring(game:HttpGet("haha"))()
]]

local function triggerServerRejoin()
    if isRejoining then return end
    isRejoining = true
    
    local queueFunction = queue_on_teleport or (syn and syn.queue_on_teleport) or nil
    if queueFunction then
        pcall(function() queueFunction(autoRejoinCode) end)
    end
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end

local function hookDeathListener(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            if AutoRejoinOnDeath then triggerServerRejoin() end
        end)
    end
end

Player.CharacterAdded:Connect(hookDeathListener)
if Player.Character then hookDeathListener(Player.Character) end

-- ==========================================
-- CENTRALIZED CACHE SYSTEM (Massive Efficiency Boost)
-- ==========================================
local ObjectCache = {
    Tringles = {},
    Statues = {}
}

local currentTringleIndex = 1

-- Updates the cache once every 2 seconds instead of every frame
task.spawn(function()
    while true do
        task.wait(2)
        if AutoTweenEnabled or AutoRemoteCollect or AutoStatuePickup or AutoPromptStatue then
            local newTringles = {}
            local newStatues = {}
            
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    local name = obj.Name:lower()
                    
                    -- Catch ALL variations (SpeedTringle, TringleFive, etc.)
                    if string.find(name, "tringle") then
                        table.insert(newTringles, obj)
                    
                    -- Catch ALL Statue variations (DeathStatue, HatredStatue, etc.)
                    elseif string.find(name, "statue") or string.find(name, "angel") then
                        table.insert(newStatues, obj)
                    end
                end
            end)
            
            -- Sort Tringles numerically based on the trailing numbers
            table.sort(newTringles, function(a, b)
                local numA = tonumber(a.Name:match("%d+"))
                local numB = tonumber(b.Name:match("%d+"))
                if numA and numB then return numA < numB
                elseif numA then return true
                elseif numB then return false
                else return a.Name < b.Name end
            end)
            
            ObjectCache.Tringles = newTringles
            ObjectCache.Statues = newStatues
            
            -- Rejoin on Complete Check
            if AutoRejoinOnComplete and #ObjectCache.Tringles == 0 and #ObjectCache.Statues == 0 then
                triggerServerRejoin()
            end
        end
    end
end)

---- CORE LOGIC THREADS ----

-- 1. Master Traversal Coordinator (Tween Engine)
task.spawn(function()
    while true do
        task.wait(0.1) 
        
        if AutoTweenEnabled and #ObjectCache.Tringles > 0 then
            if currentTringleIndex > #ObjectCache.Tringles then
                currentTringleIndex = 1
            end
            
            local targetObj = ObjectCache.Tringles[currentTringleIndex]
            
            -- Specifically target the 'Hitbox' part if it exists, otherwise fallback to any BasePart
            local targetPart = targetObj:FindFirstChild("Hitbox") 
                            or (targetObj:IsA("BasePart") and targetObj) 
                            or targetObj:FindFirstChildWhichIsA("BasePart", true)
            
            if targetPart and targetPart.Parent and targetPart:IsA("BasePart") then
                local targetCFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                local startTime = os.clock()
                local timeout = 5 -- Skip after 5 seconds to prevent getting permanently stuck
                
                while AutoTweenEnabled and targetPart and targetPart.Parent do
                    local currentCharacter = Player.Character
                    local root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
                    
                    if not root then break end 
                    if os.clock() - startTime > timeout then break end 
                    
                    local dt = RunService.Heartbeat:Wait()
                    if not AutoTweenEnabled then break end
                    
                    local currentPos = root.Position
                    local targetPos = targetCFrame.Position
                    local distance = (targetPos - currentPos).Magnitude
                    
                    if distance < 3 then
                        root.CFrame = targetCFrame * root.CFrame.Rotation
                        break
                    end
                    
                    if distance > 0.1 then
                        local direction = (targetPos - currentPos).Unit
                        local step = direction * math.min(TweenSpeed * dt, distance)
                        root.CFrame = CFrame.new(currentPos + step) * root.CFrame.Rotation
                    end
                end
            end
            
            currentTringleIndex = currentTringleIndex + 1
        end
    end
end)

-- 2. Throttled Remote Collector (Prevents Network Breaking)
task.spawn(function()
    while true do
        task.wait(0.5) 
        if AutoRemoteCollect then
            for _, tringleObj in ipairs(ObjectCache.Tringles) do
                if not AutoRemoteCollect then break end
                if tringleObj and tringleObj.Parent then
                    task.spawn(function()
                        pcall(function() CollectRemote:FireServer(tringleObj.Name) end)
                    end)
                    task.wait(0.05) -- Throttle: Safe delay to prevent server from ignoring packets
                end
            end
        end
    end
end)

-- 3. Legacy Statue Auto-Pickup (Throttled)
task.spawn(function()
    while true do
        task.wait(1)
        if AutoStatuePickup then
            for _, statueObj in ipairs(ObjectCache.Statues) do
                if not AutoStatuePickup then break end
                if statueObj and statueObj.Parent then
                    task.spawn(function()
                        pcall(function() PickupRemote:InvokeServer(statueObj.Name) end)
                    end)
                    task.wait(0.1) 
                end
            end
        end
    end
end)

-- 4. Statue Physical Teleport & Prompt Firer
task.spawn(function()
    while true do
        task.wait(0.5)
        if AutoPromptStatue then
            for _, statueObj in ipairs(ObjectCache.Statues) do
                if not AutoPromptStatue then break end
                
                -- Look for the prompt inside the cached statue
                local prompt = statueObj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Name == "StatuePrompt" then
                    local targetPart = prompt.Parent
                    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    
                    if targetPart and targetPart:IsA("BasePart") and root then
                        root.CFrame = targetPart.CFrame
                        task.wait(0.25)
                        pcall(function() fireproximityprompt(prompt) end)
                        task.wait(0.5)
                    end
                end
            end
        end
    end
end)


-- 5. Jump Spammer & Noclip Frame Injection
RunService.Stepped:Connect(function()
    if Player.Character then
        local humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
        local root = Player.Character:FindFirstChild("HumanoidRootPart")
        
        if AutoTweenEnabled and root and root.Parent then
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end

        if AutoJumpEnabled and humanoid and humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        
        if AutoTweenEnabled or AutoJumpEnabled then
            for _, part in ipairs(Player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- 6. Enemy Deletion Daemon
task.spawn(function()
    while true do
        task.wait(2) -- Slowed down to save CPU
        if AutoDeleteEnemies then
            pcall(function()
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name == "Enemies" or obj.Name == "Hitboxes" then
                        obj:ClearAllChildren()
                    elseif obj.Name:lower():match("enemy") and not obj:IsA("Folder") and not obj:IsA("Script") then
                        obj:Destroy()
                    end
                end
            end)
        end
    end
end)


UserInputService.JumpRequest:Connect(function()
    if InfJumpEnabled and Player.Character then
        local humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)


---- USER INTERFACE RENDER ----

local FarmTab = Window:CreateTab("Auto-Farm", nil)
local MoveTab = Window:CreateTab("Movement", nil)
local UtilityTab = Window:CreateTab("Utilities", nil)

---- FARM CONTROLS ----

FarmTab:CreateToggle({
   Name = "Linear Progressor (All Tringle Types)",
   CurrentValue = false,
   Flag = "FarmToggle",
   Callback = function(Value)
       AutoTweenEnabled = Value
       if not Value then currentTringleIndex = 1 end
   end,
})

FarmTab:CreateToggle({
   Name = "Auto-Collect Statues (Physical Prompt/TP)",
   CurrentValue = false,
   Flag = "PhysicalStatueToggle",
   Callback = function(Value)
       AutoPromptStatue = Value
   end,
})

FarmTab:CreateSection("Network Remote Actions")

FarmTab:CreateToggle({
   Name = "Instant Remote Auto-Collect (Tringles)",
   CurrentValue = false,
   Flag = "RemoteCollectToggle",
   Callback = function(Value)
       AutoRemoteCollect = Value
   end,
})

FarmTab:CreateToggle({
   Name = "Instant Remote Auto-Pickup (Statues/Angels)",
   CurrentValue = false,
   Flag = "StatuePickupToggle",
   Callback = function(Value)
       AutoStatuePickup = Value
   end,
})

FarmTab:CreateSlider({
   Name = "Real-Time Velocity Speed",
   Range = {10, 1000},
   CurrentValue = 60,
   Increment = 5,
   Flag = "VelocitySlider",
   Callback = function(Value)
       TweenSpeed = Value
   end,
})

---- MOVEMENT CONTROLS ----

MoveTab:CreateButton({
   Name = "Trigger Bumper (Teleport & Return)",
   Callback = function()
       local bumperPart = nil
       for _, obj in ipairs(workspace:GetDescendants()) do
           if obj.Name == "Bumper" and obj:IsA("BasePart") then
               bumperPart = obj
               break
           end
       end

       local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
       if bumperPart and root then
           local originalCFrame = root.CFrame
           root.CFrame = bumperPart.CFrame
           task.wait(0.3)
           root.CFrame = originalCFrame
       end
   end,
})

MoveTab:CreateToggle({
   Name = "Fully Automatic Jump Spam",
   CurrentValue = false,
   Flag = "SpamJumpToggle",
   Callback = function(Value)
       AutoJumpEnabled = Value
   end,
})

MoveTab:CreateToggle({
   Name = "Classic Infinite Jump (Spacebar)",
   CurrentValue = false,
   Flag = "InfJumpToggle",
   Callback = function(Value)
       InfJumpEnabled = Value
   end,
})

---- UTILITY CONTROLS ----

UtilityTab:CreateToggle({
   Name = "Auto-Rejoin on Death",
   CurrentValue = false,
   Flag = "RejoinDeathToggle",
   Callback = function(Value)
       AutoRejoinOnDeath = Value
   end,
})

UtilityTab:CreateToggle({
   Name = "Auto-Rejoin when fully cleared",
   CurrentValue = false,
   Flag = "RejoinCompleteToggle",
   Callback = function(Value)
       AutoRejoinOnComplete = Value
   end,
})

UtilityTab:CreateToggle({
   Name = "Auto-Clear Enemies & Hitboxes",
   CurrentValue = false,
   Flag = "EnemyToggle",
   Callback = function(Value)
       AutoDeleteEnemies = Value
   end,
})

UtilityTab:CreateButton({
   Name = "Instant Enemy Purge",
   Callback = function()
       pcall(function()
           for _, obj in ipairs(workspace:GetDescendants()) do
               if obj.Name == "Enemies" or obj.Name == "Hitboxes" then
                   obj:ClearAllChildren()
               end
           end
       end)
   end,
})
