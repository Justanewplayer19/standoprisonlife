local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Prison Rizz",
   Icon = 0,
   LoadingTitle = "Prison Life Script",
   LoadingSubtitle = "by kyri",
   ShowText = "Prison Life",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = false
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "Kyri Hub",
      Subtitle = "Key System",
      Note = "No key required",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Hello"}
   }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local isFlying = false
local flyEnabled = false
local speed = 50
local bv
local bg
local jmpCount = 0
local jmpReset = 0.3
local lastJmp = 0
local animTracks = {}
local walkSpeedValue = 16
local jumpPowerValue = 50
local lastPosition = root.CFrame

local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local replStorage = game:GetService("ReplicatedStorage")
local teams = game:GetService("Teams")
local cam = workspace.CurrentCamera

local espObjects = {}
local aimbotEnabled = false
local aimbotFOV = 200
local targetPart = "Head"
local aimbotKeybind = Enum.KeyCode.C
local lockedTarget = nil
local silentAimEnabled = false
local silentAimFOV = 300

local killAuraEnabled = false
local killAuraDistance = 15
local antiArrestEnabled = false
local antiArrestLoop = nil
local cloneRoot = nil
local tased = false

local movement = {
   w = false,
   a = false,
   s = false,
   d = false
}

local function killPlayer()
   local humanoid = char:FindFirstChildOfClass("Humanoid")
   if humanoid and humanoid.Health > 0 then
      humanoid.Health = 0
   end
end

rs.Heartbeat:Connect(function()
   if char and char:FindFirstChild("Humanoid") then
      local currentHum = char.Humanoid
      if currentHum.WalkSpeed ~= walkSpeedValue then
         currentHum.WalkSpeed = walkSpeedValue
      end
      if currentHum.JumpPower ~= jumpPowerValue then
         currentHum.JumpPower = jumpPowerValue
      end
   end
   
   if char and char:FindFirstChild("HumanoidRootPart") then
      local currentRoot = char.HumanoidRootPart
      if currentRoot.CFrame.Position.Y > -100 then
         lastPosition = currentRoot.CFrame
      end
   end
end)

local function stopAnims()
   for _, track in pairs(hum:GetPlayingAnimationTracks()) do
      track:Stop()
      table.insert(animTracks, track)
   end
   
   local anim = char:FindFirstChild("Animate")
   if anim then
      anim.Disabled = true
   end
end

local function startAnims()
   local anim = char:FindFirstChild("Animate")
   if anim then
      anim.Disabled = false
   end
end

local function flyStart()
   if isFlying or not flyEnabled then return end
   isFlying = true
   
   stopAnims()
   
   bv = Instance.new("BodyVelocity")
   bv.MaxForce = Vector3.new(100000, 100000, 100000)
   bv.Velocity = Vector3.new(0, 0, 0)
   bv.Parent = root
   
   bg = Instance.new("BodyGyro")
   bg.MaxTorque = Vector3.new(100000, 100000, 100000)
   bg.P = 10000
   bg.CFrame = root.CFrame
   bg.Parent = root
   
   hum.PlatformStand = true
end

local function flyStop()
   if not isFlying then return end
   isFlying = false
   
   if bv then
      bv:Destroy()
      bv = nil
   end
   
   if bg then
      bg:Destroy()
      bg = nil
   end
   
   hum.PlatformStand = false
   startAnims()
end

local function flyUpdate()
   if not isFlying then return end
   if not bv or not bg then return end
   
   local dir = Vector3.new(0, 0, 0)
   
   if movement.w then
      dir = dir + cam.CFrame.LookVector
   end
   if movement.s then
      dir = dir - cam.CFrame.LookVector
   end
   if movement.a then
      dir = dir - cam.CFrame.RightVector
   end
   if movement.d then
      dir = dir + cam.CFrame.RightVector
   end
   
   if dir.Magnitude > 0 then
      dir = dir.Unit
   end
   
   bv.Velocity = dir * speed
   bg.CFrame = cam.CFrame
end

