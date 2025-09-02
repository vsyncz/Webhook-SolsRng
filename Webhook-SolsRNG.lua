--[[
    Script: Webhook Notifier with UI
    Original Author: Sols (Logic)
    UI & Integration: Dibuat oleh Gemini berdasarkan permintaan pengguna

    Deskripsi:
    Script ini menyediakan UI untuk mengonfigurasi notifikasi webhook Discord
    ketika biome dalam game berubah. UI ini memungkinkan pengguna untuk:
    1. Memasukkan URL webhook Discord kustom.
    2. Memilih biome mana yang akan memicu notifikasi (whitelist).
]]

--================================================================================
-- BAGIAN 1: PEMBUATAN ANTARMUKA PENGGUNA (UI)
--================================================================================

-- Hapus UI lama jika ada untuk menghindari duplikasi saat dieksekusi ulang
if game:GetService("CoreGui"):FindFirstChild("SolsWebhookUI") then
    game:GetService("CoreGui").SolsWebhookUI:Destroy()
end

-- Inisialisasi variabel global untuk elemen UI
local webhookUrlBox

-- Daftar Biome yang akan ditampilkan di UI
local availableBiomes = {
    "Windy", "BlazingSun", "Snowy", "Rainy", "Null", 
    "Sandstorm", "Hell", "Starfall", "Corruption", "Dreamspace", "Glitched"
}

-- Tabel untuk melacak status biome mana yang di-whitelist
local biomeWhitelist = {}
for _, biomeName in ipairs(availableBiomes) do
    biomeWhitelist[biomeName] = false -- Awalnya semua tidak aktif
end

-- Membuat container utama untuk UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SolsWebhookUI"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

-- Frame utama yang menjadi jendela
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -175)
MainFrame.Size = UDim2.new(0, 420, 0, 350)
MainFrame.Active = true
MainFrame.Draggable = true -- Membuat jendela bisa digeser

-- Header untuk judul dan tombol tutup
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Header.Size = UDim2.new(1, 0, 0, 30)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = Header
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, -30, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "Webhook Notifier By Sols"
TitleLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

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

-- Container untuk tombol tab di sebelah kiri
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Parent = MainFrame
TabContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
TabContainer.BorderSizePixel = 0
TabContainer.Position = UDim2.new(0, 0, 0, 30)
TabContainer.Size = UDim2.new(0, 110, 1, -30)

-- Container untuk konten dari tab yang aktif
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MainFrame
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 110, 0, 30)
ContentContainer.Size = UDim2.new(1, -110, 1, -30)

-- Fungsi untuk membuat tab
local function createTab(tabName)
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = tabName .. "Content"
    contentFrame.Parent = ContentContainer
    contentFrame.BackgroundTransparency = 1
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.Visible = false -- Sembunyikan secara default
    
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
        for _, child in ipairs(TabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                child.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
        for _, child in ipairs(ContentContainer:GetChildren()) do
            if child:IsA("Frame") then
                child.Visible = false
            end
        end
        contentFrame.Visible = true
        tabButton.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    
    return contentFrame, tabButton
end

-- Membuat layout untuk tombol tab
local tabListLayout = Instance.new("UIListLayout")
tabListLayout.Parent = TabContainer
tabListLayout.Padding = UDim.new(0, 2)

-- Membuat tab "Webhook"
local webhookTab, webhookTabButton = createTab("Webhook")

-- Mengaktifkan tab pertama secara default
webhookTabButton.MouseButton1Click:Invoke()

-- Fungsi untuk membuat kotak input webhook
local function createWebhookInput(parent)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.LayoutOrder = 1
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Text = "URL Webhook Discord:"
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    webhookUrlBox = Instance.new("TextBox")
    webhookUrlBox.Parent = parent
    webhookUrlBox.LayoutOrder = 2
    webhookUrlBox.Size = UDim2.new(1, 0, 0, 30)
    webhookUrlBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    webhookUrlBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    webhookUrlBox.Font = Enum.Font.SourceSans
    webhookUrlBox.Text = ""
    webhookUrlBox.PlaceholderText = "Tempel URL webhook Anda di sini"
    webhookUrlBox.ClearTextOnFocus = false
end

-- Fungsi untuk membuat daftar centang biome
local function createBiomeCheckboxes(parent)
    local title = Instance.new("TextLabel")
    title.Parent = parent
    title.Name = "WhitelistTitle"
    title.LayoutOrder = 3
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSans
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.Text = "Whitelist Biome (Pilih untuk notifikasi):"
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left

    local biomeContainer = Instance.new("ScrollingFrame")
    biomeContainer.Name = "BiomeContainer"
    biomeContainer.Parent = parent
    biomeContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    biomeContainer.BorderSizePixel = 1
    biomeContainer.BorderColor3 = Color3.fromRGB(50, 50, 55)
    biomeContainer.Size = UDim2.new(1, 0, 1, -85)
    biomeContainer.LayoutOrder = 4
    biomeContainer.CanvasSize = UDim2.new(0, 0, 0, #availableBiomes * 28)
    biomeContainer.ScrollBarThickness = 6

    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = biomeContainer
    listLayout.Padding = UDim.new(0, 3)

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
end

-- Menambahkan elemen ke dalam tab Webhook
createWebhookInput(webhookTab)
createBiomeCheckboxes(webhookTab)

--================================================================================
-- BAGIAN 2: LOGIKA WEBHOOK
--================================================================================

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage.ReplicaRemoteEvents.Replica_ReplicaSetValue

function SendMessageEMBED(embed)
    local webhookURL = webhookUrlBox and webhookUrlBox.Text or ""
    
    if not webhookURL:match("^https://discord.com/api/webhooks/") then
        print("URL Webhook tidak valid atau kosong. Notifikasi dibatalkan.")
        return false
    end

    local headers = { ["Content-Type"] = "application/json" }
    
    local embedData = {
        ["title"] = embed.title or "Tanpa Judul",
        ["description"] = embed.description or "",
        ["color"] = embed.color or 0,
        ["fields"] = embed.fields or {},
        ["footer"] = embed.footer or {}
    }
    
    local data = { ["embeds"] = {embedData} }
    
    pcall(function()
        HttpService:RequestAsync({
            Url = webhookURL,
            Method = "POST",
            Headers = headers,
            Body = HttpService:JSONEncode(data)
        })
        print("Notifikasi embed dikirim ke Discord!")
    end)
end

Event.OnClientEvent:Connect(function(id, path, newValue)
    if typeof(path) == "table" and newValue then
        for _, key in ipairs(path) do
            -- Cek jika event ini adalah perubahan biome DAN biome tersebut ada di whitelist
            if (key == "BiomeName" or key == "Biome") and biomeWhitelist[tostring(newValue)] then
                local embed = {
                    title = "Perubahan Biome Terdeteksi",
                    description = string.format("Biome di server telah berubah menjadi **%s**.", newValue),
                    color = 3447003, -- Biru
                    fields = {
                        {
                            name = "Username",
                            value = tostring(game.Players.LocalPlayer.Name or "Tidak ditemukan"),
                            inline = true
                        },
                        {
                            name = "Biome Baru",
                            value = tostring(newValue),
                            inline = true
                        }
                    },
                    footer = {
                        text = "Sols Notifier | " .. os.date("!%Y-%m-%d %H:%M:%S UTC")
                    }
                }
                
                SendMessageEMBED(embed)
                break -- Hentikan loop setelah menemukan dan mengirim notifikasi
            end
        end
    end
end)

print("Script Webhook dengan UI oleh Sols telah dimuat!")
