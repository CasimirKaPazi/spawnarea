local radius = 128
local spawn = {x=0, y=0, z=0}
local center = {x=0, y=0, z=0}
local timer = 295 -- first run shortly after start

--
-- Determine center of spawnpoint as mean of player positions
--

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer < 300 then return end -- 300 = 5 minutes
	timer = 0

	local cx = 0
	local cy = 0
	local cz = 0
	local n = 0 -- number of players counted
	local players = minetest.get_connected_players()
	if #players < 1 then return end
	for _,player in ipairs(players) do
		local pos = player:get_pos()
		-- only count players close to the surface
		if pos.y >= 0 and pos.y < 256 then
			cx = cx+pos.x
			cy = cy+pos.y
			cz = cz+pos.z
			n = n + 1
		end
	end
	center = {x=cx/n, y=cy/n, z=cz/n}
	-- slowly approximate spawnpoint to new center
	-- changes faster with more players
	local sx = math.floor((spawn.x * 10 + center.x * n) / (10+n))
	local sy = math.floor((spawn.y * 10 + center.y * n) / (10+n))
	local sz = math.floor((spawn.z * 10 + center.z * n) / (10+n))
	spawn = {x = sx, y = sy, z = sz}
    print("spawnarea: new spawn at = "..spawn.x..", "..spawn.y..", "..spawn.z)
end)

--
-- Spawn players randomly within the defined area
--

local function findspawn(player)
	for try=100, 0, -1 do
		local pos = {x = spawn.x, y = spawn.y, z = spawn.z}
		pos.x = spawn.x + math.random(-radius, radius)
		pos.y = spawn.y
		pos.z = spawn.z + math.random(-radius, radius)
		local free = pos
		minetest.forceload_block(free, true)
		-- Find ground level
		local ground_y = nil
		for y=128, -128, -1 do
			local nn = minetest.get_node({x=pos.x, y=pos.y+y, z=pos.z}).name
			if nn ~= "air" and nn ~= "ignore" then
				ground_y = pos.y+y
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
		minetest.forceload_free_block(free, true)
	end
end

local function spawnarea(player)
	local pos = findspawn(player)
	if pos then
		player:setpos(pos)
	else
		player:setpos(spawn)
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