uis.InputBegan:Connect(function(input, gp)
   if gp then return end
   
   local key = input.KeyCode.Name:lower()
   if movement[key] ~= nil then
      movement[key] = true
   end
   
   if input.KeyCode == Enum.KeyCode.Space and flyEnabled then
      local now = tick()
      
      if now - lastJmp <= jmpReset then
         jmpCount = jmpCount + 1
      else
         jmpCount = 1
      end
      
      lastJmp = now
      
      if jmpCount >= 2 then
         if isFlying then
            flyStop()
         else
            flyStart()
         end
         jmpCount = 0
      end
   end
   
   if input.KeyCode == aimbotKeybind and aimbotEnabled then
      if lockedTarget then
         lockedTarget = nil
         Rayfield:Notify({
            Title = "Aimbot",
            Content = "Target unlocked",
            Duration = 2,
            Image = 4483362458,
         })
      else
         local target = getClosestPlayer()
         if target then
            lockedTarget = target
            Rayfield:Notify({
               Title = "Aimbot",
               Content = "Locked onto " .. target.Name,
               Duration = 2,
               Image = 4483362458,
            })
         end
      end
   end
   
   -- Mobile aimbot support
   if input.UserInputType == Enum.UserInputType.Touch and aimbotEnabled then
      if lockedTarget then
         lockedTarget = nil
      else
         local target = getClosestPlayer()
         if target then
            lockedTarget = target
         end
      end
   end
end)

uis.InputEnded:Connect(function(input, gp)
   local key = input.KeyCode.Name:lower()
   if movement[key] ~= nil then
      movement[key] = false
   end
end)

rs.Heartbeat:Connect(flyUpdate)

local deathPosition = nil

local function setupDeathListener()
   if char and char:FindFirstChild("Humanoid") then
      local currentHum = char.Humanoid
      currentHum.Died:Connect(function()
         if char and char:FindFirstChild("HumanoidRootPart") then
            local currentRoot = char.HumanoidRootPart
            deathPosition = currentRoot.CFrame
            print("Saved death position: " .. tostring(deathPosition.Position))
         end
      end)
   end
end

setupDeathListener()

plr.CharacterAdded:Connect(function(newChar)
   char = newChar
   hum = char:WaitForChild("Humanoid")
   root = char:WaitForChild("HumanoidRootPart")
   
   task.wait(1)
   
   if deathPosition then
      task.wait(0.5)
      root.CFrame = deathPosition
      print("Respawned at death position: " .. tostring(deathPosition.Position))
   end
   
   setupDeathListener()
   
   isFlying = false
   bv = nil
   bg = nil
   jmpCount = 0
   animTracks = {}
   
   for k in pairs(movement) do
      movement[k] = false
   end
   
   if antiArrestEnabled then
      wait(2)
      startAntiArrest()
   end
   
   if noclipConnection then
      noclipConnection:Disconnect()
      noclipConnection = rs.Stepped:Connect(function()
         for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
               v.CanCollide = false
            end
         end
      end)
   end
end)

local function getTeamColor(player)
   if not player.Team then return Color3.fromRGB(255, 255, 255) end
   
   local teamName = player.Team.Name
   
   if teamName == "Guards" then
      return Color3.fromRGB(0, 0, 255)
   elseif teamName == "Inmates" then
      return Color3.fromRGB(255, 165, 0)
   elseif teamName == "Criminals" then
      return Color3.fromRGB(255, 0, 0)
   end
   
   return Color3.fromRGB(255, 255, 255)
end

local function createESP(player)
   if player == plr then return end
   
   local box = Drawing.new("Square")
   box.Visible = false
   box.Color = getTeamColor(player)
   box.Thickness = 2
   box.Transparency = 1
   box.Filled = false
   
   local name = Drawing.new("Text")
   name.Visible = false
   name.Color = Color3.fromRGB(255, 255, 255)
   name.Text = player.Name
   name.Size = 18
   name.Center = true
   name.Outline = true
   name.OutlineColor = Color3.fromRGB(0, 0, 0)
   name.Font = 2
   
   espObjects[player] = {box = box, name = name}
end

local function removeESP(player)
   if espObjects[player] then
      espObjects[player].box:Remove()
      espObjects[player].name:Remove()
      espObjects[player] = nil
   end
end

