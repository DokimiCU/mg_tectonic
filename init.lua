---============================================================================
--MG TECTONIC
--By Dokimi

--A naturalistic mapgen.
--This is the main mapgen code.

--=============================================================================
--PRELIMINARIES
mgtec = {}
local mod_storage = minetest.get_mod_storage()



-----------------
--PLANTS API
dofile(minetest.get_modpath("mg_tectonic").."/trees.lua")
dofile(minetest.get_modpath("mg_tectonic").."/plants_api.lua")
dofile(minetest.get_modpath("mg_tectonic").."/plants.lua")
--may cause bugs when used???? -- this is an experiment for adding custom plants
if minetest.get_modpath("mgt_flora") ~= nil then
	dofile(minetest.get_modpath("mgt_flora").."/plants_reg.lua")
end


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
--will effect gradient and number of major mt ranges
local XRS = 537--617

--Where does the continental shelf end?
local SHELFX = 25000
local SHELFZ = 28000
--How deep are the oceans?
local SEABED = -15000
--Strength of noise on continental shelf boundaries lines
local CONOI = 2500

--Cave size.
--Base cave threshold for fissures
local BCAVTF = 0.0079

--Base cave threshold for caves
local BCAVT = 0.996

--Ore threshold
local ORET = 0.975





--==================================================================
--FUNCTIONS

--Checks if this is a place for ore deposits.

local function ore(nocave, ab_stra, ab_cave, ab_cave2, y, ORET, ybig, n_strata, data, vi, OREID)
	--c_coal, c_iron, c_copp, c_tin, c_gold, c_diam, c_mese

	--strata thickness
	local thick = 100 + (50 * ab_stra)

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


	--threshold adjusted with depth to get bigger down deep.
	local ore_t = ORET + ybig

	--harder if actually in the cave.
	if not nocave then
		ore_t = ore_t + 0.05
	end

	--height limits
	local blend = n_strata * 50
	local orehmin_c = -10000 + (n_strata * 500) --min height for coal (a shallow ore)
	local orehmax_g = -30 + blend   --dig a little for gold
	local orehmax_d = -600 + blend   --diamonds are deep
	local orehmax_m = -400 + blend   --mese is deep

	--above their threshold
	--add some of the cave noise to increase chance of finding ores near caves
	--working with caves: should be less inside the actual cave (less floaters), but..
	--..reduced threshold should boost approaching cave
	if ab_stra >= ore_t - (ab_cave2 * 0.02)  then

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
--this function can be called by other mods instead of default biome climate checks

mgtec.climate = function(x, z, y, n_terr, n_terr2)


	--east = + x, west = - x, south = -z, n = + z
	--Climate is decided by:
	-- -Ranges: rains come from the west (-x), rise over the ranges dumping cooling rain, descending hot and dry (east +x)
	-- - Altitude: it's cold up there.
	-- - Latitude: hot north, cold south

	--blending
	local blend = math.random(-4, 4)

	--to help climate be accessed by other mods (mainly weather)
	--we will ignore noise (thorn0906's solution crashes when actually used,
	-- accessing noise repeatedly likely very heavy for little gain
	-- reducing noiseyness better? Randomness can make things throw a fit)
	if n_terr == nil or n_terr2 == nil then
		blend = 0
		n_terr = 0
		n_terr2 = 0
	end

	--adjust x to match with the adjusted centreline of symmetry
	local x_adj = (n_terr * 1466)
	x = x + x_adj


	--We are Southern Hemisphererers here!
	--decreasing temp from max z to min z (latitude) (from 100 to 0 i.e north desert to south ice)
	-- linear increase, intercept at 50
	local temp_z = (0.00163*z) + 50 - blend


	-- no Fohn? Westies are controlled by z only
	local temp_x = 0

	--offset east-west border with some noise
	-- centreline from noise with more noise
	local lon_blend = x_adj + ((blend*3) - (n_terr2 * 200))

	-- Easterners?
	if x > lon_blend then
		--Fohn Winds! They are hot! The East Coast gets a temp boost
		-- adds + 20 at centre of map, declines to zero
		temp_x = (-0.00065*x) + 20 - blend
	end



	--Mountain tops ought to be cold!
	--decreasing temp with hieght...and combine previous two as baseline
	local temp = temp_z + temp_x - blend
	--only apply height adjustment above sea level, otherwise cooking oceans
	--large parts of "lowlands" are very high too, so start cooling high.
	--i.e. -0.05 = -50 at 1000m
	if y >= 200 + (n_terr *75) then
		temp = (-0.05*y) + temp_z + temp_x - blend
	end

	---------------
	--what's the humidity? Rainshadow!
	--decreasing humid from far x to x= 0,(rain shadow)
	--tip a little past 50 for greater variety
	--i.e. 0-60, so have wet islands on the dry side, dry islands on wet side

	--if in doubt ...
	local hum = 50

	----positive, east coast. Dry inland
	--linear increase,
	if x > lon_blend then
		hum = (0.00194*x) + blend
	--increasing humid from far x to x= 0,(rain shadow)
	else  --negative , west coast. Wet inland
		--linear increase,
		--starts a little lower than max (i.e. + <100)
		--so that altitude boosts it to max
		hum = (0.00145*x) + 85 + blend
	end


	--Transition humidity
	--this is to avoid a sharp line East West
	-- not perfect but better than nothing?
	if x > lon_blend and x < lon_blend + 400 then
		--east must be wetter
		if x < lon_blend + 100 then
			hum = hum + 35
		elseif x < lon_blend + 200 then
			hum = hum + 20
		else
			hum = hum + 15
		end
	elseif x < lon_blend and x > lon_blend - 300 then
		--west must be drier
		if x > lon_blend - 100 then
			hum = hum - 20
		elseif x > lon_blend - 200 then
			hum = hum - 10
		else
			hum = hum - 5
		end
	end


	--disturbance regime
	--i.e. ecological succession
	local distu =  math.abs(n_terr * 100 + blend)


	--altitude effects..
	--coast is wet, but disturbed
	-- hill tops catch rain but are more disturbed
	if y > 490 or (y < 10 and y > -3) then
		--alpine (force snowy)
		if y > 1200 + math.random(-30, 5) then
			hum = hum + 48
			temp = temp - 32
			distu = distu + 12
			--subalpine
		elseif y > 1100 + blend then
			hum = hum + 24
			temp = temp - 16
			distu = distu + 6
		elseif y > 1000 + blend then
			hum = hum + 12
			temp = temp - 8
			distu = distu + 3
			--montane
		elseif y > 900 + blend then
			temp = temp - 4
			hum = hum + 6
		elseif y > 700 + blend then
			temp = temp - 2
			hum = hum + 3
		elseif y > 500 + blend then
			hum = hum + 2
			--coast
		elseif (y <= 3 and y >= -1) then
			-- generally wetter, but sometimes drier
			--..coasts are more variable
			hum = hum + 3 + blend
			distu = distu + 5
		end
	end


	--disturbance Feedsback on micro-climate
	--calm areas hold water.
	--exposed areas are hotter
	--sheltered a little colder
	if distu <15 or distu >80 then
		if distu < 10 then
			if distu <5 then
				hum = hum + 8
				temp = temp - 4
			elseif distu <15 then
				hum = hum + 4
				temp = temp - 2
			end
		elseif distu > 80 then
			if distu > 95 then
				hum = hum - 12
				temp = temp + 12
			elseif distu > 90 then
				hum = hum - 6
				temp = temp + 6
			elseif distu > 80 then
				hum = hum - 3
				temp = temp + 3
			end
		end
	end


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
		c_dry_dirt = minetest.get_content_id("default:dry_dirt"),
		c_perma = minetest.get_content_id("default:permafrost"),
}

