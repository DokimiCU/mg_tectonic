--MG TECTONIC Plants api trees section
--adapted from valleys mapgen
--====================================================================


--Functions

--- Add tree roots. Called after mapgen via register

local function make_root(x0, y0, z0, data, area, tree, air)
	local ystride = area.ystride
	local ybot = y0 - 1
	for x = x0 - 1, x0 + 1 do
		for z = z0 - 1, z0 + 1 do -- iterate in a 3x3 square around the trunk
			local iv = area:index(x, ybot, z)
			for i = 0, 5 do
				if data[iv] == air then -- find the ground level
					if math.random() < 0.6 then
						data[iv-ystride] = tree -- make jungle tree below
						if math.random() < 0.6 then
							data[iv] = tree -- make jungle tree at this air node
						end
					end
					break
				end
				iv = iv + ystride -- increment by one node up
			end
		end
	end
end

--------------------------------------------------------------
--Make thick trunk?
local function make_thick(x0, y0, z0, data, area, tree, air,  height)
	local ystride = area.ystride
	local ybot = y0 - 1
	for x = x0 - 1, x0 + 1 do
		for z = z0 - 1, z0 + 1 do -- iterate in a 3x3 square around the trunk
			local iv = area:index(x, ybot, z)
			local h = 0
			for i = 0,  6 do
				if data[iv] == air then -- find the ground level
					if math.random() < 0.6 then
						data[iv-ystride] = tree -- make  tree below
						if h <  height then
							data[iv] = tree -- make  tree at this air node
							h = h+1
						end
					end
					break
				end
				iv = iv + ystride -- increment by one node up
			end
		end
	end
end



--------------------------------------------------------------
--Make tree leaves
local function make_leavesblob(pos, data, area, leaves, air, ignore, radius, np, fruit_chance, fruit)
	fruit_chance = fruit_chance or 0

	np.seed = math.random(0, 16777215) -- noise seed
	local minp = vector.subtract(pos, radius) -- minimal corner of the leavesblob
	local maxp = vector.add(pos, radius) -- maximal corner of the leavesblob
	local int_minp = {x = math.floor(minp.x), y = math.floor(minp.y), z = math.floor(minp.z)} -- Same positions, but with integer coordinates
	local int_maxp = {x = math.ceil(maxp.x), y = math.ceil(maxp.y), z = math.ceil(maxp.z)}

	local length = vector.subtract(int_maxp, int_minp)
	local chulens = vector.add(length, 1)
	local obj = minetest.get_perlin_map(np, chulens)
	local pmap = obj:get3dMap_flat(minp)
	local i = 1
	-- iterate for every position
	-- calculate the distance from the center by the Pythagorean theorem: d = sqrt(x²+y²+z²)
	for x = int_minp.x, int_maxp.x do
		local xval = ((x - pos.x) / radius.x) ^ 2 -- calculate x², y², z² separately, to avoid recalculating x² for every y or z iteration. Divided by the radius to scale it to 0…1
		for y = int_minp.y, int_maxp.y do
			local yval = ((y - pos.y) / radius.y) ^ 2
			for z = int_minp.z, int_maxp.z do
				local zval = ((z - pos.z) / radius.z) ^ 2
				local dist = math.sqrt(xval + yval + zval) -- Calculate the distance
				local nval = pmap[i] -- Get the noise value
				if nval > dist then -- if the noise is bigger than the distance, make leaves
					local iv = area:index(x, y, z)
					if data[iv] == air or data[iv] == ignore then
						if math.random() < fruit_chance then
							data[iv] = fruit
						else
							data[iv] = leaves
						end
					end
				end
				i = i + 1 -- increment noise index
			end
		end
	end
end

--==================================================================================

--Generic tree
-- tree + roots
function mgtec.make_tree(pos, data, area, height, radius, trunk, leaves, air, ignore)
	local ystride = area.ystride -- Useful to get the index above
	local iv = area:indexp(pos)
	for i = 1, height do -- Build the trunk
		data[iv] = trunk
		iv = iv + ystride -- increment by one node up
	end
	make_root(pos.x, pos.y, pos.z, data, area, trunk, air)
	local np = {offset = 0.8, scale = 0.4, spread = {x = 8, y = 4, z = 8}, octaves = 3, persist = 0.5} -- trees use a PerlinNoise to place leaves
	pos.y = pos.y + height - 1 -- pos was at the sapling position. By adding height we have the first air node above the trunk, so subtract 1 to get the highest trunk node.
	make_leavesblob(pos, data, area, leaves, air, ignore, {x = radius, y = radius, z = radius}, np) -- Generate leaves
end

--without roots
function mgtec.make_tree2(pos, data, area, height, radius, trunk, leaves, air, ignore)
	local ystride = area.ystride -- Useful to get the index above
	local iv = area:indexp(pos)
	for i = 1, height do -- Build the trunk
		data[iv] = trunk
		iv = iv + ystride -- increment by one node up
	end
	local np = {offset = 0.8, scale = 0.4, spread = {x = 8, y = 4, z = 8}, octaves = 3, persist = 0.5} -- trees use a PerlinNoise to place leaves
	pos.y = pos.y + height - 1 -- pos was at the sapling position. By adding height we have the first air node above the trunk, so subtract 1 to get the highest trunk node.
	make_leavesblob(pos, data, area, leaves, air, ignore, {x = radius, y = radius, z = radius}, np) -- Generate leaves
end


-------------------------------------------------------------------------
--Tree with apples
--no roots
function mgtec.make_apple_tree(pos, data, area, height, radius, trunk, leaves, fruit, air, ignore) -- Same code but with apples
	local ystride = area.ystride -- Useful to get the index above
	local iv = area:indexp(pos)
	for i = 1, height do -- Build the trunk
		data[iv] = trunk
		iv = iv + ystride -- increment by one node up
	end
	local np = {offset = 0.8, scale = 0.4, spread = {x = 8, y = 4, z = 8}, octaves = 3, persist = 0.5}
	pos.y = pos.y + height - 1
	make_leavesblob(pos, data, area, leaves, air, ignore, {x = radius, y = radius, z = radius}, np, 0.06, fruit)
end


-----------------------------------------------------------------------
--Thick Tree????

function mgtec.make_thick_tree(pos, data, area, height, radius, trunk, leaves, air, ignore)
	if vmg.loglevel >= 3 then
		print("[Valleys Mapgen] Generating birch tree at " .. minetest.pos_to_string(pos) .. " ...")
	end
	local ystride = area.ystride -- Useful to get the index above
	local iv = area:indexp(pos)
	for i = 1, height do -- Build the trunk
		data[iv] = trunk
		iv = iv + ystride -- increment by one node up
	end
	make_root(pos.x, pos.y, pos.z, data, area, trunk, air)
	make_thick(pos.x, pos.y, pos.z, data, area, trunk, air,  height)
	local np = {offset = 0.8, scale = 0.4, spread = {x = 8, y = 4, z = 8}, octaves = 3, persist = 0.5}
	pos.y = pos.y + height - 1
	make_leavesblob(pos, data, area, leaves, air, ignore, {x = radius, y = radius, z = radius}, np)
end
