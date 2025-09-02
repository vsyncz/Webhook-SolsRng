--[[
    Script: Webhook Biome Notifier (Executor Safe + Whitelist UI)
    Author: MuiHub + Fix by ChatGPT
    Version: 5.4

    Fitur:
    - UI + Apply + Test webhook.
    - Whitelist biome dengan indikator centang "✓".
    - Jika tidak ada biome dipilih → semua biome terkirim.
]]

--================================================================================
-- BAGIAN 1: SAFE PARENT UNTUK UI
--================================================================================

local CoreGui = game:GetService("CoreGui")
local safeParent = (gethui and gethui()) or CoreGui

-- Hapus UI lama
if safeParent:FindFirstChild("MuiHubWebhookUI") then
    safeParent.MuiHubWebhookUI:Destroy()
end

local webhookUrlBox
local appliedWebhookURL = ""

local availableBiomes = {
    "Windy", "BlazingSun", "Snowy", "Rainy", "Null", 
    "Sandstorm", "Hell", "Starfall", "Corruption", "Dreamspace", "Glitched"
}
local biomeWhitelist = {}
for _, biomeName in ipairs(availableBiomes) do
    biomeWhitelist[biomeName] = false
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MuiHubWebhookUI"
ScreenGui.Parent = safeParent
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

-- Frame utama
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -175)
MainFrame.Size = UDim2.new(0, 420, 0, 380)
MainFrame.ClipsDescendants = true

print("[MuiHub] UI Loaded to: " .. tostring(ScreenGui.Parent))

--================================================================================
-- TAB + INPUT WEBHOOK
--================================================================================

local BodyContainer = Instance.new("Frame")
BodyContainer.Parent = MainFrame
BodyContainer.BackgroundTransparency = 1
BodyContainer.Position = UDim2.new(0, 0, 0, 30)
BodyContainer.Size = UDim2.new(1, 0, 1, -30)

local webhookTabFrame = Instance.new("Frame")
webhookTabFrame.Parent = BodyContainer
webhookTabFrame.Size = UDim2.new(1, 0, 1, 0)
webhookTabFrame.BackgroundTransparency = 1

local webhookInputLabel = Instance.new("TextLabel")
webhookInputLabel.Parent = webhookTabFrame
webhookInputLabel.Text = "URL Webhook Discord:"
webhookInputLabel.Size = UDim2.new(1, 0, 0, 20)
webhookInputLabel.BackgroundTransparency = 1
webhookInputLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
webhookInputLabel.TextXAlignment = Enum.TextXAlignment.Left

webhookUrlBox = Instance.new("TextBox")
webhookUrlBox.Parent = webhookTabFrame
webhookUrlBox.Size = UDim2.new(1, 0, 0, 30)
webhookUrlBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
webhookUrlBox.TextColor3 = Color3.fromRGB(220, 220, 220)
webhookUrlBox.PlaceholderText = "Tempel URL webhook Anda di sini"
webhookUrlBox.ClearTextOnFocus = false
webhookUrlBox.TextXAlignment = Enum.TextXAlignment.Left

local buttonContainer = Instance.new("Frame")
buttonContainer.Parent = webhookTabFrame
buttonContainer.Position = UDim2.new(0, 0, 0, 60)
buttonContainer.Size = UDim2.new(1, 0, 0, 30)
buttonContainer.BackgroundTransparency = 1

local ApplyButton = Instance.new("TextButton")
ApplyButton.Parent = buttonContainer
ApplyButton.Size = UDim2.new(0.5, -5, 1, 0)
ApplyButton.Text = "Apply"
ApplyButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)

local TestButton = Instance.new("TextButton")
TestButton.Parent = buttonContainer
TestButton.Size = UDim2.new(0.5, -5, 1, 0)
TestButton.Position = UDim2.new(0.5, 5, 0, 0)
TestButton.Text = "Test"
TestButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
TestButton.TextColor3 = Color3.fromRGB(255, 255, 255)

