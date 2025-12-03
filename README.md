# Open Cheating Network

A distributed WebSocket chat system for Roblox exploits, allowing multiple scripts across different servers to communicate seamlessly.

Used in various Roblox exploit scripts for cross-server communication.

## Features

- **Distributed Architecture**: Multiple servers act as one unified network
- **Bridge System**: Servers automatically sync messages and user lists
- **Hidden Mode**: Users can connect without appearing in user lists or receiving messages
- **Rate Limiting**: Built-in protection against spam and abuse
- **Discord Integration**: Optional webhook support for logging messages
- **Secure Authentication**: HMAC-SHA256 tokens and bridge authentication with shared secrets
- **Auto-reconnect**: Clients automatically reconnect on disconnection
- **IP-based Limits**: Configurable user limits per IP address

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
    "secret_key": "your-secret-key",
    "bridge_secret": "your-bridge-secret",
    "max_users_per_ip": 1,
    "rate_limit_messages": 20,
    "rate_limit_window": 10,
    "max_message_length": 500,
    "max_username_length": 20,
    "heartbeat_timeout": 10,
    "discord_webhook": "https://discord.com/api/webhooks/...",
    "bridge_servers": [
        {"url": "http://other-server.com:8888/bridge", "secret": "their-secret"}
    ]
}
```

### Running the Server
```bash
python server.py
```

Server will start on port 8888 with two endpoints:
- `/swimhub` - WebSocket endpoint for clients
- `/bridge` - HTTP endpoint for server bridging

## Client Setup (Lua)

### Basic Usage
```lua
local IntegrationService = loadstring(game:HttpGet("https://your-server.com/client.lua"))()

IntegrationService.Init({
    serverUrl = "ws://your-server.com:8888/swimhub",
    heartbeatInterval = 5,
    autoReconnect = true,
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
- `OnSystemMessage` - Fires for system messages (joins/leaves)
- `OnUserListUpdate` - Fires when user list is updated
- `OnConnected` - Fires when successfully connected
- `OnDisconnected` - Fires when connection is lost
- `OnError` - Fires on server errors

### Functions
- `Init(config)` - Initialize connection to server
- `SendMessage(message)` - Send a chat message
- `GetUsers()` - Request current user list
- `SetHidden(boolean)` - Toggle hidden mode
- `IsConnected()` - Check connection status
- `IsHidden()` - Check hidden mode status
- `Disconnect()` - Close connection

## Bridge System

The bridge system allows multiple servers to act as one network:

1. Each server has its own `bridge_secret`
2. Servers list other servers in `bridge_servers` with their secrets
3. Messages automatically sync across all bridged servers
4. User lists combine users from all servers
5. Each server sends messages to its own Discord webhook

### Security
- Only servers with valid secrets can connect
- Each server verifies incoming bridge requests
- Rate limiting prevents abuse
- Tokens expire after 24 hours

## Hidden Mode

Users in hidden mode:
- Don't appear in user lists
- Don't receive chat messages
- Can't send messages
- Can't view user lists
- Don't trigger join/leave notifications

Useful for lurking or monitoring without being visible.

## Contributors

- **Yellow**: Creator of Open Cheating Network
