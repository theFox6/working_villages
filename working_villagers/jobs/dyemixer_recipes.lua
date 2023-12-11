local dyemixer_recipes = {}

-- TODO write a dependency management system
function dyemixer_recipes.update_color_plan(self, target_color)
	assert(self ~= nil)
	assert(target_color ~= nil)
	print('target color: '..target_color)
if target_color == "red" then
-- red
-- - yellow
-- - magenta
--   - pink
-- *   - red
--     - white
--   - violet 1
-- *   - red
--     - blue
--   - violet 2
--   * - magenta
--     - blue
	self.job_data.wools.dye_names  = {
		[1] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
	}
	self.job_data.wools.target = {
		[1] = { ["dye:red"] = 99, },
		[2] = { ["dye:magenta"] = 99, },
	}
	self.job_data.wools.names = {
		--["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  2)
	local target = self.job_data.wools.target
	assert(#target     ==  2)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "blue" then
-- blue
-- - cyan
--   - green
-- * - blue
-- - magenta
--   - pink
--     - red
--       - yellow
--   *   - magenta
--     - white
--   - violet 1
--     - red
-- *   - blue
--   - violet 2
--     - magenta
-- *   - blue
	self.job_data.wools.dye_names  = {
		[1] = {
			['a'] = { ["dye:cyan"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:white"] = 99, },
		},
	}
	self.job_data.wools.target = {
		[1] = { ["dye:blue"] = 99, },
		[2] = { ["dye:magenta"] = 99, },
		[3] = { ["dye:pink"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		--["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  3)
	local target = self.job_data.wools.target
	assert(#target     ==  3)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "cyan" then
-- cyan
-- - green
-- - blue
--
-- - green 1
--   - yellow
--   - blue
-- - green 2
-- * - cyan
--   - yellow
-- - green 3
--   - dark_green
--   * - green
--     - black
--   - white
--
-- - blue 1
-- * - cyan
--   - magenta
	self.job_data.wools.dye_names  = {
		[1] = {
			['a'] = { ["dye:green"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:white"] = 99, },
			['b'] = { ["dye:dark_green"] = 99, },
		},
	}
	self.job_data.wools.target = {
		[1] = { ["dye:cyan"] = 99, },
		[2] = { ["dye:green"] = 99, },
		[3] = { ["dye:green"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		--["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  3)
	local target = self.job_data.wools.target
	assert(#target     ==  3)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "grey" then
-- grey 1
-- - white
-- - black
-- grey 2
-- - white
-- - dark_grey
--
-- - dark_grey 1
--   - yellow
--   - violet
--
--   - violet 1
--     - red
--       - yellow
--       - magenta
--         - pink
--   *     - violet
--     - blue
--       - cyan
--         - green
--     *   - blue
--       - magenta
--   - violet 2
--     - magenta
--     - blue
-- - dark_grey 2
--   - blue
--     - cyan
--     - magenta
--       - pink
--         - red
--         - white
--       - violet 1
--         - magenta
--       * - blue
--       - violet 2
--         - red
--       * - blue
--   - orange
--     - yellow
--     - red
--       - yellow
--       - magenta
--         - pink
--         * - red
--           - white
--         - violet
--
--         - violet 1
--       *   - magenta
--           - blue
--         - violet 2
--     *     - red
--           - blue
-- - dark_grey 3
-- * - grey
--   - black
	self.job_data.wools.dye_names  = {
		[1] = {
			['a'] = { ["dye:white"] = 99, },
			['b'] = { ["dye:black"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:white"] = 99, },
			['b'] = { ["dye:dark_grey"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
		[4] = {
			['a'] = { ["dye:blue"] = 99, },
			['b'] = { ["dye:orange"] = 99, },
		},
		[5] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
		[6] = {
			['a'] = { ["dye:magenta"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
		[7] = {
			['a'] = { ["dye:cyan"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[8] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:red"] = 99, },
		},
		[9] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[10] = {
			['a'] = { ["dye:cyan"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[11] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:white"] = 99, },
		},
		[12] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
	}
	self.job_data.wools.target = {
		[1] = { ["dye:grey"] = 99, },
		[2] = { ["dye:grey"] = 99, },
		[3] = { ["dye:dark_grey"] = 99, },
		[4] = { ["dye:dark_grey"] = 99, },
		[5] = { ["dye:violet"] = 99, },
		[6] = { ["dye:violet"] = 99, },
		[7] = { ["dye:blue"] = 99, },
		[8] = { ["dye:orange"] = 99, },
		[9] = { ["dye:red"] = 99, },
		[10] = { ["dye:blue"] = 99, },
		[11] = { ["dye:pink"] = 99, },
		[12] = { ["dye:magenta"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		--["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names == 12)
	local target    = self.job_data.wools.target
	assert(#target     == 12)
	local names     = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "pink" then
-- pink
-- - red
--   - yellow
--   - magenta
-- - white
	self.job_data.wools.dye_names  = {
		[1] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:white"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
	}
	self.job_data.wools.target = {
		[1] = { ["dye:pink"] = 99, },
		[2] = { ["dye:red"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		--["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  2)
	local target    = self.job_data.wools.target
	assert(#target     ==  2)
	local names     = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "black" then
	self.job_data.wools.dye_names  = {
	}
	self.job_data.wools.target = {
		[1] = { ["dye:black"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		--["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  0)
	local target = self.job_data.wools.target
	assert(#target     ==  1)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "brown" then
-- brown
-- - red
--   - yellow
--   - magenta
--     - pink
--     - violet
-- - green
--
-- - green 1
--   - yellow
--   - blue
--     - cyan
--     - magenta
--       - pink
--         - red
--         - white
--       - violet
-- - green 2
--   - cyan
--   - yellow
-- - green 3
--   - white
--   - dark_green

	self.job_data.wools.dye_names  = {
		[1] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:green"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
		[4] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:cyan"] = 99, },
		},
		[5] = {
			['a'] = { ["dye:white"] = 99, },
			['b'] = { ["dye:dark_green"] = 99, },
		},
		[6] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
		[7] = {
			['a'] = { ["dye:cyan"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[8] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
		[9] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:white"] = 99, },
		},
	}
	self.job_data.wools.target = {
		[1] = { ["dye:brown"] = 99, },
		[2] = { ["dye:red"] = 99, },
		[3] = { ["dye:green"] = 99, },
		[4] = { ["dye:green"] = 99, },
		[5] = { ["dye:green"] = 99, },
		[6] = { ["dye:magenta"] = 99, },
		[7] = { ["dye:blue"] = 99, },
		[8] = { ["dye:magenta"] = 99, },
		[9] = { ["dye:pink"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		--["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  9)
	local target = self.job_data.wools.target
	assert(#target     ==  9)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "green" then
-- green 1
-- - yellow
-- - blue
--   - cyan
--   - magenta
--     - pink
--       - red
--       - white
--     - violet
--
-- green 2
-- - cyan
-- - yellow
--
-- green 3
-- - white
-- - dark_green

	self.job_data.wools.dye_names  = {
		[1] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:cyan"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:white"] = 99, },
			['b'] = { ["dye:dark_green"] = 99, },
		},
		[4] = {
			['a'] = { ["dye:cyan"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[5] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
		[6] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:white"] = 99, },
		},
	}
	self.job_data.wools.target = {
		[1] = { ["dye:green"] = 99, },
		[2] = { ["dye:green"] = 99, },
		[3] = { ["dye:green"] = 99, },
		[4] = { ["dye:blue"] = 99, },
		[5] = { ["dye:cyan"] = 99, },
		[6] = { ["dye:pink"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		--["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  6)
	local target = self.job_data.wools.target
	assert(#target     ==  6)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "white" then
	self.job_data.wools.dye_names  = {
	}
	self.job_data.wools.target = {
		[1] = { ["dye:white"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		--["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  0)
	local target = self.job_data.wools.target
	assert(#target     ==  1)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "orange" then
-- orange
-- - yellow
-- - red
--   - yellow
--   - magenta
--     - pink
--     - violet
	self.job_data.wools.dye_names  = {
		[1] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:red"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
	}
	self.job_data.wools.target = {
		[1] = { ["dye:orange"] = 99, },
		[2] = { ["dye:red"] = 99, },
		[3] = { ["dye:magenta"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		--["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  3)
	local target = self.job_data.wools.target
	assert(#target     ==  3)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "violet" then
-- violet
-- - red
--   - yellow
--   - magenta
-- - blue
--   - cyan
--   - magenta
	self.job_data.wools.dye_names  = {
		[1] = {
			['a'] = { ["dye:red"] = 99, },
		 	['b'] = { ["dye:blue"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:cyan"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
	}
	self.job_data.wools.target = {
		[1] = { ["dye:violet"] = 99, },
		[2] = { ["dye:red"] = 99, },
		[3] = { ["dye:blue"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		--["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  3)
	local target = self.job_data.wools.target
	assert(#target     ==  3)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "yellow" then
	self.job_data.wools.dye_names  = {
	}
	self.job_data.wools.target = {
		[1] = { ["dye:yellow"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		--["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  0)
	local target = self.job_data.wools.target
	assert(#target     ==  1)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "magenta" then
-- magenta
-- - pink
--   - red
--   - white
-- - violet
--   - red
--   - blue
	self.job_data.wools.dye_names = {
		[1] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:white"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
	}
	self.job_data.wools.target= {
		[1] = { ["dye:magenta"] = 99, },
		[2] = { ["dye:pink"] = 99, },
		[3] = { ["dye:violet"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		--["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  3)
	local target = self.job_data.wools.target
	assert(#target     ==  3)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "dark_grey" then
-- dark_grey 1
-- - yellow
-- - violet 1
--   - red
--     - yellow
--     - magenta
--       - pink
--       - violet
--   - blue
-- - violet 2
--   - magenta
--   - blue
--
-- dark_grey 2
-- - blue
-- - orange
--   - yellow
--   - red
--     - yellow
--     - magenta
--       - pink
--       - violet
--
-- dark_grey 3
-- - grey
--   - white
--   - black
-- - black

	self.job_data.wools.dye_names = {
		[1] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:blue"] = 99, },
			['b'] = { ["dye:orange"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:grey"] = 99, },
			['b'] = { ["dye:black"] = 99, },
		},
		[4] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
		[5] = {
			['a'] = { ["dye:magenta"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
		[6] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:red"] = 99, },
		},
		[7] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[8] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
	}
	self.job_data.wools.target= {
		[1] = { ["dye:dark_grey"] = 99, },
		[2] = { ["dye:dark_grey"] = 99, },
		[3] = { ["dye:dark_grey"] = 99, },
		[4] = { ["dye:violet"] = 99, },
		[5] = { ["dye:violet"] = 99, },
		[6] = { ["dye:orange"] = 99, },
		[7] = { ["dye:red"] = 99, },
		[8] = { ["dye:magenta"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		--["wool:dark_grey"] = 99,
		["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  8)
	local target = self.job_data.wools.target
	assert(#target     ==  8)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
elseif target_color == "dark_green" then
-- dark_green
-- - black
-- - green
--
-- - green 1
--   - yellow
--   - blue
--     - cyan
--     - magenta
--       - pink
--         - red
--         - white
--       - violet
--         - red
--         - blue
-- - green 2
--   - yellow
--   - cyan

	self.job_data.wools.dye_names= {
		[1] = {
			['a'] = { ["dye:black"] = 99, },
			['b'] = { ["dye:green"] = 99, },
		},
		[2] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
		[3] = {
			['a'] = { ["dye:yellow"] = 99, },
			['b'] = { ["dye:cyan"] = 99, },
		},
		[4] = {
			['a'] = { ["dye:cyan"] = 99, },
			['b'] = { ["dye:magenta"] = 99, },
		},
		[5] = {
			['a'] = { ["dye:pink"] = 99, },
			['b'] = { ["dye:violet"] = 99, },
		},
		[6] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:white"] = 99, },
		},
		[7] = {
			['a'] = { ["dye:red"] = 99, },
			['b'] = { ["dye:blue"] = 99, },
		},
	}
	self.job_data.wools.target= {
		[1] = { ["dye:dark_green"] = 99, },
		[2] = { ["dye:green"] = 99, },
		[3] = { ["dye:green"] = 99, },
		[4] = { ["dye:blue"] = 99, },
		[5] = { ["dye:magenta"] = 99, },
		[6] = { ["dye:pink"] = 99, },
		[7] = { ["dye:violet"] = 99, },
	}
	self.job_data.wools.names = {
		["wool:red"] = 99,
		["wool:blue"] = 99,
		["wool:cyan"] = 99,
		["wool:grey"] = 99,
		["wool:pink"] = 99,
		["wool:black"] = 99,
		["wool:brown"] = 99,
		["wool:green"] = 99,
		["wool:white"] = 99,
		["wool:orange"] = 99,
		["wool:violet"] = 99,
		["wool:yellow"] = 99,
		["wool:magenta"] = 99,
		["wool:dark_grey"] = 99,
		--["wool:dark_green"] = 99,
	}
	local dye_names = self.job_data.wools.dye_names
	assert(#dye_names ==  7)
	local target = self.job_data.wools.target
	assert(#target     ==  7)
	local names = self.job_data.wools.names
	--assert(#names      == 14)
else
	assert(false)
end
assert( self.job_data.wools.target ~= nil)
assert(#self.job_data.wools.target ~= 0)
end

function dyemixer_recipes.fashion_season(self)
		self:count_timer("dyemixer:fashion") -- TODO make the color settings configurable
		if self.job_data.wools == nil then
			self.job_data.wools = {}
		end
		if self.job_data.wools.target     == nil
		or self.job_data.wools.dye_names == nil
		or self.job_data.wools.names      == nil then
			assert(self.job_data.wools.target     == nil)
			assert(self.job_data.wools.dye_names == nil)
			assert(self.job_data.wools.names      == nil)
		end
		if self.job_data.wools.target == nil
		or self.job_data.target_color == nil
		or self.job_data.colorno      == nil then
		--or self:timer_exceeded("dyemixer:fashion",3600) then
		-- TODO for testing
			-- TODO off by one? lua is weird
			local temp = math.random(#colors-1)
			print('temp: '..temp)
			assert(0<=temp)
			assert(temp < #colors)

			local new_color = colors[temp+1]
			assert(new_color ~= nil)
			print('color '..new_color)

			self.job_data.colorno = temp
			self.job_data.target_color = new_color
			assert(self.job_data.target_color ~= nil)

			dyemixer_recipes.update_color_plan(self,new_color)
			assert(self.job_data.wools.target ~= nil)

			log.action("villager %s is targeting dye color %s", self.inventory_name, self.job_data.target_color)
			self:set_state_info("The fashion of the season is "..self.job_data.target_color)
		elseif self:timer_exceeded("dyemixer:fashion",3600) then
			local temp = self.job_data.colorno
			assert(temp ~= nil)
			temp = func.mod(temp + 1, #colors)
			print('temp: '..temp)
			assert(0<=temp)
			assert(temp < #colors)

			local new_color = colors[temp+1]
			assert(new_color ~= nil)
			print('color '..new_color)

			self.job_data.colorno = temp
			self.job_data.target_color = new_color
			assert(self.job_data.target_color ~= nil)

			dyemixer_recipes.update_color_plan(self,new_color)
			assert(self.job_data.wools.target ~= nil)

			log.action("villager %s is targeting dye color %s", self.inventory_name, self.job_data.target_color)
			self:set_state_info("The fashion of the season is "..self.job_data.target_color)
		end
		assert(self.job_data.wools.target ~= nil)

	end




return dyemixer_recipes
