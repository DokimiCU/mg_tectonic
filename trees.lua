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


---------------------------------------------------------------------------


-----------------------------------------------------------------------
--Layered Tree

function mgtec.make_layered_tree(pos, data, area, height, radius, trunk, leaves, air, ignore)
	local ystride = area.ystride -- Useful to get the index above
	local iv = area:indexp(pos)
	for i = 1, height do -- Build the trunk
		data[iv] = trunk
		iv = iv + ystride -- increment by one node up
	end

	-- add leaves on the top (4% 0 ; 36% 1 ; 60% 2)
	local rand = math.random()
	if rand < 0.96 then
		data[iv] = leaves
		if rand < 0.60 then
			iv = iv + ystride
			data[iv] = leaves
		end
	end

	-- make several leaves rings
	local max_height = pos.y + height
	local min_height = pos.y + math.floor((0.2 + 0.3 * math.random()) * height)
	local radius_increment = (radius - 1.2) / (max_height - min_height)
	local np = {offset = 0.8, scale = 0.4, spread = {x = 12, y = 4, z = 12}, octaves = 3, persist = 0.8}

	pos.y = max_height - 1
	while pos.y >= min_height do
		local ring_radius = (max_height - pos.y) * radius_increment + 1.2
		make_leavesblob(pos, data, area, leaves, air, ignore, {x = ring_radius, y = 2, z = ring_radius}, np)
		pos.y = pos.y - math.random(2, 3)
	end
end

