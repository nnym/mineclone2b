local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)
local modpath = minetest.get_modpath(modname)
local peaceful = minetest.settings:get_bool("only_peaceful_mobs", false)

local spawnon = {"mcl_core:stripped_oak"}

mcl_structures.register_structure("pillager_outpost",{
	place_on = {"group:grass_block","group:dirt","mcl_core:dirt_with_grass","group:sand"},
	fill_ratio = 0.01,
	flags = "place_center_x, place_center_z",
	solid_ground = true,
	make_foundation = true,
	sidelen = 23,
	y_offset = 0,
	chunk_probability = 600,
	y_max = mcl_vars.mg_overworld_max,
	y_min = 1,
	biomes = { "Desert", "Plains", "Savanna", "IcePlains", "Taiga" },
	filenames = { modpath.."/schematics/mcl_structures_pillager_outpost.mts" },
	loot = {
		["mcl_chests:chest_small" ] ={
		{
			stacks_min = 2,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_farming:wheat_item", weight = 7, amount_min = 3, amount_max=5 },
				{ itemstring = "mcl_farming:carrot_item", weight = 5, amount_min = 3, amount_max=5 },
				{ itemstring = "mcl_farming:potato_item", weight = 5, amount_min = 2, amount_max=5 },
			}
		},
		{
			stacks_min = 1,
			stacks_max = 2,
			items = {
				{ itemstring = "mcl_experience:bottle", weight = 6, amount_min = 0, amount_max=1 },
				{ itemstring = "mcl_bows:arrow", weight = 4, amount_min = 2, amount_max=7 },
				{ itemstring = "mcl_mobitems:string", weight = 4, amount_min = 1, amount_max=6 },
				{ itemstring = "mcl_core:iron_ingot", weight = 3, amount_min = 1, amount_max = 3 },
				{ itemstring = "mcl_books:book", weight = 1, func = function(stack, pr)
					mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr)
				end },
			}
		},
		{
			stacks_min = 1,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_core:darktree", amount_min = 2, amount_max=3 },
			}
		},
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_bows:crossbow" },
			}
		}}
	},
	after_place = function(p,def,pr)
		local p1 = vector.offset(p,-7,0,-7)
		local p2 = vector.offset(p,7,14,7)
		mcl_structures.spawn_mobs("mobs_mc:pillager",spawnon,p1,p2,pr,5)
		mcl_structures.spawn_mobs("mobs_mc:evoker",spawnon,p1,p2,pr,1)
	end
})

mcl_structures.register_structure_spawn({
	name = "mobs_mc:pillager",
	y_min = mcl_vars.mg_overworld_min,
	y_max = mcl_vars.mg_overworld_max,
	chance = 10,
	interval = 60,
	limit = 9,
	spawnon = spawnon,
})

mcl_structures.register_structure_spawn({
	name = "mobs_mc:evoker",
	y_min = mcl_vars.mg_overworld_min,
	y_max = mcl_vars.mg_overworld_max,
	chance = 100,
	interval = 60,
	limit = 4,
	spawnon = spawnon,
})
