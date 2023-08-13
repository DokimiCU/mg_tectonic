
-- PARAMETERS
----------------------
--MISC
-- the edge of the map
local YMAX = 31000

-------------------
--BASE LAYER:
-- Wave Roll Size: i.e Period
--Controls distance between ranges, and thickness.
--This is the period at the map centre. Grows to double at map edges
--will effect gradient and number of major mt ranges
local XRS = 537--617

local nobj_terr
local nobj_terr2
local nobj_cave
local nobj_cave2
local nobj_strata

minetest.after(0, function()
	nobj_terr = minetest.get_perlin(mgtec.np_terrain)
	nobj_terr2 = minetest.get_perlin(mgtec.np_terrain2)

	nobj_cave = minetest.get_perlin(mgtec.np_cave)
	nobj_cave2 = minetest.get_perlin(mgtec.np_cave2)
	nobj_strata = minetest.get_perlin(mgtec.np_strata)
end)

local function collect_sample(x, z)
	local t0 = minetest.get_us_time()
	local sample = {}
	----------------------------------------------------------------------------
	-- local n_terr   = nobj_terr:get_2d({x=x,y=z})
	local n_terr   = nobj_terr:get_2d({x = x + 970, y = z})
	-- sample.n_terr = n_terr
	local n_terr2  = nobj_terr2:get_2d({x = x + 970, y = z})
	-- sample.n_terr2 = n_terr2
	----------------------------------------------------------------------------
	-- local xab = math.abs(x + (n_terr * 1466))
	local xab = math.abs(x) + (n_terr * 1466)
	-- local xab = math.abs(x)
	local xtgrad = (xab/YMAX)
	-- sample.xtgrad = xtgrad
	local whs = (1-xtgrad) + (n_terr * 0.06)
	local mup = whs - xtgrad - (n_terr * 0.25)
	local x_roll = XRS + (XRS * xtgrad)  + (234 - (n_terr * 234))
	local dwav = ((whs*math.cos(xab/(x_roll/6.89))) ^ 3)*1.67 + ((whs*math.cos(xab/x_roll)) ^ 3)*6.89 + mup*10.81
	-- local dnoi = (n_terr^3 + n_terr*0.5 + n_terr2*n_terr*0.8) * 2.8 * (whs + 0.02)
	local dnoi = 2.8 * n_terr * (0.5 + n_terr^2 + n_terr2*0.8) * (whs + 0.02)
	local pos = {x=x,z=z}   -- y set in the loop
	----------------------------------------------------------------------------
	local basin
	local river_basin
	---------------------------------------------------

	local e_terrain_y = mgtec.estimate_base_terrain_height(x, z, n_terr, n_terr2)
	local ocean_basin_y = mgtec.get_ocan_basin_height(x, z, n_terr, n_terr2)
	local river_basin_y = mgtec.get_river_bed_heigh(x, z, n_terr, n_terr2)
	sample.estimate_y = math.floor(math.min(e_terrain_y, ocean_basin_y, river_basin_y))


	-- local d_base = dwav + dnoi
	-- local d_soft = d_base * 0.4  + 1.3 + (1 - n_terr) * (2.22 - xtgrad * 2)
	-- local d_allu = d_soft * 0.95 + 0.1
	-- local d_sedi = d_allu + 0.03


	for y = sample.estimate_y + 1, sample.estimate_y - 50, -1 do
		pos.y = y
		local val_cave   = nobj_cave:get_3d(pos)
		local val_cave2  = nobj_cave2:get_3d(pos)
		local val_strata = nobj_strata:get_3d(pos)
		local dstrata = math.abs(val_strata)*0.16
		local dclif2 = math.abs(val_cave*val_cave2*0.05)

		local den_base = dwav + dnoi - math.abs(val_strata)*0.16 - dclif2
		-- assert(den_base == d_base - dstrata - dclif2)
		local den_soft = den_base*0.4  + 1.3 + (1-n_terr) * (2.22 - xtgrad*2) - dclif2
		-- assert(den_soft == d_soft - dstrata * 0.4 - dclif2 * 1.4, "Works, but doesn't because of rounding errors")
		local den_allu = den_soft*0.95 + 0.1 - dclif2  --Alluvium --eroded rock etc, deposited on lowlands
		-- assert(den_base == d_allu - dstrata * 0.38 - dclif2 * 2.33)
		local den_sedi = den_allu      + 0.03 --Sediment--subsurface soils and sands
		-- assert(den_base == d_sedi - dstrata * 0.38 - dclif2 * 2.33)
		local t_base = 0.00969*y --Base Threshold (use for all of them now) effects heights of landscape
		-- sample.t_base = t_base
		if den_base > t_base
		or den_soft > t_base
		or den_allu > t_base
		or den_sedi > t_base then
			river_basin = false
			basin = false
			if y > ocean_basin_y then
				basin = true
			elseif y > river_basin_y then
				river_basin = true
			end
			if not basin and not river_basin then
				sample.time = minetest.get_us_time() - t0
				sample.height = y
				sample.dif = sample.estimate_y - sample.height
				return sample
			end
		end
	end
	sample.time = minetest.get_us_time() - t0
	sample.height = alt_min
	sample.dif = sample.estimate_y - sample.height
	return sample
