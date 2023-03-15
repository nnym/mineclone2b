--License for code WTFPL and otherwise stated in readmes

local S = minetest.get_translator("mobs_mc")

local cow_def = {
	description = S("Cow"),
	type = "animal",
	spawn_class = "passive",
	passive = true,
	runaway = true,
	hp_min = 10,
	hp_max = 10,
	xp_min = 1,
	xp_max = 3,
	collisionbox = {-0.45, -0.01, -0.45, 0.45, 1.39, 0.45},
	spawn_in_group = 4,
	spawn_in_group_min = 2,
	visual = "mesh",
	mesh = "mobs_mc_cow.b3d",
	textures = {{
		"mobs_mc_cow.png",
		"blank.png",
	}},
	head_swivel = "head.control",
	bone_eye_height = 10,
	head_eye_height = 1.1,
	horrizonatal_head_height=-1.8,
	curiosity = 2,
	fear_height = 4,
	head_yaw="z",
	makes_footstep_sound = true,
	walk_velocity = 1,
	run_velocity = 3,
	follow_velocity = 3.4,
	follow = {"mcl_farming:wheat_item", "mcl_mobitems:carrot_on_a_stick"},
	view_range = 10,
	drops = {
		{name = "mcl_mobitems:beef",
		chance = 1,
		min = 1,
		max = 3,
		looting = "common"},
		{name = "mcl_mobitems:leather",
		chance = 1,
		min = 0,
		max = 2,
		looting = "common"}
	},
	sounds = {
		random = "mobs_mc_cow",
		damage = "mobs_mc_cow_hurt",
		death = "mobs_mc_cow_hurt",
		eat = "mobs_mc_animal_eat_generic",
		distance = 16,
	},
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40, walk_speed = 30,
		run_start = 0, run_end = 40, run_speed = 40,
	},
	child_animations = {
		stand_start = 41, stand_end = 41,
		walk_start = 41, walk_end = 81, walk_speed = 45,
		run_start = 41, run_end = 81, run_speed = 60,
	},
	do_custom = function(self, dtime)
		if not self.v3 then
			self.v3 = 0
			self.max_speed_forward = 4
			self.max_speed_reverse = 2
			self.accel = 4
			self.terrain_type = 3
			self.driver_attach_at = {x = 0.0, y = 9.5, z = -3.75}
			self.driver_eye_offset = {x = 0, y = 6, z = 0}
			self.driver_scale = {x = 1 / self.visual_size.x, y = 1 / self.visual_size.y}
			self.base_texture = self.texture_list[1]
			self.object:set_properties {textures = self.base_texture}
		end

		if self.driver then
			mcl_mobs.drive(self, "walk", "stand", false, dtime)
			return false
		end

		return true
	end,
	on_rightclick = function(self, clicker)
		local item = clicker:get_wielded_item()
		local itemName = item:get_name()

		if itemName ~= "mcl_mobitems:carrot_on_a_stick" and self:feed_tame(clicker, 1, true, false) or mcl_mobs.protect(self, clicker) or self.child then
			return
		elseif itemName == "mcl_buckets:bucket_empty" and clicker:get_inventory() then
			local inv = clicker:get_inventory()
			inv:remove_item("main", "mcl_buckets:bucket_empty")
			minetest.sound_play("mobs_mc_cow_milk", {pos = self.object:get_pos(), gain = 0.6})
			-- if room add bucket of milk to inventory, otherwise drop as item
			if inv:room_for_item("main", {name = "mcl_mobitems:milk_bucket"}) then
				clicker:get_inventory():add_item("main", "mcl_mobitems:milk_bucket")
			else
				local pos = self.object:get_pos()
				pos.y = pos.y + 0.5
				minetest.add_item(pos, {name = "mcl_mobitems:milk_bucket"})
			end

			return
		end

		if itemName == "mcl_mobitems:saddle" and not self.saddle then
			self.base_texture = {
				"mobs_mc_cow.png",
				"mobs_mc_pig_saddle.png"
			}
			self.object:set_properties {textures = self.base_texture}
			self.saddle = true
			self.tamed = true

			table.insert(self.drops, {
				name = "mcl_mobitems:saddle",
				chance = 1,
				min = 1,
				max = 1
			})

			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				local inv = clicker:get_inventory()
				local stack = inv:get_stack("main", clicker:get_wield_index())
				stack:take_item()
				inv:set_stack("main", clicker:get_wield_index(), stack)
			end

			return minetest.sound_play({name = "mcl_armor_equip_leather"}, {gain = 0.5, max_hear_distance = 8, pos = self.object:get_pos()}, true)
		end

		if self.moo then
			if itemName == "mcl_tools:shears" then
				local pos = self.object:get_pos()
				minetest.sound_play("mcl_tools_shears_cut", {pos = pos}, true)

				if self.base_texture[1] == "mobs_mc_mooshroom_brown.png" then
					minetest.add_item({x = pos.x, y = pos.y + 1.4, z = pos.z}, "mcl_mushrooms:mushroom_brown 5")
				else
					minetest.add_item({x = pos.x, y = pos.y + 1.4, z = pos.z}, "mcl_mushrooms:mushroom_red 5")
				end

				local oldyaw = self.object:get_yaw()
				self.object:remove()
				local cow = minetest.add_entity(pos, "mobs_mc:cow")
				cow:set_yaw(oldyaw)

				if not minetest.is_creative_enabled(clicker:get_player_name()) then
					item:add_wear(mobs_mc.shears_wear)
					clicker:get_inventory():set_stack("main", clicker:get_wield_index(), item)
				end

				return
			end

			if itemName == "mcl_core:bowl" and clicker:get_inventory() then
				local inv = clicker:get_inventory()
				inv:remove_item("main", "mcl_core:bowl")
				minetest.sound_play("mobs_mc_cow_mushroom_stew", {pos=self.object:get_pos(), gain=0.6})
				-- If room, add mushroom stew to inventory, otherwise drop as item
				if inv:room_for_item("main", {name = "mcl_mushrooms:mushroom_stew"}) then
					clicker:get_inventory():add_item("main", "mcl_mushrooms:mushroom_stew")
				else
					local pos = self.object:get_pos()
					pos.y = pos.y + 0.5
					minetest.add_item(pos, {name = "mcl_mushrooms:mushroom_stew"})
				end

				return
			end
		end

		if self.driver and clicker == self.driver then
			mcl_mobs.detach(clicker, {x = 1, y = 0, z = 0})
		elseif not self.driver and self.saddle and itemName == "mcl_mobitems:carrot_on_a_stick" then
			mcl_mobs.attach(self, clicker)

			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				local inv = self.driver:get_inventory()

				-- 26 uses
				if item:get_wear() > 63000 then
					-- Break carrot on a stick
					local def = item:get_definition()

					if def.sounds and def.sounds.breaks then
						minetest.sound_play(def.sounds.breaks, {pos = clicker:get_pos(), max_hear_distance = 8, gain = 0.5}, true)
					end

					item = {name = "mcl_fishing:fishing_rod", count = 1}
				else
					item:add_wear(2521)
				end

				inv:set_stack("main",self.driver:get_wield_index(), item)
			end
		elseif not self.driver and itemName ~= "" then
			mcl_mobs:capture_mob(self, clicker, 0, 5, 60, false, nil)
		end
	end,
	on_die = function(self, pos)
		if self.driver then
			mcl_mobs.detach(self.driver, {x = 1, y = 0, z = 1})
		end
	end,
	on_breed = function(parent1, parent2)
		local pos = parent1.object:get_pos()
		local child = mcl_mobs.spawn_child(pos, parent1.name)
		if child then
			local ent_c = child:get_luaentity()
			ent_c.tamed = true
			ent_c.owner = parent1.owner
			return false
		end
	end
}

