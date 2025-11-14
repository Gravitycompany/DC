

-- ======= Servicios y referencias =======
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local LocalPlayer = Players.LocalPlayer

-- espera personaje
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local c = getChar()
    return c:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local c = getChar()
    return c:FindFirstChild("HumanoidRootPart")
end

-- ======= PANTALLA INICIAL (FULLSCREEN) =======
local function makeStartupScreen()
    -- limpiar si ya existe
    if game.CoreGui:FindFirstChild("PapitaStartup") then
        game.CoreGui.PapitaStartup:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "PapitaStartup"
    sg.ResetOnSpawn = false
    sg.Parent = game.CoreGui

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(1,0,1,0)
    frame.Position = UDim2.new(0,0,0,0)
    frame.BackgroundColor3 = Color3.fromRGB(8,8,8)
    frame.BackgroundTransparency = 0.05

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0.2,0)
    title.Position = UDim2.new(0,0,0.2,0)
    title.BackgroundTransparency = 1
    title.Text = "¿ERES DANI?"
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.TextColor3 = Color3.fromRGB(255,255,255)

    local subtitle = Instance.new("TextLabel", frame)
    subtitle.Size = UDim2.new(1,0,0.08,0)
    subtitle.Position = UDim2.new(0,0,0.4,0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Pulsa SÍ para cargar el panel completo"
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextColor3 = Color3.fromRGB(200,200,200)

    local yes = Instance.new("TextButton", frame)
    yes.Size = UDim2.new(0.25,0,0.12,0)
    yes.Position = UDim2.new(0.2,0,0.6,0)
    yes.Text = "SÍ"
    yes.Font = Enum.Font.GothamBold
    yes.TextScaled = true
    yes.BackgroundColor3 = Color3.fromRGB(30,160,40)
    yes.TextColor3 = Color3.fromRGB(255,255,255)

    local no = Instance.new("TextButton", frame)
    no.Size = UDim2.new(0.25,0,0.12,0)
    no.Position = UDim2.new(0.55,0,0.6,0)
    no.Text = "NO"
    no.Font = Enum.Font.GothamBold
    no.TextScaled = true
    no.BackgroundColor3 = Color3.fromRGB(160,30,30)
    no.TextColor3 = Color3.fromRGB(255,255,255)

    return sg, yes, no
end

local function makeMiniPanel()
    if game.CoreGui:FindFirstChild("PapitaMini") then return end
    local sg = Instance.new("ScreenGui", game.CoreGui)
    sg.Name = "PapitaMini"
    sg.ResetOnSpawn = false

    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0,250,0,80)
    f.Position = UDim2.new(0.5,-125,0.05,0)
    f.BackgroundColor3 = Color3.fromRGB(40,0,0)
    f.Active = true
    f.Draggable = true

    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1,0,1,0)
    t.BackgroundTransparency = 1
    t.Text = "NO ERES DIGNO"
    t.TextScaled = true
    t.Font = Enum.Font.GothamBlack
    t.TextColor3 = Color3.fromRGB(255,80,80)
end

-- ======= RAYCAST UTIL (para TP Tool) =======
local function rayFromCameraToCursor(maxDist)
    maxDist = maxDist or 5000
    local cam = workspace.CurrentCamera
    local mouse = LocalPlayer:GetMouse()
    if not mouse then return nil end
    local origin = cam.CFrame.Position
    local direction = (mouse.Hit.Position - origin)
    if direction.Magnitude < 0.1 then
        direction = cam.CFrame.LookVector * maxDist
    else
        direction = direction.Unit * math.min(direction.Magnitude, maxDist)
    end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {getChar()}
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local r = workspace:Raycast(origin, direction, params)
    if r then return r.Position, r.Instance end
    return nil
end

-- ======= FUNCIONES PRINCIPALES (Fly estable, Noclip, Invisible, InfJump, TP) =======
local Fly = {
    Enabled = false,
    BV = nil,
    BG = nil,
    Speed = 80,
}

