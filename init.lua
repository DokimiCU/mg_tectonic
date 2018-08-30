---============================================================================
--MG TECTONIC
--By Dokimi

--A naturalistic mapgen.
--This is the main mapgen code.

--=============================================================================
--PRELIMINARIES
mgtec = {}

---------------------
--SINGLENODE
minetest.set_mapgen_params({mgname = "singlenode", flags = "nolight"})
--minetest.set_mapgen_setting("mgname", "singlenode", true)
--minetest.set_mapgen_setting("flags", "nolight", true)

-----------------
--PLANTS API
dofile(minetest.get_modpath("mg_tectonic").."/trees.lua")
dofile(minetest.get_modpath("mg_tectonic").."/plants_api.lua")
dofile(minetest.get_modpath("mg_tectonic").."/plants.lua")

if mgtec.registered_on_first_mapgen then -- Run callbacks
		for _, f in ipairs(mgtec.registered_on_first_mapgen) do
			f()
		end
		mgtec.registered_on_first_mapgen = nil
		mgtec.register_on_first_mapgen = nil
	end

--=============================================================================
-- PARAMETERS
----------------------
--MISC
-- the edge of the map
local YMAX = 33000
local YMIN = -33000

 --sealevel
local SEA = 0

--height of lava
local MAXMAG = -15000

-------------------
--BASE LAYER:
-- Wave Roll Size: i.e Period
--Controls distance between ranges, and thickness.
--This is the period at the map centre. Grows to double at map edges
local XRS = 150

--Where does the continental shelf end?
local SHELFX = 15000
local SHELFZ = 18000
--How deep are the oceans?
local SEABED = -128
--Strength of noise on continental shelf boundaries lines
local CONOI = 10000

--Cave size.
--Base cave threshold for fissures
local BCAVTF = 0.006
--Base cave threshold for caves
local BCAVT = 0.999

--Ore threshold
local ORET = 0.96

--==================================================================
--FUNCTIONS

--Checks if this is a place for ore deposits.

local function ore(ab_stra, y, ORET, ybig, n_strata, data, vi, OREID)
	--c_coal, c_iron, c_copp, c_tin, c_gold, c_diam, c_mese

	--strata thickness
	local thick = 50 + (50 * ab_stra)

	--strata splits for ore types..
	local t1 = 0.25
	local t2 = 0.5
	local t3 = 0.83

	local ystrata = math.sin(y/thick)

	 --a fair sine wave split, with low value ores dominant
	 --[[for reference... if the above gets confusing
	local ysmin_coal = 0 * TSTRA
	local ysmax_coal = 0.25 * TSTRA
	local ysmin_cop = 0.25 * TSTRA
	local ysmax_cop = 0.5 * TSTRA
	local ysmin_gol = 0.5 * TSTRA
	local ysmax_gol = 0.83 * TSTRA
	local ys_mese1 = 0.83 * TSTRA --mese is on the ends of the range
	local ysmin_iron = -0.25 * TSTRA
	local ysmax_iron = 0 * TSTRA
	local ysmax_tin = -0.25 * TSTRA
	local ysmin_tin = -0.5 * TSTRA
	local ysmax_dia = -0.5 * TSTRA
	local ysmin_dia = -0.83 * TSTRA
	local ys_mese2 = -0.83 * TSTRA
	--]]


	--threshold adjusted with depth
	local ore_t = ORET + ybig

	--height limits
	local blend = n_strata * 50
	local orehmin_c = -10000 + (n_strata * 500) --min height for coal (a shallow ore)
	local orehmax_g = -100 + blend   --dig a little for gold
	local orehmax_d = -150 + blend   --diamonds are deep
	local orehmax_m = -200 + blend   --mese is deep

	--above their threshold
	if ab_stra >= ore_t then

		--split them by height and strata
		--coal.
		if y > orehmin_c
		and ystrata >= 0     --strata splits
		and ystrata < t1
		then
			data[vi] = OREID.c_coal
			return true
		--iron
		elseif ystrata > -t1    --strata splits
		and ystrata < 0 then
			data[vi] = OREID.c_iron
			return true
		--copper
		elseif ystrata > t1    --strata splits
		and ystrata < t2 then
			data[vi] = OREID.c_copp
			return true
		--tin
		elseif ystrata > -t2    --strata splits
		and ystrata < -t1 then
			data[vi] = OREID.c_tin
			return true
		--Gold
		elseif  y < orehmax_g
		and ystrata > t2    --strata splits
		and ystrata < t3 then
			data[vi] = OREID.c_gold
			return true
		--Diamonds
		elseif y < orehmax_d
		and ystrata > -t3    --strata splits
		and ystrata < -t2 then
			data[vi] = OREID.c_diam
			return true
		--Mese
		elseif y < orehmax_m
		and (ystrata > t3    --strata splits, end of range
		or ystrata < -t3) then
			data[vi] = OREID.c_mese
			return true
		end
			--end of ores
	else
		--have to let it know so it can set void etc
		return false
	end
	--end of all ores
end
--End of Ore function



