--------------------------------------
--MG TECTONIC adapted plants api
--from mg valleys_mapgen
------------------------------------
mgtec.registered_plants = {}

--------------------------------------
--Called by the list of plants to register them
--adds it to the registered plant ..
--this register is then used by the other functions
function mgtec.register_plant(params)
	local n = #mgtec.registered_plants + 1
	params.priority = math.floor(params.priority) + 1 / n

	mgtec.registered_plants[n] = params
end

--makes in the form it can be read for voxel manip
local function get_content_id(value) -- get content ID recursively from a table.
	local typeval = type(value)

	if typeval == "string" then
		return minetest.get_content_id(value)
	elseif typeval == "table" then
		for k, v in pairs(value) do
			value[k] = get_content_id(v)
		end
	end

	return value
end


--sorts out plants in the list
mgtec.registered_on_first_mapgen = {}

--takes the table above and inserts the result of the function (at the end?)
function mgtec.register_on_first_mapgen(func) -- Callback
	table.insert(mgtec.registered_on_first_mapgen, func)
end

--this takes the plant list and sorts it based on the priority.
--all this is then run through to get proper ids. Which are inserted into "on first .." table
mgtec.register_on_first_mapgen(function()
	table.sort(mgtec.registered_plants,
		function(a, b)
			return a.priority > b.priority
		end
	)

	for _, plant in ipairs(mgtec.registered_plants) do -- convert 'nodes' into content IDs
		plant.nodes = get_content_id(plant.nodes)
	end
end)


-------------------------------------------------------------
--Main function
--called by the mapgen

function mgtec.choose_generate_plant(conditions, pos, data, area, ivm)
	local rand = math.random() -- Random number to choose the plant
	for _, plant in ipairs(mgtec.registered_plants) do -- for each registered plant
		local cover = plant.cover
		--will it meet the conditions for this species?
		if plant.check(conditions, pos) then -- Place this plant, or do not place anything (see Cover parameter)
			if rand < cover then
				if rand < plant.density then
					local grow = plant.grow
					local nodes = plant.nodes

					if grow then -- if a grow function is defined, then run it
						grow(nodes, pos, data, area, ivm, conditions)
					else
						if type(nodes) == "number" then -- 'nodes' is just a number
							data[ivm] = nodes
						else -- 'nodes' is an array
							local node = nodes[math.random(#nodes)]
							local n = nodes.n or 1
							local ystride = area.ystride

							for h = 1, n do
								data[ivm] = node
								ivm = ivm + ystride
							end
						end
					end
				end
				break
			else
				rand = (rand - cover) / (1 - cover)
			end
		end
	end
	return true
end
