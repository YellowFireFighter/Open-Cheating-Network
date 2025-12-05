-- Shit ui made with gui to lua but u can use if u want ig
local IntegrationService = loadstring(request({Url = "https://raw.githubusercontent.com/YellowFireFighter/Open-Cheating-Network/refs/heads/main/Client/Main.lua", Method = "Get"}).Body)()

local active_tab = "chat"
local messages = {}
local users_list = {}
local is_connected = false
local is_hidden = false
local current_username = ""
local tween_service = game:GetService("TweenService")

local function create(class, props)
    local inst = Instance.new(class)
    for prop, val in pairs(props) do
        if prop ~= "Parent" then
            inst[prop] = val
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function tween(obj, props, time, style, direction)
    local tween_info = TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
    local tween = tween_service:Create(obj, tween_info, props)
    tween:Play()
    return tween
end

local screen_gui = create("ScreenGui", {
    Name = "ocn_chat_ui",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = game:GetService("CoreGui")
})

local main_frame = create("Frame", {
    Name = "main_frame",
    Size = UDim2.new(0, 480, 0, 520),
    Position = UDim2.new(0.5, -240, 0.5, -260),
    BackgroundColor3 = Color3.fromRGB(20, 20, 25),
    BorderColor3 = Color3.fromRGB(60, 60, 80),
    BorderSizePixel = 2,
    Parent = screen_gui
})

main_frame.Position = UDim2.new(0.5, -240, 0.5, -350)
tween(main_frame, {Position = UDim2.new(0.5, -240, 0.5, -260)}, 0.5, Enum.EasingStyle.Back)

local dragging = false
local drag_input
local drag_start
local start_pos

main_frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        drag_start = input.Position
        start_pos = main_frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

main_frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        drag_input = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == drag_input and dragging then
        local delta = input.Position - drag_start
        main_frame.Position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + delta.X, start_pos.Y.Scale, start_pos.Y.Offset + delta.Y)
    end
end)

local header_frame = create("Frame", {
    Name = "header_frame",
    Size = UDim2.new(1, 0, 0, 35),
    BackgroundColor3 = Color3.fromRGB(15, 15, 20),
    BorderSizePixel = 0,
    Parent = main_frame
})

local header_border = create("Frame", {
    Name = "header_border",
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(60, 60, 80),
    BorderSizePixel = 0,
    Parent = header_frame
})

local title_label = create("TextLabel", {
    Name = "title_label",
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 15, 0, 0),
    BackgroundTransparency = 1,
    Text = "OCN",
    TextColor3 = Color3.fromRGB(200, 200, 210),
    TextSize = 14,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = header_frame
})

local close_button = create("TextButton", {
    Name = "close_button",
    Size = UDim2.new(0, 25, 0, 25),
    Position = UDim2.new(1, -30, 0, 5),
    BackgroundColor3 = Color3.fromRGB(140, 50, 60),
    BorderColor3 = Color3.fromRGB(100, 30, 40),
    BorderSizePixel = 1,
    Text = "X",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 12,
    Font = Enum.Font.Code,
    Parent = header_frame
})

close_button.MouseButton1Click:Connect(function()
    tween(main_frame, {Position = UDim2.new(0.5, -240, 0.5, -350)}, 0.3)
    task.wait(0.3)
    screen_gui:Destroy()
    IntegrationService.Disconnect()
end)

local hidden_button = create("TextButton", {
    Name = "hidden_button",
    Size = UDim2.new(0, 70, 0, 25),
    Position = UDim2.new(1, -105, 0, 5),
    BackgroundColor3 = Color3.fromRGB(40, 40, 50),
    BorderColor3 = Color3.fromRGB(60, 60, 80),
    BorderSizePixel = 1,
    Text = "HIDDEN",
    TextColor3 = Color3.fromRGB(150, 150, 160),
    TextSize = 11,
    Font = Enum.Font.Code,
    Parent = header_frame
})

local tabs_frame = create("Frame", {
    Name = "tabs_frame",
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 35),
    BackgroundColor3 = Color3.fromRGB(15, 15, 20),
    BorderSizePixel = 0,
    Parent = main_frame
})

local tabs_border = create("Frame", {
    Name = "tabs_border",
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(60, 60, 80),
    BorderSizePixel = 0,
    Parent = tabs_frame
})

