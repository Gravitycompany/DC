--[[
    ==================================================================
    🐾 SCRIPT DE AUTO-TP PARA ZONAS COMPRABLES (ROBLOX / DELTA) 🐾
    ==================================================================
    Este script escanea el mapa buscando zonas que se puedan comprar 
    (normalmente partes con costo, "Gates", "Areas" o "BuyPad") y 
    crea una interfaz móvil (GUI) súper cómoda para teletransportarte.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local TweenService = game:GetService("TweenService")

-- Asegurar que el personaje cargue si morimos
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

-- Crear la interfaz visual (GUI) para Delta
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusText = Instance.new("TextLabel")
local ButtonsFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local RefreshButton = Instance.new("TextButton")
local MinimizeButton = Instance.new("TextButton")

-- Configuración de la interfaz (Diseño Moderno Oscuro)
ScreenGui.Name = "NekoZonasTP"
ScreenGui.Parent = game:CoreGui -- Se inserta en CoreGui para que no desaparezca al morir
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 320)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- ¡Puedes mover la ventana arrastrándola!

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "🐾 TP ZONAS COMPRABLES 🐾"
Title.TextColor3 = Color3.fromRGB(255, 200, 255)
Title.TextSize = 16
Title.BorderSizePixel = 0

MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = MainFrame
MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 40, 60)
MinimizeButton.Position = UDim2.new(0.85, 0, 0, 5)
MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 14
MinimizeButton.BorderSizePixel = 0

StatusText.Name = "StatusText"
StatusText.Parent = MainFrame
StatusText.BackgroundTransparency = 1
StatusText.Position = UDim2.new(0, 10, 0, 40)
StatusText.Size = UDim2.new(1, -20, 0, 20)
StatusText.Font = Enum.Font.SourceSansItalic
StatusText.Text = "Buscando zonas en el juego..."
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.TextSize = 12
StatusText.TextXAlignment = Enum.TextXAlignment.Left

ButtonsFrame.Name = "ButtonsFrame"
ButtonsFrame.Parent = MainFrame
ButtonsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ButtonsFrame.Position = UDim2.new(0, 10, 0, 65)
ButtonsFrame.Size = UDim2.new(1, -20, 0, 210)
ButtonsFrame.BorderSizePixel = 0
ButtonsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ButtonsFrame.ScrollBarThickness = 6

UIListLayout.Parent = ButtonsFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

RefreshButton.Name = "RefreshButton"
RefreshButton.Parent = MainFrame
RefreshButton.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
RefreshButton.Position = UDim2.new(0, 10, 0, 285)
RefreshButton.Size = UDim2.new(1, -20, 0, 25)
RefreshButton.Font = Enum.Font.SourceSansBold
RefreshButton.Text = "🔄 Escanear Zonas Nuevas"
RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshButton.TextSize = 14
RefreshButton.BorderSizePixel = 0

-- Lógica para minimizar/maximizar la ventana
local minimizado = false
MinimizeButton.MouseButton1Click:Connect(function()
    if not minimizado then
        MainFrame:TweenSize(UDim2.new(0, 260, 0, 35), "Out", "Quad", 0.3, true)
        ButtonsFrame.Visible = false
        StatusText.Visible = false
        RefreshButton.Visible = false
        MinimizeButton.Text = "+"
        minimizado = true
    else
        MainFrame:TweenSize(UDim2.new(0, 260, 0, 320), "Out", "Quad", 0.3, true)
        ButtonsFrame.Visible = true
        StatusText.Visible = true
        RefreshButton.Visible = true
        MinimizeButton.Text = "-"
        minimizado = false
    end
end)

-- Función para teletransportarse de forma segura con suavidad (No Clip / Anti-Kick por TP)
local function teleportTo(targetCFrame)
    if Character and Character:FindFirstChild("HumanoidRootPart") then
        local hrp = Character.HumanoidRootPart
        -- Animación suave con TweenService para evitar ser detectado por anti-cheats básicos
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame + Vector3.new(0, 3, 0)})
        tween:Play()
    end
end

-- Función principal para escanear zonas de compra en el mapa
local function escanearZonas()
    -- Limpiar botones anteriores
    for _, item in ipairs(ButtonsFrame:GetChildren()) do
        if item:IsA("TextButton") then
            item:Destroy()
        end
    end

    local zonasEncontradas = 0
    local canvasSizeY = 0

    -- Buscaremos carpetas en el Workspace con nombres comunes
    local posiblesCarpetas = {
        workspace:FindFirstChild("Areas"),
        workspace:FindFirstChild("Zones"),
        workspace:FindFirstChild("Gates"),
        workspace:FindFirstChild("BuyPads"),
        workspace:FindFirstChild("Zonas"),
        workspace:FindFirstChild("Map"),
        workspace
    }

    for _, contenedor in ipairs(posiblesCarpetas) do
        if contenedor then
            -- Buscamos objetos que contengan palabras clave de compra o costos
            for _, obj in ipairs(contenedor:GetDescendants()) do
                local nombre = obj.Name:lower()
                local esZonaCompra = false

                -- Filtros comunes de zonas en juegos simuladores/tycoons
                if nombre:find("buy") or nombre:find("cost") or nombre:find("price") or nombre:find("gate") or nombre:find("zona") or nombre:find("area") then
                    -- Nos aseguramos que sea un botón físico, una parte o modelo
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        esZonaCompra = true
                    end
                end

                if esZonaCompra then
                    zonasEncontradas = zonasEncontradas + 1
                    
                    -- Crear botón para la lista
                    local btn = Instance.new("TextButton")
                    btn.Name = obj.Name
                    btn.Parent = ButtonsFrame
                    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    btn.Size = UDim2.new(1, -10, 0, 35)
                    btn.Font = Enum.Font.SourceSans
                    btn.Text = "📍 Ir a: " .. obj.Name
                    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
                    btn.TextSize = 14
                    btn.BorderSizePixel = 0

                    -- Efecto visual al pasar el dedo/mouse
                    btn.MouseEnter:Connect(function()
                        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
                    end)
                    btn.MouseLeave:Connect(function()
                        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    end)

                    -- Evento al hacer clic en la zona
                    btn.MouseButton1Click:Connect(function()
                        StatusText.Text = "🐾 Volando hacia " .. obj.Name .. "..."
                        if obj:IsA("Model") then
                            local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                            if primary then
                                teleportTo(primary.CFrame)
                            end
                        else
                            teleportTo(obj.CFrame)
                        end
                    end)

                    canvasSizeY = canvasSizeY + 40
                end
            end
        end
    end

    StatusText.Text = "Se encontraron " .. zonasEncontradas .. " zonas de compra nya."
    ButtonsFrame.CanvasSize = UDim2.new(0, 0, 0, canvasSizeY)
end

-- Escaneo al dar clic en el botón de recargar
RefreshButton.MouseButton1Click:Connect(escanearZonas)

-- Primer escaneo automático al iniciar el script
escanearZonas()