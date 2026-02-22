local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for config to be available (mapped by Rojo)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local WallManager = {}

function WallManager.calculateDeathChance(wallIndex, startingChance, chanceIncrement)
	return startingChance + (wallIndex - 1) * chanceIncrement
end

function WallManager.shouldDie(roll, deathChance)
	return roll < deathChance
end

function WallManager.init()
	print("Killer Walls initializing...")
	
	-- 1. Create Folders
	local wallsFolder = Instance.new("Folder")
	wallsFolder.Name = "Walls"
	wallsFolder.Parent = workspace
	
	local hallwayFolder = Instance.new("Folder")
	hallwayFolder.Name = "Hallway"
	hallwayFolder.Parent = workspace
	
	local checkpointsFolder = Instance.new("Folder")
	checkpointsFolder.Name = "Checkpoints"
	checkpointsFolder.Parent = workspace
	
	-- 2. State Tracking
	local playerRolls = {} -- Tracks wall indices rolled in CURRENT life
	local playerCheckpoints = {} -- Tracks the highest checkpoint reached [player] -> int
	
	-- 3. Environment Generation
	local hallwayWidth = 40
	local hallwayHeight = 25
	local corridorLength = (GameConfig.WALL_COUNT + 1) * GameConfig.WALL_SPACING
	
	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(hallwayWidth, 2, corridorLength + 40)
	floor.Position = Vector3.new(0, -1, (corridorLength / 2) - 10)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(35, 35, 35)
	floor.Material = Enum.Material.Concrete
	floor.Parent = hallwayFolder
	
	-- Ceiling
	local ceiling = floor:Clone()
	ceiling.Name = "Ceiling"
	ceiling.Position = Vector3.new(0, hallwayHeight, (corridorLength / 2) - 10)
	ceiling.Parent = hallwayFolder
	
	-- Left Wall
	local leftWall = Instance.new("Part")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(2, hallwayHeight, corridorLength + 40)
	leftWall.Position = Vector3.new(-hallwayWidth/2 - 1, hallwayHeight/2, (corridorLength / 2) - 10)
	leftWall.Anchored = true
	leftWall.Color = Color3.fromRGB(50, 50, 50)
	leftWall.Material = Enum.Material.DiamondPlate
	leftWall.Parent = hallwayFolder
	
	-- Right Wall
	local rightWall = leftWall:Clone()
	rightWall.Name = "RightWall"
	rightWall.Position = Vector3.new(hallwayWidth/2 + 1, hallwayHeight/2, (corridorLength / 2) - 10)
	rightWall.Parent = hallwayFolder
	
	-- Spawn Location (invisible, we handle teleportation explicitly)
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, -10)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.Parent = workspace
	
	-- 4. Wall & Checkpoint Generation
	for i = 1, GameConfig.WALL_COUNT do
		-- WALL
		local wallPos = Vector3.new(0, hallwayHeight/2, i * GameConfig.WALL_SPACING)
		local wall = Instance.new("Part")
		wall.Name = "Wall_" .. i
		wall.Size = Vector3.new(hallwayWidth, hallwayHeight, 2)
		wall.Position = wallPos
		wall.Anchored = true
		wall.CanCollide = false
		wall.Transparency = GameConfig.WALL_TRANSPARENCY
		
		-- Color gradient from red (start) to deep red (end)
		local progress = (i - 1) / (GameConfig.WALL_COUNT - 1)
		wall.Color = Color3.fromHSV(0, 0.8, 0.5 + progress * 0.5) 
		wall.Material = Enum.Material.Neon
		wall.Parent = wallsFolder
		
		local deathChance = WallManager.calculateDeathChance(i, GameConfig.STARTING_DEATH_CHANCE, GameConfig.CHANCE_INCREMENT)
		
		-- Checkpoint (placed halfway between this wall and the next)
		if i < GameConfig.WALL_COUNT then
			local cpPadding = GameConfig.WALL_SPACING / 2
			local cpZ = (i * GameConfig.WALL_SPACING) + cpPadding
			
			local cp = Instance.new("Part")
			cp.Name = "Checkpoint_" .. i
			cp.Size = Vector3.new(hallwayWidth, 0.5, 4)
			cp.Position = Vector3.new(0, 0.25, cpZ)
			cp.Anchored = true
			cp.CanCollide = false
			cp.Color = Color3.fromRGB(50, 150, 255)
			cp.Material = Enum.Material.Neon
			cp.Parent = checkpointsFolder
			
			-- Touched Logic for Checkpoint
			cp.Touched:Connect(function(hit)
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if player then
					local currentCP = playerCheckpoints[player] or 0
					if i > currentCP then
						playerCheckpoints[player] = i
						
						local leaderstats = player:FindFirstChild("leaderstats")
						if leaderstats and leaderstats:FindFirstChild("Level") then
							leaderstats.Level.Value = i
						end
						
						print("[KILLER-WALLS] " .. player.Name .. " reached Checkpoint " .. i)
					end
				end
			end)
		end
		
		-- Touched Logic for Wall
		wall.Touched:Connect(function(hit)
			local character = hit.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				if not playerRolls[player] then playerRolls[player] = {} end
				if playerRolls[player][i] then return end -- Already rolled
				
				playerRolls[player][i] = true
				
				local roll = math.random()
				print(string.format("[KILLER-WALLS] Player %s crossing Wall %d. Chance: %.1f%%, Roll: %.1f%%", 
					player.Name, i, deathChance * 100, roll * 100))
					
				if WallManager.shouldDie(roll, deathChance) then
					local humanoid = character:FindFirstChild("Humanoid")
					if humanoid then
						humanoid.Health = 0
						print("[KILLER-WALLS] Player " .. player.Name .. " ELIMINATED at Wall " .. i)
					end
				end
			end
		end)
	end
	
	-- Victory Area
	local winPad = Instance.new("Part")
	winPad.Name = "WinPad"
	winPad.Size = Vector3.new(hallwayWidth, 1, 20)
	winPad.Position = Vector3.new(0, 0.5, (GameConfig.WALL_COUNT + 1) * GameConfig.WALL_SPACING)
	winPad.Anchored = true
	winPad.Color = Color3.fromRGB(0, 255, 100)
	winPad.Material = Enum.Material.Neon
	winPad.Parent = hallwayFolder
	
	local victoryLabel = Instance.new("Part")
	victoryLabel.Name = "VictoryLabelPart"
	victoryLabel.Transparency = 1
	victoryLabel.Anchored = true
	victoryLabel.CanCollide = false
	victoryLabel.Position = winPad.Position + Vector3.new(0, 10, 0)
	victoryLabel.Parent = hallwayFolder
	
	winPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Prevent multiple wins in a single touch/life
			local currentCP = playerCheckpoints[player] or 0
			if currentCP == -1 then return end 
			
			print("[KILLER-WALLS] Player " .. player.Name .. " HAS WON!")
			
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Wins") then
				leaderstats.Wins.Value += 1
			end
			
			-- Reset their checkpoint so they can play again if they die or respawn
			playerCheckpoints[player] = -1
			if leaderstats and leaderstats:FindFirstChild("Level") then
				leaderstats.Level.Value = 0
			end
			task.wait(1)
			playerCheckpoints[player] = 0
		end
	end)
	
	-- 5. Manage Respawns & Orientation
	Players.PlayerAdded:Connect(function(player)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		
		local levelStat = Instance.new("IntValue")
		levelStat.Name = "Level"
		levelStat.Value = 0
		levelStat.Parent = leaderstats
		
		local winsStat = Instance.new("IntValue")
		winsStat.Name = "Wins"
		winsStat.Value = 0
		winsStat.Parent = leaderstats

		playerCheckpoints[player] = 0 -- Default to 0 (start)
		
		player.CharacterAdded:Connect(function(character)
			playerRolls[player] = {} -- Reset rolls for this life
			
			-- Wait for HumanoidRootPart to exist
			local hrp = character:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				-- Small delay to let Roblox's default spawn behavior finish
				task.wait(0.05)
				
				-- Determine where they should spawn
				local cp = playerCheckpoints[player] or 0
				local spawnZ = -10 -- For CP 0
				
				if cp > 0 then
					spawnZ = (cp * GameConfig.WALL_SPACING) + (GameConfig.WALL_SPACING / 2)
				end
				
				-- CFrame to look towards positive Z
				local targetCFrame = CFrame.lookAt(Vector3.new(0, 4, spawnZ), Vector3.new(0, 4, spawnZ + 20))
				character:PivotTo(targetCFrame)
				
				print(string.format("[KILLER-WALLS] Spawned %s at Checkpoint %d", player.Name, cp))
			end
		end)
	end)

	-- 6. Lighting Setup
	local Lighting = game:GetService("Lighting")
	Lighting.Ambient = Color3.fromRGB(80, 80, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 60)
	Lighting.Brightness = 1.0
	Lighting.ClockTime = 12
	Lighting.FogEnd = 500
	Lighting.FogStart = 100
	Lighting.FogColor = Color3.fromRGB(20, 20, 20)
end

return WallManager