local chat_tab = create("TextButton", {
    Name = "chat_tab",
    Size = UDim2.new(0.5, -1, 0, 30),
    Position = UDim2.new(0, 0, 0, 5),
    BackgroundColor3 = Color3.fromRGB(100, 80, 180),
    BorderColor3 = Color3.fromRGB(120, 100, 200),
    BorderSizePixel = 1,
    Text = "Chatbox",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 12,
    Font = Enum.Font.Code,
    Parent = tabs_frame
})

local users_tab = create("TextButton", {
    Name = "users_tab",
    Size = UDim2.new(0.5, -1, 0, 30),
    Position = UDim2.new(0.5, 2, 0, 5),
    BackgroundColor3 = Color3.fromRGB(40, 40, 50),
    BorderColor3 = Color3.fromRGB(60, 60, 80),
    BorderSizePixel = 1,
    Text = "Users",
    TextColor3 = Color3.fromRGB(150, 150, 160),
    TextSize = 12,
    Font = Enum.Font.Code,
    Parent = tabs_frame
})

local content_frame = create("Frame", {
    Name = "content_frame",
    Size = UDim2.new(1, -20, 1, -145),
    Position = UDim2.new(0, 10, 0, 80),
    BackgroundColor3 = Color3.fromRGB(15, 15, 20),
    BorderColor3 = Color3.fromRGB(60, 60, 80),
    BorderSizePixel = 1,
    ClipsDescendants = true,
    Parent = main_frame
})

local chat_scroll = create("ScrollingFrame", {
    Name = "chat_scroll",
    Size = UDim2.new(1, -8, 1, -8),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Parent = content_frame
})

local chat_list = create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
    Parent = chat_scroll
})

chat_list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    chat_scroll.CanvasSize = UDim2.new(0, 0, 0, chat_list.AbsoluteContentSize.Y + 8)
    chat_scroll.CanvasPosition = Vector2.new(0, chat_scroll.CanvasSize.Y.Offset)
end)

local users_scroll = create("ScrollingFrame", {
    Name = "users_scroll",
    Size = UDim2.new(1, -8, 1, -8),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Visible = false,
    Parent = content_frame
})

local users_list_layout = create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
    Parent = users_scroll
})

users_list_layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    users_scroll.CanvasSize = UDim2.new(0, 0, 0, users_list_layout.AbsoluteContentSize.Y + 8)
end)

local input_frame = create("Frame", {
    Name = "input_frame",
    Size = UDim2.new(1, -20, 0, 50),
    Position = UDim2.new(0, 10, 1, -60),
    BackgroundColor3 = Color3.fromRGB(15, 15, 20),
    BorderColor3 = Color3.fromRGB(60, 60, 80),
    BorderSizePixel = 1,
    Parent = main_frame
})

local input_box = create("TextBox", {
    Name = "input_box",
    Size = UDim2.new(1, -60, 1, -10),
    Position = UDim2.new(0, 5, 0, 5),
    BackgroundColor3 = Color3.fromRGB(25, 25, 30),
    BorderColor3 = Color3.fromRGB(50, 50, 65),
    BorderSizePixel = 1,
    Text = "",
    PlaceholderText = "Type message...",
    PlaceholderColor3 = Color3.fromRGB(100, 100, 110),
    TextColor3 = Color3.fromRGB(200, 200, 210),
    TextSize = 12,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    Parent = input_frame
})

create("UIPadding", {
    PaddingLeft = UDim.new(0, 5),
    Parent = input_box
})

local send_button = create("TextButton", {
    Name = "send_button",
    Size = UDim2.new(0, 50, 1, -10),
    Position = UDim2.new(1, -55, 0, 5),
    BackgroundColor3 = Color3.fromRGB(80, 120, 80),
    BorderColor3 = Color3.fromRGB(100, 140, 100),
    BorderSizePixel = 1,
    Text = "SEND",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    Font = Enum.Font.Code,
    Parent = input_frame
})

local status_label = create("TextLabel", {
    Name = "status_label",
    Size = UDim2.new(1, -20, 0, 15),
    Position = UDim2.new(0, 10, 1, 2),
    BackgroundTransparency = 1,
    Text = "Status: Connecting",
    TextColor3 = Color3.fromRGB(150, 150, 160),
    TextSize = 11,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = main_frame
})

