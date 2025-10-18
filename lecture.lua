local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local rs = game:GetService("RunService")
local replStorage = game:GetService("ReplicatedStorage")
local textChatService = game:GetService("TextChatService")
local teleportService = game:GetService("TeleportService")

local owner = nil
local ownerChar = nil
local killAuraTarget = nil
local killAuraEnabled = false
local followEnabled = true
local stickToOwner = false

local generalChannel = textChatService:FindFirstChild("TextChannels")
if generalChannel then
   generalChannel = generalChannel:FindFirstChild("RBXGeneral")
end

-- Listen for link code
textChatService.MessageReceived:Connect(function(message)
   local text = message.Text
   
   if text:find("LINK_") and not owner then
      local code = text:match("LINK_(%d+)")
      if code then
         owner = message.TextSource.UserId
         for _, player in pairs(game.Players:GetPlayers()) do
            if player.UserId == owner then
               ownerChar = player.Character
               break
            end
         end
         
         task.wait(0.5)
         if generalChannel then
            generalChannel:SendAsync("ALT_LINKED_" .. code)
         end
         print("Linked to owner with code: " .. code)
      end
   end
   
   if owner and message.TextSource and message.TextSource.UserId == owner then
      if text:find("ALTCMD_KILLAURA_") then
         local targetName = text:match("ALTCMD_KILLAURA_(.+)")
         if targetName == "OFF" then
            killAuraEnabled = false
            killAuraTarget = nil
            print("Kill aura disabled")
         else
            for _, player in pairs(game.Players:GetPlayers()) do
               if player.Name == targetName then
                  killAuraTarget = player
                  killAuraEnabled = true
                  print("Kill aura targeting: " .. targetName)
                  break
               end
            end
         end
      elseif text:find("ALTCMD_GOTO_") then
         local targetName = text:match("ALTCMD_GOTO_(.+)")
         for _, player in pairs(game.Players:GetPlayers()) do
            if player.Name == targetName and player.Character then
               local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
               if targetRoot then
                  root.CFrame = targetRoot.CFrame + Vector3.new(3, 0, 0)
                  print("Went to: " .. targetName)
               end
               break
            end
         end
      elseif text == "ALTCMD_FOLLOW" then
         followEnabled = true
         stickToOwner = false
         print("Following enabled")
      elseif text == "ALTCMD_UNFOLLOW" then
         followEnabled = false
         stickToOwner = false
         print("Following disabled")
      elseif text == "ALTCMD_STICK" then
         stickToOwner = true
         followEnabled = false
         print("Stick mode enabled")
      elseif text == "ALTCMD_UNSTICK" then
         stickToOwner = false
         print("Stick mode disabled")
      elseif text:find("ALTCMD_SPEED_") then
         local speedVal = tonumber(text:match("ALTCMD_SPEED_(%d+)"))
         if speedVal then
            hum.WalkSpeed = speedVal
            print("Speed set to: " .. speedVal)
         end
      elseif text:find("ALTCMD_JUMP_") then
         local jumpVal = tonumber(text:match("ALTCMD_JUMP_(%d+)"))
         if jumpVal then
            hum.JumpPower = jumpVal
            print("Jump power set to: " .. jumpVal)
         end
      elseif text == "ALTCMD_RESET" then
         local humanoid = char:FindFirstChildOfClass("Humanoid")
         if humanoid and humanoid.Health > 0 then
            humanoid.Health = 0
         end
         print("Resetting character")
      elseif text == "ALTCMD_REJOIN" then
         teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
         print("Rejoining server")
      end
   end
end)

-- Kill aura loop
spawn(function()
   while wait(0.1) do
      if killAuraEnabled and killAuraTarget then
         if not killAuraTarget.Character or not killAuraTarget.Character:FindFirstChild("Humanoid") or killAuraTarget.Character.Humanoid.Health <= 0 then
            killAuraEnabled = false
            killAuraTarget = nil
            print("Target died, kill aura disabled")
         else
            local targetRoot = killAuraTarget.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = killAuraTarget.Character:FindFirstChild("Humanoid")
            
            if targetRoot and root and targetHum and targetHum.Health > 0 then
               local distance = (targetRoot.Position - root.Position).Magnitude
               
               -- Teleport close if too far
               if distance > 10 then
                  root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
                  wait(0.1)
               end
               
               -- Try to hit with melee
               local meleeEvent = replStorage:FindFirstChild("meleeEvent")
               if meleeEvent then
                  for i = 1, 3 do
                     pcall(function()
                        meleeEvent:FireServer(killAuraTarget)
                     end)
                     wait(0.05)
                  end
               end
            end
         end
      end
   end
end)

