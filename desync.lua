local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 120, 0, 50)
Frame.Position = UDim2.new(0.5, -60, 0.5, -25)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = Frame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 80, 0, 30)
ToggleButton.Position = UDim2.new(0.5, -40, 0.5, -15)
ToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ToggleButton.Text = "OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Parent = Frame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleButton

local teleportEnabled = false
local cameraCFrame = nil
local cameraFocus = nil
local targetCFrame = CFrame.new(0, -100000000000000000000000000000, 0)
local root = nil

local function enableDesync()
    local camera = Workspace.CurrentCamera
    local character = LocalPlayer.Character
    if not character then return end
    
    root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    cameraCFrame = camera.CFrame
    cameraFocus = camera.Focus
    camera.CameraType = Enum.CameraType.Scriptable
end

local function disableDesync()
    local camera = Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
        end
    end
    cameraCFrame = nil
    cameraFocus = nil
    root = nil
end

ToggleButton.MouseButton1Click:Connect(function()
    teleportEnabled = not teleportEnabled
    ToggleButton.Text = teleportEnabled and "ON" or "OFF"
    ToggleButton.BackgroundColor3 = teleportEnabled and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(70, 70, 70)
    
    if teleportEnabled then
        enableDesync()
    else
        disableDesync()
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.C then
        teleportEnabled = not teleportEnabled
        ToggleButton.Text = teleportEnabled and "ON" or "OFF"
        ToggleButton.BackgroundColor3 = teleportEnabled and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(70, 70, 70)
        
        if teleportEnabled then
            enableDesync()
        else
            disableDesync()
        end
    end
end)

RunService:BindToRenderStep("DesyncCamera", Enum.RenderPriority.Camera.Value, function()
    if not teleportEnabled or not cameraCFrame then return end
    
    local camera = Workspace.CurrentCamera
    
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local mouseDelta = UserInputService:GetMouseDelta()
        local sensitivity = 0.5
        
        local rotY = CFrame.Angles(0, -math.rad(mouseDelta.X * sensitivity), 0)
        local rotX = CFrame.Angles(-math.rad(mouseDelta.Y * sensitivity), 0, 0)
        
        cameraCFrame = cameraCFrame * rotY * rotX
    end
    
    camera.CFrame = cameraCFrame
end)

RunService.Heartbeat:Connect(function()
    if not teleportEnabled then return end
    
    if root and root.Parent then
        for _ = 1, 10 do
            root.CFrame = targetCFrame
        end
    else
        local character = LocalPlayer.Character
        if character then
            root = character:FindFirstChild("HumanoidRootPart")
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    if teleportEnabled then
        task.wait(0.5)
        enableDesync()
    end
end)

ScreenGui.Destroying:Connect(function()
    disableDesync()
    RunService:UnbindFromRenderStep("DesyncCamera")
end)

print("LOADED")
