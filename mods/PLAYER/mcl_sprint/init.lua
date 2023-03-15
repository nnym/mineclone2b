--[[
Sprint mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights
to this software to the public domain worldwide. This software is
distributed without any warranty.
]]

--Configuration variables, these are all explained in README.md
mcl_sprint = {}

mcl_sprint.SPEED = 1.3

local players = {}
local metas = {}

local function meta(player)
	if type(player) == "string" then player = minetest.get_player_by_name(player) end
	return metas[player:get_player_name()]
end

minetest.register_on_joinplayer(function(player)
	metas[player:get_player_name()] = {
		lastPos = player:get_pos(),
		sprintDistance = 0,
		channel = minetest.mod_channel_join("mcl_sprint")
	}
end)

minetest.register_on_leaveplayer(function(player)
	metas.remove(player:get_player_name())
end)

-- Returns true if the player with the given name is sprinting, false if not.
-- Returns nil if player does not exist.
function mcl_sprint.is_sprinting(player)
	return meta(player).sprinting == true
end

local function setSprinting(player, sprinting) --Sets the state of a player (0=stopped/moving, 1=sprinting)
	local meta = meta(player)

	if meta.sprinting and not sprinting then
		meta.channel:send_all("")
		meta.clientSprint = false
	end

	meta.sprinting = sprinting

	if sprinting then
		playerphysics.add_physics_factor(player, "speed", "mcl_sprint:sprint", mcl_sprint.SPEED)
	else
		playerphysics.remove_physics_factor(player, "speed", "mcl_sprint:sprint")
		player:set_fov(1, true, 0.15)
	end

	if player:get_player_control().RMB
		and string.find(player:get_wielded_item():get_name(), "mcl_bows:bow")
		and player:get_wielded_item():get_name() ~= "mcl_bows:bow" then
		player:set_fov(0.7, true, 0.3)
	elseif string.match(player:get_wielded_item():get_name(), "mcl_bows:bow_[0-2]") then
		player:set_fov(math.max(player:get_fov() - 0.05, 1.0), true, 0.15)
	end

	return true
end

-- Given the param2 and paramtype2 of a node, returns the tile that is facing upwards
local function get_top_node_tile(param2, paramtype2)
	if paramtype2 == "colorwallmounted" then
		param2 = param2 % 8
	elseif paramtype2 == "colorfacedir" then
		param2 = param2 % 32
	end

	if paramtype2 == "colorwallmounted" then
		local values = {2, 1}
		return values[param2] or 5
	elseif paramtype2 == "colorfacedir" then
		if param2 >= 0 and param2 <= 3 then return 1
		elseif param2 == 4 or param2 == 10 or param2 == 13 or param2 == 19 then return 6
		elseif param2 == 5 or param2 == 11 or param2 == 14 or param2 == 16 then return 3
		elseif param2 == 6 or param2 == 8 or param2 == 15 or param2 == 17 then return 5
		elseif param2 == 7 or param2 == 9 or param2 == 12 or param2 == 18 then return 4
		elseif param2 >= 20 and param2 <= 23 then return 2
		end
	end

	return 1
end

minetest.register_on_modchannel_message(function(channel_name, sender, message)
	if channel_name == "mcl_sprint" then
		meta(sender).clientSprint = minetest.is_yes(message)
	end
end)

minetest.register_on_respawnplayer(function(player)
	cancelClientSprinting(player)
end)

minetest.register_globalstep(function(dtime)
	--Get the gametime
	local gameTime = minetest.get_gametime()

	--Loop through all connected players
	for _, player in pairs(minetest.get_connected_players()) do
		local ctrl = player:get_player_control()
		local meta = meta(player)
		--Check if the player should be sprinting
		local v = player:get_velocity()
		local shouldSprint = meta.clientSprint or ctrl.aux1 and ctrl.up and not ctrl.sneak and math.abs(v.x) + math.abs(v.z) >= 0.3
		local playerPos = player:get_pos()

		--If the player is sprinting, create particles behind and cause exhaustion
		if meta.sprinting and not player:get_attach() and gameTime % 0.1 == 0 then
			local lastPos = meta.lastPos

			-- Exhaust player for sprinting
			local dist = vector.distance({x = lastPos.x, y = 0, z = lastPos.z}, {x = playerPos.x, y = 0, z = playerPos.z})
			meta.sprintDistance = meta.sprintDistance + dist

			if meta.sprintDistance >= 1 then
				local superficial = math.floor(meta.sprintDistance)
				mcl_hunger.exhaust(player:get_player_name(), mcl_hunger.EXHAUST_SPRINT * superficial)
				meta.sprintDistance = meta.sprintDistance - superficial
			end

			-- Sprint node particles
			local playerNode = minetest.get_node({x = playerPos.x, y = playerPos.y - 1, z = playerPos.z})
			local def = minetest.registered_nodes[playerNode.name]

			if def and def.walkable then
				minetest.add_particlespawner({
					amount = math.random(1, 2),
					time = 1,
					minpos = {x=-0.5, y=0.1, z=-0.5},
					maxpos = {x=0.5, y=0.1, z=0.5},
					minvel = {x=0, y=5, z=0},
					maxvel = {x=0, y=5, z=0},
					minacc = {x=0, y=-13, z=0},
					maxacc = {x=0, y=-13, z=0},
					minexptime = 0.1,
					maxexptime = 1,
					minsize = 0.5,
					maxsize = 1.5,
					collisiondetection = true,
					attached = player,
					vertical = false,
					node = playerNode,
					node_tile = get_top_node_tile(playerNode.param2, def.paramtype2),
				})
			end
		end

		--Adjust player states
		meta.lastPos = playerPos

		if shouldSprint then --Stopped
			-- Prevent sprinting if hungry or sleeping
			local sprinting = (mcl_hunger.active and mcl_hunger.get_hunger(player) > 6)
				and player:get_meta():get_string("mcl_beds:sleeping") ~= "true"

			setSprinting(player, sprinting)
		else
			setSprinting(player, false)
		end
	end
end)
