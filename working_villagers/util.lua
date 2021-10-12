local wv_util = {}

local debug_checks = working_villages.setting_enabled("debug_checks",true)

function wv_util.get_euclidean_neighbors()
  local base = vector.new()
  local neigh = {}
  for _,v in pairs({"x","y","z"}) do
    local pos, neg = vector.new(base),vector.new(base)
    pos[v] = 1
    neg[v] = -1
    neigh["+"..v] = pos
    neigh["-"..v] = neg
  end
  return neigh
end

--TODO: add generator to iterate through euclidean neigbors spiraling outward

function wv_util.get_eneigbor_offsets(radius,adjacent)
  local r = radius or 1
  local a = adjacent or "xzy"
  if type(a) == "string" then
    local n = wv_util.get_euclidean_neighbors()
    local tab = {}
    for l in a:gmatch(".") do
      table.insert(tab,n["+"..l])
      table.insert(tab,n["-"..l])
    end
    a = tab
  elseif type(a) == "table" then
    if debug_checks then
      for i,v in ipairs(a) do
        assert(type(v) == "table","neigbor distance table contains non-table element at "..i..": "..dump(v))
        assert(type(v.x) == "number", "neigbor distance table has no x value in element "..i)
        assert(type(v.y) == "number", "neigbor distance table has no y value in element "..i)
        assert(type(v.z) == "number", "neigbor distance table has no z value in element "..i)
      end
    end
  else
    error("expected string or table as third argument (neighbor distances)",2)
  end
  local list = {vector.new()}
  local lb = {list[1]}
  local hs = {}
  for _ = 1,r do
    local nb = {}
    for _,b in ipairs(lb) do
      for _,n in ipairs(a) do
        local off = vector.add(n,b)
        local hash = (off.x + r) + (off.y + r) * ((r+1) * 2) + (off.z + r) * ((r+1) * 2)^2
        if hash < 0 then print("oof") end
        if not hs[hash] then
          hs[hash] = true
          table.insert(list,off)
          table.insert(nb,off)
        end
      end
    end
    lb = nb
  end
  return list
end

return wv_util
