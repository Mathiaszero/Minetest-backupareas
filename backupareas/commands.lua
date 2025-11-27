local S = core.get_translator("backupareas")

core.register_chatcommand("sa", {
	description = S("Save areas."),
	privs = {server = true,},
	func = function(name, param)
		--create folder to store areas as text files
		local schema_dir = core.get_worldpath().."/schema/"
		--cleanup directory to delete areas that no longer exist
		core.rmdir(schema_dir, true)
		--recreate directory
		core.mkdir(schema_dir)
		--get list of areas in areas mod data file
		local ad_path = core.get_worldpath().."/areas.dat" 
		--open areas dat file
		local ad_file, err = io.open(ad_path, "r")
		--read all text in areas dat file
		local ad_data = ad_file:read("*all")
		--text in areas dat file can be parsed to json
		local ad_json = core.parse_json(ad_data)
		--no areas shows as "null" in areas dat file, so catch it
		if ad_json == nil then
			core.chat_send_player(name, "Error, no areas to save.")
			ad_file:close()
			return
		end
		--loop through each areas dat entry to get area bounds pos1 and pos2
		for i, v in ipairs(ad_json) do
			--get pos1 coordinates
			local p1x , p1y, p1z = v["pos1"]["x"], v["pos1"]["y"], v["pos1"]["z"]
			--get pos2 coordinates
			local p2x , p2y, p2z = v["pos2"]["x"], v["pos2"]["y"], v["pos2"]["z"]
			--format coordinates as list for schema file name
			local schema_suffix = string.format(
				"%s,%s,%s,%s,%s,%s,.txt",
				p1x,p1y,p1z,p2x,p2y,p2z
			)
			--create empty schema file with suffix name
			local schema_file, err = io.open(schema_dir..schema_suffix, "w")
			--close schema file for use later
			schema_file:close()
		end
		--close areas dat file since all schema files are created
		ad_file:close()
		--get list of files in schema folder
		local dir_list = core.get_dir_list(schema_dir, false)
		--loop through each schema file name
		for i, file in ipairs(dir_list) do
			--split the schema file name based on ","
			local fns = string.split(file, ",")
			--first 3 are pos1 coordinates
			local p1x, p1y, p1z = fns[1], fns[2], fns[3]
			--last 3 are pos2 coordinates
			local p2x, p2y, p2z = fns[4], fns[5], fns[6]
			--determine min coordinates to loop through area nodes
			local xmin, ymin, zmin = math.min(p1x, p2x), math.min(p1y, p2y), math.min(p1z, p2z)
			--determine max coordinates to loop through area nodes
			local xmax, ymax, zmax = math.max(p1x, p2x), math.max(p1y, p2y), math.max(p1z, p2z)
			--create list for adding each node in area
			local area_nodes = {}
			--loop through each node within area bounds
			for x = xmin, xmax do
				for y = ymin, ymax do
					for z = zmin, zmax do
						--insert each node position into area nodes list
						table.insert(area_nodes, {x, y, z})
					end
				end
			end
			--loop through each node in area nodes list
			for i, v in ipairs(area_nodes) do
				--open file to append node data
				local schema_file, err = io.open(schema_dir..file, "a")
				--create list to hold node data
				local node = {}
				--get node coordinates from a node in area nodes list
				local x, y, z = v[1], v[2], v[3]
				--insert each coordinate into node data list
				table.insert(node, x)
				table.insert(node, y)
				table.insert(node, z)
				--combine coordinates into vector position
				local pos = vector.new(x, y, z)
				--get node name, lighting and orientation data
				local node_table = core.get_node(pos)
				--insert data into node data list
				table.insert(node, node_table.name)
				table.insert(node, node_table.param1)
				table.insert(node, node_table.param2)
				--get node metadata
				local node_meta = core.get_meta(pos)
				--get node inventory metadata
				local inv = node_meta:get_inventory()
				--get inventory types
				for list, items in pairs(inv:get_lists()) do
					--for each inventory type, loop through slots
					for i, itemstack in ipairs(items) do
						--if slot empty, insert placeholder, b/c data organized as [list] [name] [count]
						if itemstack:is_empty() then
							table.insert(node, "0 0 0")
						else
							table.insert(node, list.." "..itemstack:get_name().." "..itemstack:get_count())
						end
					end
				end		
				--write node data as comma separated line in schema file
				schema_file:write(table.concat(node, ",").."\n")
				--close schema file after writing in all data for that node
				schema_file:close()
			end
		end
	end,
})

core.register_chatcommand("la", {
	description = S("Load areas."),
	privs = {server = true,},
	func = function(name, param)
		local schema_dir = core.get_worldpath().."/schema/"
		local dir_list = core.get_dir_list(schema_dir, false)
		for i, file in ipairs(dir_list) do
			local schema_file, err = io.open(schema_dir..file, "r")
			for line in schema_file:lines() do
				local node_list = string.split(line, ",")
				local x, y, z = node_list[1], node_list[2], node_list[3]
				local pos = vector.new(x, y, z)
				local node_table = {name = node_list[4], param1 = node_list[5], param2 = node_list[6]}
				core.set_node(pos, node_table)
				local node_meta = core.get_meta(pos)
				local inv = node_meta:get_inventory(pos)
				for i = 7, #node_list do
					local item_data = string.split(node_list[i], " ")
					local list_name, item_name, item_count = item_data[1], item_data[2], item_data[3]
					inv:add_item(list_name, item_name.." "..item_count)
				end
			end
			schema_file:close()
		end
	end,
})
