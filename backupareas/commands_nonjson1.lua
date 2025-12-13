local S = core.get_translator("backupareas")

local dd = "||"
local d = "|"

local function save_node(player, schema_file, x, y, z)
	--open file to append node data (lags b/c each node)
	--local schema_file, err = io.open(schema_dir..file, "a")
	
	--create list to hold node data
	local node = {}
	--insert each coordinate into node data list
	table.insert(node, string.format("x%s%s", d, x))
	table.insert(node, string.format("y%s%s", d, y))
	table.insert(node, string.format("z%s%s", d, z))
	--combine coordinates into vector position
	local pos = vector.new(x, y, z)
	--get node name, lighting and orientation data
	local node_base = core.get_node(pos)
	--insert data into node data list
	table.insert(node, string.format("name%s%s", d, node_base.name))
	table.insert(node, string.format("param1%s%s", d, node_base.param1))
	table.insert(node, string.format("param2%s%s", d, node_base.param2))
	--get node metadata
	local node_meta = core.get_meta(pos)
	local node_meta_keys = node_meta:get_keys()

	for i, v in ipairs(node_meta_keys) do
		--core.chat_send_player(name, v)
		--remove \n in string value
		local sub = string.gsub(node_meta:get(v), "\n", " ")
		table.insert(node, string.format("%s%s%s%s%s", "nodemeta", d, v, d, sub))
	end

	-- --get node inventory metadata
	-- local inv = node_meta:get_inventory()
	-- --get inventory types
	-- for list, items in pairs(inv:get_lists()) do
	-- 	--for each inventory type, loop through slots
	-- 	for i, itemstack in ipairs(items) do
	-- 		--if slot empty, insert placeholder, b/c data organized as [list] [name] [count]
	-- 		if itemstack:is_empty() then
	-- 			table.insert(node, "0 0 0 0 0")
	-- 		else
	-- 			local itemstack_meta = itemstack:get_meta()
	-- 			local itemstack_meta_keys = itemstack_meta:get_keys()
	-- 			--local book_body = {}
	-- 			local book_body = ""
	-- 			for i, v in ipairs(itemstack_meta_keys) do
	-- 				-- if i == #itemstack_meta_keys then
	-- 				-- 	table.insert(book_body, v)
	-- 				-- end
	-- 				--book_body = book_body..v
	-- 			end

	-- 			table.insert(
	-- 				node, 
	-- 				list.." "..
	-- 				itemstack:get_name().." "..
	-- 				itemstack:get_count()
	-- 				--"_"..itemstack_meta:get_string("description").."|"..
	-- 				--"_"..itemstack_meta:get_string("text")
	-- 			)
	-- 		end
	-- 	end
	-- end

	--write node data as comma separated line in schema file
	schema_file:write(table.concat(node, dd).."\n")
	
	--close schema file after writing in all data for that node 
	--schema_file:close()
end