end


-- resolution - length of square represented by 1 data point
local function collect_cartography_data(co, min_x, min_z, max_x, max_z, resolution)
	local t0 = minetest.get_us_time()

	local distance_x = max_x - min_x
	local steps_x = math.ceil(distance_x / resolution)
	local step_size_x = distance_x / steps_x
	local distance_z = max_z - min_z
	local steps_z = math.ceil(distance_z / resolution)
	local step_size_z = distance_z / steps_z



	local samples = {}
	local sample_positions = {}

	local lt0 = minetest.get_us_time()

	-- fisrt colect all sample positions
	-- iterrating backwards over Z to make it easier to embed the data into a formspec
	for z = max_z - (step_size_z / 2), min_z, -step_size_z do
		for x = min_x + (step_size_x / 2), max_x, step_size_x do
			table.insert(sample_positions, {math.round(x), math.round(z)})
		end
	end

	-- then colect data samples at the positions
	for i, pos in ipairs(sample_positions) do
		local sample = collect_sample(pos[1], pos[2]) -- -2700)
		table.insert(samples, sample)

		if minetest.get_us_time() - lt0 > 1000000 then
			print("[mg_tectonic] colecting cartography samples: " .. i .. " / " .. #sample_positions .. " - " .. math.floor((i / #sample_positions) * 100) .. " %")
			minetest.after(0, function()
				coroutine.resume(co)
			end)
			coroutine.yield()
			lt0 = minetest.get_us_time()
		end
	end

	-- organize sample data into data maps
	local categories = {}
	local category_names = {}
	for category, v in pairs(samples[1]) do
		categories[category] = {
			data_map = {},
			min = v,
			max = v,
		}
		table.insert(category_names, category)
	end

	for category, data in pairs(categories) do
		local total = 0
		for i, sample in ipairs(samples) do
			local val = sample[category]
			table.insert(data.data_map, val)
			if data.min > val then data.min = val end
			if data.max < val then data.max = val end
			total = total + val
		end
		data.average = total / #samples
	end

	local cartography_data = {
		dimensions = {
			x = steps_x,
			z = steps_z,
			minp = {x = min_x, z = min_z},
			maxp = {x = max_x, z = max_z},
		},
		categories = categories,
		category_names = category_names,
	}

	print("[mg_tectonic] colected cartography data in " .. (minetest.get_us_time() - t0) / 1000000 .. " seconds")
	print("[mg_tectonic] data dimensions are " .. steps_x .. " X " .. steps_z)
	minetest.chat_send_all("[mg_tectonic] colected cartography data in " .. (minetest.get_us_time() - t0) / 1000000 .. " seconds")

	mgtec.cartography_data = cartography_data
	mgtec.mod_storage:set_string("cartography_data", minetest.serialize(cartography_data))
end

local function start_collecting_cartography_data(min_x, min_z, max_x, max_z, resolution)
	local co
	co = coroutine.create(function()
		collect_cartography_data(co, min_x, min_z, max_x, max_z, resolution)
	end)
	coroutine.resume(co)
end


local function load_cartography_data()
	if mgtec.cartography_data then return end

	local cartography_data = mgtec.mod_storage:get("cartography_data")
	if cartography_data then
		cartography_data = minetest.deserialize(cartography_data)
		mgtec.cartography_data = cartography_data
		print("[mg_tectonic]: loading cartography data from mod storage. size: " .. cartography_data.dimensions.x .. " X " .. cartography_data.dimensions.z)
	else
		collect_cartography_data(-30000, -30000, 30000, 30000, 750)
	end

end

local function clamp(n, min, max)
	return math.min(max, math.max(min, n))
end

local function lerp(a, b, ratio)
	return (a * (1 - ratio)) + (b * ratio)
end

local function ilerp(a, b, value)
	return (value - a) / (b - a)
end

local function remap(in_a, in_b, out_a, out_b, value)
	return lerp(out_a, out_b, ilerp(in_a, in_b, value))
end
local function get_cartography_map(size, category)
	load_cartography_data()

	local steps_x = mgtec.cartography_data.dimensions.x
	local steps_z = mgtec.cartography_data.dimensions.z

	local category_data = mgtec.cartography_data.categories[category]

	local max = category_data.max
	local min = category_data.min

	local image_data = {}
	for i, val in ipairs(category_data.data_map) do

		if val == nil then
			image_data[#image_data + 1] = {r = 255, g = 0, b = 0, a = 255}
		else
			-- remaps map data to show only positive values
			local intensity = clamp(remap(0, max, 0, 255, val), 0, 255)
			-- use this instead to see full range
			-- local intensity = clamp(remap(min, max, 0, 255, val), 0, 255)
			image_data[#image_data + 1] = {r = intensity, g = intensity, b = intensity, a = 255}
			if val < 0 then
				image_data[#image_data] = {r = intensity, g = intensity/2, b = intensity/2, a = 255}
			end
		end
	end

	local width, height = size, size
	if steps_x ~= steps_z then
		if steps_x < steps_z then
			width = width * (steps_x / steps_z)
		else
			height = height * (steps_z / steps_x)
		end
	end

	return "image[0,0;" .. width .. "," .. height .. ";[png:" .. minetest.encode_base64(minetest.encode_png(steps_x, steps_z, image_data)) .. "]"

end

local function get_player_marker(player, scale, dimensions)

	local p = 1 / 16
	local pos = player:get_pos()

	local x = remap(dimensions.minp.x, dimensions.maxp.x, -(scale / 2), (scale / 2), pos.x)
	local y = remap(dimensions.minp.z, dimensions.maxp.z, (scale / 2), -(scale / 2), pos.z)

	return "box[" .. x - (p / 2) .. "," .. y - (p / 2) .. ";" .. p .. "," .. p .. ";#F00F]"
end

local function get_fs_tabs(selected)
	load_cartography_data()
	local fs = {
		"tabheader[0,0;category_selector;"
	}
	local n = 1
	for i, category in pairs(mgtec.cartography_data.category_names) do
		fs[#fs + 1] = category
		fs[#fs + 1] = ","
		if selected == category then n = i end
	end
	fs[#fs] = ";" .. n .. "]"
	return table.concat(fs)
end

local function get_map_grid()
	local p = 1/64
	local fs = {
		"box[" .. 5 - p .. ",0;" .. p * 2 .. ",10;#00FF00FF]",
	}
	return table.concat(fs)
end

local function show_cartography_map(player, category)
	local category_data = mgtec.cartography_data.categories[category]
	local fs = {
		"formspec_version[6]",
		"size[11,11]",
		get_fs_tabs(category),
		"container[0.5,0.5]",
		get_cartography_map(10, category),
		get_map_grid(),
		"container[5,5]",
		get_player_marker(player, 10, mgtec.cartography_data.dimensions),
		"container_end[]",
		"label[0,10.25;Min: " .. category_data.min .. "]",
		"label[8,10.25;Max: " .. category_data.max .. "]",
		"label[4,10.25;Avg: " .. category_data.average .. "]",
		"container_end[]",
	}
	fs = table.concat(fs)
	minetest.show_formspec(player:get_player_name(), "mgtec:map", fs)
end




minetest.register_craftitem("mg_tectonic:debug_stick", {
	description = "Tectonic Debug Stick",
	inventory_image = "default_stick.png",
	-- wield_image = "cicrev_axe_of_trees.png",
	stack_max = 1,
	on_place = function(itemstack, placer, pointed_thing)
		-- entire map
		start_collecting_cartography_data(-30000, -30000, 30000, 30000, 93.75)

		local pos = pointed_thing.under
		-- tight area around player
		-- start_collecting_cartography_data(pos.x - 320, pos.z - 320, pos.x + 320, pos.z + 320, 1)
		-- larger area around player
		-- start_collecting_cartography_data(pos.x - 1280, pos.z - 1280, pos.x + 1280, pos.z + 1280, 4)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		load_cartography_data()
		show_cartography_map(user, mgtec.cartography_data.category_names[1])
	end,
	on_use = function(itemstack, user, pointed_thing)
		user:set_physics_override({speed = 3})
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "mgtec:map" then return end
	if fields.category_selector then
		local index = tonumber(fields.category_selector)
		show_cartography_map(player, mgtec.cartography_data.category_names[index])
	end
end)
