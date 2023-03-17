local S = minetest.get_translator(minetest.get_current_modname())

local function inventory(height, y)
	local x = 0
	y = y or 4
	local w = mcl_vars.inventoryWidth

	return "size[" .. w .. "," .. (height or 8.75) .. "]"
		.. "container[" .. x ..  "," .. y .. "]"
		.. "label[0,0;" .. minetest.formspec_escape(minetest.colorize(mcl_vars.font_color, S("Inventory"))) .. "]"
		.. "list[current_player;main;0," .. 0.5 .. ";" .. w .. ",3;" .. w .. "]"
		.. mcl_formspec.get_itemslot_bg(0, 0.5, w, 3)
		.. "list[current_player;main;0," .. 3.75 .. ";" .. w .. ",1;]"
		.. mcl_formspec.get_itemslot_bg(0, 3.75, w, 1)
		.. "listring[current_player;main]"
		.. "container_end[]"
end

local function withInventory(variables, formspec)
	local y, height, width = unpack(variables)
	formspec = type(formspec) == "table" and join(formspec) or formspec

	if width then
		formspec = "container[" .. (mcl_vars.inventoryWidth - width) / 2 .. ",0]"
		.. formspec
		.. "container_end[]"
	end

	return inventory(height, y) .. formspec
end

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
	withInventory = function(width, height, y, formspec)
		local variables = {y, height, width}

		for index, value in pairs(variables) do
			if not formspec and ("(string)(table)"):find(type(value)) then
				formspec, variables[index] = value
			end

			if formspec then return withInventory(variables, formspec) end
			if value then break end
		end

		return function(formspec)
			return withInventory(variables, formspec)
		end
	end
}