core.register_chatcommand("sa", {
	description = S("Save areas."),
	privs = {server = true,},
	func = function(player, param)
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
			--loop through each node within area bounds
			local schema_file, err = io.open(schema_dir..file, "a")
			for x = xmin, xmax do
				for y = ymin, ymax do
					for z = zmin, zmax do
						--monitor(i, #dir_list, x, y, z, xmax, ymax, zmax)
						--save_node(schema_dir, file, x, y, z)
						save_node(player, schema_file, x, y, z)
					end
				end
			end	
			schema_file:close()
		end
	end,
})

core.register_chatcommand("la", {
	description = S("Load areas."),
	privs = {server = true,},
	func = function(player, param)
		--get schema folder path
		local schema_dir = core.get_worldpath().."/schema/"
		--get list of files in schema folder
		local dir_list = core.get_dir_list(schema_dir, false)
		--loop through each schema file
		for i, file in ipairs(dir_list) do
			--open schema file to read node data
			local schema_file, err = io.open(schema_dir..file, "r")
			--loop through each node data which is a line in schema file
			for line in schema_file:lines() do
				--split data of the node by ","
				local node_cat = string.split(line, dd)
				for i, subcat in ipairs(node_cat) do
					--core.chat_send_player(name, subcat)
					local kv = string.split(subcat, d)
					--core.chat_send_player(name, kv[1]) -- x, y, z, name, etc. as each new line
					if kv[1] == "x" then
						x = kv[2]
					end
					if kv[1] == "y" then
						y = kv[2]
					end
					if kv[1] == "z" then
						z = kv[2]
					end
					if kv[1] == "name" then
						name = kv[2]
					end
					if kv[1] == "param1" then
						param1 = kv[2]
					end
					if kv[1] == "param2" then
						param2 = kv[2]
					end
					if x and y and z then
						pos = vector.new(x, y, z)
					end
					if name and param1 and param2 then
						node_base = {name = name, param1 = param1, param2 = param2}
					end
					if pos and node_base then
						core.set_node(pos, node_base)
						if node_base.name == "default:sign_wall_wood" then
							--ran over 7 times! should be ran only once assuming one sign in all areas
							--prob why text on sign did not save b/c it set node after setting text
							core.chat_send_player(player, "OOG")
						end
						-- local voxel = core.get_node(pos)
						local voxel_meta = core.get_meta(pos)
						
						if kv[1] == "nodemeta" then
							--core.chat_send_player(player, "OOG")
							
							--voxel_meta:set_string(tostring(kv[2]), tostring(kv[3]))
							--core.chat_send_player(player, kv[2]..","..kv[3].." set at pos "..dump(pos))
						end

						-- --to make sure node meta has both key and value
						-- if kv[1] and kv[2] and kv[3] and kv[1] == "nodemeta" then
						-- 	voxel_meta:set_string(kv[2], kv[3])
						-- end

					end
					-- local voxel_meta = core.get_meta(pos)
					-- --to make sure node meta has both key and value
					-- if kv[1] and kv[2] and kv[3] and kv[3] == "nodemeta" then
					-- 	voxel_meta:set_string(kv[2], kv[3])
					-- end
				end
				
				-- for i, subcat in ipairs(node_cat) do
				-- 	core.chat_send_player(name, subcat) --shows e.g. x|30
				-- 	--core.chat_send_player(name, subcat)
				-- 	local kv = string.split(subcat, d)

				-- 	for i, v in ipairs(kv) do
				-- 		core.chat_send_player(name, v)
				-- 	end

				-- 	if kv[1] == "x" then
				-- 		--core.chat_send_player(name, "OOG")
				-- 		x = kv[2]
				-- 	elseif kv[1] == "y" then
				-- 		y = kv[2]
				-- 	elseif kv[1] == "z" then
				-- 		z = kv[2]
				-- 	elseif kv[1] == "name" then
				-- 		name = kv[2]
				-- 	elseif kv[1] == "param1" then
				-- 		param1 = kv[2]
				-- 	elseif kv[1] == "param2" then
				-- 		param2 = kv[2]
				-- 	end
					
					--core.chat_send_player(name, kv[1])

					--core.chat_send_player(name, string.format("%s,%s,%s", x, y, z))
					
					--local pos = vector.new(tonumber(x), tonumber(y), tonumber(z))
					
					--local node_base = {name = name, param1 = param1, param2 = param2}
					--core.set_node(pos, node_base)


				-- --extract node position coordinates
				-- local x, y, z = node_list[1], node_list[2], node_list[3]
				-- --create position vector
				-- local pos = vector.new(x, y, z)
				-- --create node table with name, lighting and orientation data
				-- local node_table = {name = node_list[4], param1 = node_list[5], param2 = node_list[6]}
				-- --set node into world at position with node table data
				-- core.set_node(pos, node_table)
				-- --get node metadata from position
				-- local node_meta = core.get_meta(pos)

				-- --[7]
				-- if node_table.name == "default:chest_locked" then
				-- 	node_meta:set_string("owner", node_list[7])
				-- 	node_meta:set_string("infotext", node_list[7])
				-- elseif node_table.name == "default:sign_wall_wood" then
				-- 	node_meta:set_string("text", node_list[7])
				-- 	node_meta:set_string("infotext", node_list[7])
				-- end
				
				-- --get node inventory metadata from position
				-- local inv = node_meta:get_inventory(pos)
				-- --loop through remaining data in node list for inventory items
				-- for i = 8, #node_list do
				-- 	--split each inventory slot into list name, item name and item count
				-- 	local item_data = string.split(node_list[i], " ")
				-- 	--set each element into variables
				-- 	local list_name, item_name, item_count = item_data[1], item_data[2], item_data[3]
				-- 	--add item into each node inventory slot
				-- 	inv:add_item(list_name, item_name.." "..item_count)
					
				--end
			end
			--close schema file after all nodes and their data are set in world
			schema_file:close()
		end
	end,
})

--[[
--random hex separator instead of commas, so sign/book text can be added
local divider = "|2ef9c|"

local function monitor(i, total, x, y, z, xmax, ymax, zmax)
	local monitor_file, err = io.open(core.get_worldpath().."/monitor.txt", "w")
	monitor_file:write(i.."/"..total..": "..x..","..y..","..z.."/"..xmax..","..ymax..","..zmax)
	monitor_file:close()
end

local function save_node(name, schema_file, x, y, z)
	--open file to append node data (lags b/c each node)
	--local schema_file, err = io.open(schema_dir..file, "a")
	
	--create list to hold node data
	local node = {}
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
	local node_meta_keys = node_meta:get_keys()

	if #node_meta_keys > 0 then
		--core.chat_send_player(name, dump(node_meta_keys))
	end

	--[7]
	if node_table.name == "default:chest_locked" then
		table.insert(node, node_meta:get_string("owner"))
	elseif node_table.name == "default:sign_wall_wood" then
		table.insert(node, node_meta:get_string("text"))
	end

	--get node inventory metadata
	local inv = node_meta:get_inventory()
	--get inventory types
	for list, items in pairs(inv:get_lists()) do
		--for each inventory type, loop through slots
		for i, itemstack in ipairs(items) do
			--if slot empty, insert placeholder, b/c data organized as [list] [name] [count]
			if itemstack:is_empty() then
				table.insert(node, "0 0 0 0 0")
			else
				local itemstack_meta = itemstack:get_meta()
				local itemstack_meta_keys = itemstack_meta:get_keys()
				--local book_body = {}
				local book_body = ""
				for i, v in ipairs(itemstack_meta_keys) do
					-- if i == #itemstack_meta_keys then
					-- 	table.insert(book_body, v)
					-- end
					--book_body = book_body..v
				end

				table.insert(
					node, 
					list.." "..
					itemstack:get_name().." "..
					itemstack:get_count()
					--"_"..itemstack_meta:get_string("description").."|"..
					--"_"..itemstack_meta:get_string("text")
				)
			end
		end
	end
	--write node data as comma separated line in schema file
	schema_file:write(table.concat(node, divider).."\n")
	
	--close schema file after writing in all data for that node 
	--schema_file:close()
end

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
			--loop through each node within area bounds
			local schema_file, err = io.open(schema_dir..file, "a")
			for x = xmin, xmax do
				for y = ymin, ymax do
					for z = zmin, zmax do
						--monitor(i, #dir_list, x, y, z, xmax, ymax, zmax)
						--save_node(schema_dir, file, x, y, z)
						save_node(name, schema_file, x, y, z)
					end
				end
			end	
			schema_file:close()
		end
	end,
})

core.register_chatcommand("la", {
	description = S("Load areas."),
	privs = {server = true,},
	func = function(name, param)
		--get schema folder path
		local schema_dir = core.get_worldpath().."/schema/"
		--get list of files in schema folder
		local dir_list = core.get_dir_list(schema_dir, false)
		--loop through each schema file
		for i, file in ipairs(dir_list) do
			--open schema file to read node data
			local schema_file, err = io.open(schema_dir..file, "r")
			--loop through each node data which is a line in schema file
			for line in schema_file:lines() do
				--split data of the node by ","
				local node_list = string.split(line, divider)
				--extract node position coordinates
				local x, y, z = node_list[1], node_list[2], node_list[3]
				--create position vector
				local pos = vector.new(x, y, z)
				--create node table with name, lighting and orientation data
				local node_table = {name = node_list[4], param1 = node_list[5], param2 = node_list[6]}
				--set node into world at position with node table data
				core.set_node(pos, node_table)
				--get node metadata from position
				local node_meta = core.get_meta(pos)

				--[7]
				if node_table.name == "default:chest_locked" then
					node_meta:set_string("owner", node_list[7])
					node_meta:set_string("infotext", node_list[7])
				elseif node_table.name == "default:sign_wall_wood" then
					node_meta:set_string("text", node_list[7])
					node_meta:set_string("infotext", node_list[7])
				end
				
				--get node inventory metadata from position
				local inv = node_meta:get_inventory(pos)
				--loop through remaining data in node list for inventory items
				for i = 8, #node_list do
					--split each inventory slot into list name, item name and item count
					local item_data = string.split(node_list[i], " ")
					--set each element into variables
					local list_name, item_name, item_count = item_data[1], item_data[2], item_data[3]
					--add item into each node inventory slot
					inv:add_item(list_name, item_name.." "..item_count)
					
				end
			end
			--close schema file after all nodes and their data are set in world
			schema_file:close()
		end
	end,
})
	--]]