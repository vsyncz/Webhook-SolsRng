--[[
    Script: Webhook Biome Notifier (Executor Safe Full)
    Author: MuiHub + Fix by ChatGPT
    Version: 5.2 (Safe for Executors)

    Perubahan:
    - GUI diparent ke (gethui() or CoreGui) supaya aman di Delta/ArceusX.
    - Log tambahan untuk debug UI dan Webhook.
    - Semua fitur UI (Apply, Test, whitelist biome) tetap ada.
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

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.Active = true

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local dragging, dragStart, startPos = false, nil, nil

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = UserInputService:GetMouseLocation()
        startPos = MainFrame.Position
        local connection
        connection = UserInputService.InputEnded:Connect(function(endInput)
            if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                connection:Disconnect()
            end
        end)
    end
end)

RunService.Heartbeat:Connect(function()
    if dragging then
        local currentPos = UserInputService:GetMouseLocation()
        local delta = currentPos - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = Header
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "Webhook Biome By MuiHub"
TitleLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = Header
MinimizeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MinimizeButton.Size = UDim2.new(0, 30, 1, 0)
MinimizeButton.Position = UDim2.new(1, -60, 0, 0)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = Color3.fromRGB(225, 225, 225)
MinimizeButton.TextSize = 16

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = Header
CloseButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
CloseButton.Size = UDim2.new(0, 30, 1, 0)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(225, 225, 225)
CloseButton.TextSize = 16
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local BodyContainer = Instance.new("Frame")
BodyContainer.Name = "BodyContainer"
BodyContainer.Parent = MainFrame
BodyContainer.BackgroundTransparency = 1
BodyContainer.Position = UDim2.new(0, 0, 0, 30)
BodyContainer.Size = UDim2.new(1, 0, 1, -30)

local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    BodyContainer.Visible = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(UDim2.new(0, 420, 0, 30), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        MinimizeButton.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 420, 0, 380), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        MinimizeButton.Text = "—"
    end
end)

local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = BodyContainer
TabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
TabContainer.BorderSizePixel = 0
TabContainer.Size = UDim2.new(0, 110, 1, 0)

local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = BodyContainer
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 110, 0, 0)
ContentContainer.Size = UDim2.new(1, -110, 1, 0)

