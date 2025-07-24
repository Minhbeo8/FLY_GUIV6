
local lp = game:GetService("Players").LocalPlayer
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local currentCamera = workspace.CurrentCamera

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "FlyGUI_FullControl"
gui.ResetOnSpawn = false

local isEditMode = false
local allButtons = {}
local toggleButton = nil
local startX, startY, btnW, btnH = 50, 120, 55, 45

local mainFrame = Instance.new("Frame", gui); mainFrame.Name = "Container"; mainFrame.Position = UDim2.new(0, startX, 0, startY); mainFrame.Size = UDim2.new(0, btnW * 4, 0, btnH * 3); mainFrame.BackgroundTransparency = 1; mainFrame.Draggable = true; mainFrame.Active = true; mainFrame.ZIndex = 9

local buttonsData = {
    {Name = "Toggle", Text = "Edit Layout", Pos = UDim2.new(0,0,0,0), Size = UDim2.new(0,btnW,0,btnH), Color = Color3.fromRGB(200,50,50)},
    {Name = "Title", Text = "Anchor Fly", Pos = UDim2.new(0,btnW,0,0), Size = UDim2.new(0,btnW*2,0,btnH), Color = Color3.fromRGB(255,182,229)},
    {Name = "Close", Text = "X", Pos = UDim2.new(0,0,0,btnH), Size = UDim2.new(0,btnW,0,btnH), Color = Color3.fromRGB(255,0,0)},
    {Name = "Minimize", Text = "-", Pos = UDim2.new(0,btnW,0,btnH), Size = UDim2.new(0,btnW,0,btnH), Color = Color3.fromRGB(211,243,255)},
    {Name = "Up", Text = "UP", Pos = UDim2.new(0,btnW*2,0,btnH), Size = UDim2.new(0,btnW,0,btnH), Color = Color3.fromRGB(120,255,150)},
    {Name = "PlusSpeed", Text = "+", Pos = UDim2.new(0,btnW*3,0,btnH), Size = UDim2.new(0,btnW,0,btnH), Color = Color3.fromRGB(211,243,255)},
    {Name = "Fly", Text = "fly", Pos = UDim2.new(0,0,0,btnH*2), Size = UDim2.new(0,btnW,0,btnH), Color = Color3.fromRGB(255,255,150)},
    {Name = "SpeedLabel", Text = "50", Pos = UDim2.new(0,btnW,0,btnH*2), Size = UDim2.new(0,btnW,0,btnH), Color = Color3.fromRGB(255,128,0)},
    {Name = "Down", Text = "DOWN", Pos = UDim2.new(0,btnW*2,0,btnH*2), Size = UDim2.new(0,btnW,0,btnH), Color = Color3.fromRGB(230,255,150)},
    {Name = "MinusSpeed", Text = "-", Pos = UDim2.new(0,btnW*3,0,btnH*2), Size = UDim2.new(0,btnW,0,btnH), Color = Color3.fromRGB(203,195,227)}
}

local buttons = {}
for _, data in ipairs(buttonsData) do
    local btn = Instance.new("TextButton")
    btn.Parent = mainFrame
    btn.Text = data.Text
    btn.Position = data.Pos
    btn.Size = data.Size
    btn.BackgroundColor3 = data.Color
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSansBold
    btn.TextColor3 = data.Name == "Toggle" and Color3.new(1,1,1) or Color3.new(0,0,0)
    btn.ZIndex = 10
    btn.Draggable = false
    table.insert(allButtons, btn)
    if data.Name then buttons[data.Name] = btn end
    if data.Name == "Toggle" then toggleButton = btn end
end

local keysDown = {}

local moveDPad
if uis.TouchEnabled then
    moveDPad = Instance.new("Frame", gui)
    moveDPad.Name = "MoveDPad"
    moveDPad.Size = UDim2.new(0, 150, 0, 100)
    moveDPad.Position = UDim2.new(0, 20, 1, -120)
    moveDPad.BackgroundTransparency = 1
    moveDPad.Active = true
    moveDPad.Draggable = false

    local function createMobileButton(props)
        local btn = Instance.new("TextButton")
        for p, v in pairs(props) do btn[p] = v end
        btn.Parent = moveDPad
        btn.TextScaled = true
        btn.Font = Enum.Font.SourceSansBold
        btn.TextColor3 = Color3.new(0,0,0)
        return btn
    end

    local forwardBtn = createMobileButton({Text="▲", Position=UDim2.new(0.5,-22.5,0,0), Size=UDim2.new(0,45,0,45), BackgroundColor3=Color3.fromRGB(211, 243, 255)})
    local backBtn = createMobileButton({Text="▼", Position=UDim2.new(0.5,-22.5,1,-45), Size=UDim2.new(0,45,0,45), BackgroundColor3=Color3.fromRGB(211, 243, 255)})
    local leftBtn = createMobileButton({Text="◄", Position=UDim2.new(0,0,0.5,-22.5), Size=UDim2.new(0,45,0,45), BackgroundColor3=Color3.fromRGB(211, 243, 255)})
    local rightBtn = createMobileButton({Text="►", Position=UDim2.new(1,-45,0.5,-22.5), Size=UDim2.new(0,45,0,45), BackgroundColor3=Color3.fromRGB(211, 243, 255)})

    forwardBtn.InputBegan:Connect(function() keysDown[Enum.KeyCode.W] = true end)
    forwardBtn.InputEnded:Connect(function() keysDown[Enum.KeyCode.W] = false end)
    backBtn.InputBegan:Connect(function() keysDown[Enum.KeyCode.S] = true end)
    backBtn.InputEnded:Connect(function() keysDown[Enum.KeyCode.S] = false end)
    leftBtn.InputBegan:Connect(function() keysDown[Enum.KeyCode.A] = true end)
    leftBtn.InputEnded:Connect(function() keysDown[Enum.KeyCode.A] = false end)
    rightBtn.InputBegan:Connect(function() keysDown[Enum.KeyCode.D] = true end)
    rightBtn.InputEnded:Connect(function() keysDown[Enum.KeyCode.D] = false end)
