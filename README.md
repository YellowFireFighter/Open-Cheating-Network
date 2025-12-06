# Open Cheating Network

A distributed WebSocket communication system for Roblox scripts, allowing multiple scripts across different servers to communicate.

Used in various Roblox exploit scripts for cross-server communication.

## Features

- **Bridge System**: Servers automatically sync messages and user lists
- **Discord Integration**: Optional webhook support for logging messages
- **IP Locked**: Configurable user limits per IP address

## Server Setup

### Requirements
- Python 3.7+
- tornado
- requests

### Installation
```bash
pip install tornado requests
```

### Configuration
```python
CONFIG = {
    "secret_key": "swimdroid_is_a_furry", # CHANGE THIS
    "bridge_secret": "yellow_is_a_bad_bih", # CHANGE THIS
    "max_users_per_ip": 1,
    "rate_limit_messages": 20,
    "rate_limit_window": 10,
    "max_message_length": 500,
    "max_username_length": 20,
    "heartbeat_timeout": 10,
    "discord_webhooks": [

    ], # sends all messages sent between users to this webhook
    "bridge_servers": [
        #{"url": "http://localhost:8889/chronos", "secret": "yellow_is_a_bad_bih"}, # example testing stuff make sure secret matches the other servers bridge secret (you can put as many servers as u want)
    ] 
} 
```

### Running the Server
```bash
python server.py
```

Servers endpoints:
- `/swimhub` - WebSocket endpoint for clients
- `/chronos` - HTTP endpoint for server bridging

## Client Setup (Lua)

### Basic Usage
```lua
local IntegrationService = loadstring(request({Url = "https://raw.githubusercontent.com/YellowFireFighter/Open-Cheating-Network/refs/heads/main/Client/Main.lua", Method = "Get"}).Body)()

IntegrationService.Init({
    serverUrl = "ws://your-server.com:8888/swimhub",
    heartbeatInterval = 5,
    autoReconnect = false,
    hidden = false
})

-- Listen for messages
IntegrationService.OnChatMessage.Event:Connect(function(username, message, timestamp)
    print(string.format("[%s]: %s", username, message))
end)

-- Send messages
IntegrationService.SendMessage("Hello everyone!")

-- Get user list
IntegrationService.GetUsers()
```

### Events
- `OnChatMessage` - Fires when a chat message is received
- `OnSystemMessage` - Fires for system messages (join/leaves)
- `OnUserListUpdate` - Fires when user list is updated
- `OnConnected` - Fires when successfully connected
- `OnDisconnected` - Fires when connection is lost

### Functions
- `Init(config)` - Initialize connection to server
- `SendMessage(message)` - Send a chat message
- `GetUsers()` - Request current user list
- `SetHidden(boolean)` - Toggle hidden mode
- `IsConnected()` - Check connection status
- `IsHidden()` - Check hidden mode status
- `Disconnect()` - Close connection

## Contributors

- **Yellow**: Creator of Open Cheating Network