local function updateESP()
   for player, drawings in pairs(espObjects) do
      if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
         local hrp = player.Character.HumanoidRootPart
         local head = player.Character:FindFirstChild("Head")
         
         local vector, onScreen = cam:WorldToViewportPoint(hrp.Position)
         
         if onScreen then
            local headPos = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local legPos = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height / 2
            
            drawings.box.Size = Vector2.new(width, height)
            drawings.box.Position = Vector2.new(vector.X - width / 2, vector.Y - height / 2)
            drawings.box.Visible = true
            drawings.box.Color = getTeamColor(player)
            
            drawings.name.Position = Vector2.new(vector.X, vector.Y - height / 2 - 15)
            drawings.name.Visible = true
         else
            drawings.box.Visible = false
            drawings.name.Visible = false
         end
      else
         drawings.box.Visible = false
         drawings.name.Visible = false
      end
   end
end

function getClosestPlayer()
   local closestPlayer = nil
   local shortestDistance = aimbotFOV
   
   for _, player in pairs(game.Players:GetPlayers()) do
      if player ~= plr and player.Character and player.Character:FindFirstChild(targetPart) and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
         local part = player.Character[targetPart]
         local screenPoint, onScreen = cam:WorldToViewportPoint(part.Position)
         
         if onScreen then
            local mousePos = uis:GetMouseLocation()
            local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
            
            if distance < shortestDistance then
               closestPlayer = player
               shortestDistance = distance
            end
         end
      end
   end
   
   return closestPlayer
end

local function getClosestGuard()
   local closestPlayer = nil
   local shortestDistance = silentAimFOV
   
   for _, player in pairs(game.Players:GetPlayers()) do
      if player ~= plr and player.Team and player.Team.Name == "Guards" and player.Character and player.Character:FindFirstChild(targetPart) and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
         local part = player.Character[targetPart]
         local screenPoint, onScreen = cam:WorldToViewportPoint(part.Position)
         
         if onScreen then
            local mousePos = uis:GetMouseLocation()
            local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
            
            if distance < shortestDistance then
               closestPlayer = player
               shortestDistance = distance
            end
         end
      end
   end
   
   return closestPlayer
end

local function killAuraLoop()
   while killAuraEnabled and wait(0.1) do
      local meleeEvent = replStorage:FindFirstChild("meleeEvent")
      if meleeEvent then
         for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
               local targetRoot = player.Character.HumanoidRootPart
               local distance = (targetRoot.Position - root.Position).Magnitude
               
               if distance <= killAuraDistance then
                  meleeEvent:FireServer(player)
               end
            end
         end
      end
   end
end

function startAntiArrest()
   if antiArrestLoop then return end
   
   local rootJoint = root:FindFirstChild("RootJoint")
   if rootJoint then
      rootJoint.Enabled = false
   end
   
   cloneRoot = root:Clone()
   cloneRoot.Parent = char
   root.Parent = workspace
   root.Transparency = 1
   
   local playerTased = replStorage:FindFirstChild("GunRemotes")
   if playerTased then
      playerTased = playerTased:FindFirstChild("PlayerTased")
      if playerTased then
         for _, conn in pairs(getconnections(playerTased.OnClientEvent)) do
            conn:Disable()
         end
         
         playerTased.OnClientEvent:Connect(function()
            tased = true
            task.wait(5)
            tased = false
         end)
      end
   end
   
   antiArrestLoop = rs.Heartbeat:Connect(function()
      if cloneRoot and root then
         local offset = CFrame.new(0, -2, 0)
         if tased then
            offset = CFrame.new(0, -7, 0)
         end
         root.CFrame = cloneRoot.CFrame * offset * CFrame.Angles(math.rad(180), 0, 0)
         root.Velocity = Vector3.zero
      end
   end)
   
   local deathConn
   deathConn = hum.Died:Connect(function()
      if rootJoint then
         rootJoint.Enabled = true
      end
      root.Velocity = Vector3.zero
      root.Anchored = true
      deathConn:Disconnect()
   end)
end