local function startFly()
    local char = getChar()
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return end
    if Fly.Enabled then return end
    Fly.Enabled = true

    -- crear BodyGyro y BodyVelocity
    Fly.BG = Instance.new("BodyGyro")
    Fly.BG.P = 4500
    Fly.BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
    Fly.BG.CFrame = hrp.CFrame
    Fly.BG.Parent = hrp

    Fly.BV = Instance.new("BodyVelocity")
    Fly.BV.MaxForce = Vector3.new(9e9,9e9,9e9)
    Fly.BV.Velocity = Vector3.new(0,0,0)
    Fly.BV.Parent = hrp

    -- desactivar gravedad loca
    hum.PlatformStand = true

    -- loop de control fino
    spawn(function()
        while Fly.Enabled and hrp.Parent do
            local cam = workspace.CurrentCamera
            local move = Vector3.new(0,0,0)
            -- teclado
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end

            -- aplicar movimiento (incluye control táctil que modifica Fly.TouchControl)
            if Fly.TouchControl then
                move = move + Fly.TouchControl * 1
            end

            if move.Magnitude > 0 then
                Fly.BV.Velocity = move.Unit * Fly.Speed
            else
                Fly.BV.Velocity = Vector3.new(0,0,0)
            end

            -- mantener orientación
            if cam and cam.CFrame then
                Fly.BG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
            end
            task.wait()
        end
    end)
end

local function stopFly()
    Fly.Enabled = false
    local hum = getHumanoid()
    if Fly.BV then Fly.BV:Destroy() Fly.BV = nil end
    if Fly.BG then Fly.BG:Destroy() Fly.BG = nil end
    if hum then pcall(function() hum.PlatformStand = false end) end
end

-- Noclip
local NoclipEnabled = false
local noclipConn
local function setNoclip(v)
    NoclipEnabled = v
    if v and not noclipConn then
        noclipConn = RunService.Stepped:Connect(function()
            local c = getChar()
            if c then
                for _,p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end
        end)
    elseif not v and noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
        -- restaurar intentando fijar cancollide = true en partes
        local c = getChar()
        if c then
            for _,p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
    end
end

-- Invisible (local): cambia transparencia y desactiva decals/face
local InvisibleEnabled = false
local function setInvisible(v)
    InvisibleEnabled = v
    local c = getChar()
    if not c then return end
    for _,obj in pairs(c:GetDescendants()) do
        if obj:IsA("BasePart") then
            if v then
                obj.Transparency = 1
            else
                -- si es HumanoidRootPart o similar, dejamos 0
                obj.Transparency = 0
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = v and 1 or 0
        end
    end
end

