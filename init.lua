local RADIUS = 128
local SPAWN = {x=0, y=0, z=0}
local timer = 0

--
-- Determine center of spawnpoint as mean of player positions
--

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 60 then return end
	timer = 0

	local sx = 0 -- mean x value
	local sz = 0 -- mean z value
	local players = minetest.get_connected_players()
	for _,player in ipairs(players) do
		local pos = player:get_pos()
		sx = sx+pos.x
		sz = sz+pos.z
	end
	SPAWN = {x=sx/#players, y=0, z=sz/#players}
    --print("new Spawn at = "..SPAWN.x..", "..SPAWN.z)
end)

--
-- Spawn players randomly within the defined area
--

local function findspawn(player)
	for try=100000, 0, -1 do
		local pos = {x = SPAWN.x, y = SPAWN.y, z = SPAWN.z}
		pos.x = SPAWN.x + math.random(-RADIUS, RADIUS)
		pos.z = SPAWN.z + math.random(-RADIUS, RADIUS)
		if minetest.forceload_block(pos) then
			-- Find ground level (0...15)
			local ground_y = nil
			for y=16, 0, -1 do
				local nn = minetest.get_node({x=pos.x, y=y, z=pos.z}).name
				if nn ~= "air" and nn~= "ignore" then
					ground_y = y
					break
				end
			end
			if ground_y then
				pos.y = ground_y
				if minetest.registered_nodes[minetest.get_node(pos).name].walkable == true and
					minetest.get_node({x=pos.x, y=pos.y+1, z=pos.z}).name == "air" and
					minetest.get_node({x=pos.x, y=pos.y+2, z=pos.z}).name == "air" then
					local pos_spawn = {x=pos.x, y=pos.y+1, z=pos.z}
					return pos_spawn
				end
			end
			minetest.forceload_free_block(pos)
		end
	end
end

local function spawnarea(player)
	local pos = findspawn(player)
	if pos then
		player:setpos(pos)
	else
		player:setpos(SPAWN)
	end
end

if not minetest.is_singleplayer() then
minetest.register_on_newplayer(function(player)
	spawnarea(player)
end)
end

minetest.register_on_respawnplayer(function(player)
	spawnarea(player)
	return true
end)