local function stopAntiArrest()
   if antiArrestLoop then
      antiArrestLoop:Disconnect()
      antiArrestLoop = nil
   end
   
   if cloneRoot then
      cloneRoot:Destroy()
      cloneRoot = nil
   end
   
   local rootJoint = root:FindFirstChild("RootJoint")
   if rootJoint then
      rootJoint.Enabled = true
   end
   
   root.Parent = char
   root.Transparency = 0
   tased = false
end

rs.RenderStepped:Connect(function()
   if getgenv().ESPEnabled then
      updateESP()
   end
   
   if aimbotEnabled and lockedTarget then
      if not lockedTarget.Character or not lockedTarget.Character:FindFirstChild(targetPart) or not lockedTarget.Character:FindFirstChild("Humanoid") or lockedTarget.Character.Humanoid.Health <= 0 then
         lockedTarget = nil
         Rayfield:Notify({
            Title = "Aimbot",
            Content = "Target died, aimbot disabled",
            Duration = 2,
            Image = 4483362458,
         })
      else
         local part = lockedTarget.Character[targetPart]
         cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
      end
   end
end)

local WalkSpeedSlider = MainTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 200},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
   Callback = function(Value)
      walkSpeedValue = Value
      hum.WalkSpeed = Value
   end,
})

local JumpPowerSlider = MainTab:CreateSlider({
   Name = "Jump Power",
   Range = {50, 300},
   Increment = 1,
   Suffix = "Power",
   CurrentValue = 50,
   Flag = "JumpPowerSlider",
   Callback = function(Value)
      jumpPowerValue = Value
      hum.JumpPower = Value
   end,
})

local FlyToggle = MainTab:CreateToggle({
   Name = "Fly (Double Jump)",
   CurrentValue = false,
   Flag = "FlyToggle",
   Callback = function(Value)
      flyEnabled = Value
      if not Value and isFlying then
         flyStop()
      end
   end,
})

local FlySpeedSlider = MainTab:CreateSlider({
   Name = "Fly Speed",
   Range = {10, 200},
   Increment = 1,
   Suffix = "Speed",
   CurrentValue = 50,
   Flag = "FlySpeedSlider",
   Callback = function(Value)
      speed = Value
   end,
})

local InfiniteJumpToggle = MainTab:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfiniteJump",
   Callback = function(Value)
      getgenv().InfiniteJumpEnabled = Value
   end,
})

uis.JumpRequest:connect(function()
   if getgenv().InfiniteJumpEnabled then
      hum:ChangeState("Jumping")
   end
end)

local AimbotToggle = CombatTab:CreateToggle({
   Name = "Aimbot",
   CurrentValue = false,
   Flag = "Aimbot",
   Callback = function(Value)
      aimbotEnabled = Value
      if not Value then
         lockedTarget = nil
      end
   end,
})

local AimbotKeybindInput = CombatTab:CreateInput({
   Name = "Aimbot Keybind",
   PlaceholderText = "C",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      local key = Enum.KeyCode[Text:upper()]
      if key then
         aimbotKeybind = key
         Rayfield:Notify({
            Title = "Keybind Set",
            Content = "Aimbot key set to " .. Text:upper(),
            Duration = 2,
            Image = 4483362458,
         })
      end
   end,
})

local AimbotFOVSlider = CombatTab:CreateSlider({
   Name = "Aimbot FOV",
   Range = {50, 500},
   Increment = 10,
   Suffix = "px",
   CurrentValue = 200,
   Flag = "AimbotFOV",
   Callback = function(Value)
      aimbotFOV = Value
   end,
})

local AimbotPartDropdown = CombatTab:CreateDropdown({
   Name = "Aimbot Target",
   Options = {"Head", "Torso", "HumanoidRootPart"},
   CurrentOption = {"Head"},
   MultipleOptions = false,
   Flag = "AimbotPart",
   Callback = function(Option)
      targetPart = Option[1]
   end,
})

local KillAuraToggle = CombatTab:CreateToggle({
   Name = "Kill Aura",
   CurrentValue = false,
   Flag = "KillAura",
   Callback = function(Value)
      killAuraEnabled = Value
      if Value then
         spawn(killAuraLoop)
      end
   end,
})

