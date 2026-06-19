-- this will put your client in void while keeping the server revealed
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local sens = 1.0
local zoomMul = 3.0

local active = false
local void = CFrame.new(0, -1.7e308, 0)
local root = nil
local hum = nil
local fakeCF = nil
local oidx = nil
local vel = Vector3.zero
local jumping = false
local jpower = 50
local jrdy = true
local camX = 0
local camY = 0
local fdir = 0
local rclick = false
local camdist = 8
local wantdist = 8
local flooroff = 3

local function lcur(b)
    UIS.MouseBehavior = b and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
end

local function gfo()
    if not root then return 3 end
    local ch = root.Parent
    if not ch then return 3 end
    local lo = root.Position.Y
    local ry = root.Position.Y
    for _, v in pairs(ch:GetChildren()) do
        if v:IsA("BasePart") and v ~= root then
            local b = v.Position.Y - v.Size.Y / 2
            if b < lo then lo = b end
        end
    end
    return math.max(ry - lo, 2)
end

local function start()
    local ch = player.Character
    if not ch then return end
    root = ch:FindFirstChild("HumanoidRootPart")
    hum = ch:FindFirstChild("Humanoid")
    if not root or not hum then return end

    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    fakeCF = root.CFrame
    vel = Vector3.zero
    jumping = false
    jrdy = true

    local lv = root.CFrame.LookVector
    fdir = math.atan2(-lv.X, -lv.Z)
    flooroff = gfo()

    local clv = cam.CFrame.LookVector
    camY = math.atan2(-clv.X, -clv.Z)
    camX = math.asin(math.clamp(clv.Y, -1, 1))

    camdist = 8
    wantdist = 8

    hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)

    root.CFrame = void
end

local function stop()
    local cam = Workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    local ch = player.Character
    if ch and ch:FindFirstChild("Humanoid") then
        cam.CameraSubject = ch.Humanoid
        ch.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
    end
    lcur(false)
    root = nil
    hum = nil
    fakeCF = nil
    vel = Vector3.zero
    jumping = false
    jrdy = true
    rclick = false
end

local function toggle()
    active = not active
    if active then start() else stop() end
end

UIS.InputBegan:Connect(function(inp, p)
    if not p and inp.KeyCode == Enum.KeyCode.C then
        toggle()
    end
end)

UIS.InputBegan:Connect(function(inp, p)
    if active and inp.UserInputType == Enum.UserInputType.MouseWheel then
        wantdist = math.clamp(wantdist - inp.Position.Z * zoomMul, 3, 50)
        return
    end

    if p then return end

    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        rclick = true
        if active then UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition end
    end

    if inp.KeyCode == Enum.KeyCode.Space then
        if active and hum then
            hum.Jump = true
            if not jumping and jrdy then
                jumping = true
                jrdy = false
                vel = Vector3.new(vel.X, jpower, vel.Z)
            end
        end
    end
end)

UIS.InputChanged:Connect(function(inp)
    if active and inp.UserInputType == Enum.UserInputType.MouseWheel then
        wantdist = math.clamp(wantdist - inp.Position.Z * zoomMul, 3, 50)
    end
end)

UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        rclick = false
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end
    if inp.KeyCode == Enum.KeyCode.Space then jrdy = true end
end)

oidx = hookmetamethod(game, "__index", newcclosure(function(self, k)
    if active and not checkcaller() and self == root and k == "CFrame" and fakeCF then
        return fakeCF
    end
    return oidx(self, k)
end))

RunService:BindToRenderStep("Cam", Enum.RenderPriority.Camera.Value + 1, function()
    if not active or not fakeCF then return end
    local cam = Workspace.CurrentCamera

    if rclick then
        local d = UIS:GetMouseDelta()
        local s = 0.008 * sens
        camY = camY - d.X * s
        camX = math.clamp(camX - d.Y * s, -math.rad(75), math.rad(75))
    end

    local spd = 12
    camdist = camdist + (wantdist - camdist) * math.min(spd * 0.016, 1)

    local ox = math.sin(camY) * math.cos(-camX) * camdist
    local oy = math.sin(-camX) * camdist
    local oz = math.cos(camY) * math.cos(-camX) * camdist

    local pos = fakeCF.Position
    local targ = pos + Vector3.new(0, 1.5, 0)
    local cpos = targ + Vector3.new(ox, oy, oz)

    cam.CFrame = CFrame.new(cpos, targ)
end)

RunService.Heartbeat:Connect(function(dt)
    if not active or not root or not hum or not fakeCF then return end

    vel = Vector3.new(vel.X, vel.Y - Workspace.Gravity * dt, vel.Z)

    local md = hum.MoveDirection

    if md.Magnitude > 0 then
        local spd = hum.WalkSpeed
        local fw = Vector3.new(-math.sin(camY), 0, -math.cos(camY))
        local ri = Vector3.new(math.cos(camY), 0, -math.sin(camY))

        local f = 0
        local r = 0
        if UIS:IsKeyDown(Enum.KeyCode.W) then f = f + 1 end
        if UIS:IsKeyDown(Enum.KeyCode.S) then f = f - 1 end
        if UIS:IsKeyDown(Enum.KeyCode.D) then r = r + 1 end
        if UIS:IsKeyDown(Enum.KeyCode.A) then r = r - 1 end

        local wm = fw * f + ri * r
        if wm.Magnitude > 0 then
            wm = wm.Unit
            vel = Vector3.new(wm.X * spd, vel.Y, wm.Z * spd)

            local tr = math.atan2(-wm.X, -wm.Z)
            local df = tr - fdir
            while df > math.pi do df = df - 2 * math.pi end
            while df < -math.pi do df = df + 2 * math.pi end
            fdir = fdir + df * math.min(12 * dt, 1)
        end
    else
        vel = Vector3.new(0, vel.Y, 0)
    end

    local np = fakeCF.Position + vel * dt

    local rs = np + Vector3.new(0, 1, 0)
    local rd = Vector3.new(0, -(flooroff + 3), 0)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {root.Parent}

    local hit = Workspace:Raycast(rs, rd, rp)

    if hit then
        local gy = hit.Position.Y
        if (np.Y - flooroff) <= gy then
            np = Vector3.new(np.X, gy + flooroff, np.Z)
            if vel.Y < 0 then vel = Vector3.new(vel.X, 0, vel.Z) end
            jumping = false

            if UIS:IsKeyDown(Enum.KeyCode.Space) and jrdy then
                hum.Jump = true
                jumping = true
                jrdy = false
                vel = Vector3.new(vel.X, jpower, vel.Z)
            else
                jrdy = true
            end
        end
    elseif np.Y < -100 then
        np = Vector3.new(np.X, 10, np.Z)
        vel = Vector3.new(0, 0, 0)
        jumping = false
        jrdy = true
    end

    fakeCF = CFrame.new(np) * CFrame.Angles(0, fdir, 0)

    root.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
    root.CFrame = void
end)

RunService.RenderStepped:Connect(function()
    if not active or not root or not fakeCF then return end
    root.CFrame = fakeCF
end)

RunService.Stepped:Connect(function()
    if not active or not root then return end
    root.CFrame = void
end)

player.CharacterAdded:Connect(function(ch)
    task.wait(0.6)
    root = ch:FindFirstChild("HumanoidRootPart")
    hum = ch:FindFirstChild("Humanoid")
    fakeCF = nil
    vel = Vector3.zero
    jumping = false
    jrdy = true
    rclick = false
    if active and root then
        flooroff = gfo()
        start()
    end
end)

player.CharacterRemoving:Connect(function()
    stop()
end)
