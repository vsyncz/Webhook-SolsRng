--[[
    Script: Webhook Biome Notifier
    Author: MuiHub (UI & Features by Gemini)
    Version: 5.1 (Fixed Version - Back to Basics with Old Functionality)
    
    Deskripsi:
    Versi fixed berdasarkan "webhook-final.lua" dengan perbaikan error potensial pada GetService dan fungsi webhook.
    - Menggunakan fungsi SendMessageEMBED yang mirip dengan "webhook old.lua" untuk kestabilan.
    - Menyesuaikan logika event listener agar lebih mirip "webhook old.lua" (check path untuk "BiomeName" atau "Biome", tanpa bergantung whitelist sepenuhnya jika tidak diperlukan).
    - Memperbaiki potensial error di GetService dengan pengecekan eksistensi ReplicatedStorage dan event.
    - Template notifikasi disesuaikan agar lebih mirip "webhook old.lua" (path sebagai table.concat, username hardcoded jika diperlukan, tapi gunakan player.Name untuk dinamis).
    - Fungsionalitas Apply & Test dipertahankan, dengan penanganan error lebih baik.
    - Menambahkan pengecekan jika webhookURL kosong atau invalid.
    - UI style tetap seperti "webhook-final.lua".
    - Print debug untuk membantu identifikasi error.
]]

--================================================================================
-- BAGIAN 1: PEMBUATAN ANTARMUKA PENGGUNA (UI)
--================================================================================

-- Hapus UI lama untuk mencegah tumpang tindih
if game:GetService("CoreGui"):FindFirstChild("MuiHubWebhookUI") then
    game:GetService("CoreGui").MuiHubWebhookUI:Destroy()
end

-- Inisialisasi variabel dan daftar biome
local webhookUrlBox
local appliedWebhookURL = "" -- Webhook hanya aktif setelah di-"Apply"

local availableBiomes = {
    "Windy", "BlazingSun", "Snowy", "Rainy", "Null", 
    "Sandstorm", "Hell", "Starfall", "Corruption", "Dreamspace", "Glitched"
}
local biomeWhitelist = {}
for _, biomeName in ipairs(availableBiomes) do
    biomeWhitelist[biomeName] = false
end

-- ScreenGui sebagai lapisan utama UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MuiHubWebhookUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

-- Frame utama yang bisa digeser
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -175)
MainFrame.Size = UDim2.new(0, 420, 0, 380)
MainFrame.ClipsDescendants = true

-- Header untuk judul dan tombol kontrol
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Header.Size = UDim2.new(1, 0, 0, 30)
Header.Active = true

-- Logika Geser (Drag) yang Sangat Halus
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local dragging = false
local dragStart
local startPos

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

-- Tombol Minimize
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

-- Tombol Tutup
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

-- Kontainer untuk bodi UI (tab dan konten)
local BodyContainer = Instance.new("Frame")
BodyContainer.Name = "BodyContainer"
BodyContainer.Parent = MainFrame
BodyContainer.BackgroundTransparency = 1
BodyContainer.Position = UDim2.new(0, 0, 0, 30)
BodyContainer.Size = UDim2.new(1, 0, 1, -30)

-- Logika untuk tombol minimize
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

-- Container untuk tombol tab
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = BodyContainer
TabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
TabContainer.BorderSizePixel = 0
TabContainer.Size = UDim2.new(0, 110, 1, 0)

-- Container untuk konten tab
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = BodyContainer
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 110, 0, 0)
ContentContainer.Size = UDim2.new(1, -110, 1, 0)

-- Tabel untuk menyimpan referensi tab
local tabs = {}

-- Fungsi untuk membuat tab baru
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

-- Layout untuk tombol tab
local tabListLayout = Instance.new("UIListLayout")
tabListLayout.Parent = TabContainer
tabListLayout.Padding = UDim.new(0, 2)

-- Membuat tab "Webhook" dan mengambil framenya
local webhookTabFrame = createTab("Webhook")