--surfaces
local c_dirtgr = minetest.get_content_id("default:dirt_with_grass")
local c_dirtdgr = minetest.get_content_id("default:dirt_with_dry_grass")
local c_dry_dirtdgr = minetest.get_content_id("default:dry_dirt_with_dry_grass")
local c_dirtsno = minetest.get_content_id("default:dirt_with_snow")
local c_dirtlit = minetest.get_content_id("default:dirt_with_rainforest_litter")
local c_dirtconlit = minetest.get_content_id("default:dirt_with_coniferous_litter")
local c_snowbl = minetest.get_content_id("default:snowblock")
local c_snow = minetest.get_content_id("default:snow")
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
--controls: large rounded mountains.
local np_terrain = {
	offset = 0,
	scale = 1,
	spread = {x = 1944, y = 3078, z = 1944},
	seed = 110013,
	octaves = 5,
	persist = 0.3,
	lacunarity = 3,
	--flags = 'noeased',
}

-- 2D Soft rock Terrain.
--controls: sharp peaks
local np_terrain2 = {
	offset = 0,
	scale = 1,
	spread = {x = 405, y = 243, z = 405},
	seed = 5938033,
	octaves = 3,
	persist = 0.6,
	lacunarity = 3,
	flags = 'noeased',
}


-- 3D Caves 1
--used by: fissures in basement rock,
local np_cave = {
	offset = 0,
	scale = 1,
	spread = {x = 108, y = 243, z = 324},
	seed = -9103323,
	octaves = 3,
	persist = 0.2,
	lacunarity = 3,
	--flags = 'noeased',
}

-- 3D Caves 2
--used by: breaks in fissures, caves in basement rock
local np_cave2 = {
	offset = 0,
	scale = 1,
	spread = {x = 81, y = 27, z = 81},
	seed = 205301,
	octaves = 3,
	persist = 0.5,
	lacunarity = 3,
	flags = 'noeased',
}


--3D Strata
-- used by: ore thresholds.
local np_strata = {
	offset = 0,
	scale = 1,
	spread = {x = 81, y = 81, z = 81},
	seed = 51055033,
	octaves = 3,
	persist = 0.7, --high or get few ore
	lacunarity = 3,
}



--======================================================================================================================
--NOISE MEMORY

-- Initialize noise object to nil. It will be created once only during the
-- generation of the first mapchunk, to minimise memory use.
local nobj_terrain = nil
local nobj_terrain2 = nil
local nobj_cave = nil
local nobj_cave2 = nil
local nobj_strata = nil
-- For getting individual n_terr values
--nobj_terr_i = nil
--nobj_terr2_i = nil

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


--============================================================================================================ --***
----ON--------------------------------------------------------------------
logg = function(sss) --for debug
	minetest.log(sss)
	--minetest.chat_send_all(sss)  --Causes silent crash if called to soon
	minetest.after(0 , minetest.chat_send_all , sss) --delay until global step loop
