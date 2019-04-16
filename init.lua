---============================================================================
--MG TECTONIC
--By Dokimi

--A naturalistic mapgen.
--This is the main mapgen code.

--=============================================================================
--PRELIMINARIES
mgtec = {}
local mod_storage = minetest.get_mod_storage()

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
local YMAX = 31000
local YMIN = -31000

 --sealevel
local SEA = 0

--height of lava
local MAXMAG = -15000

-------------------
--BASE LAYER:
-- Wave Roll Size: i.e Period
--Controls distance between ranges, and thickness.
--This is the period at the map centre. Grows to double at map edges
local XRS = 650 --150

--Where does the continental shelf end?
local SHELFX = 28000
local SHELFZ = 28000
--How deep are the oceans?
local SEABED = -15000
--Strength of noise on continental shelf boundaries lines
local CONOI = 2000

--Cave size.
--Base cave threshold for fissures
local BCAVTF = 0.006
--Base cave threshold for caves
local BCAVT = 0.999

--Ore threshold
local ORET = 0.97

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
function climate(x, z, y, n_terr, n_terr2)
	if n_terr == nil then -- So it can be used outside of the loop
		n_terr = nobj_terr_i:get2d({x=x,y=z})
	end
	if n_terr2 == nil then
		n_terr2 = nobj_terr2_i:get2d({x = x, y = z})
	end
	--east = + x, west = - x, south = -z, n = + z
	--Climate is decided by:
	-- -Ranges: rains come from the west (-x), rise over the ranges dumping cooling rain, descending hot and dry (east +x)
	-- - Altitude: it's cold up there.
	-- - Latitude: hot north, cold south

	--blending
	local blend = (((n_terr2 + n_terr)/2) * math.random(-4, 10))

	--We are Southern Hemisphererers here!
	--decreasing temp from max z to min z (latitude) (from 100 to 0 i.e north desert to south ice)
	-- linear increase, intercept at 50
	local temp_z = (0.00163*z) + 50 - blend

	--Fohn Winds! They are hot! The East Coast gets a temp boost

	-- no Fohn? Westies are controlled by z
	local temp_x = 0

  local lon_blend = math.random(-20,20) + n_terr * 200 --offset east-west border with some noise

	-- Easterners?
	if x > lon_blend then
		-- adds + 20 at centre of map, declines to zero
		temp_x = (-0.00065*x) + 20 - blend
	end


	--Mountain tops ought to be cold!
	--decreasing temp with hieght...and combine previous two as baseline
	local temp = (-0.095*y) + temp_z + temp_x - blend

	--blur edges
	temp = temp + math.random(-4, 4)

	---------------
	--what's the humidity? Rainshadow!
	--decreasing humid from far x to x= 0,(rain shadow)

	--if in doubt ...
	local hum = 50 + blend

	----poitive, east coast. Dry inland
	--linear increase,
	if x > lon_blend then
		hum = (0.00161*x) + blend
	--increasing humid from far x to x= 0,(rain shadow)
	else  --negative , west coast. Wet inland
		--linear increase,
		hum = (0.00161*x) + 100 + blend
	end

	--humidity transition zone East/west.
	--[[--not right at all!!!
	--  make wetter
	if x < (100 + lon_blend) and x > lon_blend then
		hum = hum + 60
	-- make drier
	elseif x > (-100 + lon_blend) and x < lon_blend then
		hum = hum -60
	--little wetter
	elseif (200 + lon_blend) and x > lon_blend then
		hum = hum + 40
	-- little drier
	elseif x > (-200 + lon_blend) and x < lon_blend then
			hum = hum -40
	--tiny wetter
	elseif (300 + lon_blend) and x > lon_blend then
			hum = hum + 15
		-- tiny drier
	elseif x > (-300 + lon_blend) and x < lon_blend then
			hum = hum -15
	end]]

	--give a boost to low altitude.. (they tend to be near water)
	--and to hill tops (catch rain)
	if y < 15 + math.random(-4, 4) or y > 300 + math.random(-5, 5) then
		hum = hum + (hum*0.05)
		--force snow capped peaks...
		if y > 700 + math.random(-30, 5) then
			hum = hum + (hum * 0.55) + 30
			temp = temp - 30
		elseif y > 600 + math.random(-5, 5) then
			hum = hum + (hum * 0.55)
		elseif y > 500 + math.random(-5, 5) then
			hum = hum + (hum * 0.35)
		elseif y > 400 + math.random(-5, 5) then
			hum = hum + (hum*0.15)
		end
	end

	--disturbance regime
	local distu = math.abs(((n_terr + n_terr2)*100)/2) + blend