-- Menambahkan elemen-elemen UI ke dalam frame tab Webhook
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
    if url:match("^https://discord.com/api/webhooks/") or url:match("^https://discordapp.com/api/webhooks/") then
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

local biomeTitleLabel = Instance.new("TextLabel")
biomeTitleLabel.Parent = webhookTabFrame
biomeTitleLabel.LayoutOrder = 4
biomeTitleLabel.Size = UDim2.new(1, 0, 0, 20)
biomeTitleLabel.BackgroundTransparency = 1
biomeTitleLabel.Font = Enum.Font.SourceSans
biomeTitleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
biomeTitleLabel.Text = "Whitelist Biome (Pilih untuk notifikasi):"
biomeTitleLabel.TextSize = 14
biomeTitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local biomeContainer = Instance.new("ScrollingFrame")
biomeContainer.Parent = webhookTabFrame
biomeContainer.LayoutOrder = 5
biomeContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
biomeContainer.BorderSizePixel = 1
biomeContainer.BorderColor3 = Color3.fromRGB(50, 50, 55)
biomeContainer.Size = UDim2.new(1, 0, 1, -125)
biomeContainer.CanvasSize = UDim2.new(0, 0, 0, #availableBiomes * 28)
biomeContainer.ScrollBarThickness = 6

local biomeListLayout = Instance.new("UIListLayout")
biomeListLayout.Parent = biomeContainer
biomeListLayout.Padding = UDim.new(0, 3)

for _, biomeName in ipairs(availableBiomes) do
    local checkboxFrame = Instance.new("Frame")
    checkboxFrame.Parent = biomeContainer
    checkboxFrame.BackgroundTransparency = 1
    checkboxFrame.Size = UDim2.new(1, 0, 0, 25)
    
    local checkboxButton = Instance.new("TextButton")
    checkboxButton.Parent = checkboxFrame
    checkboxButton.Size = UDim2.new(0, 25, 0, 25)
    checkboxButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    checkboxButton.Text = ""
    checkboxButton.Font = Enum.Font.SourceSansBold
    checkboxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkboxButton.TextSize = 18

    local checkboxLabel = Instance.new("TextLabel")
    checkboxLabel.Parent = checkboxFrame
    checkboxLabel.Size = UDim2.new(1, -30, 1, 0)
    checkboxLabel.Position = UDim2.new(0, 30, 0, 0)
    checkboxLabel.BackgroundTransparency = 1
    checkboxLabel.Font = Enum.Font.SourceSans
    checkboxLabel.Text = biomeName
    checkboxLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    checkboxLabel.TextSize = 14
    checkboxLabel.TextXAlignment = Enum.TextXAlignment.Left

    checkboxButton.MouseButton1Click:Connect(function()
        biomeWhitelist[biomeName] = not biomeWhitelist[biomeName]
        if biomeWhitelist[biomeName] then
            checkboxButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
            checkboxButton.Text = "✓"
        else
            checkboxButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
            checkboxButton.Text = ""
        end
    end)
end

tabs["Webhook"].button.MouseButton1Click:Invoke()

--================================================================================
-- BAGIAN 2: LOGIKA WEBHOOK (DIPERBAIKI DAN DISESUAIKAN DENGAN "webhook old.lua")
--================================================================================

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Pengecekan eksistensi event untuk menghindari error GetService atau path
local ReplicaRemoteEvents = ReplicatedStorage:FindFirstChild("ReplicaRemoteEvents")
local Event
if ReplicaRemoteEvents then
    Event = ReplicaRemoteEvents:FindFirstChild("Replica_ReplicaSetValue")
    if Event then
        print("MuiHub: Event ditemukan dan siap.")
    else
        warn("MuiHub WARNING: Replica_ReplicaSetValue tidak ditemukan di ReplicaRemoteEvents.")
    end
else
    warn("MuiHub WARNING: ReplicaRemoteEvents tidak ditemukan di ReplicatedStorage.")
end

-- Fungsi SendMessageEMBED disesuaikan agar mirip "webhook old.lua" dengan error handling lebih baik
function SendMessageEMBED(url, embed)
    if not url or url == "" then
        warn("MuiHub WARNING: URL Webhook kosong. Tekan 'Apply' terlebih dahulu.")
        return false
    end
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    -- Pastikan struktur embed sesuai format Discord, mirip old
    local embedData = {
        ["title"] = embed.title or "No Title",
        ["description"] = embed.description or "",
        ["color"] = embed.color or 3447003, -- Biru sebagai contoh, mirip old
    }
    
    -- Tambahkan fields jika ada
    if embed.fields and #embed.fields > 0 then
        embedData["fields"] = embed.fields
    end
    
    -- Tambahkan footer jika ada
    if embed.footer and embed.footer.text then
        embedData["footer"] = {
            ["text"] = embed.footer.text
        }
    end
    
    local data = {
        ["embeds"] = {embedData}
    }
    
    local body = HttpService:JSONEncode(data)
    
    -- Gunakan pcall untuk error handling, mirip old
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = body
        })
    end)
    
    if success then
        if response.Success then
            print("MuiHub: Embed sent successfully!")
            return true
        else
            warn("MuiHub WARNING: Failed to send embed. Status Code: " .. response.StatusCode)
            warn("MuiHub WARNING: Response: " .. response.Body)
            return false
        end
    else
        warn("MuiHub WARNING: Error sending embed: " .. tostring(response))
        return false
    end
