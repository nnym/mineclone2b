local S = minetest.get_translator(minetest.get_current_modname())

mcl_formspec = {
	get_itemslot_bg = function(x, y, w, h)
		local out = ""
		for i = 0, w - 1, 1 do
			for j = 0, h - 1, 1 do
				out = out .. "image[" .. x + i .. "," .. y + j .. ";1,1;mcl_formspec_itemslot.png]"
			end
		end
		return out
	end,

	player = function(height, y, x)
		x = x or 0
		y = y or 4
		local w = mcl_vars.inventory_width

		return "size[" .. w .. "," .. (height or 8.75) .. "]"
			.. "label[" .. x .. "," .. y .. ";" .. minetest.formspec_escape(minetest.colorize(mcl_vars.font_color, S("Inventory"))) .. "]"
			.. "list[current_player;main;" .. x .. "," .. y + 0.5 .. ";" .. w .. ",3;" .. w .. "]"
			.. mcl_formspec.get_itemslot_bg(x, y + 0.5, w, 3)
			.. "list[current_player;main;" .. x .. "," .. y + 3.75 .. ";" .. w .. ",1;]"
			.. mcl_formspec.get_itemslot_bg(x, y + 3.75, w, 1)
			.. "listring[current_player;main]"
	end
}