end
----OFF-------------------------------------------------------------------
--logg = function(sss) end
--------------------------------------------------------------------------
--========== OVERRIDE minetest.get_heat(pos) , minetest.get_humidity(pos) ============================================== --***

--Some mod could query heat/hum too frequently, return cached data to save CPU if pos "enough" near to last calculated pos.
--(heat and humidity vary smoothly)
-- h_th (horizontal) and v_th(vertical) are the threshold distances that decide wether return cached or recalculate
-- Different h_th and v_th due to heat, hum being more altitude dependent than x,z dependent
-- This naive cache system is only good for singleplayer.Multiplayer would need kind of per player cache.
-- (Cached pos of player 1 is useless if player 2 queries hum/heat)

local clima_cache = {50, 50, x=100000, y=0, z=0 }
local v_th = 15 --PLEASE ADJUST THIS VALUE!
local h_th = 30 --PLEASE ADJUST THIS VALUE!
local h_th2 = h_th^2
local get_heat_or_humidity = function(pos,what)
	if math.abs(pos.y - clima_cache.y) > v_th
	or (pos.x - clima_cache.x)^2 + (pos.z - clima_cache.z)^2 > h_th2
	then
		--local n_terr  = nvals_terrain[nixz] ---doesn't actually give it noise?
		--local n_terr2  = nvals_terrain2[nixz]
		local temp, hum, distu = mgtec.climate(pos.x, pos.z, pos.y)--, n_terr, n_terr2)
		clima_cache.x = pos.x
		clima_cache.y = pos.y
		clima_cache.z = pos.z
		clima_cache[1] = temp
		clima_cache[2] = hum
		logg("get_heat_or_humidity -> recalculated T,H = ".. temp .." , ".. hum)
	else
		logg("get_heat_or_humidity -> cached T,H = ".. clima_cache[1] .." , ".. clima_cache[2])
	end
	return clima_cache[what]
end

minetest.get_heat     = function(pos) return get_heat_or_humidity(pos,1) end
minetest.get_humidity = function(pos) return get_heat_or_humidity(pos,2) end


--=============================================================================
-- GENERATION

local num_lakes = nil
local lakes = nil
local spawnpoint = {x = 0, z = 0}