end

-- Logika Test Button, mirip final tapi dengan template old
TestButton.MouseButton1Click:Connect(function()
    local testEmbed = {
        title = "Perubahan Cuaca di Server Roblox",
        description = "Nilai 'Biome' telah berubah menjadi 'Test Biome'.",
        color = 3447003,
        fields = {
            { name = "Username: " .. (player.Name or "KeylaFitF9"), value = tostring(player.UserId or "N/A"), inline = true },
            { name = "Path", value = "Biome", inline = true },
            { name = "Nilai Baru", value = "Test Biome", inline = true }
        },
        footer = { text = "Notifikasi dari Game Roblox" }
    }
    
    local success = SendMessageEMBED(appliedWebhookURL, testEmbed)
    local originalColor = TestButton.BackgroundColor3
    if success then
        TestButton.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
    else
        TestButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    task.wait(2)
    TestButton.BackgroundColor3 = originalColor
end)

-- Handler untuk event OnClientEvent, disesuaikan agar mirip "webhook old.lua"
if Event then
    Event.OnClientEvent:Connect(function(id, path, newValue)
        -- Periksa jika path adalah array dan mengandung "BiomeName" atau "Biome", mirip old
        if typeof(path) == "table" then
            local isBiomeChange = false
            local keyMatched = ""
            for _, key in ipairs(path) do
                if key == "BiomeName" or key == "Biome" then
                    isBiomeChange = true
                    keyMatched = key
                    break
                end
            end
            
            if isBiomeChange and (next(biomeWhitelist) == nil or biomeWhitelist[tostring(newValue)]) then  -- Jika whitelist kosong, selalu kirim; jika tidak, check whitelist
                -- Buat embed notifikasi mirip old
                local embed = {
                    title = "Perubahan Cuaca di Server Roblox",
                    description = string.format("Nilai '%s' telah berubah menjadi '%s'.", table.concat(path, "."), newValue),
                    color = 3447003,
                    fields = {
                        {
                            name = "Username: " .. (player.Name or "KeylaFitF9"),  -- Dinamis, fallback ke KeylaFitF9 seperti old
                            value = tostring(id or "N/A"),
                            inline = true
                        },
                        {
                            name = "Path",
                            value = table.concat(path, ", "),
                            inline = true
                        },
                        {
                            name = "Nilai Baru",
                            value = tostring(newValue),
                            inline = true
                        }
                    },
                    footer = {
                        text = "Notifikasi dari Game Roblox"
                    }
                }
                
                -- Kirim ke Discord
                SendMessageEMBED(appliedWebhookURL, embed)
            end
        end
    end)
end

print("Script Webhook Biome oleh MuiHub (v5.1-Fixed) telah dimuat! Cek console untuk warning jika ada error.")