-- Stick to owner permanently
rs.Heartbeat:Connect(function()
   if owner and stickToOwner then
      local ownerPlayer = game.Players:GetPlayerByUserId(owner)
      if ownerPlayer and ownerPlayer.Character then
         ownerChar = ownerPlayer.Character
         local ownerRoot = ownerChar:FindFirstChild("HumanoidRootPart")
         if ownerRoot and root then
            root.CFrame = ownerRoot.CFrame * CFrame.new(3, 0, 0)
         end
      end
   end
end)

-- Follow owner
rs.Heartbeat:Connect(function()
   if owner and followEnabled and not killAuraEnabled and not stickToOwner then
      local ownerPlayer = game.Players:GetPlayerByUserId(owner)
      if ownerPlayer and ownerPlayer.Character then
         ownerChar = ownerPlayer.Character
         local ownerRoot = ownerChar:FindFirstChild("HumanoidRootPart")
         if ownerRoot and root then
            local distance = (ownerRoot.Position - root.Position).Magnitude
            if distance > 10 then
               root.CFrame = CFrame.new(root.Position, ownerRoot.Position) * CFrame.new(0, 0, -8)
            end
         end
      end
   end
end)

plr.CharacterAdded:Connect(function(newChar)
   char = newChar
   hum = char:WaitForChild("Humanoid")
   root = char:WaitForChild("HumanoidRootPart")
end)

print("Alt controller loaded. Waiting for link code...")local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local rs = game:GetService("RunService")
local replStorage = game:GetService("ReplicatedStorage")
local textChatService = game:GetService("TextChatService")

local owner = nil
local ownerChar = nil
local killAuraTarget = nil
local killAuraEnabled = false
local followEnabled = true
local stickToOwner = false

local generalChannel = textChatService:FindFirstChild("TextChannels")
if generalChannel then
   generalChannel = generalChannel:FindFirstChild("RBXGeneral")
end

-- Listen for link code
textChatService.MessageReceived:Connect(function(message)
   local text = message.Text
   
   if text:find("LINK_") and not owner then
      local code = text:match("LINK_(%d+)")
      if code then
         owner = message.TextSource.UserId
         for _, player in pairs(game.Players:GetPlayers()) do
            if player.UserId == owner then
               ownerChar = player.Character
               break
            end
         end
         
         task.wait(0.5)
         if generalChannel then
            generalChannel:SendAsync("ALT_LINKED_" .. code)
         end
         print("Linked to owner with code: " .. code)
      end
   end
   
   if owner and message.TextSource and message.TextSource.UserId == owner then
      if text:find("ALTCMD_KILLAURA_") then
         local targetName = text:match("ALTCMD_KILLAURA_(.+)")
         if targetName == "OFF" then
            killAuraEnabled = false
            killAuraTarget = nil
            print("Kill aura disabled")
         else
            for _, player in pairs(game.Players:GetPlayers()) do
               if player.Name == targetName then
                  killAuraTarget = player
                  killAuraEnabled = true
                  print("Kill aura targeting: " .. targetName)
                  break
               end
            end
         end
      elseif text:find("ALTCMD_GOTO_") then
         local targetName = text:match("ALTCMD_GOTO_(.+)")
         for _, player in pairs(game.Players:GetPlayers()) do
            if player.Name == targetName and player.Character then
               local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
               if targetRoot then
                  root.CFrame = targetRoot.CFrame + Vector3.new(3, 0, 0)
                  print("Went to: " .. targetName)
               end
               break
            end
         end
      elseif text:find("ALTCMD_BRING_") then
         local targetName = text:match("ALTCMD_BRING_(.+)")
         for _, player in pairs(game.Players:GetPlayers()) do
            if player.Name == targetName and player.Character then
               local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
               if targetRoot and ownerChar then
                  local ownerRoot = ownerChar:FindFirstChild("HumanoidRootPart")
                  if ownerRoot then
                     targetRoot.CFrame = ownerRoot.CFrame + Vector3.new(3, 0, 0)
                     print("Brought: " .. targetName)
                  end
               end
               break
            end
         end
      elseif text == "ALTCMD_FOLLOW" then
         followEnabled = true
         stickToOwner = false
         print("Following enabled")
      elseif text == "ALTCMD_UNFOLLOW" then
         followEnabled = false
         stickToOwner = false
         print("Following disabled")
      elseif text == "ALTCMD_STICK" then
         stickToOwner = true
         followEnabled = false
         print("Stick mode enabled")
      elseif text == "ALTCMD_UNSTICK" then
         stickToOwner = false
         print("Stick mode disabled")
      elseif text:find("ALTCMD_SPEED_") then
         local speedVal = tonumber(text:match("ALTCMD_SPEED_(%d+)"))
         if speedVal then
            hum.WalkSpeed = speedVal
            print("Speed set to: " .. speedVal)
         end
      elseif text:find("ALTCMD_JUMP_") then
         local jumpVal = tonumber(text:match("ALTCMD_JUMP_(%d+)"))
         if jumpVal then
            hum.JumpPower = jumpVal
            print("Jump power set to: " .. jumpVal)
         end
      elseif text == "ALTCMD_RESET" then
         plr.Character:BreakJoints()
         print("Resetting character")
      elseif text:find("ALTCMD_FLING_") then
         local targetName = text:match("ALTCMD_FLING_(.+)")
         for _, player in pairs(game.Players:GetPlayers()) do
            if player.Name == targetName and player.Character then
               local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
               if targetRoot then
                  root.CFrame = targetRoot.CFrame
                  wait(0.1)
                  root.Velocity = Vector3.new(0, 300, 0)
                  print("Flinging: " .. targetName)
               end
               break
            end
         end
      end
   end
end)