local tabs = {}
local function createTab(tabName)
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = tabName .. "Content"
    contentFrame.Parent = ContentContainer
    contentFrame.BackgroundTransparency = 1
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.Visible = false

    local padding = Instance.new("UIPadding")
    padding.Parent = contentFrame
    padding.PaddingTop = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.PaddingRight = UDim.new(0, 15)
    padding.PaddingBottom = UDim.new(0, 15)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = contentFrame
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)

    local tabButton = Instance.new("TextButton")
    tabButton.Name = tabName
    tabButton.Parent = TabContainer
    tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    tabButton.BorderSizePixel = 0
    tabButton.Size = UDim2.new(1, 0, 0, 35)
    tabButton.Font = Enum.Font.SourceSans
    tabButton.Text = tabName
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.TextSize = 16

    tabButton.MouseButton1Click:Connect(function()
        for name, tabData in pairs(tabs) do
            tabData.button.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            tabData.button.TextColor3 = Color3.fromRGB(200, 200, 200)
            tabData.frame.Visible = false
        end
        contentFrame.Visible = true
        tabButton.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    tabs[tabName] = {button = tabButton, frame = contentFrame}
    return contentFrame
end

local tabListLayout = Instance.new("UIListLayout")
tabListLayout.Parent = TabContainer
tabListLayout.Padding = UDim.new(0, 2)

local webhookTabFrame = createTab("Webhook")

-- Label + Input webhook
local webhookInputLabel = Instance.new("TextLabel")
webhookInputLabel.Parent = webhookTabFrame
webhookInputLabel.LayoutOrder = 1
webhookInputLabel.Size = UDim2.new(1, 0, 0, 20)
webhookInputLabel.BackgroundTransparency = 1
webhookInputLabel.Font = Enum.Font.SourceSans
webhookInputLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
webhookInputLabel.Text = "URL Webhook Discord:"
webhookInputLabel.TextSize = 14
webhookInputLabel.TextXAlignment = Enum.TextXAlignment.Left

webhookUrlBox = Instance.new("TextBox")
webhookUrlBox.Name = "WebhookURLInput"
webhookUrlBox.Parent = webhookTabFrame
webhookUrlBox.LayoutOrder = 2
webhookUrlBox.Size = UDim2.new(1, 0, 0, 30)
webhookUrlBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
webhookUrlBox.TextColor3 = Color3.fromRGB(220, 220, 220)
webhookUrlBox.Font = Enum.Font.SourceSans
webhookUrlBox.Text = ""
webhookUrlBox.PlaceholderText = "Tempel URL webhook Anda di sini"
webhookUrlBox.ClearTextOnFocus = false
webhookUrlBox.TextXAlignment = Enum.TextXAlignment.Left

local textPadding = Instance.new("UIPadding")
textPadding.Parent = webhookUrlBox
textPadding.PaddingLeft = UDim.new(0, 8)
textPadding.PaddingRight = UDim.new(0, 8)

-- Tombol Apply + Test
local buttonContainer = Instance.new("Frame")
buttonContainer.Parent = webhookTabFrame
buttonContainer.LayoutOrder = 3
buttonContainer.BackgroundTransparency = 1
buttonContainer.Size = UDim2.new(1, 0, 0, 30)

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.Parent = buttonContainer
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonLayout.Padding = UDim.new(0, 10)

local ApplyButton = Instance.new("TextButton")
ApplyButton.Name = "ApplyButton"
ApplyButton.Parent = buttonContainer
ApplyButton.Size = UDim2.new(0.5, -5, 1, 0)
ApplyButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
ApplyButton.Font = Enum.Font.SourceSansBold
ApplyButton.Text = "Apply"
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyButton.TextSize = 14

local TestButton = Instance.new("TextButton")
TestButton.Name = "TestButton"
TestButton.Parent = buttonContainer
TestButton.Size = UDim2.new(0.5, -5, 1, 0)
TestButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
TestButton.Font = Enum.Font.SourceSansBold
TestButton.Text = "Test"
TestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TestButton.TextSize = 14

ApplyButton.MouseButton1Click:Connect(function()
    local url = webhookUrlBox.Text
    local originalColor = ApplyButton.BackgroundColor3
    if url:match("^https://discord.com/api/webhooks/") then
        appliedWebhookURL = url
        ApplyButton.Text = "Applied ✓"
        ApplyButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
    else
        appliedWebhookURL = ""
        ApplyButton.Text = "Invalid"
        ApplyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    task.wait(2)
    ApplyButton.Text = "Apply"
    ApplyButton.BackgroundColor3 = originalColor
end)

--================================================================================
-- BAGIAN 2: LOGIKA WEBHOOK
--================================================================================

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage.ReplicaRemoteEvents.Replica_ReplicaSetValue
local player = game.Players.LocalPlayer

function SendMessageEMBED(url, embed)
    if not url or url == "" then
        warn("[MuiHub] Webhook URL kosong. Tekan 'Apply' dulu.")
        return false
    end

    local headers = { ["Content-Type"] = "application/json" }

    local embedData = {
        ["title"] = embed.title or "No Title",
        ["description"] = embed.description or "",
        ["color"] = embed.color or 3447003,
    }

    if embed.fields and type(embed.fields) == "table" and #embed.fields > 0 then
        embedData["fields"] = embed.fields
    end

    if embed.footer and embed.footer.text then
        embedData["footer"] = { ["text"] = embed.footer.text }
    end

    local data = { ["embeds"] = {embedData} }
    local body = HttpService:JSONEncode(data)

    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = body
        })
    end)

    if success and response.Success then
        print("[MuiHub] Embed sent successfully!")
        return true
    else
        warn("[MuiHub] ERROR SEND → " .. tostring(response.StatusCode or response))
        return false
    end
end

-- Tombol Test
TestButton.MouseButton1Click:Connect(function()
    local testEmbed = {
        title = "Perubahan Cuaca di Server Roblox",
        description = "Nilai 'Biome' telah berubah menjadi 'Test Biome'.",
        fields = {
            { name = "Username: " .. (player.Name or "Unknown"), value = tostring(player.UserId or "N/A"), inline = true },
            { name = "Path", value = "Biome", inline = true },
            { name = "Nilai Baru", value = "Test Biome", inline = true }
        },
        footer = { text = "Notifikasi dari Game Roblox" }
    }

    local success = SendMessageEMBED(appliedWebhookURL, testEmbed)
    if success then
        TestButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
    else
        TestButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    task.wait(2)
    TestButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
end)

-- Event listener
Event.OnClientEvent:Connect(function(id, path, newValue)
    if typeof(path) == "table" and newValue then
        for _, key in ipairs(path) do
            if key == "BiomeName" or key == "Biome" then
                if (next(biomeWhitelist) == nil) or biomeWhitelist[tostring(newValue)] then
                    local embed = {
                        title = "Perubahan Cuaca di Server Roblox",
                        description = string.format("Nilai '%s' berubah menjadi '%s'.", table.concat(path, "."), tostring(newValue)),
                        color = 3447003,
                        fields = {
                            { name = "Username: " .. (player.Name or "Unknown"), value = tostring(id or "N/A"), inline = true },
                            { name = "Path", value = table.concat(path, "."), inline = true },
                            { name = "Nilai Baru", value = tostring(newValue), inline = true }
                        },
                        footer = { text = "Notifikasi dari Game Roblox" }
                    }
                    SendMessageEMBED(appliedWebhookURL, embed)
                    break
                end
            end
        end
    end
end)

print("[MuiHub] Script Webhook v5.2 (Executor Safe) Loaded!")
