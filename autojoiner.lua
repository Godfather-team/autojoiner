-- GODFATHER AUTOJOINER v3.0 (Sessiz ve Profesyonel)
-- Kullanım: 
-- Discord_token = "token" 
-- channelId = "kanal_id" 
-- Delay_BetweenHits = 1 
-- loadstring(game:HttpGet('https://godfather-joiner.vercel.app/autojoiner.lua'))()

-- Gerekli servisler
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local plr = Players.LocalPlayer

-- Kullanıcı değişkenlerini kontrol et (sessizce)
local TOKEN = Discord_token
local CHANNEL = channelId
local DELAY = Delay_BetweenHits or 1
local MM2_PLACE_ID = 142823291

-- Token veya channel yoksa sessizce dur
if not TOKEN or not CHANNEL then return end

-- WebSocket bağlantısını kur
local ws = WebSocket.connect("wss://gateway.discord.gg/?v=9&encoding=json")

-- Bağlantı başarısız olursa sessizce dene
local heartbeatTask
ws.OnMessage:Connect(function(msg)
    local data = HttpService:JSONDecode(msg)
    
    -- Heartbeat başlat
    if data.op == 10 then
        local interval = data.d.heartbeat_interval / 1000
        heartbeatTask = task.spawn(function()
            while ws do
                task.wait(interval)
                pcall(function()
                    ws:Send(HttpService:JSONEncode({ op = 1, d = nil }))
                end)
            end
        end)
    end
    
    -- Yeni mesajları işle
    if data.t == "MESSAGE_CREATE" then
        local msgData = data.d
        if msgData.channel_id == CHANNEL then
            local content = msgData.content or ""
            
            if content:find("@everyone") then
                -- PlaceId ve JobId'yi bul
                local placeId = content:match("placeId=(%d+)") 
                    or content:match("PlaceId=(%d+)")
                    or content:match("game:Teleport%((%d+)")
                    or content:match("(%d+),")
                
                local jobId = content:match("jobId=(%w+-%w+-%w+-%w+-%w+)")
                    or content:match("JobId=(%w+-%w+-%w+-%w+-%w+)")
                    or content:match('"(%w+-%w+-%w+-%w+-%w+)"')
                
                if placeId and jobId then
                    task.wait(DELAY)
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(placeId, jobId, plr)
                    end)
                end
            end
        end
    end
end)

-- Bağlantı koparsa sessizce yeniden bağlan
ws.OnClose:Connect(function()
    if heartbeatTask then task.cancel(heartbeatTask) end
    task.wait(5)
    pcall(function()
        loadstring(game:HttpGet("https://godfather-joiner.vercel.app/autojoiner.lua"))()
    end)
end)

-- Discord'a bağlan
pcall(function()
    ws:Send(HttpService:JSONEncode({
        op = 2,
        d = {
            token = TOKEN,
            properties = {
                ["$os"] = "windows",
                ["$browser"] = "chrome",
                ["$device"] = "pc"
            },
            intents = 512
        }
    }))
end)

-- AFK koruması
plr.Idled:Connect(function()
    pcall(function()
        game:GetService("VirtualUser"):CaptureController()
        game:GetService("VirtualUser"):ClickButton2(Vector2.new())
    end)
end)

-- Script burada sessizce çalışmaya devam eder