------------------------------
--Climate Calculations.
local function climate(x, z, y, n_terr, n_terr2)
	--east = + x, west = - x, south = -z, n = + z
	--Climate is decided by:
	-- -Ranges: rains come from the west (-x), rise over the ranges dumping cooling rain, descending hot and dry (east +x)
	-- - Altitude: it's cold up there.
	-- - Latitude: hot north, cold south

	--blending
	local blend = (((n_terr2 + n_terr)/2) * math.random(-4, 10))

	--Fohn Winds! They are hot! The East Coast is a hot dry place
	--increasing temp from far +x to x = 0,(rain shadow) (from 50 to 100)

	-- no Fohn? Westies have it mild
	local temp_x = 50 - blend

	-- Easterners?
	if x > 0 + (n_terr * 400) then --offset east-west border with some noise
		-- linear decrease, intercept at 100 (don't use in -x)
		temp_x = (-0.0017*x) + 100 - blend
	end

	--We are Southern Hemisphererers here!
	--decreasing temp from max z to min z (latitude) (from 100 to 0 i.e north desert to south ice)
	-- linear increase, intercept at 50
	local temp_z = (0.0017*z) + 50 - blend

	--Mountain tops ought to be cold!
	--decreasing temp with hieght...and combine previous two as baseline
	local temp = (-0.21*y) + ((temp_z + temp_x)/2) - blend

	--blur edges
	temp = temp + math.random(-4, 4)

	---------------
	--what's the humidity? Rainshadow!
	--decreasing humid from far x to x= 0,(rain shadow)

	--if in doubt ...
	local hum = 50 + blend

	----poitive, east coast. Dry inland
	--linear increase,
	if x > 0 + (n_terr * 400) then
		hum = (0.002*x) + blend
	--increasing humid from far x to x= 0,(rain shadow)
	else  --negative , west coast. Wet inland
		--linear increase,
		hum = (0.0012*x) + 100 + blend
	end

	--give a boost to low altitude.. (they tend to be near water)
	--and to hill tops (catch rain)
	if y < 15 + math.random(-4, 4) or y > 120 + math.random(-5, 5) then
		hum = hum + (hum*0.05)
	end

	hum = hum + math.random(-4, 4)

return temp, hum
--done climate calculations
end

-------------------------------------
--Create Swamp
local function swamp(data, vi, chance, mud, water)


	--let's place a messy swampy mire
	local roll = math.random(1, chance)
	if roll == 1 then
		data[vi] = water
	else
		data[vi] = mud
	end
--end of swamp
end




--End of functions

--=============================================================================
--IDs
-- Get the content IDs for the nodes used.

--rocks
local c_stone = minetest.get_content_id("default:stone")
local c_stone2 = minetest.get_content_id("default:desert_stone")
local c_sandstone = minetest.get_content_id("default:desert_sandstone")
local c_sandstone2 = minetest.get_content_id("default:sandstone")
local c_sandstone3 = minetest.get_content_id("default:silver_sandstone")
local c_obsid = minetest.get_content_id("default:obsidian")
local c_coral = minetest.get_content_id("default:coral_skeleton")

--sediments
local SEDID = {
 			c_gravel = minetest.get_content_id("default:gravel"),
 			c_clay = minetest.get_content_id("default:clay"),
 			c_sand = minetest.get_content_id("default:sand"),
 			c_sand2 = minetest.get_content_id("default:silver_sand"),
 			c_dirt = minetest.get_content_id("default:dirt"),
}

--surfaces
local c_dirtgr = minetest.get_content_id("default:dirt_with_grass")
local c_dirtdgr = minetest.get_content_id("default:dirt_with_dry_grass")
local c_dirtsno = minetest.get_content_id("default:dirt_with_snow")
local c_dirtlit = minetest.get_content_id("default:dirt_with_rainforest_litter")
local c_snowbl = minetest.get_content_id("default:snowblock")
local c_ice = minetest.get_content_id("default:ice")
local c_dsand = minetest.get_content_id("default:desert_sand")

--Miscellaneous

local MISCID = {
		c_water = minetest.get_content_id("default:water_source"),
		c_river = minetest.get_content_id("default:river_water_source"),
		c_air = minetest.get_content_id("air"),
		c_ignore = minetest.get_content_id("ignore"),
		c_lava = minetest.get_content_id("default:lava_source"),
}

--ores
local OREID = {
		c_diam = minetest.get_content_id("default:stone_with_diamond"),
		c_mese = minetest.get_content_id("default:stone_with_mese"),
		c_gold = minetest.get_content_id("default:stone_with_gold"),
		c_copp = minetest.get_content_id("default:stone_with_copper"),
		c_tin = minetest.get_content_id("default:stone_with_tin"),
		c_iron = minetest.get_content_id("default:stone_with_iron"),
		c_coal = minetest.get_content_id("default:stone_with_coal")
}

--=============================================================================
--NOISES

-- 2D Mountain Terrain.
--controls: base layer variation in mountains.
local np_terrain = {
   offset = 0,
   scale = 1,
   spread = {x = 512, y = 608, z = 608},
   seed = 5900033,
   octaves = 7,
   persist = 0.6,
   lacunarity = 2,
}

-- 2D Soft rock Terrain.
--controls: soft rock layer variation.
local np_terrain2 = {
   offset = 0,
   scale = 1,
   spread = {x = 128, y = 128, z = 128},
   seed = 5900033,
   octaves = 4,
   persist = 0.6,
   lacunarity = 2.5,
}


-- 3D Caves 1
--used by: fissures in basement rock,
local np_cave = {
   offset = 0,
   scale = 1,
   spread = {x = 128, y = 224, z = 224},
   seed = -9103323,
   octaves = 5,
   persist = 0.2,
   lacunarity = 2,
}

-- 3D Caves 2
--used by: breaks in fissures, caves in basement rock
local np_cave2 = {
  offset = 0,
	scale = 1,
	spread = {x = 48, y = 24, z = 48},
	seed = 205301,
	octaves = 4,
	persist = 0.3,
  lacunarity = 2.5,
}


-- 3D Strata
-- used by: ore thresholds.
local np_strata = {
   offset = 0,
   scale = 1,
   spread = {x = 64, y = 64, z = 64},
   seed = 51055033,
   octaves = 2,
   persist = 0.8,
   lacunarity = 2,
}


---============================================================================
--NOISE MEMORY

-- Initialize noise object to nil. It will be created once only during the
-- generation of the first mapchunk, to minimise memory use.
local nobj_terrain = nil
local nobj_terrain2 = nil
local nobj_cave = nil
local nobj_cave2 = nil
local nobj_strata = nil

-- Localise noise buffer table outside the loop, to be re-used for all
-- mapchunks, therefore minimising memory use.
local nvals_terrain = {}
local nvals_terrain2 = {}
local nvals_cave = {}
local nvals_cave2 = {}
local nvals_strata = {}

-- Localise data buffer table outside the loop, to be re-used for all
-- mapchunks, therefore minimising memory use.
local data = {}

--=============================================================================
-- GENERATION

minetest.register_on_generated(function(minp, maxp, seed)
  math.randomseed(seed)
	--------------------------------
	--don't do out of bounds!
	--world is a square, ymin will do for z and x too.
  if minp.x < YMIN
	or maxp.x > YMAX
	or minp.y < YMIN
	or maxp.y > YMAX
	or minp.z < YMIN
	or maxp.z > YMAX
	then
		return
	end

	-----------------------------
	-- Start time of mapchunk generation.
	local t0 = os.clock()

	--------------------------------
	-- NOISE
	-- Side length of mapchunk.
	local sidelen = maxp.x - minp.x + 1

	-- Required dimensions noise perlin map.
	--3d
	local chulen = {x = sidelen, y = sidelen, z = sidelen}
	--2d
	local chulenxz = {x = sidelen, y = sidelen, z = 1}

	local minposxyz = {x = minp.x, y = minp.y - 1, z = minp.z}
	local minposxz = {x = minp.x, y = minp.z}

	-- strides for voxelmanip
	local ystridevm = sidelen + 32
	local zstridevm = ystridevm ^ 2

	-- Create the perlin map noise object once only, during the generation of
	-- the first mapchunk when 'nobj_terrain' is 'nil'.
	nobj_terrain = nobj_terrain or minetest.get_perlin_map(np_terrain, chulenxz)
	nobj_terrain2 = nobj_terrain2 or minetest.get_perlin_map(np_terrain2, chulenxz)
	nobj_cave = nobj_cave or minetest.get_perlin_map(np_cave, chulen)
	nobj_cave2 = nobj_cave2 or minetest.get_perlin_map(np_cave2, chulen)
	nobj_strata = nobj_strata or minetest.get_perlin_map(np_strata, chulen)


	-- Create a flat array of noise values from the perlin map, with the
	-- minimum point being 'minp'.
	-- Set the buffer parameter to use and reuse 'nvals_X' for this.
	nobj_terrain:get2dMap_flat(minposxz, nvals_terrain)
	nobj_terrain2:get2dMap_flat(minposxz, nvals_terrain2)
	nobj_cave:get3dMap_flat(minposxyz, nvals_cave)
	nobj_cave2:get3dMap_flat(minposxyz, nvals_cave2)
	nobj_strata:get3dMap_flat(minposxyz, nvals_strata)


	-----------------------------------------------------------
	-- VOXELMANIP
	-- Load the voxelmanip with the result of engine mapgen. Since 'singlenode'
	-- mapgen is used this will be a mapchunk of air nodes.
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")

	-- 'area' is used later to get the voxelmanip indexes for positions.
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}

	-- Get the content ID data from the voxelmanip in the form of a flat array.
	-- Set the buffer parameter to use and reuse 'data' for this.
	vm:get_data(data)

    -- some things need to be random, but stay constant throughout the loop
    
    -- number of lakes
    local num_lakes = math.random(0,20)
    local lakes = {}
    for i = 0, num_lakes do
        lakes[i] = {x = math.random(-SHELFX,SHELFX), z = math.random(-SHELFZ,SHELFZ), r = math.random(0,4) > 0}
    end

	---------------------------------------------
	-- GENERATION LOOP

	----------------------------
	--Begin the Loop

	-- Noise index for the flat array of noise values.
	-- 3D perlinmap indexes
	local nixyz = 1
	-- 2D perlinmap indexes
	local nixz = 1

	-- Process the content IDs in 'data'.
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			-- Voxelmanip index for the flat array of content IDs.
		 	-- Initialise to first node in this x row.
			local vi = area:index(minp.x, y, z)
			for x = minp.x, maxp.x do

				----------------------------------------------------
			 	--Welcome to the Loop


				-----------
				--Noises
				local n_terr  = nvals_terrain[nixz]
				local n_terr2  = nvals_terrain2[nixz]
				local n_cave = nvals_cave[nixyz]
				local n_cave2 = nvals_cave2[nixyz]
				local ab_cave = math.abs(n_cave)
				local ab_cave2 = math.abs(n_cave2)
				local n_strata = nvals_strata[nixyz]
				local ab_stra = math.abs(n_strata)

				--Get the node underneath
				local nodu  = data[(vi - ystridevm)]

				-----------
				-- Math

				--absolute for x (for symmetry on both sides of map)
				local xab = math.abs(x)
				--x axis terrain gradient. 0 at centre. 1 at edges.
				--Used by equations to adjust along x axis
				local xtgrad = (xab/YMAX)
				--Move up/down along x axis. Goes from +1 to -1
        --mup raises and lowers along x axis. the two terms cancel out in middle of x range (15k).
        --aimed for equations that need to lift map centre, sink edges
        local mup = (1 - xtgrad) + (-1 * xtgrad)


				------------------
				--Base Layer Waves
				--creates the underlying, undulating and mountainous terrain

				--amplitude... going from 1 to zero at map edge
				local whs = 1-xtgrad


				--Wave period. "Roll". i.e. how wide/steep and they are.
				--Gradient widens the ranges towards the edges.
				local x_roll = XRS + (XRS * xtgrad)   --x axis

				--The Wave!
				local xwav = (whs*math.sin(x/x_roll))    -- north south wave (main ranges)


				--Base Wave Density.
				--This is checked against the threshold to decide where the base layer can go.
				--the wave controls the landscape folding i.e. the bunching up caused by the plates hitting eachother.
				--variation along this fold is caused by erosion, so is much more random...
				--therefore it is contolled by noise (rather than another wave which is too regular)

				--cubing/squaring flattens out the middle range,
				--for the wave that gives it a flat shelf at sea level.
				--for the noise it mellows part of it out, so it adds mainly extreme peaks and dips
				--mup lowers the landscape at the edges (ocean), otherwise the flattening of height would lead to endless plains

				local den_base = (xwav ^ 3) + mup + ((n_terr ^2) * whs)


				---Base Threshold
				local t_base = 0.01*y



				-------------------------------------
				--Soft Rock
				--layered on top of the base layer.
				--soft sandstone... a good enough stand in for easily erobable rocks
				--creates regions of soft rock on top of the base layer in lowlands

				--density
				local den_soft = (den_base*1.5) + ((n_terr2 ^3)*0.5) -xtgrad
				--threshold
				local t_soft = 0.03*y -1.5


				------------------------------------
				--Alluvium
				--eroded rock etc, deposited on lowlands

				--density
				local den_allu = (den_soft*1.01) -(xtgrad*1.5)
				--threshold
				local t_allu = 0.056*y - 2.98


				------------------------------------
				--Sediment
				--subsurface soils and sands
				--density
				local den_sedi = (den_allu*1.1)
				--threshold
				local t_sedi = 0.057*y - 3.2

				-------------------------------------
				--Checks
				--This is so we know if we placed something.

				local void = true  -- we have yet to set anything
				local nocave = true		--basement rock caves
				local basin = false		--ocean basin


				--------------------------------------------------
				--THE DECISION TREE
				-------------------------------------------------

				-------------------------------
				--Start with Things that must be kept clear of rock etc.
				if den_base > t_base
				or den_soft > t_soft
				or den_allu > t_allu
				or den_sedi > t_sedi then

					----------------------------
					-- Ocean Basin
					-- This is so the oceans aren't a flat 5m deep boring yawn.

					local zab = math.abs(z)
					local inn_terr = 1 - n_terr
					local inn_terr2 = 1 - n_terr2
					local shelfnoi = ((inn_terr ^ 3) * CONOI) -- softens cliffs
					local shelfsl = ((96 + (inn_terr2 *95))*y) - 100 --sets slope
					local bed = SEABED + ((inn_terr2 ^ 3) * (SEABED/2))  --so sea bed is bumpy, with possible isles
					--Are we in the right place for oceans?
					if (xab > (SHELFX + shelfnoi) - shelfsl
					or zab > (SHELFZ + shelfnoi) - shelfsl)
					and y > bed then --avoids  infinitely deepening oceans
						basin = true
					end

					-----------------------------
					--Lakes and rivers.
					--These are put in "manually" as doing it based on noise does not work well for rivers
					--The point of these is:
					-- to bring water to the dry interior, provide access, features of interest, greater altitude variation.
					------------------------------
					--Central Caldera
					--To give a water feature in the middle of the map.
					--define a square which will be the lake, then soften it with noise
					local calr = (300 + (150 * n_terr) + (50 * n_terr2)) * (1 + (y/50))
					local cald = -90 + (47 * n_terr) + (47 * n_terr2)
					if xab < calr
					and zab < calr
					and y > cald then
						basin = true
					end

					-----------------------------
					--caldera island
					local calir = (45 + (15 * n_terr) + (15 * n_terr2)) * (1 - (y/(25 + n_terr2)))
					local calid = -1000 - (250 * n_terr) - (250 * n_terr2)
					if xab < calir
					and zab < calir
					and y > calid
				 	then
						if xab < calir/3
						and zab < calir/3
						and y < -150 + (50 * n_terr2)	--match to calir y cut off
						then
							--we have a lava chamber.
							data[vi] = MISCID.c_lava
							void = false
						else
							--obsidian and ore
							--small chance of minerals from volcanism..
							local roll = math.random(1,200)
							if roll == 1 then
								data[vi] = OREID.c_gold
								void = false
							elseif roll == 2 then
								data[vi] = OREID.c_copp
								void = false
							elseif roll == 3 then
								data[vi] = OREID.c_tin
								void = false
							elseif roll == 4 then
								data[vi] = OREID.c_mese
								void = false
							else
								data[vi] = c_obsid
								void = false
							end
						end
					end

					----------------------------------
					--Random lakes
					for n = 0, num_lakes do
	    				local laked = 25 + ((20 * n_terr) + (8 * n_terr2))
	    				local laker = (140 + (75 * n_terr) + (75 * n_terr2)) * (1 + (y/(55 + (5 * n_terr2))))
	    				if x < lakes[n].x + laker and x > lakes[n].x - laker
						and z < lakes[n].z + laker and z > lakes[n].z - laker
						and t_base > den_base - laked then
						    basin = true
						end

						--Rivers draining them
						if lakes[n].r then
                            local channel = (40 +(n_terr2*30))*math.cos(xab/36)
        					local w = (16 + (n_terr2*7) + (10*xtgrad)) * (1 + (y/(14 - (3*xtgrad))))
        					if z <= lakes[n].z + channel + w
        					and z >= lakes[n].z + channel - w
        					and x > lakes[n].x then
        						basin = true
        					end
						end
					end

                    ----------------------------------
                    --A river running out of the caldera in some direction
                    local cx = (n_terr2*30)*math.cos(xab/42)
                    local cz = (n_terr*30)*math.cos(xab/21)
                    local w = (22 + (n_terr2*9) + (10*xtgrad)) * (1 + (y/(12 - (3*xtgrad))))
                    if x <= cx + w and x >= cx - w and z <= cz + w and z >= cz - w then
                        basin = true
                    end

--[[					----------------------------------
					--a river running bisecting the land East/west
					local channel = (50 +(n_terr2*30))*math.cos(xab/42)
					local w = (22 + (n_terr2*9) + (10*xtgrad)) * (1 + (y/(12 - (3*xtgrad))))
					if z <= channel + w and z >= channel - w then
						basin = true
					end
                    
					-----------------------------------
					--Mirror lake
					--gives four lakes.
					local laker = (140 + (75 * n_terr) + (75 * n_terr2)) * (1 + (y/(55 + (5 * n_terr2))))
					local laked = -25 + (20 * n_terr) + (8 * n_terr2)
					if xab < 5000 + laker and xab > 5000 - laker
					and zab < 15000 + laker and zab > 15000 - laker
					and y > laked then
						basin = true
					end

					---------------------------------
					--Mirror Rivers
					--give four rivers draining the four lakes
					local channel = (40 +(n_terr2*30))*math.cos(xab/36)
					local w = (16 + (n_terr2*7) + (10*xtgrad)) * (1 + (y/(14 - (3*xtgrad))))
					if zab <= 15000 + channel + w
					and zab >= 15000 + channel - w
					and xab > 5000 then
						basin = true
					end
--]]
					-----------------------------------
					--the following we don't want in basins
					--caves... bc they would displace water.
					--rock and ore, for obvious reasons
					if void and not basin then

						----------------------------------
						--Things that block base rock.
						--i.e. caves etc

						--for adding/subtracting from thresholds
						--this is to change cave size with depth
						-- goes from 1 at map top to 0 at y=0, to -1 at map bottom (modified by strength)
						local ybig = ((y/YMAX)*0.2)

						--------------
						--Fissures?
						--to get the snaking plane we need to start by emptying the world..
						nocave = false
						--now our threshold for filling back in the non-cave world
						--if the noise is above this. we have ground...
						--lower the threshold.. smaller cave
						local cav_t1 = BCAVTF - ybig

						--check... can we fill in the non-cave?
						--extra noises break up sheet
						if ab_cave >= cav_t1
						or (ab_cave2 ^ 3) >= cav_t1
						then
							nocave = true
						end

						-----------------
						--Round caves?
						--These use the same noise as fissures, so they become side chambers.
						-- reverse deal from fissures.
						--If the noise is above the threshold we empty out a cave
						-- lower threshold = bigger cave..
						local cav_t2 = BCAVT + ybig

						if ab_cave2 ^ 2 >= cav_t2
						then
							nocave = false
						end


						--Now place rocks
						------------------------
						--Place basement rock
						if den_base > t_base then

							--first do ore, with no regard for caves(we want it inside caves)
							if ore(ab_stra, y, ORET, ybig, n_strata, data, vi, OREID)
							then
								void = false
							--if it wasn't ore and isn't cave now do rock
							elseif nocave then
								--strata splits..
								local thick = 9 + (6*ab_stra)
								local ystrata = math.sin(y/thick)

								--an occassional layer of obsidian around caves
								if (n_cave2 > 0.90 or n_cave > 0.90)
								and ystrata > 0.1 then
									--small chance of minerals from volcanism..
									local roll = math.random(1,1000)
									if roll == 1 then
										data[vi] = OREID.c_gold
										void = false
									elseif roll == 2 then
										data[vi] = OREID.c_copp
										void = false
									elseif roll == 3 then
										data[vi] = OREID.c_tin
										void = false
									elseif roll == 4 then
										data[vi] = OREID.c_mese
										void = false
									else
										data[vi] = c_obsid
										void = false
									end
								--grey stone layer...
								elseif ystrata >= 0 then
									--small chance of some iron
									if math.random(1,1000) == 1 then
										data[vi] = OREID.c_iron
										void = false
									--grey stone
									else
										data[vi] = c_stone
										void = false
									end
								-- red stone layer
								elseif ystrata < 0 then
									data[vi] = c_stone2
									void = false
								--finished with rocks and ores
								end
							--finished with base nocave
							end
						--finished with base layer
						end

						------------------------
						--Place soft rock
						if void then
							if den_soft > t_soft then

								-----------------
								--Caves for soft rock
								local cav_t2 = BCAVT

								if ab_cave2 >= cav_t2
								then
									nocave = false
								end

								if nocave then
									--strata splits..
									local thick = 2 + (6*ab_stra)
									local ystrata = math.sin(y/thick)

									--a little lost base rock...
									--with coal
									if ystrata >= 0.7
									and ystrata <= 0.9
									and n_strata > 0.8 then
										if math.random(1,500) == 1 then
											data[vi] = OREID.c_coal
											void = false
										else
											data[vi] = c_stone
											void = false
										end
									--a little more lost base rock...
									--with rare diamonds and mese
									elseif ystrata <= 0.6
									and ystrata >= 0.4
									and n_strata > 0.9 then
										local roll = math.random(1,3000)
										if roll == 1 then
											data[vi] = OREID.c_diam
											void = false
										elseif roll == 2 then
											data[vi] = OREID.c_mese
											void = false
										else
											data[vi] = c_stone2
											void = false
										end
									-- now the actual soft rock
									elseif ystrata >= 0.33 then
										 data[vi] = c_sandstone
										 void = false
									elseif ystrata <= -0.33 then
										 data[vi] = c_sandstone2
										 void = false
									else
										data[vi] = c_sandstone3
										void = false
									--end of placing soft layer stone
									end
								--done with not soft cave
								end
							--finished soft rock
							end
						end


						--------------------------
						--Stability Check
						-- looks at place below the current node.
						-- For those options that require to be placed on top of something
						--We've yet to see proof it's stable
						local stab = false

						if nodu ~= MISCID.c_air
						--and nodu ~= MISCID.c_ignore
						and nodu ~= MISCID.c_water
						and nodu ~= MISCID.c_river
						then
							--no air, water, or river water... therefore it's stable
							stab = true
						end

						-- the following need to be stable
						if stab then

							--Place alluvium
							if void then
								if den_allu > t_allu and nocave then

									--strata splits..
									local thick = 10 + (50*ab_stra)
									local ystrata = math.sin(y/thick)

									local t1 = 0.4
									local t2 = 0.8

									if ystrata >= 0
									and ystrata < t1 then
										data[vi] = SEDID.c_gravel
										void = false
									elseif ystrata >= t1
									and ystrata < t2 then
										data[vi] = SEDID.c_sand2
										void = false
									elseif ystrata < 0
									and ystrata > -t1 then
										data[vi] = c_dsand
										void = false
									elseif ystrata <= -t1
									and ystrata > -t2 then
										data[vi] = SEDID.c_sand
										void = false
									elseif ystrata <= -t2
									or ystrata >= t2 then
										data[vi] = SEDID.c_clay
										void = false
									end
								end
							--end of alluvium
							end

							---------------------------
							--Subsurface Sediments
							--these are done to match the location

							if void then
								if den_sedi > t_sedi and nocave then
									--non-basin seas
									if y < SEA then
										data[vi] = SEDID.c_sand
										sedi = true
										void = false
									else
										--We are above sea level...	now we need to know climate.
										local temp
										local hum
										temp, hum = climate(x, z, y, n_terr, n_terr2)

										--We have some fiddly coastal stuff.
										--on a node, that is sea surface or one above
										if (y == SEA + 1 or y == SEA) then
											--a humid place? will make swamps
											if hum > 67  then  --boundary for wet climates
												--let's place a swampy mire
												swamp(data, vi, 100, SEDID.c_dirt, MISCID.c_river)
												void = false
											--wasn't humid . Do dunes
											else
												data[vi] = SEDID.c_sand
												void = false
											end
										--lets do Temp/humidity combos
										--freezing cold
										elseif temp < 5 then
											swamp(data, vi, 3, SEDID.c_gravel, c_ice)
											void = false
										--permafrost
										elseif hum > 90 and temp < 16 then
											swamp(data, vi, 50, SEDID.c_dirt, c_ice)
											void = false
										-- hot arid
										elseif temp > 67 and hum < 33 then
											data[vi] = c_dsand
											void = false
										--wasn't one of the weirdos. Must be dirt.
										else
											data[vi] = SEDID.c_dirt
											sedi = true
											void = false
										--end of climate based sediments
										end
									--done with if sea etc..
									end
								end
							--finished sediments
							end
						--done with stables.
						end

					--finished with not in basin
					end
				--finished with things below rock thresholds.
				end

				--------------------------------
				--Skins

				if void then
					--ocean
					if y < SEA then
						if basin then
							--cover basin floors with gravel, then clay, then sand.
							if nodu ~= MISCID.c_water
							and nodu ~= SEDID.c_gravel
							and nodu ~= SEDID.c_sand2
							and nodu ~= SEDID.c_clay
							and nodu ~= MISCID.c_ignore then
								data[vi] = SEDID.c_gravel
								sedi = true
								void = false
							elseif nodu == SEDID.c_gravel then
								data[vi] = SEDID.c_clay
								sedi = true
								void = false
							elseif nodu == SEDID.c_clay then
								data[vi] = SEDID.c_sand2
								sedi = true
								void = false
							end
						--give some stuff for caves...
						--a little gravel and sand, and water. but not everywhere
						elseif not nocave then
							if nodu == c_stone then
								if n_terr > 0 then
									data[vi] = SEDID.c_gravel
									sedi = true
									void = false
								end
								if n_terr > 0.9 then
									swamp(data, vi, 50, SEDID.c_sand2, MISCID.c_river)
									sedi = true
									void = false
								end
							elseif nodu == c_stone2 then
							 	if n_terr2 > 0 then
									data[vi] = SEDID.c_sand
									sedi = true
									void = false
								end
								if n_terr2 > 0.9 then
									swamp(data, vi, 50, SEDID.c_clay, MISCID.c_river)
									sedi = true
									void = false
								end
							end
						--just regular seabed?
						elseif nodu ~= SEDID.c_sand2 and nodu ~= MISCID.c_water then
							data[vi] = SEDID.c_sand2
							sedi = true
							void = false
						end
					else
						--what we have left is skinning the land surface.
						--now we need climate data.
						local temp
						local hum
						temp, hum = climate(x, z, y, n_terr, n_terr2)

						--Check if stable below
						--doing this rather than stab, becasue that allows stacking
						--also allows it to cover unwanted things (e.g. plants)
						local can_sur = false
						if (nodu == c_ice
						or nodu == SEDID.c_sand2
						or nodu == c_dsand
						or nodu == SEDID.c_sand
						or nodu == SEDID.c_dirt
						or nodu == c_sandstone
						or nodu == c_sandstone2
						or nodu == c_sandstone3
						or nodu == c_stone
						or nodu == c_stone2
						or nodu == SEDID.c_gravel
						or nodu == SEDID.c_clay
						or nodu == OREID.c_coal
						or nodu == OREID.c_iron
						or nodu == OREID.c_copp
						or nodu == OREID.c_tin
						or nodu == OREID.c_gold
						or nodu == c_obsid
						or nodu == c_coral)
						then
							can_sur = true
						end

						--is it stable?
						-- ( remember to ban self stacking where needed..
						--i.e. it is on the can_sur list )
						-- bearing in mind we don't know yet about the ignore nodes.
						if can_sur and nodu ~= MISCID.c_ignore and nocave then
							if xab < 500 + math.random(-100, 100) then
								if nodu ~= c_ice and nodu ~= c_dsand then
									data[vi] = c_ice
									void = false
								else
									data[vi] = c_snowbl
									void = false
								end
							--Going through Temp/humidity combos
							elseif temp > 67  then
								--hot and wet = rainforest
								if hum > 67 then
									--what's the coastline like?
									if y >= SEA -1 and y < SEA + 3 then
										--swamp
										swamp(data, vi, 90, c_dirtlit, MISCID.c_river)
										void = false
									--not at coast
									elseif y >= SEA + 3 then
										data[vi] = c_dirtlit
										void = false
									end
								--hot and moist = savanna/tropical seasonal forest
								elseif hum > 33 then
									--what's the coastline like?
									if y >= SEA-1 and y < SEA + 3 and nodu ~= c_dsand then
										--sandy desert
										data[vi] = c_dsand
										void = false
									--not at coast
									elseif y >= SEA + 3 then
										--adding green ground for interest.
										if y < (10 + math.random(-3,3)) then
											data[vi] = c_dirtgr
											void = false
										else
											data[vi] = c_dirtdgr
											void = false
										end
									end
								--hot and dry= desert
								elseif nodu ~= c_dsand then
									--what's the coastline like? --same as the rest!
									--sandy desert
									data[vi] = c_dsand
									void = false
								--End of Tropics
								end
							--Temperate
							elseif temp > 33  then
								--temperate and wet=--temperate rainforest
								if hum > 67 then
									--what's the coastline like?
									if y >= SEA-1 and y < SEA + 3 then
										--swamp
										swamp(data, vi, 90, c_dirtlit, MISCID.c_river)
										void = false
										--not at coast
									elseif y >= SEA + 3 then
										data[vi] = c_dirtgr
										void = false
									end

								--temperate and moist= -- seasonal forest
								elseif hum > 33 then
									--the coast is...?
									if y >= SEA-1 and y < SEA + 3 and nodu ~= SEDID.c_sand then
										--sandy
										data[vi] = SEDID.c_sand
										void = false
									--not at coast
								elseif y >= SEA + 3 then
										data[vi] = c_dirtgr
										void = false
									end
								--temperate and dry=-- grassland
								else
									----the coast is...?
									if y >= SEA-1 and y < SEA + 3 and nodu ~= SEDID.c_sand then
										--sandy
										data[vi] = SEDID.c_sand
										void = false
									--not at coast
									elseif y >= SEA + 3 then
										--adding some very rare greener ground for interest.
										if y < (10 + math.random(0,3))
										and math.random(0,50) == 1 then
												data[vi] = c_dirtgr
												void = false
										else
											data[vi] = c_dirtdgr
											void = false
										end
									end
								--End of Temperate Zone
								end
							--Frozen... we don't care how wet you are when that cold
							elseif temp < 7 then
								-- ice
								if y >= SEA-1 and y < SEA + 3 and nodu ~= c_ice then
									--swamp
									swamp(data, vi, 15, c_ice, MISCID.c_river)
									void = false
								--not at coast
							elseif y >= SEA + 3 and  nodu ~= c_snowbl then
									data[vi] = c_snowbl
									void = false
								end
							--Okay...merely cold
							--cold and wet=-- boreal swamp
							elseif hum > 67 and nodu ~= c_ice then
								--Coast?
								if y >= SEA-1 and y < SEA + 3 then
									--swamp...no actual water.. frozen. This happens on mountains. Permafrost
									swamp(data, vi, 25, c_dirtsno, c_ice)
									void = false
								--not at coast
								elseif y >= SEA + 3 then
									swamp(data, vi, 35, c_dirtsno, c_ice)
									void = false
								end
							--cold and moist=-- boreal forest
							elseif hum > 33 then
								--cold and moist=-- boreal forest
								if y >= SEA-1 and y < SEA + 3 and nodu ~= SEDID.c_gravel then
									swamp(data, vi, 50, SEDID.c_gravel, c_ice)
									void = false
								--not at coast
								elseif y >= SEA + 3 then
									data[vi] = c_dirtsno
									void = false
								end
							--cold and dry=-- tundra
							elseif nodu ~= SEDID.c_gravel
							and nodu ~= c_ice
							and nodu ~= c_dsand
							then
								data[vi] = SEDID.c_gravel
								void = false
							--End of Cold zone
							end
						--end of places that can be surfaced by "skin"
						end
					--end of cave, oceans, skins line.
					end
				--end of voids
				end


				--Fill the oceans and deeps
				if y < SEA and void then
					if nocave then
						data[vi] = MISCID.c_water
						void = false
					else
						local magdepth = MAXMAG + (n_terr * 10)
						if y < magdepth then
							--we have lava.
							data[vi] = MISCID.c_lava
							void = false
						end
					end
				end





				-----------------------------------------------
				--Housekeeping before we exit the loop
				-- Increment noise index.
				nixyz = nixyz + 1
				nixz = nixz + 1

				-- Increment voxelmanip index along x row.
			 	-- The voxelmanip index increases by 1 when
			 	-- moving by 1 node in the +x direction.
				vi = vi + 1
			end
			nixz = nixz - sidelen
		end
		nixz = nixz + sidelen
	end
	--We have left the loop!


	-----------------------------------
	--LOOP TWO
	--For decorations etc

	nixz = 1

	for z = minp.z, maxp.z do
	 for y = minp.y, maxp.y do
		 -- Voxelmanip index for the flat array of content IDs.
		 -- Initialise to first node in this x row.
		 local vi = area:index(minp.x, y, z)
		 for x = minp.x, maxp.x do



			 ---------------------------------
			 --We aren't putting things deep underwater/ground. So let's start there.
			 --unfortunatly we can't distinguish caves anymore :-( so this will have to do.
			 if y > SEA then

				 --we only go ahead if it's empty
				 if data[vi] == MISCID.c_air then

					 --Here we decide if it is on top of the right stuff
					 local nodu  = data[(vi - ystridevm)]
					 --check off against a list of any possible usable supporting nodes
					 --this is instead of merely "if stab" so they don't get stuck ontop of themselves
					 local plant = false
					 if nodu == c_dirtlit
					 or nodu == SEDID.c_dirt
					 or nodu == c_dirtgr
					 or nodu == c_dirtdgr
					 or nodu == c_dirtsno
					 or nodu == SEDID.c_sand
					 or nodu == c_dsand
					 or nodu == SEDID.c_sand2
					 or nodu == SEDID.c_clay
					 or nodu == SEDID.c_gravel
					 or nodu == MISCID.c_river then
						 plant = true
					 end
					 --do we have a viable stable node?
					 if plant then
						 --We need these again
						 local n_terr  = nvals_terrain[nixz]
						 local n_terr2  = nvals_terrain[nixz]

						 --get climate data
						 local temp
						 local hum
						 temp, hum = climate(x, z, y, n_terr, n_terr2)

						 -- pack it in a table, for plants API
						 local conditions = {
																 temp = temp,
																 humidity = hum,
																 nodu = nodu
																 }
						 local pos = {x = x, y = y, z = z}

						 --call the api... this will create plant
							 mgtec.choose_generate_plant(conditions, pos, data, area, vi)

					 --done with plantables
					 end
				 --done with void areas.
				 end
			 --end of not underwater stuff.
			 end


			 ---------------------------
			 --Final Housekeeping
			 -- Increment noise index.
			nixz = nixz + 1
			 -- Increment voxelmanip index along x row.
			vi = vi + 1
		end
		nixz = nixz - sidelen
	end
	nixz = nixz + sidelen
end
	--we have left loop 2...probably isn't the quickest solution, but it works.


	----------------------------------------------------
	--Write to the the Map.

	-- After processing, write content ID data back to the voxelmanip.
	vm:set_data(data)
	-- Calculate lighting for what has been created.
	vm:calc_lighting()
	-- Write what has been created to the world.
	vm:write_to_map()
	-- Liquid nodes were placed so set them flowing.
	vm:update_liquids()

	--------------------------------------------------
	-- Print generation time of this mapchunk.
	local chugent = math.ceil((os.clock() - t0) * 1000)
	print ("[mg_tectonic] Mapchunk generation time " .. chugent .. " ms")

--End of Generation
end)

--===============================================================





-----------------------------------------------------------
--SPAWN PLAYER

--Start on top of the island
function spawnplayer(player)
    local pos = {x = 0, y = 30, z = 0}
	player:setpos(pos)
	-- Get the inventory of the player
	local inventory = player:get_inventory()
	--give them some gear to help escape the bleak mountains
	--[[
	inventory:add_item("main", "default:pick_steel")
	inventory:add_item("main", "default:torch 10")
	inventory:add_item("main", "default:ladder 20")
	inventory:add_item("main", "default:apple 5")--]]
	inventory:add_item("main", "boats:boat")

end


-----------------------------------------------------------
minetest.register_on_newplayer(function(player)
	spawnplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	spawnplayer(player)
end)
