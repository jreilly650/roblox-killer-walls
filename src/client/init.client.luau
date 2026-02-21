local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local function createUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "KillerWallsUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 100)
	frame.Position = UDim2.new(0, 20, 1, -120)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Text = "KILLER WALLS"
	title.TextColor3 = Color3.fromRGB(255, 50, 50)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.BackgroundTransparency = 1
	title.Parent = frame
	
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -20, 1, -40)
	status.Position = UDim2.new(0, 10, 0, 35)
	status.Text = "Walk through the walls to survive!"
	status.TextColor3 = Color3.new(1, 1, 1)
	status.Font = Enum.Font.Gotham
	status.TextSize = 14
	status.TextWrapped = true
	status.BackgroundTransparency = 1
	status.Parent = frame
end

local function generateWorldUI()
	-- Wait for the server to generate the environment
	while not workspace:FindFirstChild("Walls") do task.wait(0.1) end
	local wallsFolder = workspace.Walls

	local uiData = {}
	
	for i = 1, GameConfig.WALL_COUNT do
		local wall = wallsFolder:WaitForChild("Wall_" .. i, 10)
		if not wall then continue end
		
		local deathChance = GameConfig.STARTING_DEATH_CHANCE + (i - 1) * GameConfig.CHANCE_INCREMENT
		
		local attachment = Instance.new("Attachment", wall)
		attachment.Position = Vector3.new(0, 25/2 - 2, -1.1) -- 25 is hallwayHeight
		
		local billboard = Instance.new("BillboardGui", attachment)
		billboard.Size = UDim2.new(0, 200, 0, 100)
		billboard.AlwaysOnTop = true
		billboard.ExtentsOffset = Vector3.new(0, 0, 0)
		billboard.Enabled = false -- Start hidden
		
		local textLabel = Instance.new("TextLabel", billboard)
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextStrokeTransparency = 0
		textLabel.TextSize = 24
		textLabel.Font = Enum.Font.GothamBold
		textLabel.Text = "WALL " .. i .. "\n" .. math.floor(deathChance * 100) .. "% DANGER"
		
		uiData[i] = billboard
	end
	
	-- Victory UI
	while not workspace:FindFirstChild("Hallway") do task.wait(0.1) end
	local victoryPart = workspace.Hallway:WaitForChild("VictoryLabelPart", 10)
	
	local vBillboard = nil
	if victoryPart then
		local vAttachment = Instance.new("Attachment", victoryPart)
		vBillboard = Instance.new("BillboardGui", vAttachment)
		vBillboard.Size = UDim2.new(0, 400, 0, 200)
		vBillboard.AlwaysOnTop = true
		vBillboard.Enabled = false
		local vText = Instance.new("TextLabel", vBillboard)
		vText.Size = UDim2.new(1, 0, 1, 0)
		vText.BackgroundTransparency = 1
		vText.TextColor3 = Color3.fromRGB(0, 255, 100)
		vText.TextSize = 48
		vText.Font = Enum.Font.GothamBlack
		vText.Text = "CONGRATULATIONS!\nYOU SURVIVED"
	end

	-- Render loop to dynamically show UI based on player location
	RunService.RenderStepped:Connect(function()
		local character = player.Character
		if not character then return end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		local zPos = hrp.Position.Z
		
		-- Figure out which wall they are approaching
		local nextWall = GameConfig.WALL_COUNT + 1
		for w = 1, GameConfig.WALL_COUNT do
			if zPos < w * GameConfig.WALL_SPACING then
				nextWall = w
				break
			end
		end
		
		-- Hide all wall UIs
		for i, billboard in pairs(uiData) do
			if billboard.Enabled and i ~= nextWall then
				billboard.Enabled = false
			end
		end
		
		-- Hide / Show specific ones
		if nextWall <= GameConfig.WALL_COUNT then
			if uiData[nextWall] then
				uiData[nextWall].Enabled = true
			end
			if vBillboard and vBillboard.Enabled then
				vBillboard.Enabled = false
			end
		else
			-- Victory!
			if vBillboard and not vBillboard.Enabled then
				vBillboard.Enabled = true
			end
		end
	end)
end

createUI()
generateWorldUI()

local function setupCamera(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		-- The server yields 0.05 seconds before teleporting the character. 
		-- We wait slightly longer so the client camera adjusts after teleport.
		task.wait(0.1)
		local camera = workspace.CurrentCamera
		if camera then
			-- Place the camera slightly behind and above the player, looking in the same direction!
			local charPos = hrp.Position
			local lookDir = hrp.CFrame.LookVector
			
			local camStartPos = charPos - (lookDir * 12) + Vector3.new(0, 3, 0)
			camera.CFrame = CFrame.lookAt(camStartPos, charPos)
		end
	end
end

if player.Character then
	setupCamera(player.Character)
end
player.CharacterAdded:Connect(setupCamera)
