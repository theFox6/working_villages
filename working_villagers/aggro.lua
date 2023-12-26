local aggro = {}

function aggro.default_aggro_table()
  return {
    -- < -99: war
    -- <   0: dislike
    -- =   0: neutral
    -- >   0:    like
    -- >  99: ally
     war_threshold = math.random(-200,   -50),   -- -99, -- at which point we dislike you enough to declare war
    ally_threshold = math.random(  50,   200),   --  99, -- at which point we are willing to die for you in war
    loyalty_factor = math.random(   0.1,   0.9), -- 0.5, -- any friend of <such and such> is a friend of mine
    villages = { -- dislike entire groups of players or player-like entities
      -- ["Fredericksburg"] = 0,
      -- ["Boerne"]         = 0,
      -- ["New Braunfels"]  = 0,
      -- ["Comfort"]        = 0,
      -- ["Schulenburg"]    = 0,
      -- ["Gruene"]         = 0,
      -- ["Bellville"]      = 0,
      -- ["Muenster"]       = 0,
      -- ["Brenham"]        = 0,
      -- ["Bulverde"]       = 0,
      -- ["Weimar"]         = 0,
      -- ["Luckenbach"]     = 0,
    },
    players   = { -- dislike specific players or player-like entities
      -- ["wizard"]         = 0, -- NetHack's debug playername has an advantage with IA Discordia
      -- ["JonSkeet"]       = 0, -- the legendary programmer   has an advantage with IA Roko's Basilisk / Grey Goo
    },
    other     = { -- I'll figure out a way to dislike abstract concepts
      -- ["democracy"] =  99,
      -- ["communism"] = -99,
    },
  }
end

-- TODO this is just a villager's aggro against a player
-- TODO need variants for village's aggro
-- TODO need variants for aggro against villages, other
function aggro.get_player_aggro(villager, player_name)
	assert(villager    ~= nil)
	assert(player_name ~= nil)

	if villager.aggro         == nil then return 0 end
	if villager.aggro.players == nil then return 0 end
	local like = villager.aggro.players[player_name]
	if like == nil then return 0 end
	return like
end
function aggro.get_neighbors_player_aggro(villager, neighbor, player_name)
	return aggro.get_player_aggro(neighbor, player_name) * villager.loyalty_factor
end
function aggro.get_effective_player_aggro(villager, player_name)
	assert(villager    ~= nil)
	assert(player_name ~= nil)

	-- how much the villager likes you personally
	local like         = aggro.get_player_aggro(villager, player_name)

	-- how much the villager's village dislikes you
	local village_name = villager.village_name
	local village      = working_villages.get_village(village_name)
	like               = like + aggro.get_neighbors_player_aggro(villager, village, player_name)

	-- how much the villager's friends dislike you
	local villagers    = village.villagers
	for other_villager,other_like in pairs(villagers) do
		like = like + aggro.get_neighbors_player_aggro(villager, other_villager, player_name)
	end

	return like
end

return aggro
