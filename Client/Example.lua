local IntegrationService = loadstring(request({Url = "https://raw.githubusercontent.com/YellowFireFighter/Open-Cheating-Network/refs/heads/main/Client/Main.lua", Method = "Get"}).Body)()

IntegrationService.OnChatMessage.Event:Connect(function(username, message, timestamp)
    print(string.format("[%s]: %s", username, message))
end)

IntegrationService.OnSystemMessage.Event:Connect(function(message, timestamp)
    print("[SYSTEM]", message)
end)

IntegrationService.OnUserListUpdate.Event:Connect(function(users, timestamp)
    print("[USERS]", table.concat(users, ", "))
end)

IntegrationService.OnConnected.Event:Connect(function(username, token, hidden)
    print("Connected as:", username)
    print("Auth token:", token)
    print("Hidden mode:", hidden)
end)

IntegrationService.OnDisconnected.Event:Connect(function()
    print("Disconnected from server")
end)

IntegrationService.OnError.Event:Connect(function(errorMessage, timestamp)
    warn("Server error:", errorMessage)
end)

if IntegrationService.IsConnected() then
    print("Connected!")
end

if IntegrationService.IsHidden() then
    print("Running in hidden mode")
end

-- Init after everything is setup
IntegrationService.Init({
    serverUrl = "ws://localhost:8888/swimhub", -- ws for local host, wss for secure links
    heartbeatInterval = 5,
    autoReconnect = true,
    hidden = false
})

IntegrationService.SendMessage("Hello everyone!")

IntegrationService.GetUsers()

IntegrationService.SetHidden(true)

IntegrationService.SetHidden(false)

IntegrationService.Disconnect()