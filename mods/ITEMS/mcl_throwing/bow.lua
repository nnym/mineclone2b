mcl_throwing = {}

local arrows = {
	["mcl_throwing:arrow"] = "mcl_throwing:arrow_entity",
}

local GRAVITY = 9.81
local BOW_DURABILITY = 385
local CHARGE_SPEED = 1

local bow_load = {}

mcl_throwing.shoot_arrow = function(arrow_item, pos, dir, yaw, shooter, power, damage)
	local obj = minetest.add_entity({x=pos.x,y=pos.y,z=pos.z}, arrows[arrow_item])
	if power == nil then
		power = 19
	end
	if damage == nil then
		damage = 3
	end
	obj:setvelocity({x=dir.x*power, y=dir.y*power, z=dir.z*power})
	obj:setacceleration({x=dir.x*-3, y=-GRAVITY, z=dir.z*-3})
	obj:setyaw(yaw-math.pi/2)
	local le = obj:get_luaentity()
	le._shooter = shooter
	le._damage = damage
	le._startpos = pos
	minetest.sound_play("mcl_throwing_bow_shoot", {pos=pos})
	if shooter ~= nil then
		if obj:get_luaentity().player == "" then
			obj:get_luaentity().player = shooter
		end
		obj:get_luaentity().node = shooter:get_inventory():get_stack("main", 1):get_name()
	end
	return obj
end

local get_arrow = function(player)
	local inv = player:get_inventory()
	local arrow_stack, arrow_stack_id
	for i=1, inv:get_size("main") do
		local it = inv:get_stack("main", i)
		if not it:is_empty() and minetest.get_item_group(it:get_name(), "ammo_bow") ~= 0 then
			arrow_stack = it
			arrow_stack_id = i
			break
		end
	end
	return arrow_stack, arrow_stack_id
end

