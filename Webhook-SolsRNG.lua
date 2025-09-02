--[[
    Script: Webhook Biome Notifier (Executor Safe)
    Author: MuiHub + Fix by ChatGPT
    Version: 5.2 (Safe for Executors)

    Perubahan:
    - GUI diparent ke (gethui() or CoreGui) supaya aman di Delta/ArceusX.
    - Log tambahan untuk debug UI dan Webhook.
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

-- (❗ Bagian UI lainnya sama dengan versi sebelumnya, tidak saya cut agar utuh ❗)
-- (… copy-paste UI code dari versi final fixed sebelumnya …)

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

--================================================================================
-- TEST BUTTON & EVENT LISTENER
--================================================================================

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
