local S = minetest.get_translator(minetest.get_current_modname())

local on_place = mcl_util.generate_on_place_plant_function(function(place_pos, place_node)
	local soil_node = minetest.get_node_or_nil({x=place_pos.x, y=place_pos.y-1, z=place_pos.z})
	if not soil_node then return false end
	local snn = soil_node.name -- soil node name

	-- Placement rules:
	-- * Always allowed on podzol or mycelimu
	-- * Otherwise, must be solid, opaque and have daylight light level <= 12
	local light = minetest.get_node_light(place_pos, 0.5)
	local light_ok = false
	if light and light <= 12 then
		light_ok = true
	end
	return ((snn == "mcl_core:podzol" or snn == "mcl_core:podzol_snow" or snn == "mcl_core:mycelium" or snn == "mcl_core:mycelium_snow") or (light_ok and minetest.get_item_group(snn, "solid") == 1 and minetest.get_item_group(snn, "opaque") == 1))
end)

local longdesc_intro_brown = S("Brown mushrooms are fungi which grow and spread in darkness, but are sensitive to light. They are inedible as such, but they can be used to craft food items.")
local longdesc_intro_red = S("Red mushrooms are fungi which grow and spread in darkness, but are sensitive to light. They are inedible as such, but they can be used to craft food items.")

local longdesc_append = S("A single mushroom of this species will slowly spread over time towards a random solid opaque block with a light level of 12 or lower in a 3×3×3 cube around the mushroom. It stops spreading when there are 5 or more mushrooms of the same species within an area of 9×3×9 blocks around the mushroom.").."\n"..
S("Mushrooms will eventually uproot at a light level of 12 or higher. On mycelium or podzol, they survive and spread at any light level.")

local tt_help = S("Grows on podzol, mycelium and other blocks").."\n"..S("Spreads in darkness")

local usagehelp = S("This mushroom can be placed on mycelium and podzol at any light level. It can also be placed on blocks which are both solid and opaque, as long as the light level at daytime is not higher than 12.")

minetest.register_node("mcl_mushrooms:mushroom_brown", {
	description = S("Brown Mushroom"),
	_doc_items_longdesc = longdesc_intro_brown .. "\n\n" .. longdesc_append,
	_doc_items_usagehelp = usagehelp,
	_tt_help = tt_help,
	drawtype = "plantlike",
	tiles = { "farming_mushroom_brown.png" },
	inventory_image = "farming_mushroom_brown.png",
	wield_image = "farming_mushroom_brown.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	groups = {
		attached_node = 1, deco_block = 1, destroy_by_lava_flow = 1,
		dig_immediate = 3, dig_by_water = 1, dig_by_piston = 1,
		mushroom = 1, enderman_takable = 1, compostability = 65
	},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	light_source = 1,
	selection_box = {
		type = "fixed",
		fixed = { -3/16, -0.5, -3/16, 3/16, -2/16, 3/16 },
	},
	node_placement_prediction = "",
	on_place = on_place,
	_mcl_blast_resistance = 0,
})

minetest.register_node("mcl_mushrooms:mushroom_red", {
	description = S("Red Mushroom"),
	_doc_items_longdesc = longdesc_intro_red .. "\n\n" .. longdesc_append,
	_doc_items_usagehelp = usagehelp,
	_tt_help = tt_help,
	drawtype = "plantlike",
	tiles = { "farming_mushroom_red.png" },
	inventory_image = "farming_mushroom_red.png",
	wield_image = "farming_mushroom_red.png",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	groups = {
		attached_node = 1, deco_block = 1, destroy_by_lava_flow = 1,
		dig_immediate = 3, dig_by_water = 1, dig_by_piston = 1,
		mushroom = 1, enderman_takable = 1, compostability = 65
	},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = { -3/16, -0.5, -3/16, 3/16, -2/16, 3/16 },
	},
	node_placement_prediction = "",
	on_place = on_place,
	_mcl_blast_resistance = 0,
})

