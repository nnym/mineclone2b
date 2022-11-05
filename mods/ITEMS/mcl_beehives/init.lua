------------------
---- Beehives ----
------------------

-- Variables
local S = minetest.get_translator(minetest.get_current_modname())

-- Beehive
minetest.register_node("mcl_beehives:beehive", {
	description = S("Beehive"),
	_doc_items_longdesc = S("Artificial bee nest."),
	tiles = {
		"mcl_beehives_beehive_end.png", "mcl_beehives_beehive_end.png",
		"mcl_beehives_beehive_side.png", "mcl_beehives_beehive_side.png",
		"mcl_beehives_beehive_side.png", "mcl_beehives_beehive_front.png",
	},
	paramtype2 = "facedir",
	groups = { axey = 1, deco_block = 1, flammable = 0, fire_flammability = 5, material_wood = 1 },
	_mcl_blast_resistance = 0.6,
	_mcl_hardness = 0.6,
})

-- Bee Nest
minetest.register_node("mcl_beehives:bee_nest", {
	description = S("Bee Nest"),
	_doc_items_longdesc = S("A naturally generating block that houses bees and a tasty treat...if you can get it."),
	tiles = {
		"mcl_beehives_bee_nest_top.png", "mcl_beehives_bee_nest_bottom.png",
		"mcl_beehives_bee_nest_side.png", "mcl_beehives_bee_nest_side.png",
		"mcl_beehives_bee_nest_side.png", "mcl_beehives_bee_nest_front.png",
	},
	paramtype2 = "facedir",
	groups = { axey = 1, deco_block = 1, flammable = 0, fire_flammability = 30 },
	_mcl_blast_resistance = 0.3,
	_mcl_hardness = 0.3,
})

-- Crafting
minetest.register_craft({
	output = "mcl_beehives:beehive",
	recipe = {
		{ "group:wood", "group:wood", "group:wood" },
		{ "mcl_honey:honeycomb", "mcl_honey:honeycomb", "mcl_honey:honeycomb" },
		{ "group:wood", "group:wood", "group:wood" },
	},
})