minetest.register_on_mapgen_init(function(mapgen_params)


	minetest.log("on_mapgen_init ") --MIO
	math.randomseed(mapgen_params.seed)
	spawnpoint = {x = math.random(-23000, 23000), z = math.random(-27000, 27000)}
	minetest.set_mapgen_setting("mg_name", "singlenode", true) --***
	minetest.set_mapgen_setting("mg_flags", "nolight", true) --***


	-- some things need to be random, but stay constant throughout the loop

	-- number of lakes
	if lakes == nil then
		num_lakes = math.random(15,18)
		lakes = {}
		for i = 0, num_lakes do
			--keep back from "shelf" as the coastline is actually much further back
			--need to keep them out of main ranges...too much erosion.
			--choose east or west.
			if math.random(1,3) <=2 then
				--west lake
				lakes[i] = {x = math.random(-13000,-5500), z = math.random(-25000,25000), r = math.random(1,5)}
			else
				--East lake.
				lakes[i] = {x = math.random(5500,13000), z = math.random(-25000,25000), r = math.random(1,4)}
			end
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
	--nobj_terr_i = nobj_terr_i or minetest.get_perlin(np_terrain.seed, np_terrain.octaves, np_terrain.persist, np_terrain.scale)
	--nobj_terr2_i = nobj_terr_i or minetest.get_perlin(np_terrain2.seed, np_terrain2.octaves, np_terrain2.persist, np_terrain2.scale)

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
    --minetest.log("+++++++++ on_generated called with seed = " .. seed .. " minp= " .. minetest.pos_to_string(minp)  .. " maxp= " .. minetest.pos_to_string(maxp) .. " emin= " .. minetest.pos_to_string(emin) .. " emax= " .. minetest.pos_to_string(emax)) --MIO
    --minetest.log("+++++++++ on_generated called with seed = " .. seed .. "," .. minetest.pos_to_string(minp)  .. "," .. minetest.pos_to_string(maxp) .. "," .. minetest.pos_to_string(emin) .. "," .. minetest.pos_to_string(emax)) --MIO


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
				local ab_t =  math.abs(n_terr)
				local ab_t2 =  math.abs(n_terr2)


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

				--[[note on noise:
				Without noise the waves form straight lines down the entire map.
				This is only noticeable after much exploring,
				 but makes the map less interesting.
				Noise added to make waves more varied along the map.
				-xab: shifts symmetry
				-whs: creates high and low points (must be small or crazy effects!).
				-xroll: number and size of ranges.
				-mup: low and high points
				]]


				--absolute for x (for symmetry on both sides of map)
				local xab = math.abs(x + (n_terr * 1466))
				--x axis terrain gradient. 0 at centre. 1 at edges.
				--Used by equations to adjust along x axis
				local xtgrad = (xab/YMAX)

				--amplitude... going from 1 to zero at map edge
				local whs = (1-xtgrad) + (n_terr * 0.06)


				--Move up/down along x axis. Goes from +1 to -1
				--mup raises and lowers along x axis. the two terms cancel out in middle of x range (15k).
				--aimed for equations that need to lift map centre, sink edges
				local mup = whs + (-1 * xtgrad) + (n_terr * -0.25)


				------------------
				--Base Layer Waves
				--creates the underlying, undulating and mountainous terrain


				--Wave period. "Roll". i.e. how wide/steep and they are.
				--Gradient widens the ranges towards the edges.
				local x_roll = XRS + (XRS * xtgrad)  + (234 - (n_terr * 234))

				--The Wave!
				-- (while cos doesn't need an absolute value for x, it does need the noise adjusted one, hence xab)
				local xwav = (whs*math.cos(xab/x_roll))    -- north south wave (main ranges)
				local xwav2 = (whs*math.cos(xab/(x_roll/6.89))) --smaller more detailed wave



				--Base Wave Density.
				--This is checked against the threshold to decide where the base layer can go.
				--the wave controls the landscape folding i.e. the bunching up caused by the plates hitting eachother.
				--variation along this fold is caused by erosion, so is much more random...

				--cubing/squaring flattens out the middle range, squaring eliminates negatives
				--for the wave that gives it a flat shelf at sea level.
				--for the noise it mellows part of it out, so it adds mainly extreme peaks and dips
				--mup lowers the landscape at the edges (ocean), otherwise the flattening of height would lead to endless plains
				--wave + raise + large hills 2 + sharp hills (moderated by large or gives sky needles) + cliffs 2

				--waves
				local dwav = ((xwav2 ^ 3)*1.67) + ((xwav ^ 3)*6.89) + (mup*10.81)--+ (mup*12.16)
				--noise
				local dnoi = ((n_terr ^3) + ((n_terr)*0.5) + ((n_terr2*n_terr)*0.8)) * 2.8 * (whs + 0.02)
				--cliffs..
				local dclif1 = ((ab_stra)*0.16)
				local dclif2 = ((ab_cave*ab_cave2)*0.05)

				local den_base = dwav + dnoi - dclif1 - dclif2


				---Base Threshold (use for all of them now)
				--effects heights of landscape
				local t_base = 0.00969*y --0.01036*y



				-------------------------------------
				--Soft Rock
				--layered on top of the base layer.
				--adding to previous: x >1 = steeper. x < 1 flatter
				--soft sandstone... easily erobable rocks sedimentary rocks
				--creates regions of soft rock on top of the base layer in lowlands
				--base + boost + noise - cliff



				--density
				local den_soft = (den_base*0.4) + 1.3 + ((1-n_terr) * (2.22 - (xtgrad*2))) - dclif2
				--threshold (redundant)
				--local t_soft = 0.006*y -0.15

				------------------------------------
				--Alluvium
				--eroded rock etc, deposited on lowlands

				--density
				local den_allu = (den_soft*0.95) + 0.1 - dclif2
				--threshold (redundant)
				--local t_allu = 0.0075*y -0.17


				------------------------------------
				--Sediment
				--subsurface soils and sands
				--density
				local den_sedi = den_allu + 0.03 -- dclif2
				--threshold (redundant)
				--local t_sedi = 0.0085*y -0.18

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
				--Seperate Earth and Sky
				if den_base > t_base
				or den_soft > t_base
				or den_allu > t_base
				or den_sedi > t_base then

					--Seperate Earth from oceans, rivers, caves.
					----------------------------
					-- Ocean Basins/Erosion
					--carves out a continental shelf.
					--lowers mountains so can have sea at North and South
					local zab = math.abs(z)

					-- coastline
					local shelfnoi = (((n_terr ^3) + (n_terr2 *0.08)) * CONOI) - dclif2
					local shelfsl = (3 - (n_terr^3))*y --sets slope for x
					--local bed = SEABED + ((n_terr^3)*SEABED)
					--Are we in the right place for oceans?
					if (xab > ((SHELFX + (shelfnoi*2)) - shelfsl)
					or zab > ((SHELFZ + shelfnoi) - shelfsl))
					and y >= SEABED  then --max depth,
						basin = true
					end

					-----------------------------
					--Lakes and rivers.
					--These are put in "manually" as doing it based on noise does not work well for rivers
					--The point of these is:
					-- to bring water to the dry interior, provide access, features of interest, greater altitude variation.
					--they have a large erosion effect on the surrounding area. So need very steep sides
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
							local laked = -25 + (10 * n_terr2)
							local laker = (160 + (100 * n_terr) + (25 * n_terr2)) * (1 + (y/(160 + (20 * n_terr))))
							if x < lakes[n].x + (laker*1.6) and x > lakes[n].x - (laker*1.6)
							and z < lakes[n].z + laker and z > lakes[n].z - laker
							and y > laked then
								river_basin = true
							end

							--Rivers draining them
							if lakes[n].r <= 4 then
								--local interr = 1-n_terr
								local interr2 = 1-n_terr2

								--rivers have real world mathmatical geometry
								--width (actually half the width)
								local wp = (8 + (0.0003*xab))
								local w = (wp * (1 + (y/(8 + (n_terr*2))))) - ((n_terr2^3)*3)

								--period of channel
								local per_ch = ((3.5 * n_terr) + 22) * wp
								--local per_ch = 176
								--amplitude
								local am_ch = (interr2 + 4.6) * wp
								--local am_ch = 37

								--wave for channel
								local c1 = ((am_ch)*math.sin(x/per_ch))
								local c2 = (12 + (interr2*3))*math.sin(x/(56 + (n_terr*8)))
								local channel = c1 + c2

								--line it up north-south
								if z <= lakes[n].z + channel + w
								and z >= lakes[n].z + channel - w then
									--make sure the river is on the same side East-west of the map as the lake!
									--east lakes, only place the river further east
									if lakes[n].x > 0 and x + w > lakes[n].x then
										river_basin = true
										--west lakes, only place river further west
									elseif lakes[n].x < 0 and x - w < lakes[n].x then
										river_basin = true
									end
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
						local ybig = ((y/YMAX)*0.24)

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
						if (ab_cave) >= cav_t1
						or (n_cave2) >= cav_t1
						then
							nocave = true
						end

						-----------------
						--Round caves?
						-- reverse deal from fissures.
						--If the noise is above the threshold we empty out a cave
						-- lower threshold = bigger cave..
						local cav_t2 = BCAVT + ybig

						if n_cave2 ^ 2 >= cav_t2
						then
							nocave = false
						end


						--Now place rocks
						------------------------
						--Place basement rock
						if den_base > t_base then

							--first do ore, with no regard for caves(we want it inside caves)
							if ore(nocave, ab_stra, ab_cave, ab_cave2, y, ORET, ybig, n_strata, data, vi, OREID)
							then
								void = false
							--if it wasn't ore and isn't cave now do rock
							elseif nocave then
								--strata splits..
								local thick = 11 + (3*n_strata)
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
								else
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
							if den_soft > t_base then

								-----------------
								--Caves for soft rock
								local cav_t2 = BCAVT

								if ab_cave2 >= cav_t2
								then
									nocave = false
								end

								--first do ore, with no regard for caves(we want it inside caves)
								if ore(nocave, ab_stra, ab_cave, ab_cave2, y, ORET, ybig, n_strata, data, vi, OREID)
								then
									void = false
								--if it wasn't ore and isn't cave now do rock
								elseif nocave then
									--strata splits..
									local thick = 7 + (2*n_strata)
									local ystrata = math.sin(y/thick)

									--a little lost base rock...
									--with coal and iron
									if ystrata >= 0.7
									and ystrata <= 0.9
									and n_strata > 0.8 then
										if math.random(1,10) == 1 then
											data[vi] = OREID.c_coal
											void = false
										elseif math.random(1,100) == 1 then
											data[vi] = OREID.c_iron
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
						--but some solid things are stable..e.g. clay,.
						--... so covers caves, rather than have giant holes
						--allows "clay caves". Height limit or it coats everything in clay
						--only in areas where sediment is higher than base rock (so not coating all caves)
						if not stab
						and den_soft < den_sedi
						and y > (-320 + (n_strata*8))
						--and y < (128 + (n_strata*16))
						then
							if den_sedi > t_base and nocave then
								data[vi] = SEDID.c_clay
								void = false
							end
						elseif stab then

							--Place alluvium
							if void then
								if den_allu > t_base and nocave then

									--strata splits..
									local thick = 31 + (29*n_strata)
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
								if den_sedi > t_base and nocave then
									--non-basin seas
									if y < SEA-1 then
										data[vi] = SEDID.c_sand
										void = false
									else
										--We are above sea level...	now we need to know climate.
										local temp
										local hum
										local distu
										temp, hum, distu = mgtec.climate(x, z, y, n_terr, n_terr2)

										--We have some fiddly coastal stuff.
										--on a node, that is sea surface or one above
										if y <= SEA + 1 and y >= SEA-1 then
											--a humid place? will make swamps
											if hum > 80  then  --boundary for swamp
												--let's place a swampy mire
												swamp(data, vi, 40, SEDID.c_clay, MISCID.c_river)
												void = false
											elseif hum > 60  then -- less swampy
												swamp(data, vi, 80, SEDID.c_clay, MISCID.c_river)
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
										elseif hum < 15 then
											--sand dunes...?
											data[vi] = c_dsand
											void = false
										elseif hum < 30 then
											--more moisture no more sand, dry dirt
											data[vi] = SEDID.c_dry_dirt
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


				if void
				and nodu ~= nil
				and nodu ~= MISCID.c_ignore then
					--now we need climate data.
					local temp
					local hum
					local distu
					temp, hum, distu = mgtec.climate(x, z, y, n_terr, n_terr2)

					--ocean
					if y <= SEA-1
					and nodu ~= MISCID.c_air
					and (basin == true or river_basin == true) then
						--floating ice
						if temp < 30 and distu > 6 and distu <40 and y == SEA-1 then
							data[vi] = c_ice
							void = false
							--thicker ice in low disturbance
							if distu < 30 then
								if nodu == MISCID.c_water or nodu == MISCID.c_river then
									--This is nodu: nodu  = data[(vi - ystridevm)]
									--overwrite water
									data[(vi - ystridevm)] = c_ice
									--thicker?
									if distu < 20 then
										if data[(vi - 2*ystridevm)] == MISCID.c_water then
											data[(vi - 2*ystridevm)] = c_ice
											--higher on top
											--can't do ice or it becomes an island!
											if data[(vi + ystridevm)] == MISCID.c_air then
												data[(vi + ystridevm)] = c_snow
											end
											--even thicker
											if distu < 10 then
												if data[(vi - 3*ystridevm)] == MISCID.c_water then
													data[(vi - 3*ystridevm)] = c_ice
												end
												--higher on top
												data[(vi + ystridevm)] = c_snowbl
											end
										end
									end
								end
							end
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
							--corals: low disturbance, warm, shallow
							if not river_basin
							and distu > 12
							and distu < 30
							and temp > 40
							and y <= SEA-3
							and y > SEA - 17
							then
								-- allow stacking coral
								local c = math.random(1,31)
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
							--kelp: higher disturbance, colder, deeper
							elseif not river_basin
							and math.random()<0.5 --spacing
							and distu < 60
							and distu > 10
							and temp < 80
							then
								--short kelp in shallows
								if y <= SEA-5
								and y > SEA - 7 then
									data[vi] = MISCID.c_kelpsand
									data2[vi] = math.random(3, 4) * 16
									void = false
								elseif y <= SEA-7
								and y > SEA - 9 then
									data[vi] = MISCID.c_kelpsand
									data2[vi] = math.random(4, 6) * 16
									void = false
								elseif y <= SEA-9
								and y > SEA - 24 then
									data[vi] = MISCID.c_kelpsand
									data2[vi] = math.random(6, 8) * 16
									void = false
								end

							--rare short kelp:
							--everywhere needs some sea life
							elseif not river_basin
							and y <= SEA - 5
						 	and y > SEA - 15
							and math.random()<0.1 then
								data[vi] = MISCID.c_kelpsand
								data2[vi] = math.random(3, 4) * 16
								void = false

							--low disturbance do fine sediment
							elseif distu < 5
							and nodu ~= SEDID.c_clay
							and nodu ~= SEDID.c_sand2
							and nodu ~= c_coral
							and nodu ~= c_ice then
								data[vi] = SEDID.c_clay
								void = false
							-- volcanic if rough
							elseif distu > 96 and nodu ~= c_ice then
								local c = math.random(1,10)
								if c > 6 then
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
					or nodu == SEDID.c_dry_dirt
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
												swamp(data, vi, 10, c_permamoss, c_ice)
												void = false
											else
												swamp(data, vi, 10, c_permastone, c_ice)
												void = false
											end
											--cold
										elseif temp <30 then
											swamp(data, vi, 10, c_dirtsno, MISCID.c_river)
											void = false
											--muddy
										else
											swamp(data, vi, 10, SEDID.c_clay, MISCID.c_river)
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
											swamp(data, vi, 20, c_dirtsno, MISCID.c_river)
											void = false
											--muddy
										else
											swamp(data, vi, 20, SEDID.c_clay, MISCID.c_river)
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
							elseif nodu ~= c_ice then
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
								elseif temp >= 80 then
									data[vi] = c_dsand
									void = false
								--temperate
								else
									-- more moisture have soil
									if hum > 6 then
										data[vi] = c_dry_dirtdgr
										void = false
									--very dry (or if in doubt) are gravel
									else
										--data[vi] = OREID.c_mese --for bug testing!
										data[vi] = SEDID.c_gravel
										void = false
									end
								end
							end

							--Forests..
							--less disturbance. with enough moisture, not too cold.
						elseif distu < 25 and hum > 30 and temp > 25 and temp < 90 then
							--conifers... cold and dry
							if temp < 40 and hum < 45 then
								data[vi] = c_dirtconlit
								void = false
							--all the others...because that's all we got
							else
								data[vi] = c_dirtlit
								void = false
							end


							--All the rest must be grasslands
						else
							--dry...
							if hum < 20 or temp >95 then
								data[vi] = c_dry_dirtdgr
								void = false
							elseif hum < 40 or temp >90 then
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

						--Substrate, all plants should check it themselves...
						-- so no need to check here
						local nodu  = data[(vi - ystridevm)]

						--We need these again
						local n_terr  = nvals_terrain[nixz]
						local n_terr2  = nvals_terrain[nixz]

						--get climate data
						local temp
						local hum
						local distu
						temp, hum, distu = mgtec.climate(x, z, y, n_terr, n_terr2)

						-- pack it in a table, for plants API
						local conditions = {
							temp = temp,
							humidity = hum,
							disturb = distu,
							nodu = nodu
							}
						local pos = {x = x, y = y, z = z}
						--call the api... this will create plant
						mgtec.choose_generate_plant(vm, conditions, pos, data, data2, area, vi)

						--do snow pack over everything
						if data[vi] == MISCID.c_air
						and nodu ~= MISCID.c_ignore
						and nodu ~= MISCID.c_air
						and hum > 15
						and temp < 30
						and nodu ~= c_snow
						and y >= SEA + 2 then
							local name = minetest.get_name_from_content_id(nodu)

							if not minetest.registered_nodes[name] then
								minetest.log("********* Second loop: minetest.registered_nodes[name] is nil   name = "..dump(name).." *************")  --***
								return nil --***  ???
							end
							local draw = minetest.registered_nodes[name]['drawtype']

							if draw == 'normal'
							or draw == 'allfaces_optional'  then
								data[vi] = c_snow
								--void = false --***
								--this causes WARNING[Emerge-0]: Assignment to undeclared global "void" inside a function at ...  --***
								--void is declared local to the first loop --***
								--and seems unused here ?  --***
							end
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

--[=[ ================ THE OLD spawnplayer & get_far_node FUNCTIONS ==================================================== --***

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


	--an attempt to reduce time...puts player underground :-(
	--local xtgr_spawn = 1-(math.abs(pos.x)/YMAX)
	--alt = math.floor(alt * xtgr_spawn)

	for i = alt, 0,-1 do
		alt = i
		pos.y = i
		minetest.chat_send_player(player:get_player_name(), "Please wait. The spawning code is looking for the ground. Spawning at... x:"..pos.x.." z:"..pos.z .." y:"..pos.y)
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
--]=]

--===================== THE NEW spawnplayer FUNCTIONS ======================================================================= --***

local ALT_START = 2600 --Starting height to begin searching ground downwards
-- Used in register_on_newplayer and xteleport chatcommand

local find_ground_level_at = function(x,z , alt_max, alt_min, step)
	--Based on den_base , t_base or den_soft, t_base or den_allu , t_base or den_sedi > t_base
	--and  basin , river_basin
	--Does not account for "toppings": snow, ice...
	local t0 = minetest.get_us_time()   -- os.clock()
	local step = step or -1  -- step optional, default -1
	-----------------------------------------------------------------------
	local noi_cave   = minetest.get_perlin(np_cave)
	local noi_cave2  = minetest.get_perlin(np_cave2)
	local noi_strata = minetest.get_perlin(np_strata)
	----------------------------------------------------------------------
	local n_terr   = minetest.get_perlin(np_terrain):get_2d({x=x,y=z})
	local n_terr2  = minetest.get_perlin(np_terrain2):get_2d({x=x,y=z})
	----------------------------------------------------------------------
	local xab = math.abs(x + (n_terr * 1466))
	local xtgrad = (xab/YMAX)
	local whs = (1-xtgrad) + (n_terr * 0.06)
	local mup = whs + (-1 * xtgrad) + (n_terr * -0.25)
	local x_roll = XRS + (XRS * xtgrad)  + (234 - (n_terr * 234))
	local dwav = ((whs*math.cos(xab/(x_roll/6.89))) ^ 3)*1.67 + ((whs*math.cos(xab/x_roll)) ^ 3)*6.89 + mup*10.81
	--local dnoi = (n_terr^3 + n_terr*0.5 + n_terr2*n_terr*0.8) * 2.8 * (whs + 0.02)
	local dnoi = 2.8 * n_terr * (0.5 + n_terr^2 + n_terr2*0.8) * (whs + 0.02)
	local pos = {x=x,z=z}   -- y set in the loop
	---------------------------------------------------
	local basin
	local river_basin
	local shelfnoi
	local shelfsl
	local laked = -25 + 10 * n_terr2
	local zab = math.abs(z)
	local shelfnoi_xz = (n_terr^3 + n_terr2*0.08) * CONOI
	local laker_0 = 160 + 100*n_terr + 25*n_terr2
	local laker_1 = laker_0/(160 + 20*n_terr)
	local wp = 8 + 0.0003*xab
	local w_0 = wp - 3*n_terr2^3
	local w_1 = wp/(8 + 2*n_terr)
	local per_ch = (3.5*n_terr + 22) * wp --period of channel
	local interr2 = 1-n_terr2
	local am_ch = (interr2 + 4.6) * wp --amplitude
	local c1 = am_ch*math.sin(x/per_ch) --wave for channel
	local c2 = (12 + 3*interr2)*math.sin(x/(56 + 8*n_terr))
	local channel = c1 + c2
	---------------------------------------------------
	for y = alt_max, alt_min, step do
		pos.y = y
		local val_cave   = noi_cave:get_3d(pos)
		local val_cave2  = noi_cave2:get_3d(pos)
		local val_strata = noi_strata:get_3d(pos)
		local dclif2 = math.abs(val_cave*val_cave2*0.05)
		local den_base = dwav + dnoi - math.abs(val_strata)*0.16 - dclif2
		local den_soft = den_base*0.4  + 1.3 + (1-n_terr) * (2.22 - xtgrad*2) - dclif2
		local den_allu = den_soft*0.95 + 0.1 - dclif2  --Alluvium --eroded rock etc, deposited on lowlands
		local den_sedi = den_allu      + 0.03 --Sediment--subsurface soils and sands
		local t_base = 0.00969*y --Base Threshold (use for all of them now) effects heights of landscape
		if den_base > t_base
		or den_soft > t_base
		or den_allu > t_base
		or den_sedi > t_base then
			river_basin = false		--river basin
			shelfnoi = shelfnoi_xz - dclif2
			shelfsl = (3 - n_terr^3)*y --sets slope for x
			if y >= SEABED
			and (xab > (SHELFX + shelfnoi*2 - shelfsl) --Are we in the right place for oceans?
			or   zab > (SHELFZ + shelfnoi   - shelfsl)) then
				basin = true
			else
				basin = false
				local laker = laker_0 + laker_1*y
				local w = w_0 + w_1*y
				for n = 0, num_lakes do
					if  math.abs(x - lakes[n].x) < laker*1.6
					and math.abs(z - lakes[n].z) < laker
					and y > laked then
						river_basin = true
					end
					if lakes[n].r <= 4 then
						if  z <= lakes[n].z + channel + w
						and z >= lakes[n].z + channel - w then
							if lakes[n].x > 0 and x + w > lakes[n].x then
								river_basin = true
							elseif lakes[n].x < 0 and x - w < lakes[n].x then  --west lakes, only place river further west
								river_basin = true
							end
						end
					end
				end
			end
			if not basin and not river_basin then
				logg("+++++++++++ find_ground_level_at ".. x ..",".. z .." -> y= " .. y .." took " .. math.ceil((minetest.get_us_time()-t0)/1000) .. " miliseconds")
				--string.format("elapsed time: %.5f\n", os.clock() - x)
				return y
			end
		end
	end
	logg("+++++++++++ find_ground_level_at ".. x ..",".. z .." -> reached alt_min " .. alt_min .." took " .. math.ceil((minetest.get_us_time()-t0)/1000) .. " miliseconds")
	return alt_min
end

local spawnplayer = function(player,alt_max)
	local pos = spawnpoint
	pos.y = 2 + find_ground_level_at(pos.x,pos.z, alt_max, 0) --(x, z, alt_max, alt_min)
	player:setpos(pos)

	--save location
	mod_storage:set_int("x", pos.x)
	mod_storage:set_int("y", pos.y)
	mod_storage:set_int("z", pos.z)
end

--Based on minetest-5.0.1-win32/builtin/game/chatcommands.lua
minetest.register_chatcommand("xteleport", {
	params = "<X>,<Z>",
	description = "Teleport to position X,Z at ground level",
	privs = {teleport=true},
	func = function(name, param)
		-- Returns (pos, true) if found, otherwise (pos, false)
		--[[
		local function find_free_position_near(pos)
			local tries = {
				{x=1,y=0,z=0},
				{x=-1,y=0,z=0},
				{x=0,y=0,z=1},
				{x=0,y=0,z=-1},
			}
			for _, d in ipairs(tries) do
				local p = {x = pos.x+d.x, y = pos.y+d.y, z = pos.z+d.z}
				local n = minetest.get_node_or_nil(p)
				if n and n.name then
					local def = minetest.registered_nodes[n.name]
					if def and not def.walkable then
						return p, true
					end
				end
			end
			return pos, false
		end
		--]]------------------------------------------------
		local teleportee = nil
		local p = {}
		--p.x, p.y, p.z = string.match(param, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
		p.x, p.z = string.match(param, "^([%d.-]+)[, ] *([%d.-]+)$")
		p.x = tonumber(p.x)
		p.z = tonumber(p.z)
		if p.x and p.z then
			if p.x < YMIN or p.x > YMAX or p.z < YMIN or p.z > YMAX then
				return false, "Cannot teleport out of map bounds!"
			end
			teleportee = minetest.get_player_by_name(name)
			if teleportee then
				local survival = minetest.settings:get_bool("enable_damage")
				--local alt_min = SEABED  --0
				local alt_min = survival and 0 or SEABED
				logg("Survival: " .. dump(survival) .. " alt_min = " .. alt_min )
				p.y = 2 + find_ground_level_at(p.x,p.z,ALT_START,alt_min)
				teleportee:set_pos(p)
				minetest.log("action", "Xteleporting " .. name .. " to " .. minetest.pos_to_string(p))
				return true, "Teleporting to ".. minetest.pos_to_string(p)
			end
		else
			return false, 'Invalid parameters ("' .. param .. '") , expected params <X>,<Z>'
		end
	end,
})
--======================= END OF NEW FUNCTIONS =====================================================================================

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
	spawnplayer(player,ALT_START)


	-- Get the inventory of the player
	local inventory = player:get_inventory()
	--give them some gear to help in survival mode
	--sometimes spawns in barren places

	--inventory:add_item("main", "default:pick_stone")
	--inventory:add_item("main", "default:torch 15")
	--inventory:add_item("main", "default:ladder 10")
	inventory:add_item("main", "farming:bread 7")
	inventory:add_item("main", "farming:seed_wheat 4")
	inventory:add_item("main", "farming:seed_cotton 4")
	inventory:add_item("main", "default:sapling")
end)


--default clouds are way too low...raise them
local init_cloud = function(player)
	player:set_clouds({color="#FFFFFFFC", density=0.40, height=1500, thickness=25, speed ={x=1, z=0}})
end

--use beds rather than original spawn point
local enable_bed_respawn = minetest.settings:get_bool("enable_bed_respawn")
if enable_bed_respawn == nil then
	enable_bed_respawn = true
end


--this is needed to stop it putting player at 0,0,0...but overrides bed save :-(
minetest.register_on_respawnplayer(function(player)
	init_cloud(player)
	-- Avoid respawn conflict with beds mod
	if beds
	and enable_bed_respawn
	and	beds.spawn[player:get_player_name()] then
		return
	end

	savedspawn(player)
	--disable default
	return true
end)


minetest.register_on_joinplayer(init_cloud)

---------------------------------------
--Bug testing Climate tool
--need to give n_terr etc or gives inaccurate reading,
-- and blend gives a random margin of error
--[[
local enviro_meter = function(user, pointed_thing)

	local name =user:get_player_name()
	local pos = user:getpos()

	minetest.chat_send_player(name, minetest.colorize("#00ff00", "ENVIRONMENT MEASUREMENT:"))

	local t,h,d = mgtec.climate(pos.x, pos.z, pos.y)

	minetest.chat_send_player(name, minetest.colorize("#cc6600","TEMPERATURE INDEX LEVEL = "..t))
	minetest.chat_send_player(name, minetest.colorize("#cc6600","HUMIDITY INDEX LEVEL = "..h))
	minetest.chat_send_player(name, minetest.colorize("#cc6600","DISTURBANCE INDEX LEVEL = "..d))


end


minetest.register_craftitem("mg_tectonic:enviro_meter", {
	description = "Enviro Meter",
	inventory_image = "default_paper.png",
	stack_max = 1,

	on_use = function(itemstack, user, pointed_thing)
		enviro_meter(user, pointed_thing)
	end,
})
--]]
