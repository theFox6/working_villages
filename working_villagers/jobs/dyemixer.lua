local func = working_villages.require("jobs/util")
local log = working_villages.require("log")

function mod(x, m)
	assert(x ~= nil)
	assert(m ~= nil)
	local r = x % m
	--if r < 0 then
	--	r = r+m
	--end
	r = r % m
	assert(0 <= r)
	assert(r <  m)
	return r
end

local dyemixers = {
	names = {
		["mcg_dyemixer:dye_mixer"]={},
	},
}

local wools = {
	dye_groups = {
	},
	groups = {
		["wool"]=99,
	},
}

-- TODO write a dependency management system
function update_color_plan(self, target_color)
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



-- called by take_func for all iterations
function wools.get_dyingsupplies(self, item_name, iteration)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	--if iteration == nil then iteration = 0 end -- TODO
	if self.job_data.wools.dye_names[iteration] ~= nil then
		for k,v in pairs(self.job_data.wools.dye_names[iteration]) do
	for key, value in pairs(v) do
		if item_name==key then
			return value
		end
	end
		end
	end
	if self.job_data.wools.target[iteration] ~= nil then
	for key, value in pairs(self.job_data.wools.target[iteration]) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	end
	for key, value in pairs(self.job_data.wools.names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(wools.dye_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	for key, value in pairs(wools.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
-- called by put_func for all iterations
function wools.is_dyingsupplies(self, item_name, iteration)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	-- TODO 
  local data = wools.get_dyingsupplies(self, item_name, iteration);
  return data ~= nil
end
function wools.get_dyeable(self,item_name)
	assert(item_name ~= nil)
	for key, value in pairs(self.job_data.wools.names) do
		if item_name==key then
			return value
		end
	end
	for key, value in pairs(wools.groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function wools.is_dyeable(self, item_name)
	assert(item_name ~= nil)
  local data = wools.get_dyeable(self, item_name);
  return data ~= nil
end
function wools.get_dye(self, item_name, iteration,ab)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	assert(ab        ~= nil)
	--if iteration == nil then iteration = 0 end -- TODO
	if self.job_data.wools.dye_names[iteration] ~= nil then
	for key, value in pairs(self.job_data.wools.dye_names[iteration][ab]) do
		if item_name==key then
			return value
		end
	end
	end
	for key, value in pairs(wools.dye_groups) do
		if minetest.get_item_group(item_name, key) > 0 then
			return value;
		end
	end
	return nil
end
function wools.is_dye(self, item_name, iteration,ab)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	assert(ab        ~= nil)
  local data = wools.get_dye(self, item_name, iteration,ab);
  return data ~= nil
end

function wools.get_target(self, item_name, iteration)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
	if self.job_data.wools.target[iteration] == nil then return nil end
	for key, value in pairs(self.job_data.wools.target[iteration]) do
		if item_name==key then
			return value
		end
	end
end
function wools.is_target(self, item_name, iteration)
	assert(item_name ~= nil)
	assert(iteration ~= nil)
  local data = wools.get_target(self, item_name, iteration);
  return data ~= nil
end





function dyemixers.get_dyemixer(item_name)
	assert(item_name ~= nil)
	for key, value in pairs(dyemixers.names) do
		if item_name==key then
			return value
		end
	end
	return nil
end

function dyemixers.is_dyemixer(item_name)
	assert(item_name ~= nil)
	local data = dyemixers.get_dyemixer(item_name);
	return data ~= nil
end

local function find_dyemixer_node(pos)
	assert(pos       ~= nil)
	local node = minetest.get_node(pos);
	local data = dyemixers.get_dyemixer(node.name);
	return data ~= nil
end

local searching_range = {x = 10, y = 3, z = 10}

local function put_func(villager,stack)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	local ntarget = villager.job_data.wools.target
	      ntarget = #ntarget
	for iteration=0,ntarget,1 do
		if wools.is_dyingsupplies(villager,stack:get_name(), iteration) then -- TODO all iterations
			return false
		end
	end
	return true;
end
local function take_func(villager,stack)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	local item_name = stack:get_name()
	local ntarget = villager.job_data.wools.target
	      ntarget = #ntarget
	for iteration=0,ntarget,1 do
		if wools.is_dyingsupplies(villager,item_name, iteration) then
			local inv = villager:get_inventory()
			local itemstack = ItemStack(item_name)
			itemstack:set_count(wools.get_dyingsupplies(villager,item_name, iteration)) -- TODO all iterations
			if (not inv:contains_item("main", itemstack)) then
				return true
			end
		end
	end
	return false
end


























local function take_func2(villager,stack)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	-- TODO take all dyes and non-target wool
	local item_name = stack:get_name()
	local inv = villager:get_inventory()
	return (inv:room_for_item("main", stack))
end



















local function put_dye(villager,stack,data)--,iteration,ab)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	assert(data      ~= nil)
	local iteration = data.iteration
	assert(iteration ~= nil)
	local ab        = data.ab
	assert(ab        ~= nil)
	return wools.is_dye(villager,stack:get_name(), iteration,ab) -- TODO
end

local function put_dyeable(villager,stack)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	return wools.is_dyeable(villager,stack:get_name())
end

local function put_target(villager,stack)--,data,iteration)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	local iteration = 1
	return wools.is_target(villager,stack:get_name(), iteration) -- TODO
end
local function take_target(villager,stack)--,data,iteration)
	assert(villager  ~= nil)
	assert(stack     ~= nil)
	local inv = villager:get_inventory()
	return (inv:room_for_item("main", stack))
end

local colors = {
	"red",     "blue",      "cyan",  "grey",   "pink",   "black",
	"brown",   "green",     "white", "orange", "violet", "yellow",
	"magenta", "dark_grey", "dark_green",
}

working_villages.register_job("working_villages:job_dyemixer", {
	description			= "dyemixer (working_villages)",
	long_description = "I look for a dyemixer and start putting your wools into it.",
	inventory_image	= "default_paper.png^working_villages_herb_collector.png",
	jobfunc = function(self)
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

			update_color_plan(self,new_color)
			assert(self.job_data.wools.target ~= nil)

			log.action("villager %s is targeting dye color %s", self.inventory_name, self.job_data.target_color)
			self:set_state_info("The fashion o the season is "..self.job_data.target_color)
		elseif self:timer_exceeded("dyemixer:fashion",3600) then
			local temp = self.job_data.colorno
			assert(temp ~= nil)
			temp = mod(temp + 1, #colors)
			print('temp: '..temp)
			assert(0<=temp)
			assert(temp < #colors)

			local new_color = colors[temp+1]
			assert(new_color ~= nil)
			print('color '..new_color)

			self.job_data.colorno = temp
			self.job_data.target_color = new_color
			assert(self.job_data.target_color ~= nil)

			update_color_plan(self,new_color)
			assert(self.job_data.wools.target ~= nil)

			log.action("villager %s is targeting dye color %s", self.inventory_name, self.job_data.target_color)
			self:set_state_info("The fashion o the season is "..self.job_data.target_color)
		end
		assert(self.job_data.wools.target ~= nil)

		self:handle_night()
		self:handle_chest(
			take_func, -- take dyeable + dye
			put_func   -- put not(dyeable or dye)
		)
		self:handle_job_pos()

		self:count_timer("dyemixer:search")
		self:count_timer("dyemixer:change_dir")
		self:handle_obstacles()
		if self:timer_exceeded("dyemixer:search",20) then
			self:collect_nearest_item_by_condition(dyemixers.is_dyemixer, searching_range)
			local target = func.search_surrounding(self.object:get_pos(), find_dyemixer_node, searching_range)
			if target ~= nil then
				local destination = func.find_adjacent_clear(target)
				if destination then
					destination = func.find_ground_below(destination)
				end
				if destination==false then
					print("failure: no adjacent walkable found")
					destination = target
				end
				self:go_to(destination)
				local target_def = minetest.get_node(target)
				local plant_data = dyemixers.get_dyemixer(target_def.name);
				if plant_data then
					self:set_displayed_action("operating the furnace")
					self:handle_dyemixer(
					        target,
						take_func2, -- take everything
						put_dyeable, -- put what we need to furnace
						put_dye,
						take_target,
						put_target
					)
				end
			end
		elseif self:timer_exceeded("dyemixer:change_dir",50) then
			self:change_direction_randomly()
		end
	end,
})



function func.is_dyemixer(pos)
	local node = minetest.get_node(pos)
  if (node==nil) then
    return false;
  end
  if node.name=="mcg_dyemixer:dye_mixer" then
    return true;
  end
  local is_chest = minetest.get_item_group(node.name, "dyemixer");
  if (is_chest~=0) then
    return true;
  end
  return false;
end




--function working_villages.villager:handle_dyemixer(dyemixer_pos, take_func, put_func, put_lock, data)
function working_villages.villager:handle_dyemixer(dyemixer_pos, take_func, put_func, put_fuel, take_target, put_target, data)
	assert(dyemixer_pos     ~= nil)
	assert(take_func        ~= nil)
	assert(put_func         ~= nil)
	assert(put_fuel         ~= nil)
	assert(take_target      ~= nil)
	assert(put_target       ~= nil)
	assert(data             == nil)
	assert(func.is_dyemixer ~= nil)
	local my_data = {
		appliance_id  = 'my_dyemixer',
		appliance_pos = dyemixer_pos,
		is_appliance  = func.is_dyemixer,
		operations    = {},
	}
	local ntarget = self.job_data.wools.target
	      ntarget = #ntarget
	--print('ntarget: '..ntarget)
	-- I've switched the indexing to and from 0- and 1-based so many times
	-- I'm pretty sure there's an off-by-one error, but the bot seems to be
	-- more-or-less functional
	for iteration=ntarget,0,-1 do
		--print('iteration: '..iteration)

		local index = 5*(ntarget-iteration)

		--print('index    : '..index)
		my_data.operations[index+0]   = {
			list      = "input_a",
			is_put    = true,
			put_func  = put_fuel,
			data      = {
				iteration = iteration,
				ab        = 'a',
			},
		}

		--print('index    : '..index+1)
		my_data.operations[index+1]   = {
			list      = "input_b",
			is_put    = true,
			put_func  = put_fuel,
			data      = {
				iteration = iteration,
				ab        = 'b',
			},
		}

		--print('index    : '..index+2)
		my_data.operations[index+2]   = {
			list      = "output",
			is_take   = true,
			take_func = take_target,
			--data      = data[2] or nil
		}
		
		--print('index    : '..index+3)
		my_data.operations[index+3]   = {
			list      = "input_a",
			is_take   = true,
			take_func = take_target,
			--data      = data[2] or nil
		}
		
		--print('index    : '..index+4)
		my_data.operations[index+4]   = {
			list      = "input_b",
			is_take   = true,
			take_func = take_target,
			--data      = data[2] or nil
		}
	end
	--print('iteration: 0 (tail)')
	local index = 5*(ntarget-0)

	--print('index    : '..index+5)
	my_data.operations[index+5]   = {
		list      = "input_a",
		is_put    = true,
		put_func  = put_target,
		data      = {
			iteration = 0,
			ab        = 'a',
		},
	}
	--print('index    : '..index+6)
	my_data.operations[index+6]   = {
		list      = "input_b",
		is_put    = true,
		put_func  = put_func,
		--data      = data[1] or nil,
	}
	--print('index    : '..index+7)
	my_data.operations[index+7]   = {
		list      = "output",
		is_take   = true,
		take_func = take_func,
		--data      = data[2] or nil
	}
	--assert(index == ntarget*5+3)
	--assert(index == #my_data.operations)
	--print('ntarget: '..ntarget)
	--print('actual : '..ntarget*5+8)
	--print('#op    : '..#my_data.operations)
	--assert(ntarget*5+8 == #my_data.operations)
	--for iteration=1,index,1 do
	for iteration=0,#my_data.operations,1 do
		assert(my_data.operations[iteration] ~= nil)
	end
	self:handle_appliance(my_data)
end

