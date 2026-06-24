--[[
    ==================================================================
    🐾 MINI-SCRIPT DE AUTO-TP CON RAYFIELD UI (ULTRA ROBUSTO) 🐾
    ==================================================================
    Diseño premium usando la librería Rayfield.
    Escanea inteligentemente zonas de compra, pads y TouchTransmitters
    con un solo clic y sistema de notificaciones integrado.
]]

-- Cargar la librería Rayfield UI desde su repositorio oficial
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local TweenService = game:GetService("TweenService")

-- Asegurar que el personaje cargue correctamente tras reaparecer
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

-- Crear la ventana principal de Rayfield
local Window = Rayfield:CreateWindow({
    Name = "🐾 Neko Mini-TP 🐾",
    LoadingTitle = "Neko Teleport",
    LoadingSubtitle = "by Cravedad_O amiko",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "NekoTPConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- Crear pestaña principal
local MainTab = Window:CreateTab("Inicio", 4483362458) -- Icono de casa/inicio

-- Crear etiqueta de estado
local StatusLabel = MainTab:CreateLabel("Estado: Esperando orden nya... 🐾")

-- Función de teletransporte suave
local function teleportTo(targetCFrame)
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local hrp = Character.HumanoidRootPart
        local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame + Vector3.new(0, 3, 0)})
        tween:Play()
    end
end

-- Lista gigante de palabras clave de compra en juegos comunes
local palabrasClave = {
    "buy", "cost", "price", "gate", "zona", "area", "purchase", "unlock", 
    "pad", "puerta", "door", "button", "boton", "adquirir", "desbloquear",
    "rebirth", "next", "siguiente", "isla", "island", "teleport", "portal"
}

-- Comprobador inteligente de elementos de compra
local function esZonaDeCompra(obj)
    local nombre = obj.Name:lower()
    
    if obj:IsDescendantOf(Character) then return false end
    
    local coincidePalabra = false
    for _, palabra in ipairs(palabrasClave) do
        if nombre:find(palabra) then
            coincidePalabra = true
            break
        end
    end
    
    if coincidePalabra then
        if obj:IsA("BasePart") and obj:FindFirstChildOfClass("TouchTransmitter") then
            return true
        end
        if obj:IsA("Model") then
            local tieneSensor = obj:FindFirstChildWhichIsA("BasePart") and obj:FindFirstChild("TouchInterest", true)
            local tieneTexto = obj:FindFirstChildOfClass("BillboardGui", true)
            if tieneSensor or tieneTexto then
                return true
            end
        end
    end
    return false
end

-- Escáner inteligente global y TP directo
local function buscarYSiguiente()
    StatusLabel:Set("Estado: 🔍 Buscando zonas...")
    
    Rayfield:Notify({
        Title = "Neko TP",
        Content = "Escaneando el mapa en busca de zonas... 🔎",
        Duration = 1.5,
        Image = 4483362458,
    })
    
    task.wait(0.1)

    -- Escaneo primario (Zonas con nombres clave)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if esZonaDeCompra(obj) then
            StatusLabel:Set("Estado: 🐾 ¡Volando a zona detectada!")
            
            Rayfield:Notify({
                Title = "¡Zona Detectada!",
                Content = "Volando hacia: " .. obj.Name .. " ✨",
                Duration = 2,
                Image = 4483362458,
            })
            
            if obj:IsA("Model") then
                local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if primary then 
                    teleportTo(primary.CFrame) 
                end
            else
                teleportTo(obj.CFrame)
            end
            
            task.wait(0.8)
            StatusLabel:Set("Estado: Listo para siguiente zona 🐾")
            return
        end
    end

    -- Escaneo secundario (Cualquier TouchInterest/Pad activo que no sea el Spawn)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj:FindFirstChildOfClass("TouchTransmitter") then
            local parentName = obj.Parent and obj.Parent.Name:lower() or ""
            local nombre = obj.Name:lower()
            
            if not nombre:find("part") and not nombre:find("spawn") and not parentName:find("spawn") then
                StatusLabel:Set("Estado: 🐾 ¡Pulsando Pad Genérico!")
                
                Rayfield:Notify({
                    Title = "Pad Genérico Encontrado",
                    Content = "Viajando al botón interactivo miau 🐾",
                    Duration = 2,
                    Image = 4483362458,
                })
                
                teleportTo(obj.CFrame)
                task.wait(0.8)
                StatusLabel:Set("Estado: Listo para siguiente zona 🐾")
                return
            end
        end
    end

    -- Si no encuentra nada
    StatusLabel:Set("Estado: ❌ No se encontraron zonas")
    Rayfield:Notify({
        Title = "Error de Escaneo",
        Content = "No se detectaron zonas de compra ni pads interactivos miau. 🧶",
        Duration = 3,
        Image = 4483362458,
    })
    task.wait(1)
    StatusLabel:Set("Estado: Listo para siguiente zona 🐾")
end

-- Crear el botón interactivo de Rayfield
MainTab:CreateButton({
    Name = "✨ Siguiente Zona (Auto-TP)",
    Callback = function()
        buscarYSiguiente()
    end,
})

-- Notificación de inicio exitoso
Rayfield:Notify({
    Title = "🐾 Neko TP Listo 🐾",
    Content = "Rayfield cargado correctamente amiko. ¡A disfrutar! ✨",
    Duration = 3.5,
    Image = 4483362458,
})