local KillAuraDistanceSlider = CombatTab:CreateSlider({
   Name = "Kill Aura Distance",
   Range = {5, 30},
   Increment = 1,
   Suffix = "studs",
   CurrentValue = 15,
   Flag = "KillAuraDistance",
   Callback = function(Value)
      killAuraDistance = Value
   end,
})

local AntiArrestToggle = CombatTab:CreateToggle({
   Name = "Anti Arrest",
   CurrentValue = false,
   Flag = "AntiArrest",
   Callback = function(Value)
      antiArrestEnabled = Value
      if Value then
         startAntiArrest()
      else
         stopAntiArrest()
      end
   end,
})

local ESPToggle = VisualsTab:CreateToggle({
   Name = "Player ESP",
   CurrentValue = false,
   Flag = "ESP",
   Callback = function(Value)
      getgenv().ESPEnabled = Value
      
      if Value then
         for _, player in pairs(game.Players:GetPlayers()) do
            createESP(player)
         end
         
         game.Players.PlayerAdded:Connect(function(player)
            if getgenv().ESPEnabled then
               createESP(player)
            end
         end)
         
         game.Players.PlayerRemoving:Connect(function(player)
            removeESP(player)
         end)
      else
         for player, _ in pairs(espObjects) do
            removeESP(player)
         end
      end
   end,
})

local CriminalButton = MiscTab:CreateButton({
   Name = "Become Criminal",
   Callback = function()
      local crimSpawn = workspace:FindFirstChild("Criminals Spawn")
      if crimSpawn then
         local spawnPad = crimSpawn:FindFirstChild("SpawnLocation")
         if spawnPad and root then
            root.CFrame = spawnPad.CFrame + Vector3.new(0, 3, 0)
            Rayfield:Notify({
               Title = "Criminal",
               Content = "Teleported to criminal spawn",
               Duration = 2,
               Image = 4483362458,
            })
         end
      end
   end,
})

local RespawnButton = MiscTab:CreateButton({
   Name = "Instant Respawn",
   Callback = function()
      killPlayer()
   end,
})

local RejoinButton = MiscTab:CreateButton({
   Name = "Rejoin Server",
   Callback = function()
      game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
   end,
})

local textChatService = game:GetService("TextChatService")

-- Generate unique link code
local linkCode = "LINK_" .. math.random(100000, 999999)
local altLinked = false
local altPlayer = nil

local generalChannel = textChatService:FindFirstChild("TextChannels")
if generalChannel then
   generalChannel = generalChannel:FindFirstChild("RBXGeneral")
end