local status_dots = 0
local status_base_text = "Status: Connecting"
local animating_dots = false

local function update_status(new_text, animate_type)
    animating_dots = false -- Stop any ongoing animations
    
    if animate_type == "typewriter" then
        task.spawn(function()
            local old_text = status_label.Text
            -- Erase old text
            for i = #old_text, 0, -1 do
                status_label.Text = old_text:sub(1, i)
                task.wait(0.02)
            end
            -- Type new text
            for i = 1, #new_text do
                status_label.Text = new_text:sub(1, i)
                task.wait(0.02)
            end
        end)
    elseif animate_type == "dots" then
        animating_dots = true
        status_dots = 0
        task.spawn(function()
            while animating_dots and not is_connected do
                status_dots = (status_dots % 3) + 1
                status_label.Text = new_text .. string.rep(".", status_dots)
                task.wait(0.5)
            end
        end)
    else
        -- Instant update
        status_label.Text = new_text
    end
end

update_status("Status: Connecting", "dots")

local function add_message(username, message_text)
    local message_frame = create("Frame", {
        Size = UDim2.new(1, -5, 0, 0),
        BackgroundTransparency = 1,
        Parent = chat_scroll
    })
    
    local username_label = create("TextLabel", {
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundTransparency = 1,
        Text = username,
        TextColor3 = username == "SYSTEM" and Color3.fromRGB(150, 150, 160) or Color3.fromRGB(150, 120, 220),
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTransparency = 1,
        Parent = message_frame
    })
    
    local message_label = create("TextLabel", {
        Size = UDim2.new(1, -105, 1, 0),
        Position = UDim2.new(0, 105, 0, 0),
        BackgroundTransparency = 1,
        Text = message_text,
        TextColor3 = Color3.fromRGB(200, 200, 210),
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        TextTransparency = 1,
        Parent = message_frame
    })
    
    tween(message_frame, {Size = UDim2.new(1, -5, 0, 20)}, 0.3, Enum.EasingStyle.Back)
    tween(username_label, {TextTransparency = 0}, 0.3)
    tween(message_label, {TextTransparency = 0}, 0.3)
end

local function update_users_list()
    for _, child in pairs(users_scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if is_hidden then
        local hidden_frame = create("Frame", {
            Size = UDim2.new(1, -5, 0, 100),
            BackgroundTransparency = 1,
            Parent = users_scroll
        })
        
        local hidden_label = create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "HIDDEN MODE\n\nUser list unavailable",
            TextColor3 = Color3.fromRGB(150, 150, 160),
            TextSize = 14,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = hidden_frame
        })
        return
    end
    
    for _, username in ipairs(users_list) do
        local user_frame = create("Frame", {
            Size = UDim2.new(1, -5, 0, 25),
            BackgroundColor3 = Color3.fromRGB(25, 25, 30),
            BorderColor3 = Color3.fromRGB(50, 50, 65),
            BorderSizePixel = 1,
            Parent = users_scroll
        })
        
        local user_label = create("TextLabel", {
            Size = UDim2.new(1, -10, 1, 0),
            Position = UDim2.new(0, 5, 0, 0),
            BackgroundTransparency = 1,
            Text = username,
            TextColor3 = Color3.fromRGB(150, 120, 220),
            TextSize = 12,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = user_frame
        })
        
        user_frame.Size = UDim2.new(1, -5, 0, 0)
        tween(user_frame, {Size = UDim2.new(1, -5, 0, 25)}, 0.2)
    end
end

