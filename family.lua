-- family.lua

-- Services Roblox
local VIM = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variables globales (définies dans le script principal)
local Fluent = getgenv().Fluent
local Tabs = getgenv().Tabs
local Webhook = getgenv().Webhook
local discordID = getgenv().discordID

-- Fonction utilitaire pour Discord
local function sendMessage(title, description, items)
    if not Webhook or Webhook == "" then
        Fluent:Notify({
            Title = "Webhook Missing",
            Content = "Please set a Discord webhook in Settings",
            Duration = 5
        })
        return
    end
    local itemString = items and table.concat(items, "\n") or ""
    local data = {
        content = discordID ~= "" and "<@" .. discordID .. ">" or "",
        embeds = {{
            title = title,
            description = description .. "\n" .. itemString,
            color = 4286945
        }}
    }
    local actual = game:GetService("HttpService"):JSONEncode(data)
    local success, response = pcall(function()
        request({
            Url = Webhook,
            Method = "POST",
            Body = actual,
            Headers = {["content-type"] = "application/json"}
        })
    end)
end

-- Logique pour Family Spin
local success, familyTitle = pcall(function()
    return LocalPlayer.PlayerGui:WaitForChild("Interface", 10)
        :WaitForChild("Customisation", 10)
        :WaitForChild("Family", 10)
        :WaitForChild("Family", 10)
        :WaitForChild("Title", 10)
end)

if not success or not familyTitle then
    Fluent:Notify({
        Title = "Erreur",
        Content = "Impossible de charger l'interface Family. Veuillez réessayer.",
        Duration = 5
    })
    return
end

local lastFamily = ""
local foundRare = false
local maxSameFamilyTime = 10
local lastChangeTime = os.clock()
local selectedRarities = {}
local isAutoSpinActivated = false
local nombreExecutions = 7

local function SpecialSpin()
    for _ = 1, 3 do
        VIM:SendKeyEvent(true, Enum.KeyCode.Left, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.Left, false, game)
        task.wait(0.1)
    end
    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    task.wait(1)
    for _ = 1, 3 do
        VIM:SendKeyEvent(true, Enum.KeyCode.Right, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, Enum.KeyCode.Right, false, game)
        task.wait(0.1)
    end
end

local function Spin()
    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
end

for i = 1, nombreExecutions do
    local success, errorMsg = pcall(SpecialSpin)
    if not success then
        Fluent:Notify({
            Title = "Erreur",
            Content = "Échec SpecialSpin: " .. tostring(errorMsg),
            Duration = 5
        })
        break
    end
    task.wait(0.1)
end

local function CheckRarity(TargetRarities)
    local family = familyTitle.Text
    for _, rarity in pairs(TargetRarities) do
        if string.find(family, rarity) then
            return true
        end
    end
    return false
end

local function StartSpinning(targetRarities)
    foundRare = false
    while not foundRare do
        local family = familyTitle.Text
        local currentTime = os.clock()
        local rollsText = LocalPlayer.PlayerGui.Interface.Customisation.Family.Buttons_2.Roll.Title.Text

        if family ~= lastFamily then
            lastFamily = family
            lastChangeTime = currentTime

            if CheckRarity(targetRarities) then
                foundRare = true
                sendMessage("Target Family Found", "You have received the family: ", {family})
            else
                Spin()
                task.wait(0.3)
                local Frame = LocalPlayer.PlayerGui.Interface:FindFirstChild("Frame")
                if Frame then
                    SpecialSpin()
                end
            end
        else
            if (currentTime - lastChangeTime) >= maxSameFamilyTime then
                Spin()
                lastChangeTime = currentTime
            end
        end

        if rollsText == "ROLL (0)" then
            break
        end

        task.wait(0.1)
    end
end

local familySection = Tabs.Family:AddSection("Family Spin Controls")

local autoSpinButton = Tabs.Family:AddButton({
    Title = "AutoSpin",
    Description = "Trigger auto-spin sequence (required before spinning)",
    Callback = function()
        isAutoSpinActivated = true
        VIM:SendKeyEvent(true, Enum.KeyCode.BackSlash, false, game)
        task.wait(0.1)
        for _ = 1, 3 do
            VIM:SendKeyEvent(true, Enum.KeyCode.Right, false, game)
            task.wait(0.1)
        end
        Fluent:Notify({
            Title = "AutoSpin",
            Content = "AutoSpin sequence activated! You can now select rarities and spin.",
            Duration = 3
        })
    end
})

local rarityDropdown = Tabs.Family:AddDropdown({
    Title = "Select Target Rarities",
    Description = "Choose one or more rarities to stop spinning on",
    Values = {"Epic", "Legendary", "Secret"},
    Multi = true,
    Default = {},
    Callback = function(value)
        selectedRarities = {}
        for rarity, isSelected in pairs(value) do
            if isSelected then
                table.insert(selectedRarities, "%(" .. rarity .. "%)")
            end
        end
        Fluent:Notify({
            Title = "Rarities Updated",
            Content = #selectedRarities > 0 and "Selected: " .. table.concat(selectedRarities, ", ") or "No rarities selected",
            Duration = 3
        })
    end
})

local startSpinningButton = Tabs.Family:AddButton({
    Title = "Start Spinning",
    Description = "Spin until a selected rarity is found",
    Callback = function()
        if not isAutoSpinActivated then
            Fluent:Notify({
                Title = "AutoSpin Required",
                Content = "Please press AutoSpin first!",
                Duration = 5
            })
            return
        end
        if #selectedRarities == 0 then
            Fluent:Notify({
                Title = "No Rarities Selected",
                Content = "Please select at least one rarity in the dropdown.",
                Duration = 5
            })
            return
        end
        Fluent:Notify({
            Title = "Spinning Started",
            Content = "Spinning until one of: " .. table.concat(selectedRarities, ", "),
            Duration = 5
        })
        StartSpinning(selectedRarities)
    end
})