ApplyButton.MouseButton1Click:Connect(function()
    if webhookUrlBox.Text:match("^https://discord.com/api/webhooks/") then
        appliedWebhookURL = webhookUrlBox.Text
        ApplyButton.Text = "Applied ✓"
        ApplyButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
    else
        appliedWebhookURL = ""
        ApplyButton.Text = "Invalid"
        ApplyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    task.wait(2)
    ApplyButton.Text = "Apply"
    ApplyButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
end)

--================================================================================
-- WHITELIST BIOME
--================================================================================

local biomeTitleLabel = Instance.new("TextLabel")
biomeTitleLabel.Parent = webhookTabFrame
biomeTitleLabel.Position = UDim2.new(0, 0, 0, 100)
biomeTitleLabel.Size = UDim2.new(1, 0, 0, 20)
biomeTitleLabel.BackgroundTransparency = 1
biomeTitleLabel.Text = "Whitelist Biome (Pilih untuk notifikasi):"
biomeTitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
biomeTitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local biomeContainer = Instance.new("ScrollingFrame")
biomeContainer.Parent = webhookTabFrame
biomeContainer.Position = UDim2.new(0, 0, 0, 130)
biomeContainer.Size = UDim2.new(1, 0, 1, -150)
biomeContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
biomeContainer.ScrollBarThickness = 6
biomeContainer.CanvasSize = UDim2.new(0, 0, 0, #availableBiomes * 30)

for _, biomeName in ipairs(availableBiomes) do
    local button = Instance.new("TextButton")
    button.Parent = biomeContainer
    button.Size = UDim2.new(1, 0, 0, 25)
    button.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    button.TextColor3 = Color3.fromRGB(220, 220, 220)
    button.Text = biomeName

    button.MouseButton1Click:Connect(function()
        biomeWhitelist[biomeName] = not biomeWhitelist[biomeName]
        if biomeWhitelist[biomeName] then
            button.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
            button.Text = "✓ " .. biomeName
        else
            button.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
            button.Text = biomeName
        end
    end)
end

--================================================================================
-- BAGIAN 2: LOGIKA WEBHOOK
--================================================================================

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage.ReplicaRemoteEvents.Replica_ReplicaSetValue
local player = game.Players.LocalPlayer

local function SendMessageEMBED(url, embed)
    if not url or url == "" then return false end
    local headers = { ["Content-Type"] = "application/json" }
    local body = HttpService:JSONEncode({["embeds"] = {embed}})
    local ok, res = pcall(function()
        return HttpService:RequestAsync({Url = url, Method = "POST", Headers = headers, Body = body})
    end)
    return ok and res.Success
end

-- Test Button
TestButton.MouseButton1Click:Connect(function()
    local testEmbed = {
        title = "Test Biome Change",
        description = "Ini hanya percobaan.",
        fields = {
            { name = "Username", value = player.Name, inline = true },
            { name = "UserId", value = tostring(player.UserId), inline = true }
        },
        footer = { text = "Notifikasi dari Roblox" },
        color = 3447003
    }
    SendMessageEMBED(appliedWebhookURL, testEmbed)
end)

-- Event listener biome change
Event.OnClientEvent:Connect(function(id, path, newValue)
    if typeof(path) == "table" and newValue then
        for _, key in ipairs(path) do
            if key == "BiomeName" or key == "Biome" then
                local biomeName = tostring(newValue)

                -- cek apakah whitelist kosong
                local whitelistEmpty = true
                for _, v in pairs(biomeWhitelist) do
                    if v then whitelistEmpty = false break end
                end

                if whitelistEmpty or biomeWhitelist[biomeName] then
                    local embed = {
                        title = "Perubahan Biome Terdeteksi",
                        description = string.format("Nilai '%s' berubah menjadi '%s'", key, biomeName),
                        color = 3447003,
                        fields = {
                            { name = "Player", value = player.Name, inline = true },
                            { name = "ID", value = tostring(id), inline = true },
                            { name = "Path", value = table.concat(path, "."), inline = true }
                        },
                        footer = { text = "Notifikasi dari Roblox" }
                    }
                    SendMessageEMBED(appliedWebhookURL, embed)
                end
            end
        end
    end
end)

print("[MuiHub] Script Webhook v5.4 (Whitelist UI Active) Loaded!")
