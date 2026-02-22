return function()
	local WallManager = require(script.Parent.WallManager)

	describe("calculateDeathChance", function()
		it("should return the starting chance for the first wall", function()
			local result = WallManager.calculateDeathChance(1, 0.05, 0.01)
			expect(result).to.be.equal(0.05)
		end)

		it("should correctly increment the chance for subsequent walls", function()
			local result = WallManager.calculateDeathChance(5, 0.05, 0.01)
			-- Wall 1: 0.05
			-- Wall 2: 0.06
			-- Wall 3: 0.07
			-- Wall 4: 0.08
			-- Wall 5: 0.09
			expect(result).to.be.near(0.09, 1e-6)
		end)
	end)

	describe("shouldDie", function()
		it("should return true when roll is strictly less than death chance", function()
			expect(WallManager.shouldDie(0.04, 0.05)).to.equal(true)
			expect(WallManager.shouldDie(0.00, 0.05)).to.equal(true)
		end)

		it("should return false when roll is greater than or equal to death chance", function()
			expect(WallManager.shouldDie(0.05, 0.05)).to.equal(false)
			expect(WallManager.shouldDie(0.99, 0.05)).to.equal(false)
		end)
	end)
end