end

local isFlying, flySpeed, flightConnection = false, 50, nil

local function flyLoop(deltaTime)
    if isEditMode or not isFlying or not lp.Character or not lp.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = lp.Character.HumanoidRootPart
    if not hrp.Anchored then hrp.Anchored = true end

    
    local moveDirection = Vector3.new()
    if keysDown[Enum.KeyCode.W] then moveDirection = moveDirection + currentCamera.CFrame.LookVector end
    if keysDown[Enum.KeyCode.S] then moveDirection = moveDirection - currentCamera.CFrame.LookVector end
    if keysDown[Enum.KeyCode.D] then moveDirection = moveDirection + currentCamera.CFrame.RightVector end
    if keysDown[Enum.KeyCode.A] then moveDirection = moveDirection - currentCamera.CFrame.RightVector end

    local verticalDirection = Vector3.new()
    if keysDown[Enum.KeyCode.E] or keysDown[Enum.KeyCode.Space] then verticalDirection = verticalDirection + Vector3.new(0, 1, 0) end
    if keysDown[Enum.KeyCode.Q] or keysDown[Enum.KeyCode.LeftShift] then verticalDirection = verticalDirection - Vector3.new(0, 1, 0) end

    local finalMoveDir = Vector3.new(moveDirection.X, 0, moveDirection.Z) + verticalDirection
    
    if finalMoveDir.Magnitude > 0.01 then
        local newPos = hrp.Position + (finalMoveDir.Unit * flySpeed * deltaTime)
        hrp.CFrame = CFrame.new(newPos)
    end
end

local function toggleFly(state)
    isFlying = state
    buttons.Fly.BackgroundColor3 = isFlying and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(255, 255, 150)
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if isFlying then
        hrp.Anchored = true
        flightConnection = rs.Heartbeat:Connect(flyLoop)
    else
        hrp.Anchored = false
        if flightConnection then flightConnection:Disconnect() flightConnection = nil end
    end
end

buttons.Fly.MouseButton1Click:Connect(function() toggleFly(not isFlying) end)
local function updateSpeedLabel() buttons.SpeedLabel.Text = tostring(flySpeed) end
buttons.PlusSpeed.MouseButton1Click:Connect(function() flySpeed = math.min(flySpeed + 10, 1000); updateSpeedLabel() end)
buttons.MinusSpeed.MouseButton1Click:Connect(function() flySpeed = math.max(1, flySpeed - 10); updateSpeedLabel() end)
updateSpeedLabel()
uis.InputBegan:Connect(function(input, gpe) if not gpe then keysDown[input.KeyCode] = true end end)
uis.InputEnded:Connect(function(input, gpe) if not gpe then keysDown[input.KeyCode] = false end end)

buttons.Up.InputBegan:Connect(function() keysDown[Enum.KeyCode.E] = true end)
buttons.Up.InputEnded:Connect(function() keysDown[Enum.KeyCode.E] = false end)
buttons.Down.InputBegan:Connect(function() keysDown[Enum.KeyCode.Q] = true end)
buttons.Down.InputEnded:Connect(function() keysDown[Enum.KeyCode.Q] = false end)

buttons.Close.MouseButton1Click:Connect(function() if isFlying then toggleFly(false) end; gui:Destroy() end)

local isMinimized = false
buttons.Minimize.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    buttons.Minimize.Text = isMinimized and "+" or "-"
    for name, btn in pairs(buttons) do
        if name ~= "Toggle" and name ~= "Title" and name ~= "Minimize" and name ~= "Close" then
            btn.Visible = not isMinimized
        end
    end
end)

local function handleCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function() if isFlying then toggleFly(false) end end)
end
if lp.Character then handleCharacter(lp.Character) end
lp.CharacterAdded:Connect(handleCharacter)

local function toggleEditMode()
    isEditMode = not isEditMode
    if isEditMode then
        toggleButton.Text = "Save Layout"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        mainFrame.Draggable = false
        mainFrame.Visible = false
        local allDraggable = {unpack(allButtons)}
        if moveDPad then table.insert(allDraggable, moveDPad) end
        for _, obj in ipairs(allDraggable) do
            local absPos = obj.AbsolutePosition
            obj.Parent = gui
            obj.Position = UDim2.fromOffset(absPos.X, absPos.Y)
            obj.Draggable = true
        end
    else
        toggleButton.Text = "Edit Layout"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        local allDraggable = {unpack(allButtons)}
        if moveDPad then table.insert(allDraggable, moveDPad) end
        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
        for _, obj in ipairs(allDraggable) do
            local pos, size = obj.AbsolutePosition, obj.AbsoluteSize
            minX = math.min(minX, pos.X)
            minY = math.min(minY, pos.Y)
            maxX = math.max(maxX, pos.X + size.X)
            maxY = math.max(maxY, pos.Y + size.Y)
        end
        mainFrame.Position = UDim2.fromOffset(minX, minY)
        mainFrame.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
        for _, obj in ipairs(allDraggable) do
            local absPos = obj.AbsolutePosition
            obj.Draggable = false
            obj.Parent = mainFrame
            obj.Position = UDim2.fromOffset(absPos.X - minX, absPos.Y - minY)
        end
        mainFrame.Visible = true
        mainFrame.Draggable = true
    end
end

toggleButton.MouseButton1Click:Connect(toggleEditMode)