-- Kill aura loop
rs.Heartbeat:Connect(function()
   if killAuraEnabled and killAuraTarget then
      if not killAuraTarget.Character or not killAuraTarget.Character:FindFirstChild("Humanoid") or killAuraTarget.Character.Humanoid.Health <= 0 then
         killAuraEnabled = false
         killAuraTarget = nil
         print("Target died, kill aura disabled")
         return
      end
      
      local targetRoot = killAuraTarget.Character:FindFirstChild("HumanoidRootPart")
      if targetRoot and root then
         local distance = (targetRoot.Position - root.Position).Magnitude
         
         if distance > 15 then
            root.CFrame = targetRoot.CFrame + Vector3.new(0, 0, 10)
         end
         
         local meleeEvent = replStorage:FindFirstChild("meleeEvent")
         if meleeEvent then
            pcall(function()
               meleeEvent:FireServer(killAuraTarget)
            end)
         end
      end
   end
end)

-- Stick to owner permanently
rs.Heartbeat:Connect(function()
   if owner and stickToOwner then
      local ownerPlayer = game.Players:GetPlayerByUserId(owner)
      if ownerPlayer and ownerPlayer.Character then
         ownerChar = ownerPlayer.Character
         local ownerRoot = ownerChar:FindFirstChild("HumanoidRootPart")
         if ownerRoot and root then
            root.CFrame = ownerRoot.CFrame * CFrame.new(3, 0, 0)
         end
      end
   end
end)

-- Follow owner
rs.Heartbeat:Connect(function()
   if owner and followEnabled and not killAuraEnabled and not stickToOwner then
      local ownerPlayer = game.Players:GetPlayerByUserId(owner)
      if ownerPlayer and ownerPlayer.Character then
         ownerChar = ownerPlayer.Character
         local ownerRoot = ownerChar:FindFirstChild("HumanoidRootPart")
         if ownerRoot and root then
            local distance = (ownerRoot.Position - root.Position).Magnitude
            if distance > 10 then
               root.CFrame = CFrame.new(root.Position, ownerRoot.Position) * CFrame.new(0, 0, -8)
            end
         end
      end
   end
end)

plr.CharacterAdded:Connect(function(newChar)
   char = newChar
   hum = char:WaitForChild("Humanoid")
   root = char:WaitForChild("HumanoidRootPart")
end)

