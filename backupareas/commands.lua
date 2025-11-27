local S = core.get_translator("backupareas")

core.register_chatcommand("sa", {
	description = S("Save areas."),
	func = function(name, param)

		--create dir to store areas
		local schema_dir = core.get_worldpath().."/schema/"
		core.rmdir(schema_dir, true)
		core.mkdir(schema_dir)

		--get list of areas
		local ad_path = core.get_worldpath().."/areas.dat" 
		local ad_file, err = io.open(ad_path, "r")
		local ad_data = ad_file:read("*all")
		local ad_json = core.parse_json(ad_data)

		if ad_json == nil then
			core.chat_send_player(name, "Error, no areas to save.")
			ad_file:close()
			return
		end

		--save file for each area
		for i, v in ipairs(ad_json) do

			local p1x = v["pos1"]["x"]
			local p1y = v["pos1"]["y"]
			local p1z = v["pos1"]["z"]
			local p2x = v["pos2"]["x"]
			local p2y = v["pos2"]["y"]
			local p2z = v["pos2"]["z"]

			local schema_suffix = string.format(
				"%s,%s,%s,%s,%s,%s,.txt",
				p1x,p1y,p1z,p2x,p2y,p2z
			)

			local schema_file, err = io.open(schema_dir..schema_suffix, "w")
			schema_file:close()
		end
		ad_file:close()

		--read each file name in folder

		local dir_list = core.get_dir_list(schema_dir, false)
		
		for i, file in ipairs(dir_list) do
			local fns = string.split(file, ",")
			local p1x = fns[1]
			local p1y = fns[2]
			local p1z = fns[3]
			local p2x = fns[4]
			local p2y = fns[5]
			local p2z = fns[6]

			local xmin = math.min(p1x, p2x)
			local ymin = math.min(p1y, p2y)
			local zmin = math.min(p1z, p2z)
			local xmax = math.max(p1x, p2x)
			local ymax = math.max(p1y, p2y)
			local zmax = math.max(p1z, p2z)

			local area_nodes = {}
			for x = xmin, xmax do
				for y = ymin, ymax do
					for z = zmin, zmax do
						table.insert(area_nodes, {x, y, z})
					end
				end
			end

			for i, v in ipairs(area_nodes) do
				--core.chat_send_player(name, dump(v))
				local schema_file, err = io.open(schema_dir..file, "a")

				local node = {}
				local x = v[1]
				local y = v[2]
				local z = v[3]
				table.insert(node, x)
				table.insert(node, y)
				table.insert(node, z)
				local pos = vector.new(x, y, z)

				local node_table = core.get_node(pos)
				table.insert(node, node_table.name)
				table.insert(node, node_table.param1)
				table.insert(node, node_table.param2)

				local node_meta = core.get_meta(pos)
				local inv = node_meta:get_inventory()
				--i: list name; v: list contents
				for list, items in pairs(inv:get_lists()) do
					--core.chat_send_player(name, v)
					for i, itemstack in ipairs(items) do
						--core.chat_send_player(name, list..":"..i..":"..itemstack:get_name().." "..itemstack:get_count())
						if itemstack:is_empty() then
							--core.chat_send_player(name, "Empty slot, skipping.")
							table.insert(node, "0 0 0")
						else
							table.insert(node, list.." "..itemstack:get_name().." "..itemstack:get_count())
						end
					end
				end		
				schema_file:write(table.concat(node, ",").."\n")
				schema_file:close()
			end
		end
	end,
})

core.register_chatcommand("la", {
	description = S("Load areas."),
	func = function(name, param)
		local schema_dir = core.get_worldpath().."/schema/"
		local dir_list = core.get_dir_list(schema_dir, false)
		for i, file in ipairs(dir_list) do
			--core.chat_send_player(name, file)
			
			local schema_file, err = io.open(schema_dir..file, "r")
			for line in schema_file:lines() do
    			--core.chat_send_player(name, line)

				local node_list = string.split(line, ",")

				local x = node_list[1]
				local y = node_list[2]
				local z = node_list[3]
				local pos = vector.new(x, y, z)

				local node_table = {
					name = node_list[4],
					param1 = node_list[5],
					param2 = node_list[6]
				}

				core.set_node(pos, node_table)
				local node_meta = core.get_meta(pos)
				local inv = node_meta:get_inventory(pos)

				for i = 7, #node_list do
					local item_data = string.split(node_list[i], " ")
					local list_name = item_data[1]
					local item_name = item_data[2]
					local item_count = item_data[3]
					inv:add_item(list_name, item_name.." "..item_count)
				end
			end
		end
	end,
})