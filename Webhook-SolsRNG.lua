-- Script untuk mendengarkan perubahan cuaca dan mengirim notifikasi ke Discord via webhook
-- Ini adalah LocalScript yang ditempatkan di StarterPlayerScripts atau tempat lain yang sesuai di client-side

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage.ReplicaRemoteEvents.Replica_ReplicaSetValue
local Players = game:GetService("Players")

-- Ganti dengan URL webhook Discord Anda
local webhookURL = ""

-- Fungsi untuk mengirim embed ke Discord
function SendMessageEMBED(url, embed)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    local embedData = {
        ["title"] = embed.title or "No Title",
        ["description"] = embed.description or "",
        ["color"] = embed.color or 0,
    }
    
    if embed.fields and #embed.fields > 0 then
        embedData["fields"] = embed.fields
    end
    
    if embed.footer and embed.footer.text then
        embedData["footer"] = {
            ["text"] = embed.footer.text
        }
    end
    
    local data = {
        ["embeds"] = {embedData}
    }
    
    local body = HttpService:JSONEncode(data)
    
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
            print("Embed sent successfully!")
            return true
        else
            print("Failed to send embed. Status Code: " .. response.StatusCode)
            print("Response: " .. response.Body)
            return false
        end
    else
        print("Error sending embed: " .. tostring(response))
        return false
    end
end

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.Text = "Feed The Noob Tycoon Exploit By Balgo"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.Gotham
titleLabel.TextSize = 18
titleLabel.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Parent = mainFrame

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 350)
tabFrame.Position = UDim2.new(0, 0, 0, 50)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainFrame

local tabList = Instance.new("UIListLayout")
tabList.Padding = UDim.new(0, 5)
tabList.Parent = tabFrame

local tabButtons = {
    {Name = "Auto", Content = function() end},
    {Name = "Misc", Content = function() end},
    {Name = "Teleport Player", Content = function() end},
    {Name = "Webhook", Content = function()
        local webhookContent = Instance.new("Frame")
        webhookContent.Size = UDim2.new(1, 0, 1, 0)
        webhookContent.BackgroundTransparency = 1
        webhookContent.Parent = tabFrame

        local whitelistLabel = Instance.new("TextLabel")
        whitelistLabel.Size = UDim2.new(1, 0, 0, 20)
        whitelistLabel.Position = UDim2.new(0, 10, 0, 10)
        whitelistLabel.Text = "Whitelist Biome:"
        whitelistLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        whitelistLabel.Parent = webhookContent

        local whitelistDropdown = Instance.new("TextBox")
        whitelistDropdown.Size = UDim2.new(1, -20, 0, 30)
        whitelistDropdown.Position = UDim2.new(0, 10, 0, 35)
        whitelistDropdown.Text = "Windy, BlazingSun, Snowy, Rainy, Null, Sandstorm, Hell, Starfall, Corruption, Dreamspace, Glitched"
        whitelistDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
        whitelistDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        whitelistDropdown.Parent = webhookContent

        local webhookLabel = Instance.new("TextLabel")
        webhookLabel.Size = UDim2.new(1, 0, 0, 20)
        webhookLabel.Position = UDim2.new(0, 10, 0, 75)
        webhookLabel.Text = "Webhook URL:"
        webhookLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        webhookLabel.Parent = webhookContent

        local webhookInput = Instance.new("TextBox")
        webhookInput.Size = UDim2.new(1, -20, 0, 30)
        webhookInput.Position = UDim2.new(0, 10, 0, 100)
        webhookInput.Text = webhookURL
        webhookInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        webhookInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        webhookInput.Parent = webhookContent

        webhookInput.FocusLost:Connect(function()
            webhookURL = webhookInput.Text
        end)
    end}
}

for _, tab in ipairs(tabButtons) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 40)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.Text = tab.Name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = tabFrame

    button.MouseButton1Click:Connect(function()
        for _, btn in ipairs(tabFrame:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end
        end
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        for _, child in ipairs(tabFrame:GetChildren()) do
            if child ~= tabList and child ~= button then
                child:Destroy()
            end
        end
        tab.Content()
    end)
end

-- Handler untuk event OnClientEvent
Event.OnClientEvent:Connect(function(id, path, newValue)
    if typeof(path) == "table" then
        for _, key in ipairs(path) do
            if key == "BiomeName" or key == "Biome" then
                local whitelist = {}
                for biome in string.gmatch(whitelistDropdown.Text, "[^,]+") do
                    table.insert(whitelist, biome:match("^%s*(.-)%s*$"))
                end
                if table.find(whitelist, tostring(newValue)) then
                    local embed = {
                        title = "Perubahan Cuaca di Server Roblox",
                        description = string.format("Nilai '%s' telah berubah menjadi '%s'.", table.concat(path, "."), newValue),
                        color = 3447003,
                        fields = {
                            {
                                name = "Username: KeylaFitF9",
                                value = tostring(id),
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
                    
                    SendMessageEMBED(webhookURL, embed)
                end
                break
            end
        end
    end
end)

print("Script webhook cuaca siap mendengarkan perubahan!")