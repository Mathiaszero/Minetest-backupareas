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

	--inv convention e.g.: list name|index|item count

	--get node inventory metadata
	local inv_ref = node_meta:get_inventory()
	--get inventory types
	for list, list_inv in pairs(inv_ref:get_lists()) do
		--core.chat_send_player(player, list)

		-- for i, itemstack in ipairs(list_inv) do
		-- 	core.chat_send_player(player, i..": "..dump(itemstack))
		-- end
		
		--core.chat_send_player(player, dump(inv_ref:get_list(list)))
		for i, v in ipairs(inv_ref:get_list(list)) do
			--core.chat_send_player(player, list..": "..i..": ")
			--core.chat_send_player(player, list..": "..i..": "..v)--v userdata error

			--core.chat_send_player(player, list..": "..i..": "..inv_ref:get_stack(list, i))--get_stack userdata error

			--core.chat_send_player(player, list..": "..i..": "..tostring(inv_ref:get_stack(list, i)))--works
			local itemstack = inv_ref:get_stack(list, i)
			local item_name = itemstack:get_name()
			local item_count = itemstack:get_count()
			--table.insert(node, string.format("%s%s%s%s%s%s%s", "inv", d, list, d, i, d, inv_ref:get_stack(list, i)))
			table.insert(node, string.format("%s%s%s%s%s%s%s", "inv", d, list, d, i, d, item_name.." "..item_count))

			-- if not itemstack:is_empty() then--ok but may do simpler
			-- 	local item_meta = itemstack:get_meta()
			-- 	local item_meta_keys = item_meta:get_keys()
			-- 	core.chat_send_player(player, dump(item_meta_keys))
			-- end

			local item_meta = itemstack:get_meta()
			local item_meta_keys = item_meta:get_keys()
			if #item_meta_keys > 0 then
				--core.chat_send_player(player, dump(item_meta_keys))
				for j, key in ipairs(item_meta_keys) do
					--core.chat_send_player(player, key)
					value = item_meta:get_string(key)

					--remove any new lines in value so it won't mess up saved area data
					local sub = string.gsub(value, "\n", " ")

					--core.chat_send_player(player, key..": "..value)--works
					table.insert(node, string.format("%s%s%s%s%s%s%s%s%s", "itemmeta", d, list, d, i, d, key, d, sub))
				end
			end
		end
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
				local x
				local y
				local z
				local name
				local param1
				local param2
				local saved_nodemeta = {}
				local saved_inv = {}
				local saved_invmeta = {}
				--split data of the node by ","
				local node_cat = string.split(line, dd)
				for i, subcat in ipairs(node_cat) do
					local kv = string.split(subcat, d)
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
					if kv[1] == "nodemeta" then
						saved_nodemeta[kv[2]] = kv[3]
					end
					if kv[1] == "inv" then
						table.insert(saved_inv, {list = kv[2], index = kv[3], itemstack = kv[4]})
					end
					if kv[1] == "itemmeta" then
						table.insert(saved_invmeta, {list = kv[2], index = kv[3], key = kv[4], value = kv[5]})
					end

				end
				local pos = vector.new(x, y, z)
				local node_base = {name = name, param1 = param1, param2 = param2}
				core.set_node(pos, node_base)
				local node_meta = core.get_meta(pos)
				for key, value in pairs(saved_nodemeta) do
    				--core.chat_send_player(player, "Key: " .. key .. ", Value: " .. value)
					node_meta:set_string(key, value)
				end
				
				-- if node_base.name == "default:chest_locked" then
				-- 	core.chat_send_player(player, dump(saved_inv))
				-- end

				--only get nodes containing an inventory
				if string.find(line, "inv") then
					--core.chat_send_player(player, node_base.name)
					local inv_ref = node_meta:get_inventory()
					for i, v in ipairs(saved_inv) do
						--core.chat_send_player(player, v)
						--core.chat_send_player(player, v.list)--works
						
						--inv_ref:set_stack(v.list, v.index, v.itemstack)--every slot unknown item
						--inv_ref:set_stack(v.list, v.index, "default:cobble")--every slot default:cobble
						--inv_ref:set_stack(v.list, v.index, ItemStack("default:cobble"))--every slot default:cobble
						--inv_ref:set_stack(v.list, v.index, v.itemstack)
						inv_ref:set_stack(v.list, v.index, v.itemstack)
						
						-- local stack = inv_ref:get_stack(v.list, v.index)
						-- local item_meta = stack:get_meta()
						
						-- for j, w in ipairs(saved_invmeta) do
						-- 	item_meta:set_string(w.key,w.value)
						-- end

						--item_meta:set_string()
						
						--doens't work/set text in book
						-- for i, w in ipairs(saved_invmeta) do
						-- 	if v.list == w.list and v.index == w.index then
								
						-- 		--shows why this loop is wrong
						-- 		--core.chat_send_player(player, "v.list,w.list,v.index,w.index: "..v.list..","..w.list..","..v.index..","..w.index)
								
						-- 		--core.chat_send_player(player, "OOG")
						-- 		--stack:set_string(w.key, w.value)--set string nil value error
						-- 		--stack:set_string("1","2")--same error
								
						-- 		--item_meta:set_string(w.key, w.value)

						-- 		--core.chat_send_player(player, w.key..": "..w.value)
						-- 	end
						-- end
					
					end

					--doesnt work also
					-- for i, v in ipairs(saved_invmeta) do
					-- 	local stack = inv_ref:get_stack(v.list, v.index)
					-- 	local itemmeta = stack:get_meta()
						
					-- 	--core.chat_send_player(player, dump(v))--ok

					-- 	--core.chat_send_player(player, v.key..": "..v.value)--ok
					-- 	--itemmeta:set_string(v.key, v.value)--not sure why not working
					-- 	--itemmeta:set_string("1", "2")

					-- 	--itemmeta:set_string("title", "fuc")

					-- end

					for i, v in ipairs(saved_invmeta) do
						local stack = inv_ref:get_stack(v.list, v.index)
						local itemmeta = stack:get_meta()
						
						--core.chat_send_player(player, dump(v))--ok

						core.chat_send_player(player, v.key..": "..v.value)--ok
						itemmeta:set_string(v.key, v.value)--not sure why not working
						inv_ref:set_stack(v.list, v.index, stack)
					end
				end

				-- local inv_ref = node_meta:get_inventory()
				-- for list, list_inv in pairs(inv_ref:get_lists()) do
				-- 	for i, v in ipairs(inv_ref:get_list(list)) do
				-- 		local itemstack = inv_ref:get_stack(list, i)
				-- 		local itemmeta = itemstack:get_meta()
				-- 		itemmeta:set_string("title","ho")
				-- 		-- for j, w in ipairs(saved_invmeta) do
				-- 		-- 	--core.chat_send_player(player, w.list..":"..w.index)
				-- 		-- 	if w.list == list and w.index == tostring(i) then
				-- 		-- 		--core.chat_send_player(player,"OOG")
				-- 		-- 		itemmeta:set_string(w.key,w.value)
				-- 		-- 	end
				-- 		-- end
				-- 	end	
				-- end
				
				-- local inv_ref = node_meta:get_inventory()
				-- local itemstack = inv_ref:get_stack("main", 1)
				-- local itemmeta = itemstack:get_meta()
				-- itemmeta:set_string("page_max","1")
				-- itemmeta:set_string("owner","Jim")
				-- itemmeta:set_string("title","ho")
				-- itemmeta:set_string("text","ho")
				-- itemmeta:set_string("description","ho")

				--core.chat_send_player(player, dump(inv_ref))

				-- if inv_ref then
				-- 	core.chat_send_player(player, node_base.name)
				-- end

				-- for i, v in pairs(saved_inv) do
				-- 	core.chat_send_player(player, v)
				-- 	--inv_ref:set_stack(listname, i, stack)
				-- end

				-- local inv = core.get_inventory({type = "node", pos = {x=tonumber(x),y=tonumber(y),z=tonumber(z)}})
				-- if inv then
				-- 	core.chat_send_player(player, node_base.name)
				-- end



			end
			--close schema file after all nodes and their data are set in world
			schema_file:close()
		end
	end,
})

--testing
core.register_chatcommand("im", {
	description = S("im."),
	privs = {server = true,},
	func = function(player, param)
		local node_meta = core.get_meta(vector.new(2,67,126))
		local inv_ref = node_meta:get_inventory()
		local itemstack = inv_ref:get_stack("main", 1)
		--core.chat_send_player(player,itemstack:get_name())
		local itemmeta = itemstack:get_meta()
		--itemmeta = itemstack:get_name():get_meta()
		itemmeta:set_string("page_max","1")
		itemmeta:set_string("owner","ho")
		itemmeta:set_string("title","ho")
		itemmeta:set_string("text","ho")
		itemmeta:set_string("description","ho")
		--core.chat_send_player(player, dump(itemmeta:get_keys()))
		--core.chat_send_player(player, dump(itemmeta:get_string("title")))

		local itemmeta_keys = itemmeta:get_keys()
		for i, key in pairs(itemmeta_keys) do
			--core.chat_send_player(player, key)
			itemmeta:set_string(key,"ho")
			core.chat_send_player(player, key..":"..itemmeta:get_string(key))
		end

		inv_ref:set_stack("main", 1, itemstack)

		core.chat_send_player(player, "done")
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