--some places get disturbed more often
	if y > 300 + math.random(-5, 5) then
		distu = distu + (hum*0.10)
	end


	--calm areas hold water.
	if distu <10 then
		hum = hum + (hum*0.15)
	--rough areas hold less moisture
	elseif distu > 60 then
		hum = hum - (hum*0.05)
	elseif distu > 70 then
		hum = hum - (hum*0.15)
	elseif distu > 80 then
		hum = hum - (hum*0.20)
	elseif distu > 90 then
		hum = hum - (hum*0.25)
	elseif distu > 98 then
		hum = hum - (hum*0.75)
	end

	--lakes
	--[[
	if numlakes ~= nil and numlakes ~= 0 then
		for i = 0, numlakes do
			laker = (190 + (75 * n_terr) + (75 * n_terr2)) * (1 + (y/(55 + (5 * n_terr2))))
			if x < lakes[n].x + laker and x > lakes[n].x - laker
			and z < lakes[n].z + laker and z > lakes[n].z - laker then
				hum = hum + 0.15 * (math.abs(x - lakes[n].x) + math.abs(z - lakes[n].z))
			end
		end
	end
	]]

	hum = hum + math.random(-4, 4)

return temp, hum, distu
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
local c_coralb = minetest.get_content_id("default:coral_brown")
local c_coralo = minetest.get_content_id("default:coral_orange")



--sediments
local SEDID = {
 			c_gravel = minetest.get_content_id("default:gravel"),
 			c_clay = minetest.get_content_id("default:clay"),
 			c_sand = minetest.get_content_id("default:sand"),
 			c_sand2 = minetest.get_content_id("default:silver_sand"),
 			c_dirt = minetest.get_content_id("default:dirt"),
			c_perma = minetest.get_content_id("default:permafrost"),
}

--surfaces
local c_dirtgr = minetest.get_content_id("default:dirt_with_grass")
local c_dirtdgr = minetest.get_content_id("default:dirt_with_dry_grass")
local c_dirtsno = minetest.get_content_id("default:dirt_with_snow")
local c_dirtlit = minetest.get_content_id("default:dirt_with_rainforest_litter")
local c_dirtconlit = minetest.get_content_id("default:dirt_with_coniferous_litter")
local c_snowbl = minetest.get_content_id("default:snowblock")
local c_ice = minetest.get_content_id("default:ice")
local c_dsand = minetest.get_content_id("default:desert_sand")
local c_permamoss = minetest.get_content_id("default:permafrost_with_moss")
local c_permastone = minetest.get_content_id("default:permafrost_with_stones")


--Miscellaneous

local MISCID = {
		c_water = minetest.get_content_id("default:water_source"),
		c_river = minetest.get_content_id("default:river_water_source"),
		c_air = minetest.get_content_id("air"),
		c_ignore = minetest.get_content_id("ignore"),
		c_lava = minetest.get_content_id("default:lava_source"),
		c_kelpsand = minetest.get_content_id("default:sand_with_kelp"),
		c_coral_cyan = minetest.get_content_id("default:coral_cyan"),
		c_coral_green = minetest.get_content_id("default:coral_green"),
		c_coral_pink = minetest.get_content_id("default:coral_pink"),

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
   spread = {x = 1052, y = 1280, z = 1280},
   seed = 110013,
   octaves = 5,
   persist = 0.5,
   lacunarity = 2,
}