local function findPlayer(partialName)
   partialName = partialName:lower()
   for _, player in pairs(game.Players:GetPlayers()) do
      if player ~= plr then
         local displayName = player.DisplayName:lower()
         local username = player.Name:lower()
         if displayName:sub(1, #partialName) == partialName or username:sub(1, #partialName) == partialName then
            return player
         end
      end
   end
   return nil
end

local function spawnCar()
   local carSpawnerButton = workspace.Prison_ITEMS.buttons:FindFirstChild("Car Spawner")
   if carSpawnerButton then
      local carSpawner = carSpawnerButton:FindFirstChild("Car Spawner")
      if carSpawner and root then
         root.CFrame = carSpawner.CFrame + Vector3.new(0, 3, 0)
         wait(0.2)
         
         local success = pcall(function()
            workspace.Remote.ItemHandler:InvokeServer(carSpawner)
         end)
         if success then
            print("Successfully invoked ItemHandler - CAR SPAWNED")
         end
         wait(0.5)
      end
   end
end

local function waitForCarAndSit()
   -- First check if already sitting in a car
   local hum = char:FindFirstChild("Humanoid")
   if hum and hum.SeatPart then
      local currentSeat = hum.SeatPart
      if currentSeat.Parent and currentSeat.Parent.Parent then
         print("Already sitting in a car!")
         return currentSeat.Parent.Parent
      end
   end
   
   -- If not sitting, find and sit in a car
   local attempts = 0
   while attempts < 30 do
      local carContainer = workspace:FindFirstChild("CarContainer")
      if carContainer then
         for _, vehicle in pairs(carContainer:GetChildren()) do
            local body = vehicle:FindFirstChild("Body")
            if body then
               -- Look for VehicleSeat (driver seat)
               for _, seat in pairs(body:GetChildren()) do
                  if seat:IsA("VehicleSeat") then
                     if not seat.Occupant then
                        root.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
                        wait(0.3)
                        
                        if hum.SeatPart == seat then
                           print("Successfully sat in driver seat!")
                           return vehicle
                        end
                     end
                  end
               end
            end
         end
      end
      wait(0.1)
      attempts = attempts + 1
   end
   print("Failed to find/sit in car after 30 attempts")
   return nil
end

local function bringPlayer(targetPlayer)
   if not targetPlayer or not targetPlayer.Character then return end
   
   local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
   if not targetRoot then return end
   
   spawnCar()
   
   local myCar = waitForCarAndSit()
   if not myCar then
      Rayfield:Notify({
         Title = "Bring Failed",
         Content = "Could not spawn/enter car",
         Duration = 2,
         Image = 4483362458,
      })
      return
   end
   
   wait(0.5)
   
   -- Move the car to the target player
   local body = myCar:FindFirstChild("Body")
   if body then
      local vehicleSeat = body:FindFirstChild("VehicleSeat")
      if vehicleSeat then
         for _, part in pairs(body:GetChildren()) do
            if part:IsA("BasePart") then
               local offset = part.CFrame.Position - vehicleSeat.CFrame.Position
               part.CFrame = CFrame.new(targetRoot.CFrame.Position + offset)
            end
         end
      end
   end
   
   wait(0.5)
   
   -- Find passenger seat and put them in
   if body then
      for _, seat in pairs(body:GetChildren()) do
         if seat:IsA("Seat") and not seat:IsA("VehicleSeat") then
            if not seat.Occupant then
               targetRoot.CFrame = seat.CFrame
               wait(0.2)
               print("Put " .. targetPlayer.Name .. " in passenger seat")
               break
            end
         end
      end
   end
   
   wait(0.5)
   
   -- Teleport car back with both players
   local vehicleSeat = body:FindFirstChild("VehicleSeat")
   if vehicleSeat and root then
      for _, part in pairs(body:GetChildren()) do
         if part:IsA("BasePart") then
            local offset = part.CFrame.Position - vehicleSeat.CFrame.Position
            part.CFrame = CFrame.new(root.CFrame.Position + offset)
         end
      end
   end
end

local function gotoPlayer(targetPlayer)
   if not targetPlayer or not targetPlayer.Character then 
      print("No target player or character")
      return 
   end
   
   local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
   if not targetRoot then
      print("Target has no HumanoidRootPart")
      return
   end
   
   if not root then
      print("You have no HumanoidRootPart")
      return
   end
   
   print("Teleporting to " .. targetPlayer.Name .. " at position: " .. tostring(targetRoot.Position))
   root.CFrame = targetRoot.CFrame * CFrame.new(3, 0, 0)
   print("Your new position: " .. tostring(root.Position))
end

textChatService.OnIncomingMessage = function(message)
   local properties = Instance.new("TextChatMessageProperties")
   
   if message.TextSource and message.TextSource.UserId == plr.UserId then
      local text = message.Text
      
      -- Check for alt link response
      if text:find("ALT_LINKED_") and not altLinked then
         local code = text:match("ALT_LINKED_(%d+)")
         if code == linkCode:match("LINK_(%d+)") then
            altLinked = true
            for _, player in pairs(game.Players:GetPlayers()) do
               if player.UserId == message.TextSource.UserId and player ~= plr then
                  altPlayer = player
                  break
               end
            end
            Rayfield:Notify({
               Title = "Alt Linked",
               Content = "Alt account connected",
               Duration = 3,
               Image = 4483362458,
            })
         end
      end
      
      -- Alt commands
      if altLinked and text:sub(1, 1) == ">" then
         local cmd = text:sub(2):lower()
         
         if cmd:find("killaura ") then
            local targetName = cmd:sub(11)
            local target = findPlayer(targetName)
            if target then
               generalChannel:SendAsync("ALTCMD_KILLAURA_" .. target.Name)
            end
         elseif cmd == "killaura off" then
            generalChannel:SendAsync("ALTCMD_KILLAURA_OFF")
         elseif cmd:find("goto ") then
            local targetName = cmd:sub(6)
            local target = findPlayer(targetName)
            if target then
               generalChannel:SendAsync("ALTCMD_GOTO_" .. target.Name)
            end
         elseif cmd == "follow" then
            generalChannel:SendAsync("ALTCMD_FOLLOW")
         elseif cmd == "unfollow" then
            generalChannel:SendAsync("ALTCMD_UNFOLLOW")
         elseif cmd == "stick" then
            generalChannel:SendAsync("ALTCMD_STICK")
         elseif cmd == "unstick" then
            generalChannel:SendAsync("ALTCMD_UNSTICK")
         elseif cmd:find("speed ") then
            local speedVal = cmd:match("speed (%d+)")
            if speedVal then
               generalChannel:SendAsync("ALTCMD_SPEED_" .. speedVal)
            end
         elseif cmd:find("jump ") then
            local jumpVal = cmd:match("jump (%d+)")
            if jumpVal then
               generalChannel:SendAsync("ALTCMD_JUMP_" .. jumpVal)
            end
         elseif cmd == "reset" then
            generalChannel:SendAsync("ALTCMD_RESET")
         elseif cmd == "rejoin" then
            generalChannel:SendAsync("ALTCMD_REJOIN")
         end
         
         properties.Text = ""
         return properties
      end
      
      if text:sub(1, 6) == "!bring" then
         local playerName = text:sub(8)
         local targetPlayer = findPlayer(playerName)
         
         if targetPlayer then
            spawn(function()
               bringPlayer(targetPlayer)
            end)
            Rayfield:Notify({
               Title = "Bring",
               Content = "Bringing " .. targetPlayer.DisplayName,
               Duration = 2,
               Image = 4483362458,
            })
         else
            Rayfield:Notify({
               Title = "Bring Failed",
               Content = "Player not found",
               Duration = 2,
               Image = 4483362458,
            })
         end
         
         properties.Text = ""
         return properties
      elseif text:sub(1, 5) == "!goto" then
         local playerName = text:sub(7)
         local targetPlayer = findPlayer(playerName)
         
         if targetPlayer then
            spawn(function()
               gotoPlayer(targetPlayer)
            end)
            Rayfield:Notify({
               Title = "Goto",
               Content = "Going to " .. targetPlayer.DisplayName,
               Duration = 2,
               Image = 4483362458,
            })
         else
            Rayfield:Notify({
               Title = "Goto Failed",
               Content = "Player not found",
               Duration = 2,
               Image = 4483362458,
            })
         end
         
         properties.Text = ""
         return properties
      end
   end
   
   return properties
end

local RemoveDoorsButton = MiscTab:CreateButton({
   Name = "Remove All Doors",
   Callback = function()
      local doorCount = 0
      
      if workspace:FindFirstChild("Doors") then
         for _, door in pairs(workspace.Doors:GetChildren()) do
            door:Destroy()
            doorCount = doorCount + 1
         end
      end
      
      if workspace:FindFirstChild("CellDoors") then
         for _, door in pairs(workspace.CellDoors:GetChildren()) do
            door:Destroy()
            doorCount = doorCount + 1
         end
      end
      
      Rayfield:Notify({
         Title = "Doors Removed",
         Content = doorCount .. " doors removed permanently",
         Duration = 3,
         Image = 4483362458,
      })
   end,
})

local GetGunsButton = MiscTab:CreateButton({
   Name = "Get Guns (AK47 + Remington)",
   Callback = function()
      spawn(function()
         local currentChar = plr.Character
         if not currentChar then return end
         local currentRoot = currentChar:FindFirstChild("HumanoidRootPart")
         if not currentRoot then return end
         
         local oldCFrame = currentRoot.CFrame
         local akCFrame = CFrame.new(-922.312683, 91.2782822, 2051.95361, -0.173624277, 0, 0.984811902, 0, 1, 0, -0.984811902, 0, -0.173624277)
         local remCFrame = CFrame.new(-923.562622, 91.2783356, 2044.86316, -0.173624277, 0, 0.984811902, 0, 1, 0, -0.984811902, 0, -0.173624277)
         
         if not plr.Backpack:FindFirstChild("AK-47") and not currentChar:FindFirstChild("AK-47") then
            currentRoot.CFrame = akCFrame
            wait(0.5)
         end
         
         if not plr.Backpack:FindFirstChild("Remington 870") and not currentChar:FindFirstChild("Remington 870") then
            currentRoot.CFrame = remCFrame
            wait(0.5)
         end
         
         currentRoot.CFrame = oldCFrame
         
         Rayfield:Notify({
            Title = "Guns",
            Content = "Grabbed guns",
            Duration = 2,
            Image = 4483362458,
         })
      end)
   end,
})

local NoClipToggle = MiscTab:CreateToggle({
   Name = "NoClip",
   CurrentValue = false,
   Flag = "NoClip",
   Callback = function(Value)
      if Value then
         noclipConnection = rs.Stepped:Connect(function()
            for _, v in pairs(char:GetDescendants()) do
               if v:IsA("BasePart") then
                  v.CanCollide = false
               end
            end
         end)
      else
         if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
         end
         for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
               v.CanCollide = true
            end
         end
      end
   end,
})

local PairAltButton = MiscTab:CreateButton({
   Name = "Pair Alt Account",
   Callback = function()
      if generalChannel then
         generalChannel:SendAsync(linkCode)
         Rayfield:Notify({
            Title = "Pairing Code Sent",
            Content = "Waiting for alt to connect...",
            Duration = 3,
            Image = 4483362458,
         })
      end
   end,
})

-- Mobile fly controls
if uis.TouchEnabled and not uis.KeyboardEnabled then
   local screenGui = Instance.new("ScreenGui")
   screenGui.Name = "FlyControls"
   screenGui.ResetOnSpawn = false
   screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
   
   local function createButton(name, position, text)
      local button = Instance.new("TextButton")
      button.Name = name
      button.Size = UDim2.new(0, 60, 0, 60)
      button.Position = position
      button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
      button.TextColor3 = Color3.fromRGB(255, 255, 255)
      button.Text = text
      button.Font = Enum.Font.GothamBold
      button.TextSize = 20
      button.Parent = screenGui
      
      local corner = Instance.new("UICorner")
      corner.CornerRadius = UDim.new(0, 10)
      corner.Parent = button
      
      return button
   end
   
   local forward = createButton("Forward", UDim2.new(0.5, -30, 0.7, -120), "▲")
   local backward = createButton("Backward", UDim2.new(0.5, -30, 0.7, 0), "▼")
   local left = createButton("Left", UDim2.new(0.5, -90, 0.7, -60), "◄")
   local right = createButton("Right", UDim2.new(0.5, 30, 0.7, -60), "►")
   local up = createButton("Up", UDim2.new(0.1, 0, 0.7, -60), "↑")
   local down = createButton("Down", UDim2.new(0.1, 0, 0.7, 20), "↓")
   
   forward.MouseButton1Down:Connect(function()
      if isFlying and root then
         root.CFrame = root.CFrame + (cam.CFrame.LookVector * 5)
      end
   end)
   
   backward.MouseButton1Down:Connect(function()
      if isFlying and root then
         root.CFrame = root.CFrame - (cam.CFrame.LookVector * 5)
      end
   end)
   
   left.MouseButton1Down:Connect(function()
      if isFlying and root then
         root.CFrame = root.CFrame - (cam.CFrame.RightVector * 5)
      end
   end)
   
   right.MouseButton1Down:Connect(function()
      if isFlying and root then
         root.CFrame = root.CFrame + (cam.CFrame.RightVector * 5)
      end
   end)
   
   up.MouseButton1Down:Connect(function()
      if isFlying and root then
         root.CFrame = root.CFrame + Vector3.new(0, 5, 0)
      end
   end)
   
   down.MouseButton1Down:Connect(function()
      if isFlying and root then
         root.CFrame = root.CFrame - Vector3.new(0, 5, 0)
      end
   end)
   
   screenGui.Parent = plr.PlayerGui
end
