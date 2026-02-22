local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Server = script.Parent

-- Only run tests in Studio during Play Solo/Run mode, not in a live game
if game:GetService("RunService"):IsStudio() then
	print("--- Starting TestEZ ---")
	local TestEZ = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("TestEZ"))
	
	-- Run all tests found inside the Server directory (.spec.luau files)
	TestEZ.TestBootstrap:run({ Server })
	print("--- TestEZ Finished ---")
end