local eatStew = function(stack, eater, target)
	local bowl = "mcl_core:bowl"
	local count = stack:get_count()
	local name = stack:get_name()
	local leftover = minetest.do_item_eat(6, bowl, stack, eater, target)
	local finished = leftover:get_name() == bowl
	local inventory = eater:get_inventory()

	if leftover:get_count() ~= count or finished and inventory:contains_item("main", bowl) then
		minetest.add_item(eater:get_pos(), inventory:add_item("main", bowl))

		if finished then return {} end
	end

	return leftover
end

minetest.register_craftitem("mcl_mushrooms:mushroom_stew", {
	description = S("Mushroom Stew"),
	_doc_items_longdesc = S("Mushroom stew is a healthy soup which can be consumed to restore some hunger points."),
	inventory_image = "farming_mushroom_stew.png",
	on_place = eatStew,
	on_secondary_use = eatStew,
	groups = {food = 3, eatable = 6},
	_mcl_saturation = 7.2,
	stack_max = mcl_vars.stack_max,
})

minetest.register_craft({
	type = "shapeless",
	output = "mcl_mushrooms:mushroom_stew",
	recipe = {"mcl_core:bowl", "mcl_mushrooms:mushroom_brown", "mcl_mushrooms:mushroom_red"}
})

--[[ Mushroom spread and death
Code based on information gathered from Minecraft Wiki
<http://minecraft.gamepedia.com/Tutorials/Mushroom_farming#Videos>
]]
minetest.register_abm({
	label = "Mushroom spread and death",
	nodenames = {"mcl_mushrooms:mushroom_brown", "mcl_mushrooms:mushroom_red"},
	interval = 11,
	chance = 50,
	action = function(pos, node)
		local node_soil = minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name
		-- Mushrooms uproot in light except on podzol or mycelium
		if node_soil ~= "mcl_core:podzol" and node_soil ~= "mcl_core:mycelium" and
				node_soil ~= "mcl_core:podzol_snow" and node_soil ~= "mcl_core:mycelium_snow" and minetest.get_node_light(pos, nil) > 12 then
			minetest.dig_node(pos)
			return
		end

		local pos0 = vector.add(pos, {x=-4, y=-1, z=-4})
		local pos1 = vector.add(pos, {x=4, y=1, z=4})

		-- Stop mushroom spread if a 9×3×9 box is too crowded
		if #minetest.find_nodes_in_area(pos0, pos1, node.name) >= 5 then
			return
		end

		local selected_pos = table.copy(pos)

		-- Do two random selections which may place the new mushroom in a 5×5×5 cube
		local random = {
			x = selected_pos.x + math.random(-1, 1),
			y = selected_pos.y + math.random(0, 1) - math.random(0, 1),
			z = selected_pos.z + math.random(-1, 1)
		}
		local random_node = minetest.get_node_or_nil(random)
		if not random_node or random_node.name ~= "air" then
			return
		end
		local node_under = minetest.get_node_or_nil({x = random.x, y = random.y - 1, z = random.z})
		if not node_under then
			return
		end

		if minetest.get_node_light(random, 0.5) > 12 or (minetest.get_item_group(node_under.name, "opaque") == 0) then
			return
		end
		local random2 = {
			x = random.x + math.random(-1, 1),
			y = random.y,
			z = random.z + math.random(-1, 1)
		}
		random_node = minetest.get_node_or_nil(random2)
		if not random_node or random_node.name ~= "air" then
			return
		end
		node_under = minetest.get_node_or_nil({x = random2.x, y = random2.y - 1, z = random2.z})
		if not node_under then
			return
		end
		if minetest.get_node_light(random2, 0.5) > 12 or (minetest.get_item_group(node_under.name, "opaque") == 0) or (minetest.get_item_group(node_under.name, "solid") == 0) then
			return
		end

		minetest.set_node(random2, {name = node.name})
	end
})