local function switch_tab(tab)
    active_tab = tab
    if tab == "chat" then
        tween(chat_tab, {BackgroundColor3 = Color3.fromRGB(100, 80, 180), TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
        tween(users_tab, {BackgroundColor3 = Color3.fromRGB(40, 40, 50), TextColor3 = Color3.fromRGB(150, 150, 160)}, 0.2)
        chat_scroll.Visible = true
        users_scroll.Visible = false
        input_frame.Visible = not is_hidden
    else
        tween(users_tab, {BackgroundColor3 = Color3.fromRGB(100, 80, 180), TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
        tween(chat_tab, {BackgroundColor3 = Color3.fromRGB(40, 40, 50), TextColor3 = Color3.fromRGB(150, 150, 160)}, 0.2)
        chat_scroll.Visible = false
        users_scroll.Visible = true
        input_frame.Visible = false
        if not is_hidden then
            IntegrationService.GetUsers()
        else
            update_users_list()
        end
    end
end

local function send_message()
    local text = input_box.Text
    if text ~= "" and is_connected and not is_hidden then
        IntegrationService.SendMessage(text)
        input_box.Text = ""
        
        local original_size = send_button.Size
        tween(send_button, {Size = UDim2.new(0, 45, 1, -10)}, 0.1)
        task.wait(0.1)
        tween(send_button, {Size = original_size}, 0.1, Enum.EasingStyle.Back)
    end
end

chat_tab.MouseButton1Click:Connect(function()
    switch_tab("chat")
end)

users_tab.MouseButton1Click:Connect(function()
    switch_tab("users")
end)

hidden_button.MouseButton1Click:Connect(function()
    is_hidden = not is_hidden
    IntegrationService.SetHidden(is_hidden)
    if is_hidden then
        hidden_button.Text = "VISIBLE"
        tween(hidden_button, {BackgroundColor3 = Color3.fromRGB(80, 120, 80), TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
        if active_tab == "chat" then
            tween(input_frame, {Position = UDim2.new(0, 10, 1, -10)}, 0.3, Enum.EasingStyle.Back)
            task.wait(0.3)
            input_frame.Visible = false
            input_frame.Position = UDim2.new(0, 10, 1, -60)
        end
    else
        hidden_button.Text = "HIDDEN"
        tween(hidden_button, {BackgroundColor3 = Color3.fromRGB(40, 40, 50), TextColor3 = Color3.fromRGB(150, 150, 160)}, 0.2)
        if active_tab == "chat" then
            input_frame.Visible = true
            input_frame.Position = UDim2.new(0, 10, 1, -10)
            tween(input_frame, {Position = UDim2.new(0, 10, 1, -60)}, 0.3, Enum.EasingStyle.Back)
        end
    end
    if active_tab == "users" then
        update_users_list()
    end
end)

send_button.MouseButton1Click:Connect(send_message)

send_button.MouseEnter:Connect(function()
    tween(send_button, {BackgroundColor3 = Color3.fromRGB(90, 140, 90)}, 0.15)
end)

send_button.MouseLeave:Connect(function()
    tween(send_button, {BackgroundColor3 = Color3.fromRGB(80, 120, 80)}, 0.15)
end)

close_button.MouseEnter:Connect(function()
    tween(close_button, {BackgroundColor3 = Color3.fromRGB(180, 60, 70)}, 0.15)
end)

close_button.MouseLeave:Connect(function()
    tween(close_button, {BackgroundColor3 = Color3.fromRGB(140, 50, 60)}, 0.15)
end)

input_box.FocusLost:Connect(function(enter_pressed)
    if enter_pressed then
        send_message()
    end
end)

IntegrationService.OnChatMessage.Event:Connect(function(username, message, timestamp)
    if not is_hidden then
        add_message(username, message)
    end
end)

IntegrationService.OnSystemMessage.Event:Connect(function(message, timestamp)
    if not is_hidden then
        add_message("SYSTEM", message)
    end
end)

IntegrationService.OnUserListUpdate.Event:Connect(function(users, timestamp)
    if not is_hidden then
        users_list = users
        update_users_list()
    end
end)

IntegrationService.OnConnected.Event:Connect(function(username, token, hidden)
    current_username = username
    is_connected = true
    is_hidden = hidden
    animating_dots = false
    local old_text = status_label.Text
    local new_text = "Status: Connected as " .. username
    update_status("Status: Connected as " .. username, "typewriter")
    tween(status_label, {TextColor3 = Color3.fromRGB(100, 200, 100)}, 0.3)
end)

IntegrationService.OnDisconnected.Event:Connect(function()
    is_connected = false
    local old_text = status_label.Text
    status_base_text = "Status: Disconnected"
    update_status("Status: Disconnected", "typewriter")
    tween(status_label, {TextColor3 = Color3.fromRGB(200, 100, 100)}, 0.3)
end)

IntegrationService.OnError.Event:Connect(function(error_message, timestamp)
    add_message("ERROR", error_message)
end)

IntegrationService.Init({
    serverUrl = "ws://localhost:8888/swimhub",
    heartbeatInterval = 5,
    autoReconnect = true,
    hidden = false
})