local player_shoot_arrow = function(itemstack, player, power, damage)
	local arrow_stack, arrow_stack_id = get_arrow(player)
	local arrow_itemstring
	if not minetest.settings:get_bool("creative_mode") then
		if not arrow_stack then
			return false
		end
		arrow_itemstring = arrow_stack:get_name()
		arrow_stack:take_item()
		local inv = player:get_inventory()
		inv:set_stack("main", arrow_stack_id, arrow_stack)
	end
	local playerpos = player:getpos()
	local dir = player:get_look_dir()
	local yaw = player:get_look_horizontal()

	if not arrow_itemstring then
		arrow_itemstring = "mcl_throwing:arrow"
	end
	mcl_throwing.shoot_arrow(arrow_itemstring, {x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, dir, yaw, player, power, damage)
	return true
end

minetest.register_tool("mcl_throwing:bow", {
	description = "Bow",
	_doc_items_longdesc = "Bows are ranged weapons to shoot arrows at your foes.",
	_doc_items_usagehelp = [[To use the bow, you first need to have at least one arrow anywhere in your inventory (unless in Creative Mode). Hold down the right mouse button to charge, release to shoot.

The arrow speed and damage increase with the charge level:
• Low charge: 1 damage
• Medium charge: 2 damage
• High charge: 4-5 damage (20% chance for 5 damage)]],
	_doc_items_durability = BOW_DURABILITY,
	inventory_image = "mcl_throwing_bow.png",
	stack_max = 1,
	-- Trick to disable melee damage to entities.
	-- Range not set to 0 (unlike the others) so it can be placed into item frames
	range = 1,
	-- Trick to disable digging as well
	on_use = function() end,
	groups = {weapon=1,weapon_ranged=1},
})

minetest.register_tool("mcl_throwing:bow_0", {
	description = "Bow",
	_doc_items_create_entry = false,
	inventory_image = "mcl_throwing_bow_0.png",
	stack_max = 1,
	range = 0, -- Pointing range to 0 to prevent punching with bow :D
	groups = {not_in_creative_inventory=1, not_in_craft_guide=1},
})

minetest.register_tool("mcl_throwing:bow_1", {
	description = "Bow",
	_doc_items_create_entry = false,
	inventory_image = "mcl_throwing_bow_1.png",
	stack_max = 1,
	range = 0,
	groups = {not_in_creative_inventory=1, not_in_craft_guide=1},
})

minetest.register_tool("mcl_throwing:bow_2", {
	description = "Bow",
	_doc_items_create_entry = false,
	inventory_image = "mcl_throwing_bow_2.png",
	stack_max = 1,
	range = 0,
	groups = {not_in_creative_inventory=1, not_in_craft_guide=1},
})

controls.register_on_release(function(player, key, time)
	if key~="RMB" then return end
	local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
	local wielditem = player:get_wielded_item()
	if (wielditem:get_name()=="mcl_throwing:bow_0" or wielditem:get_name()=="mcl_throwing:bow_1" or wielditem:get_name()=="mcl_throwing:bow_2") then
		local shot = false
		if wielditem:get_name()=="mcl_throwing:bow_0" then
			shot = player_shoot_arrow(wielditem, player, 4, 1)
		elseif wielditem:get_name()=="mcl_throwing:bow_1" then
			shot = player_shoot_arrow(wielditem, player, 16, 2)
		elseif wielditem:get_name()=="mcl_throwing:bow_2" then
			local r = math.random(1,5)
			local damage
			-- Damage and range have been nerfed because the arrow charges very quickly
			-- TODO: Use Minecraft damage and range (9-10 @ ca. 53 m/s)
			if r == 1 then
				-- 20% chance for critical hit
				damage = 5
			else
				damage = 4
			end
			shot = player_shoot_arrow(wielditem, player, 26, damage)
		end
		wielditem:set_name("mcl_throwing:bow")
		if shot and minetest.settings:get_bool("creative_mode") == false then
			wielditem:add_wear(65535/BOW_DURABILITY)
		end
		player:set_wielded_item(wielditem)
		bow_load[player:get_player_name()] = false
	end
end)

controls.register_on_hold(function(player, key, time)
	if key ~= "RMB" then
		return
	end
	local name = player:get_player_name()
	local inv = minetest.get_inventory({type="player", name=name})
	local wielditem = player:get_wielded_item()
	if wielditem:get_name()=="mcl_throwing:bow" and (minetest.settings:get_bool("creative_mode") or inv:contains_item("main", "mcl_throwing:arrow")) then
		wielditem:set_name("mcl_throwing:bow_0")
		bow_load[name] = os.time()
	else
		if type(bow_load[name]) == "number" then
			if wielditem:get_name() == "mcl_throwing:bow_0" and os.time() - bow_load[name] > CHARGE_SPEED then
				wielditem:set_name("mcl_throwing:bow_1")
			elseif wielditem:get_name() == "mcl_throwing:bow_1" and os.time() - bow_load[name] > CHARGE_SPEED*2 then
				wielditem:set_name("mcl_throwing:bow_2")
			end
		else
			wielditem:set_name("mcl_throwing:bow")
		end
	end
	player:set_wielded_item(wielditem)
end)

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local wielditem = player:get_wielded_item()
		local controls = player:get_player_control()
		local inv = minetest.get_inventory({type="player", name = player:get_player_name()})
		if bow_load[player:get_player_name()] and (wielditem:get_name()~="mcl_throwing:bow_0" and wielditem:get_name()~="mcl_throwing:bow_1" and wielditem:get_name()~="mcl_throwing:bow_2") then
			local list = inv:get_list("main")
			for place, stack in pairs(list) do
				if stack:get_name()=="mcl_throwing:bow_0" or stack:get_name()=="mcl_throwing:bow_1" or stack:get_name()=="mcl_throwing:bow_2" then
					stack:set_name("mcl_throwing:bow")
					list[place] = stack
					break
				end
			end
			inv:set_list("main", list)
			bow_load[player:get_player_name()] = false
		end
	end
end)

if minetest.get_modpath("mcl_core") and minetest.get_modpath("mcl_mobitems") then
	minetest.register_craft({
		output = 'mcl_throwing:bow',
		recipe = {
			{'', 'mcl_core:stick', 'mcl_mobitems:string'},
			{'mcl_core:stick', '', 'mcl_mobitems:string'},
			{'', 'mcl_core:stick', 'mcl_mobitems:string'},
		}
	})
	minetest.register_craft({
		output = 'mcl_throwing:bow',
		recipe = {
			{'mcl_mobitems:string', 'mcl_core:stick', ''},
			{'mcl_mobitems:string', '', 'mcl_core:stick'},
			{'mcl_mobitems:string', 'mcl_core:stick', ''},
		}
	})
end

minetest.register_craft({
	type = "fuel",
	recipe = "mcl_throwing:bow",
	burntime = 15,
})

-- Add entry aliases for the Help
if minetest.get_modpath("doc") then
	doc.add_entry_alias("tools", "mcl_throwing:bow", "tools", "mcl_throwing:bow_0")
	doc.add_entry_alias("tools", "mcl_throwing:bow", "tools", "mcl_throwing:bow_1")
	doc.add_entry_alias("tools", "mcl_throwing:bow", "tools", "mcl_throwing:bow_2")
end