-- Infinite Jump
local InfJump = false
UserInputService.JumpRequest:Connect(function()
    if InfJump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- TP Tool (crea tool en backpack)
local function createTPTool()
    if not LocalPlayer.Backpack then return end
    if LocalPlayer.Backpack:FindFirstChild("PapitaTPTool") or LocalPlayer.Character:FindFirstChild("PapitaTPTool") then return end
    local tool = Instance.new("Tool")
    tool.Name = "PapitaTPTool"
    tool.RequiresHandle = false
    tool.Parent = LocalPlayer.Backpack

    local debounce = false
    tool.Activated:Connect(function()
        if debounce then return end
        debounce = true
        local pos = rayFromCameraToCursor(5000)
        if pos then
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
            end
        end
        task.wait(0.3)
        debounce = false
    end)
end

-- TP to spawn robusto
local function tpToSpawn()
    local success, spawnCF = pcall(function()
        -- buscar SpawnLocation o SpawnLocations
        local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
        if spawn and spawn:IsA("BasePart") then
            return spawn.CFrame + Vector3.new(0,4,0)
        end
        -- alternativa: buscar carpeta SpawnLocations
        if workspace:FindFirstChild("SpawnLocations") then
            local s = workspace.SpawnLocations:GetChildren()[1]
            if s and s:IsA("BasePart") then
                return s.CFrame + Vector3.new(0,4,0)
            end
        end
        -- fallback: respawn point del jugador
        local rp = LocalPlayer.RespawnLocation
        if rp and rp:IsA("BasePart") then return rp.CFrame + Vector3.new(0,4,0) end
        -- si nada, retornar la posición actual del humanoidroot + vector
        local hrp = getHRP()
        if hrp then return hrp.CFrame end
        return CFrame.new(0,10,0)
    end)
    if success and spawnCF then
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = spawnCF
        end
    end
end

-- ======= CONTROLES TÁCTILES PARA CELULAR =======
local TouchGui = nil
local function createTouchControls()
    -- evita duplicados
    if game.CoreGui:FindFirstChild("PapitaTouch") then return end
    local sg = Instance.new("ScreenGui", game.CoreGui)
    sg.Name = "PapitaTouch"
    sg.ResetOnSpawn = false

    local function newBtn(name, pos, size)
        local b = Instance.new("TextButton", sg)
        b.Size = size
        b.Position = pos
        b.Text = name
        b.TextScaled = true
        b.BackgroundTransparency = 0.2
        b.AutoButtonColor = false
        b.BorderSizePixel = 0
        b.BackgroundColor3 = Color3.fromRGB(30,30,30)
        return b
    end

    -- W A S D
    local btnW = newBtn("W", UDim2.new(0.02,0,0.7,0), UDim2.new(0,60,0,60))
    local btnA = newBtn("A", UDim2.new(0.02,0,0.77,0), UDim2.new(0,60,0,60))
    local btnS = newBtn("S", UDim2.new(0.1,0,0.77,0), UDim2.new(0,60,0,60))
    local btnD = newBtn("D", UDim2.new(0.16,0,0.77,0), UDim2.new(0,60,0,60))

    -- Jump / Descend
    local btnJump = newBtn("▲", UDim2.new(0.88,0,0.72,0), UDim2.new(0,64,0,64))
    local btnDown = newBtn("▼", UDim2.new(0.88,0,0.82,0), UDim2.new(0,64,0,64))

    -- Fly toggle & speed +/- 
    local btnFly = newBtn("FLY", UDim2.new(0.38,0,0.85,0), UDim2.new(0,80,0,48))
    local btnSpeedUp = newBtn("+", UDim2.new(0.48,0,0.85,0), UDim2.new(0,36,0,36))
    local btnSpeedDown = newBtn("-", UDim2.new(0.54,0,0.85,0), UDim2.new(0,36,0,36))

    -- estados táctiles
    local touchState = {W=false,A=false,S=false,D=false,J=false,Down=false}

    local function updateTouchControl()
        local vec = Vector3.new(0,0,0)
        local cam = workspace.CurrentCamera
        if touchState.W then vec = vec + cam.CFrame.LookVector end
        if touchState.S then vec = vec - cam.CFrame.LookVector end
        if touchState.D then vec = vec + cam.CFrame.RightVector end
        if touchState.A then vec = vec - cam.CFrame.RightVector end
        if touchState.J then vec = vec + Vector3.new(0,1,0) end
        if touchState.Down then vec = vec - Vector3.new(0,1,0) end
        Fly.TouchControl = vec
    end

    local function bindTouch(btn, key)
        btn.InputBegan:Connect(function()
            touchState[key] = true
            if key == "J" then
                -- simulamos salto
                local hum = getHumanoid()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
            updateTouchControl()
        end)
        btn.InputEnded:Connect(function()
            touchState[key] = false
            updateTouchControl()
        end)
    end

    bindTouch(btnW, "W")
    bindTouch(btnA, "A")
    bindTouch(btnS, "S")
    bindTouch(btnD, "D")
    bindTouch(btnJump, "J")
    bindTouch(btnDown, "Down")

    btnFly.MouseButton1Click:Connect(function()
        if Fly.Enabled then stopFly() else startFly() end
    end)
    btnSpeedUp.MouseButton1Click:Connect(function()
        Fly.Speed = Fly.Speed + 10
    end)
    btnSpeedDown.MouseButton1Click:Connect(function()
        Fly.Speed = math.max(10, Fly.Speed - 10)
    end)

    TouchGui = sg
end

-- ======= RAYFIELD UI (CARGA) =======
local function loadRayfieldUI()
    -- intenta cargar Rayfield
    local ok, Rayfield = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    if not ok or not Rayfield then
        -- fallback: notificar error
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {
                Title = "Papita",
                Text = "No se pudo cargar Rayfield. Revisa tu URL o conexión.",
                Duration = 4
            })
        end)
        return
    end

    local Window = Rayfield:CreateWindow({
        Name = "Betav1",
        LoadingTitle = "Papita",
        LoadingSubtitle = "Cargando funciones...",
        ConfigurationSaving = { Enabled = false }
    })

    local mainTab = Window:CreateTab("Main", 4483362453)
    local movTab = Window:CreateTab("Movilidad", 4483362453)
    local miscTab = Window:CreateTab("Misc", 4483362453)

    -- WalkSpeed
    mainTab:CreateSlider({
        Name = "correr",
        Range = {8, 300},
        Increment = 1,
        CurrentValue = 16,
        Flag = "WalkSpeed",
        Callback = function(v)
            local hum = getHumanoid()
            if hum then pcall(function() hum.WalkSpeed = v end) end
        end
    })

    -- JumpPower
    mainTab:CreateSlider({
        Name = "saltopoderoso",
        Range = {50, 500},
        Increment = 1,
        CurrentValue = 50,
        Callback = function(v)
            local hum = getHumanoid()
            if hum then pcall(function() hum.JumpPower = v end) end
        end
    })

    -- Infinite Jump
    mainTab:CreateToggle({
        Name = "muchos saltos",
        CurrentValue = false,
        Callback = function(v)
            InfJump = v
        end
    })

    -- Fly Toggle
    movTab:CreateToggle({
        Name = "Volar (W/A/S/D + Jump/Descend)",
        CurrentValue = false,
        Callback = function(v)
            if v then startFly() else stopFly() end
        end
    })

    -- Fly Speed
    movTab:CreateSlider({
        Name = "Volar velocidad",
        Range = {10, 600},
        Increment = 5,
        CurrentValue = Fly.Speed,
        Callback = function(v) Fly.Speed = v end
    })

    -- Noclip
    miscTab:CreateToggle({
        Name = "traspasar",
        CurrentValue = false,
        Callback = function(v)
            setNoclip(v)
        end
    })

    -- Invisible
    miscTab:CreateToggle({
        Name = "Invisible (local)",
        CurrentValue = false,
        Callback = function(v)
            setInvisible(v)
        end
    })

    -- Crear TP Tool
    miscTab:CreateButton({
        Name = "Crear TP Tool (apunta + activar)",
        Callback = function()
            createTPTool()
            Rayfield:Notify("TP Tool creada", "Revisa tu Backpack.")
        end
    })

    -- TP a spawn
    miscTab:CreateButton({
        Name = "TP Aquí (Spawn)",
        Callback = function()
            tpToSpawn()
        end
    })

    -- Botones extras: quitar cuerpo (break joints) y restaurar visibilidad
    miscTab:CreateButton({
        Name = "Restaurar Transparencias",
        Callback = function()
            local c = getChar()
            if c then
                for _,obj in pairs(c:GetDescendants()) do
                    if obj:IsA("BasePart") then obj.Transparency = 0 end
                    if obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency = 0 end
                end
            end
        end
    })

    -- Crear controles táctiles siempre (si el jugador está en móvil, los usará)
    createTouchControls()

    -- Notificación final
    Rayfield:Notify("Papita", "Panel cargado correctamente - Usa el Tab Movilidad para Fly/Speed")
end

-- ======= LÓGICA DE ARRANQUE: PANTALLA "¿ERES DANI?" =======
do
    local startup, yesBtn, noBtn = makeStartupScreen()

    yesBtn.MouseButton1Click:Connect(function()
        -- destruye startup y carga Rayfield UI
        if startup then startup:Destroy() end
        -- asegurar que personaje esté listo
        getChar()
        getHumanoid()
        -- cargar Rayfield UI y funciones
        loadRayfieldUI()
    end)

    noBtn.MouseButton1Click:Connect(function()
        if startup then startup:Destroy() end
        makeMiniPanel()
    end)
end

-- ======= PROTECCIONES Y SINCRONIZACIÓN =======
-- si respawnea el personaje, intentamos re-aplicar estados (noclip/invisible/flyTouch etc.)
Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    if NoclipEnabled then setNoclip(true) end
    if InvisibleEnabled then setInvisible(true) end
end)

-- FIN DEL SCRIPT