mcl_mobs.register_mob("mobs_mc:cow", cow_def)
mcl_mobs.register_mob("mobs_mc:pig", cow_def)

local mooshroom_def = table.copy(cow_def)
mooshroom_def.description = S("Mooshroom")
mooshroom_def.spawn_in_group_min = 2
mooshroom_def.spawn_in_group = 4
mooshroom_def.textures = {{"mobs_mc_mooshroom.png", "mobs_mc_mushroom_red.png"}, {"mobs_mc_mooshroom_brown.png", "mobs_mc_mushroom_brown.png" }}
mooshroom_def.moo = true
mooshroom_def.on_lightning_strike = function(self, pos, pos2, objects)
	if self.base_texture[1] == "mobs_mc_mooshroom_brown.png" then
		self.base_texture = {"mobs_mc_mooshroom.png", "mobs_mc_mushroom_red.png"}
	else
		self.base_texture = {"mobs_mc_mooshroom_brown.png", "mobs_mc_mushroom_brown.png"}
	end

	self.object:set_properties {textures = self.base_texture}
	return true
end

mcl_mobs.register_mob("mobs_mc:mooshroom", mooshroom_def)

mcl_mobs:spawn_specific(
	"mobs_mc:cow",
	"overworld",
	"ground",
	{
		"flat",
		"MegaTaiga",
		"MegaSpruceTaiga",
		"ExtremeHills",
		"ExtremeHills_beach",
		"ExtremeHillsM",
		"ExtremeHills+",
		"StoneBeach",
		"Plains",
		"Plains_beach",
		"SunflowerPlains",
		"Taiga",
		"Taiga_beach",
		"Forest",
		"Forest_beach",
		"FlowerForest",
		"FlowerForest_beach",
		"BirchForest",
		"BirchForestM",
		"RoofedForest",
		"Savanna",
		"Savanna_beach",
		"SavannaM",
		"Jungle",
		"Jungle_shore",
		"JungleM",
		"JungleM_shore",
		"JungleEdge",
		"JungleEdgeM",
		"Swampland",
		"Swampland_shore"
	},
	9,
	minetest.LIGHT_MAX + 1,
	30,
	17000,
	10,
	mobs_mc.water_level,
	mcl_vars.mg_overworld_max
)

mcl_mobs:spawn_specific(
	"mobs_mc:mooshroom",
	"overworld",
	"ground",
	{
		"MushroomIslandShore",
		"MushroomIsland"
	},
	9,
	minetest.LIGHT_MAX + 1,
	30,
	17000,
	5,
	mcl_vars.mg_overworld_min,
	mcl_vars.mg_overworld_max
)

mcl_mobs.register_egg("mobs_mc:cow", S("Cow"), "#443626", "#a1a1a1", 0)
mcl_mobs.register_egg("mobs_mc:mooshroom", S("Mooshroom"), "#a00f10", "#b7b7b7", 0)
