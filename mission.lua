-- mission.lua

-- Services Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variables globales (définies dans le script principal)
local Fluent = getgenv().Fluent
local Tabs = getgenv().Tabs

-- Logique pour les missions/raids
local objectives = ReplicatedStorage:WaitForChild("Objectives", 10)
if not objectives then
    return
end
local slay = objectives:FindFirstChild("Slay")
if slay then
    while not slay:GetAttribute("Requirement") do
        task.wait(0.1)
    end
    local waitForTitansNumber = slay:GetAttribute("Requirement")
    local titansFolder = Workspace:WaitForChild("Titans", 10)
    if not titansFolder then
        return
    end
    if slay.Value == 0 then
        while #titansFolder:GetChildren() < waitForTitansNumber do
            task.wait(0.1)
        end
    end
else
    local defendEren = objectives:FindFirstChild("Defend_Eren")
    if defendEren then
    end
end

local function AutoAttackRaid_GetRemainingAmmo()
    return tonumber(string.match(LocalPlayer.PlayerGui.Interface.HUD.Main.Top.Spears.Spears.Text.Text, "%d+")) or 0
end

local toggleState = false

local function WaitForSlayThenAdd()
    local Slay = ReplicatedStorage.Objectives:WaitForChild("Slay", 10)
    if not Slay then return end
    local requirement = Slay:GetAttribute("Requirement")
    while toggleState and Slay.Value ~= requirement do
        task.wait(0.1)
    end
    if not toggleState then return end
    pcall(function()
        ReplicatedStorage.Assets.Remotes.GET:InvokeServer("Functions", "Retry", "Add")
    end)
end

local function MissionFarm_Run()
    while toggleState do
        local titansFolder = Workspace:FindFirstChild("Titans")
        if titansFolder then
            local targetNapes = {}
            for _, titan in pairs(titansFolder:GetChildren()) do
                if not titan:FindFirstChild("Dead") then
                    local hitboxes = titan:FindFirstChild("Hitboxes")
                    if hitboxes then
                        local hit = hitboxes:FindFirstChild("Hit")
                        if hit then
                            local nape = hit:FindFirstChild("Nape")
                            if nape and nape:IsA("BasePart") then
                                table.insert(targetNapes, nape.Position)
                            end
                        end
                    end
                end
            end
            if #targetNapes > 0 then
                local ammo = AutoAttackRaid_GetRemainingAmmo()
                if ammo > 0 then
                    pcall(function()
                        ReplicatedStorage.Assets.Remotes.GET:InvokeServer("Spears", "S_Fire", tostring(ammo))
                    end)
                end
                task.wait(0.1)
                for _ = 1, 10 do
                    for _, pos in ipairs(targetNapes) do
                        pcall(function()
                            ReplicatedStorage.Assets.Remotes.POST:FireServer("Spears", "S_Explode", pos, 0.11289310455322266, 777.47021484375)
                        end)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end

local farmingSection = Tabs.Main:AddSection("Farming Controls")

local missionFarmToggle = Tabs.Main:AddToggle({
    Title = "Mission Farm Spears",
    Description = "Automatically farm mission objectives with spears",
    Default = false,
    Callback = function(state)
        toggleState = state
        if state then
            Fluent:Notify({
                Title = "Mission Farm",
                Content = "Mission farm activated!",
                Duration = 3
            })
            local buildingsFolder = Workspace:FindFirstChild("Climbable") and Workspace.Climbable:FindFirstChild("Buildings")
            if buildingsFolder then
                for _, item in ipairs(buildingsFolder:GetChildren()) do
                    item:Destroy()
                end
            end
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local rootPart = character:WaitForChild("HumanoidRootPart", 10)
            if not rootPart then
                return
            end
            local targetPos = rootPart.Position + Vector3.new(0, 500, 0)
            local bodyPosition = Instance.new("BodyPosition")
            bodyPosition.Parent = rootPart
            bodyPosition.Position = targetPos
            bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyPosition.D = 50
            bodyPosition.P = 50
            local bodyGyro = Instance.new("BodyGyro")
            bodyGyro.Parent = rootPart
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyGyro.P = 50
            task.spawn(MissionFarm_Run)
            task.spawn(WaitForSlayThenAdd)
        else
            Fluent:Notify({
                Title = "Mission Farm",
                Content = "Mission farm deactivated!",
                Duration = 3
            })
        end
    end
})