-- 2D Soft rock Terrain.
--controls: soft rock layer variation.
local np_terrain2 = {
   offset = 0,
   scale = 1,
   spread = {x = 288, y = 288, z = 288},
   seed = 5938033,
   octaves = 5,
   persist = 0.5,
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
-- For getting individual n_terr values
nobj_terr_i = nil
nobj_terr2_i = nil

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
-- param2 data
local data2 = {}

--=============================================================================
-- GENERATION

local numlakes = nil
local lakes = nil
local spawnpoint = {x = 0, z = 0}

minetest.register_on_mapgen_init(function(mapgen_params)
	math.randomseed(mapgen_params.seed)
  spawnpoint = {x = math.random(-18000, 18000), z = math.random(-18000, 18000)}


	-- some things need to be random, but stay constant throughout the loop

	-- number of lakes
	if lakes == nil then
		num_lakes = math.random(21,28)
		lakes = {}
		for i = 0, num_lakes do
			--keep back from "shelf" as the coastline is actually much further back
		    lakes[i] = {x = math.random(-10000,10000), z = math.random(-12000,12000), r = math.random(0,5)}
				--save location for bug checking
				mod_storage:set_int("Lake"..i.."x", lakes[i].x)
				mod_storage:set_int("Lake"..i.."z", lakes[i].z)
				mod_storage:set_int("Lake"..i.."river", lakes[i].r)
		end
	end
end)

table.insert(minetest.registered_on_generateds, 1, (function(minp, maxp, seed)
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
	nobj_terr_i = nobj_terr_i or minetest.get_perlin(np_terrain.seed, np_terrain.octaves, np_terrain.persist, np_terrain.scale)
	nobj_terr2_i = nobj_terr_i or minetest.get_perlin(np_terrain2.seed, np_terrain2.octaves, np_terrain2.persist, np_terrain2.scale)

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
	vm:get_param2_data(data2)

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
				local xwav = (whs*math.cos(x/x_roll))    -- north south wave (main ranges)
				--local xwav = (whs*math.sin(x/x_roll))    -- north south wave (main ranges)


				--Base Wave Density.
				--This is checked against the threshold to decide where the base layer can go.
				--the wave controls the landscape folding i.e. the bunching up caused by the plates hitting eachother.
				--variation along this fold is caused by erosion, so is much more random...
				--therefore it is contolled by noise (rather than another wave which is too regular)

				--cubing/squaring flattens out the middle range,
				--for the wave that gives it a flat shelf at sea level.
				--for the noise it mellows part of it out, so it adds mainly extreme peaks and dips
				--mup lowers the landscape at the edges (ocean), otherwise the flattening of height would lead to endless plains

				local den_base = ((xwav ^ 3)*1.2) + (mup*1.06) + ((n_terr ^2) * whs + (n_terr2*0.1))


				---Base Threshold
				local t_base = 0.0018*y



				-------------------------------------
				--Soft Rock
				--layered on top of the base layer.
				--soft sandstone... a good enough stand in for easily erobable rocks
				--creates regions of soft rock on top of the base layer in lowlands

				--density
					local den_soft = (den_base*1.05) + (n_terr2 ^3) -(xtgrad*0.2)
					--threshold
					local t_soft = 0.02*y


					------------------------------------
					--Alluvium
					--eroded rock etc, deposited on lowlands

					--density
					local den_allu = (den_soft*1.002)
					--threshold
					local t_allu = 0.03*y -0.1


					------------------------------------
					--Sediment
					--subsurface soils and sands
					--density
					local den_sedi = (den_allu*1.01)
					--threshold
					local t_sedi = 0.03*y-0.2


				-------------------------------------
				--Checks
				--This is so we know if we placed something.

				local void = true  -- we have yet to set anything
				local nocave = true		--basement rock caves
				local basin = false		--ocean basin
				local river_basin = false		--river basin



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

					local shelfnoi = (n_terr * n_terr2) * CONOI -- softens cliffs
					local shelfsl = (math.abs((n_terr*10) + (n_terr2*2))) * (0.3*y)*20  --sets slope
					local bed = SEABED + ((n_terr^2)*SEABED)
					--Are we in the right place for oceans?
					if (xab > ((SHELFX + shelfnoi) - shelfsl)
					or zab > ((SHELFZ + shelfnoi) - shelfsl))
					and y >= bed  then --avoids  infinitely deepening oceans
						basin = true
					end

					-----------------------------
					--Lakes and rivers.
					--These are put in "manually" as doing it based on noise does not work well for rivers
					--The point of these is:
					-- to bring water to the dry interior, provide access, features of interest, greater altitude variation.
					------------------------------

					--[[
					--Central Caldera
					--To give a water feature in the middle of the map.
					--define a square which will be the lake, then soften it with noise
					local calr = (350 + (150 * n_terr) + (50 * n_terr2)) * (1 + (y/50))
					local cald = -90 + (47 * n_terr) + (47 * n_terr2)
					if xab < calr
					and zab < calr
					and y > cald then
						basin = true
					end

					-----------------------------
					--caldera island
					local calir = (55 + (25 * n_terr) + (25 * n_terr2)) * (1 - (y/(25 + n_terr2)))
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
--]]

					----------------------------------
					--Random lakes
					if not basin and not river_basin then
						for n = 0, num_lakes do
		    				local laked = 25 + ((20 * n_terr) + (8 * n_terr2))
		    				local laker = (160 + (75 * n_terr) + (75 * n_terr2)) * (1 + (y/(55 + (5 * n_terr2))))
		    				if x < lakes[n].x + laker and x > lakes[n].x - laker
							and z < lakes[n].z + laker and z > lakes[n].z - laker
							and t_base > den_base - laked then
							    river_basin = true
							end

							--Rivers draining them
							if lakes[n].r <2 then
	                  --local channel = (40 +(n_terr2*30))*math.cos(xab/36)
	        					--local w = (16 + (n_terr2*7) + (10*xtgrad)) * (1 + (y/(14 - (3*xtgrad))))
										local channel = (17 +(n_terr2*40))*math.cos(x/36)
	        					local w = ((6 + (0.0003*xab)) + (math.abs(n_terr2*(10+ (0.0003*xab))))) * (1 + (y/8))
	        					if z <= lakes[n].z + channel + w
	        					and z >= lakes[n].z + channel - w
	        					and x > math.abs(lakes[n].x) then
	        						river_basin = true
	        					end
							end
						end
					end
--[[
                    ----------------------------------
                    --A river running out of the caldera in some direction
                    local cx = (n_terr2*30)*math.cos(xab/42)
                    local cz = (n_terr*30)*math.cos(xab/21)
                    local w = (22 + (n_terr2*9) + (10*xtgrad)) * (1 + (y/(12 - (3*xtgrad))))
                    if x <= cx + w and x >= cx - w and z <= cz + w and z >= cz - w then
                        basin = true
                    end

					----------------------------------
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
					if void and not basin and not river_basin then

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
						and nodu ~= c_ice
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
									if y < SEA-1 then
										data[vi] = SEDID.c_sand
										void = false
									else
										--We are above sea level...	now we need to know climate.
										local temp
										local hum
										local distu
										temp, hum, distu = climate(x, z, y, n_terr, n_terr2)

										--We have some fiddly coastal stuff.
										--on a node, that is sea surface or one above
										if y <= SEA + 1 and y >= SEA-1 then
											--a humid place? will make swamps
											if hum > 80  then  --boundary for swamp
												--let's place a swampy mire
												swamp(data, vi, 50, SEDID.c_clay, MISCID.c_river)
												void = false
											elseif hum > 60  then -- less swampy
												swamp(data, vi, 150, SEDID.c_clay, MISCID.c_river)
												void = false
											--wasn't humid . Do dunes
											else
												data[vi] = SEDID.c_sand
												void = false
											end
										-- Not coastal so...
										--lets do Temp/humidity combos
										--polar
									elseif temp < 20 then
											--'Swamp' Polar.. all ice
											if hum > 85 then
												data[vi] = c_ice
												void = false
											-- damp polar... some ice and permafrost
											elseif hum > 60 then
												swamp(data, vi, 50, SEDID.c_perma, c_ice)
												void = false
											-- too dry
											else
												data[vi] = SEDID.c_gravel
												void = false
											end
										--Non polar (not frozen) Swamps
										elseif hum > 80 then
											--disturbed swamps
											if distu > 50 then
												swamp(data, vi, 150, SEDID.c_gravel, MISCID.c_river)
												void = false
											--stable swamps
											else
												swamp(data, vi, 100, SEDID.c_clay, MISCID.c_river)
												void = false
											end
										-- Nonpolar arid
										elseif hum < 20 then
											--sand dunes...?
											data[vi] = c_dsand
											void = false
										--wasn't one of the weirdos. Must be dirt.
										else
											data[vi] = SEDID.c_dirt
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


				if void and nodu ~= nil and nodu ~= MISCID.c_ignore then
					--now we need climate data.
					local temp
					local hum
					local distu
					temp, hum, distu = climate(x, z, y, n_terr, n_terr2)

					--ocean
					if y <= SEA-1 and (basin == true or river_basin == true) then
						--floating ice
						if (nodu == MISCID.c_water or nodu ~= MISCID.c_river or nodu == c_ice) and temp < 28 and distu > 5 and distu <40 and y == SEA-1 then
							data[vi] = c_ice
							void = false
							--seafloor
						elseif nodu ~= MISCID.c_water
						and nodu ~= MISCID.c_river
						and nodu ~= c_coralo
						and nodu ~= c_coralb
						and nodu ~= MISCID.c_coral_green
						and nodu ~= MISCID.c_coral_pink
						and nodu ~= MISCID.c_coral_cyan
						and nodu ~= MISCID.c_kelpsand
						  then
							--rooted flora: low disturbance,
							if not river_basin and distu > 3 and distu < 15 then
								--Coral: warm, shallow... allow stacking coral
								if temp > 70 and y <= SEA-2 and y > SEA - 10 then
									local c = math.random(1,21)
									if c <= 1 then
										data[vi] = MISCID.c_water
										void = false
									elseif c <= 6 then
										data[vi] = c_coralb
										void = false
									elseif c <= 11 then
										data[vi] = c_coralo
										void = false
									--rooted
									elseif c <= 13 then
										data[vi] = MISCID.c_coral_green
										void = false
									elseif c <= 15 then
										data[vi] = MISCID.c_coral_pink
										void = false
									elseif c <= 17 then
										data[vi] = MISCID.c_coral_cyan
										void = false
									else
										data[vi] = c_coral
										void = false
									end
								--kelp
							 elseif temp < 50 and y <= SEA-7 and y > SEA - 25 then
									data[vi] = MISCID.c_kelpsand
									void = false
								end
							--low disturbance do fine sediment
							elseif distu < 5 and nodu ~= SEDID.c_clay and nodu ~= SEDID.c_sand2 and nodu ~= c_coral and nodu ~= c_ice then
								data[vi] = SEDID.c_clay
								void = false
							-- volcanic if rough
							elseif distu > 95 and nodu ~= c_ice then
								local c = math.random(1,10)
								if c > 4 then
									data[vi] = c_obsid
									void = false
								else
									data[vi] = MISCID.c_water
									void = false
								end
							--add sand if above sandstone or other sand
							elseif nodu == c_sandstone
							or nodu == c_sandstone2
							or nodu == c_sandstone3
							or nodu == SEDID.c_sand
							or nodu == c_dsand
							then
								data[vi] = SEDID.c_sand2
								void = false
							--add gravel if above stone
							elseif nodu == c_stone
							or nodu == c_stone2
							or nodu == OREID.c_coal
							or nodu == OREID.c_iron
							or nodu == OREID.c_copp
							or nodu == OREID.c_tin then
								data[vi] = SEDID.c_gravel
								void = false
							end
						end
					end

					--give some stuff for caves...
					--a little gravel and sand, and water. but not everywhere
					if not nocave then
						--only place on stone
						if nodu == c_stone
						or nodu == c_stone2
						or nodu == c_sandstone
						or nodu == c_sandstone2
						or nodu == c_sandstone3  then
							-- in disturbed areas
							if distu > 70 then
								if distu > 99 and y > MAXMAG then
									swamp(data, vi, 40, c_obsid, MISCID.c_lava)
									void = false
								else
									data[vi] = SEDID.c_gravel
									void = false
								end
							--water seep in stable points
						  elseif distu < 40 then
								if hum > 60 then
									swamp(data, vi, 50, SEDID.c_clay, MISCID.c_river)
									void = false
								elseif distu < 10 then
									swamp(data, vi, 150, SEDID.c_gravel, MISCID.c_river)
									void = false
								end
							--ice in cold..
						  elseif temp < 3 then
								data[vi] = c_ice
								void = false
							-- random sand
							elseif n_terr2 > 0 then
								data[vi] = SEDID.c_sand2
								void = false
							end
						end
					end

					--what we have left is skinning the land SURFACE.
					--Check if stable below... all the stuff okay with skinning for most things.
					--doing this rather than stab, becasue that allows stacking
					--also allows it to cover unwanted things (e.g. plants)
					local can_sur = false
					if (nodu == c_ice
					or nodu == SEDID.c_sand2
					or nodu == c_dsand
					or nodu == SEDID.c_sand
					or nodu == SEDID.c_dirt
					or nodu == SEDID.c_perma
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
					--or nodu == c_obsid
					or nodu == c_coral)
					then
						can_sur = true
					end

					-- ( remember to ban self stacking where needed..
					--i.e. it is on the can_sur list )
					-- bearing in mind we don't know yet about the ignore nodes.
					if can_sur
					and nodu ~= MISCID.c_ignore
					and nocave
					and y >= SEA then

						--coast

						if y <= SEA + (3*ab_stra) then

							--don't cover coral or own sediments
							if nodu ~= c_coral
							and nodu ~= c_coralb
							and nodu ~= c_coralo
							and nodu ~= SEDID.c_clay
							and nodu ~= SEDID.c_sand
							and nodu ~= SEDID.c_sand2
							--and nodu ~= SEDID.c_dirt
							and nodu ~= SEDID.c_gravel
							and nodu ~= c_ice
							then

								--Swamps
								if hum > 60
								then
									--coast super swampy..
									if hum > 80 then
										--frozen
										--icesheet
										if temp < 3 then
											data[vi] = c_ice
											void = false
											--permafrost
										elseif temp <8 then
											--disturbance gives stones.
											if distu < 50 then
												swamp(data, vi, 5, c_permamoss, c_ice)
												void = false
											else
												swamp(data, vi, 5, c_permastone, c_ice)
												void = false
											end
											--cold
										elseif temp <30 then
											swamp(data, vi, 5, c_dirtsno, MISCID.c_river)
											void = false
											--muddy
										else
											swamp(data, vi, 3, SEDID.c_clay, MISCID.c_river)
											void = false
										end
										--coast swampy..
									elseif hum > 60 then
										--frozen
										--icesheet
										if temp < 3 then
											data[vi] = c_ice
											void = false
											--permafrost
										elseif temp <8 then
											--disturbance gives stones.
											if distu < 50 then
												swamp(data, vi, 25, c_permamoss, c_ice)
												void = false
											else
												swamp(data, vi, 25, c_permastone, c_ice)
												void = false
											end
											--cold
										elseif temp <30 then
											swamp(data, vi, 10, c_dirtsno, MISCID.c_river)
											void = false
											--muddy
										else
											swamp(data, vi, 5, SEDID.c_clay, MISCID.c_river)
											void = false
										end
									end
									--frozen
								elseif temp < 5 and hum > 5 then
									data[vi] = c_ice
									void = false
								--muddy bank
								elseif distu < 5 then
									--eroded bank
									local c = math.random(1,10)
									if c > 3 then
										data[vi] = SEDID.c_clay
										void = false
									else
										data[vi] = SEDID.c_sand
										void = false
									end
								--sandy beach
								elseif distu < 40 then
									data[vi] = SEDID.c_sand
									void = false
								--gravel beach...
								elseif distu < 60 then
									data[vi] = SEDID.c_gravel
									void = false
								--rocky soft...
								elseif distu < 90 then
									data[vi] = c_sandstone2
									void = false
								--rocky...
								elseif distu < 95 then
									data[vi] = c_stone
									void = false
								-- rocky volcanic..
								else
									data[vi] = c_obsid
									void = false
								end
							end

						--Frozen Lands
						elseif temp <15 then
							--don't cover own sediments
							if nodu ~= c_snowbl
							then
								--frozen ice stacks chance
								if temp <3 and math.random(1,6) > 5 then
									data[vi] = c_ice
									void = false
									--frozen ice non-stacking
								elseif temp <6 and nodu ~= c_ice then
									data[vi] = c_ice
									void = false
									--permafrost on lowlands where wet
								elseif temp <8 and temp > 2 and hum > 70 and y < (100 + math.random(-20,20)) then
									--disturbance gives stones.
									if distu < 50 then
										data[vi] = c_permamoss
										void = false
									else
										data[vi] = c_permastone
										void = false
									end
									--snow if cold
								elseif temp <11 then
									data[vi] = c_snowbl
									void = false
								--warmer give dirt
								else
									data[vi] = c_dirtsno
									void = false
								end
							end

						--Broken lands
						elseif distu >= 99 then
							--only allow on stone
							if (nodu == c_stone
							or nodu == c_stone2
							or nodu == c_sandstone
							or nodu == c_sandstone2
							or nodu == c_sandstone3)
							and nodu ~= c_ice
							then
								--wet slips
								if hum > 80 then
									data[vi] = SEDID.c_clay
									void = false
								--gravel slip
								elseif hum < 30 then
									data[vi] = SEDID.c_gravel
									void = false
								-- stripped to rock warm is red
								elseif temp > 50 and nodu ~= c_stone2 then
									data[vi] = c_stone2
									void = false
								-- stripped to rock cold is grey
								elseif temp <= 50 and nodu ~= c_stone then
									data[vi] = c_stone
									void = false
								-- volcano on hills...
								elseif y > 100 + math.random(-10,10) then
									--stacks
									if math.random(1,3) > 1 then
										data[vi] = c_obsid
										void = false
										--nonstacks
									elseif nodu ~= c_obsid then
										data[vi] = c_obsid
										void = false
									end
								--otherwise dirt
								else
									data[vi] = SEDID.c_dirt
									void = false
								end
							end

						-- Dry barren... (or freaking scorching hot)
						elseif hum <20 or temp > 99 then
							--don't cover own sediments etc
							if nodu ~= c_dsand
							--and nodu ~= SEDID.sand
							and nodu ~= SEDID.c_sand2
							and nodu ~= SEDID.c_gravel
							and nodu ~= c_ice
							and nodu ~= c_snowbl
							then
								-- disturbed and extreme areas stripped to rock
								if distu > 90 then
									data[vi] = SEDID.c_gravel
									void = false
								--cold and dry
							  elseif temp < 30 then
									--very dry places are cold desert
									if hum < 7 then
										data[vi] = SEDID.c_sand2
										void = false
									-- wet enough for soil, still too dry to snow
								  elseif hum < 14 then
										data[vi] = c_dirtdgr
										void = false
									--more water and it snows
									else
										data[vi] = c_dirtsno
										void = false
									end
								--hot and dry
								--desert
								elseif temp >= 70 then
									data[vi] = c_dsand
									void = false
								--temperate
								else
									-- more moisture have soil
									if hum > 6 then
										data[vi] = c_dirtdgr
										void = false
									--very dry (or if in doubt) are gravel
									else
										--data[vi] = OREID.c_mese
										data[vi] = SEDID.c_gravel
										void = false
									end
								end
							end

						--Forests..
						--less disturbance. with enough moisture, not too cold.
					 elseif distu < 35 and hum > 40 and temp > 20 and temp < 90 then
							--conifers... cold and dry
							if temp < 42 and hum < 37 then
								data[vi] = c_dirtconlit
								void = false
							--unfrozen
							else
								data[vi] = c_dirtlit
								void = false
							end

						--All the rest must be grasslands
						else
							--dry...
							if hum < 40 or temp >80 then
								data[vi] = c_dirtdgr
								void = false
							--cold
						  elseif temp < 30 then
								data[vi] = c_dirtsno
								void = false
								--warm and wet
							else
								data[vi] = c_dirtgr
								void = false
							end

						--end of climate combos
						end
					--end of can sur
					end
				--end of voids
				end

				--Fill the oceans and deeps

				if y < SEA and void then
					if river_basin then
						data[vi] = MISCID.c_river
						void = false
					elseif nocave then
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
						 local distu
						 temp, hum, distu = climate(x, z, y, n_terr, n_terr2)

						 -- pack it in a table, for plants API
						 local conditions = {
																 temp = temp,
																 humidity = hum,
																 disturb = distu,
																 nodu = nodu
																 }
						 local pos = {x = x, y = y, z = z}

						 --call the api... this will create plant
							 mgtec.choose_generate_plant(conditions, pos, data, data2, area, vi)

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
	vm:set_param2_data(data2)
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
end))

--===============================================================





-----------------------------------------------------------
--SPAWN PLAYER


--spawnpoints = {} -- We don't want them respawning somewhere else! (That could be interesting, though.)

local function get_far_node(pos, player,alt)
	local node = minetest.get_node(pos)
	if node.name == "ignore" then
	    minetest.emerge_area(pos, pos)
			minetest.after(2,function()
	        spawnplayer(player, alt)
	    end)
	    return node, false
	end
	return node, true
end


function spawnplayer(player,alt)
    local pos = spawnpoint
		--scatter a little to avoid respawning bug when reusing same place
		--pos.x = spawnpoint.x + math.random(-500 , 500)
		--pos.z = spawnpoint.z + math.random(-500, 500)

    for i = alt, 0,-1 do
				alt = i
        pos.y = i
				minetest.chat_send_player(player:get_player_name(), "Spawning at... x:"..pos.x.." z:"..pos.z .." y:"..pos.y)
        local node, val = get_far_node(pos, player, alt)
        if not val then
						pos.y = pos.y + 1000
						player:setpos(pos)
            break
        end
        if node.name ~= "air" then
					break
        end
    end

	pos.y = pos.y + 2
	player:setpos(pos)

	--save location
	mod_storage:set_int("x", pos.x)
	mod_storage:set_int("y", pos.y)
	mod_storage:set_int("z", pos.z)

end



function savedspawn(player)
	--get location from storage
	local spx =  mod_storage:get_int("x")
	local spy =  mod_storage:get_int("y")
	local spz =  mod_storage:get_int("z")
	local pos = {x = spx, y = spy, z = spz}

	minetest.chat_send_player(player:get_player_name(), "Respawning at... x:"..spx.." z:"..spz .." y:"..spy)
	player:setpos(pos)
end


-----------------------------------------------------------
minetest.register_on_newplayer(function(player)
	spawnplayer(player, 1300)


	-- Get the inventory of the player
	local inventory = player:get_inventory()
	--give them some gear to help in survival mode
	--sometimes spawns in barren places

	--inventory:add_item("main", "default:pick_stone")
	--inventory:add_item("main", "default:torch 15")
	--inventory:add_item("main", "default:ladder 10")
	inventory:add_item("main", "farming:bread 4")
	inventory:add_item("main", "farming:seed_wheat")
  inventory:add_item("main", "farming:seed_cotton")
end)


--this is needed to stop it putting player at 0,0,0...but overrides bed save :-(
minetest.register_on_respawnplayer(function(player)
			savedspawn(player)
			--disable default
			return true
end)