print("Alt controller loaded. Waiting for link code...")local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local rs = game:GetService("RunService")
local replStorage = game:GetService("ReplicatedStorage")
local textChatService = game:GetService("TextChatService")

local owner = nil
local ownerChar = nil
local killAuraTarget = nil
local killAuraEnabled = false

local generalChannel = textChatService:FindFirstChild("TextChannels")
if generalChannel then
   generalChannel = generalChannel:FindFirstChild("RBXGeneral")
end

-- Listen for link code
textChatService.MessageReceived:Connect(function(message)
   local text = message.Text
   
   if text:find("LINK_") and not owner then
      local code = text:match("LINK_(%d+)")
      if code then
         owner = message.TextSource.UserId
         for _, player in pairs(game.Players:GetPlayers()) do
            if player.UserId == owner then
               ownerChar = player.Character
               break
            end
         end
         
         task.wait(0.5)
         if generalChannel then
            generalChannel:SendAsync("ALT_LINKED_" .. code)
         end
         print("Linked to owner with code: " .. code)
      end
   end
   
   if owner and message.TextSource and message.TextSource.UserId == owner then
      if text:find("ALTCMD_KILLAURA_") then
         local targetName = text:match("ALTCMD_KILLAURA_(.+)")
         if targetName == "OFF" then
            killAuraEnabled = false
            killAuraTarget = nil
            print("Kill aura disabled")
         else
            for _, player in pairs(game.Players:GetPlayers()) do
               if player.Name == targetName then
                  killAuraTarget = player
                  killAuraEnabled = true
                  print("Kill aura targeting: " .. targetName)
                  break
               end
            end
         end
      elseif text:find("ALTCMD_GOTO_") then
         local targetName = text:match("ALTCMD_GOTO_(.+)")
         for _, player in pairs(game.Players:GetPlayers()) do
            if player.Name == targetName and player.Character then
               local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
               if targetRoot then
                  root.CFrame = targetRoot.CFrame + Vector3.new(3, 0, 0)
                  print("Went to: " .. targetName)
               end
               break
            end
         end
      elseif text:find("ALTCMD_BRING_") then
         local targetName = text:match("ALTCMD_BRING_(.+)")
         for _, player in pairs(game.Players:GetPlayers()) do
            if player.Name == targetName and player.Character then
               local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
               if targetRoot and ownerChar then
                  local ownerRoot = ownerChar:FindFirstChild("HumanoidRootPart")
                  if ownerRoot then
                     targetRoot.CFrame = ownerRoot.CFrame + Vector3.new(3, 0, 0)
                     print("Brought: " .. targetName)
                  end
               end
               break
            end
         end
      end
   end
end)

-- Kill aura loop
rs.Heartbeat:Connect(function()
   if killAuraEnabled and killAuraTarget then
      if not killAuraTarget.Character or killAuraTarget.Character.Humanoid.Health <= 0 then
         killAuraEnabled = false
         killAuraTarget = nil
         print("Target died, kill aura disabled")
         return
      end
      
      local targetRoot = killAuraTarget.Character:FindFirstChild("HumanoidRootPart")
      if targetRoot then
         local distance = (targetRoot.Position - root.Position).Magnitude
         
         if distance <= 15 then
            local meleeEvent = replStorage:FindFirstChild("meleeEvent")
            if meleeEvent then
               meleeEvent:FireServer(killAuraTarget)
            end
         end
      end
   end
end)

-- Follow owner
rs.Heartbeat:Connect(function()
   if owner and not killAuraEnabled then
      local ownerPlayer = game.Players:GetPlayerByUserId(owner)
      if ownerPlayer and ownerPlayer.Character then
         ownerChar = ownerPlayer.Character
         local ownerRoot = ownerChar:FindFirstChild("HumanoidRootPart")
         if ownerRoot then
            local distance = (ownerRoot.Position - root.Position).Magnitude
            if distance > 10 then
               root.CFrame = CFrame.new(root.Position, ownerRoot.Position) * CFrame.new(0, 0, -8)
            end
         end
      end
   end
end)

plr.CharacterAdded:Connect(function(newChar)
   char = newChar
   hum = char:WaitForChild("Humanoid")
   root = char:WaitForChild("HumanoidRootPart")
end)

print("Alt controller loaded. Waiting for link code...")
