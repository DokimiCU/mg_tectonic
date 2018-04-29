---================================================================
--MG TECTONIC
--By Dokimi

--A naturalistic mapgen.


--========================================================================
mgtec = {}

--==================================================================
--FUNCTIONS
--for bits that get used a few times.

--Check if this is a place in basement rock for ore deposits.
--we set two layers of basement, so we do this twice... hence the function
local function ore(b_stone, void, y, data, vi, ystrata, TSTRA, OREID, n_cave, n_cave2, n_strata, n_terr, n_base)
	--c_coal, c_iron, c_copp, c_tin, c_gold, c_diam, c_mese
	--this makes largish balls of ore, but widely scattered.

	--strata splits for ore types..
	local sbl = n_strata * TSTRA --blend seam layers
	local t1 = (0.25 * TSTRA) + sbl
	local t2 = (0.5 * TSTRA) + sbl
	local t3 = (0.83 * TSTRA) + sbl

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
	]]

	--lower the threshold a few times with depth.
	-- so that depth leads to bigger deposits

	--noises and threshold for abundant /rare ores
	--not split into rare and abundant... the difficulty of finding a mine is challenge enough
	local ore_n = math.abs(n_cave2 - (n_strata * 0.02) + (n_terr * 0.045))
	local ore_t = 0.95 - (n_terr * 0.01) - (n_base * 0.01)
	local orehmin_c = -9000 + (n_strata * 500) --min height for coal (a shallow ore)
	local orehmax_g = -50 + (n_cave * 25)   --dig a little for gold
	local orehmax_d = -100 + (n_cave * 50)   --diamonds are deep
	local orehmax_m = -150 + (n_cave * 50)   --mese is deep

	--above their threshold
	if ore_n >= ore_t then

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
		elseif  y > orehmax_g
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
		and (ystrata > t3    --strata splits
		or ystrata < -t3) then
			data[vi] = OREID.c_mese
			return true
		end
			--end of rare ores
	else
		--have to let it know so it can set void etc
		return false
	end
	--end of all ores
end
--End of Ore function

------------------------------
--Climate Calculations.
local function climate(x, z, y, n_terr, n_base)
	--east = + x, west = - x, south = -z, n = + z
	--Climate is decided by:
	-- -Ranges: rains come from the west (-x), rise over the ranges dumping cooling rain, descending hot and dry (east +x)
	-- - Altitude: it's cold up there.
	-- - Latitude: hot north, cold south

	--Fohn Winds! They are hot! The East Coast is a hot dry place
	--increasing temp from far +x to x = 0,(rain shadow) (from 50 to 100)

	-- no Fohn? Westies have it mild
	local temp_x = 50 + (n_terr * 10)

	-- Easterners?
	if x > 0 then
		-- linear decrease, intercept at 100 (don't use in -x)
		temp_x = (-0.0017*x) + 100 + (n_terr * 10)
	end

	--We are Southern Hemisphererers here!
	--decreasing temp from max z to min z (latitude) (from 100 to 0 i.e north desert to south ice)
	-- linear increase, intercept at 50
	local temp_z = (0.0017*z) + 50 + (n_terr * 10)

	--Mountain tops ought to be cold!
	--decreasing temp with hieght
	--linear decrease. Does total snow at x,z=0 at ~y=120 ..last time I checked
	local temp_y = (-0.3*y) + 60 + (n_base * 10)

	local temp

	--altitude effect not important down low. (stops alt mellowing others)
	if y < (30 + math.random(-4, 4)) then
		temp = ((temp_x + temp_z)/2) + math.random(-4, 4)
	--at altitude the others stop mattering (stops them mellowing out mountain tops)
elseif y > (100 + math.random(-4, 4)) then
		temp = temp_y
	else
	--average temperate influences. Plus a little random to soften edges
	temp = ((temp_x + temp_z + temp_y)/3) + math.random(-4, 4)
	end


	--what's the humidity? Rainshadow!
	--decreasing humid from far x to x= 0,(rain shadow) (from 50 to 0)

	--if in doubt ...
	local hum = 50 + (n_base * 10)

	----poitive, east coast. Dry inland
	--linear increase, intercept at 10
	if x > 0 then
		hum = (0.0013*x) + 10 + (n_terr * 10)
	--increasing humid from far x to x= 0,(rain shadow) (from 50 to 100)
	elseif x <= 0 then  --negative , west coast. Wet inland
		--linear increase, intercept at 100
		hum = (0.002*x) + 100 + (n_terr * 10)
	end

	--give a boost to low altitude.. (they tend to be near water)
	--and to hill tops (catch rain)
	if y < 10 or y > 75 then
		hum = hum + (hum*0.15)
	end

	hum = hum + math.random(-4, 4)

	--to create interest we need a few odd patches. Places were conditions are abnormal.
	local denpat = (1-n_terr) + (1-n_base)
	if denpat > 1.90 or denpat < -1.90 then
		temp = temp + (temp * n_base * 0.55)
		hum = hum + (hum * n_terr * 0.55)
	end

return temp, hum
--done climate calculations
end


--Create Swamp
local function swamp(data, vi, chance, mud, water, void, sedi, n_base)

	--we'll use a bit of noise
	local ab_base = math.abs(n_base) * chance

	--let's place a messy swampy mire
	local roll = math.random(1, chance)
	if roll <= 1 + ab_base  then
		data[vi] = water
		water = true
		void = false
	else
		data[vi] = mud
		sedi = true
		void = false
	end
--end of swamp
end




--End of functions

--=============================================================
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

--==============================================================
-- PARAMETERS
-- the edge of the map
local YMAX = 33000
local YMIN = -33000

-------------------------------------------------------
--Base Layer Waves:
--This starts the landscape off, gives a base for more extreme terrain on top.
--keep it mild

--Wave Height Strength:
-- for the mountain waves
--too high gives weirdness e.g. floats...too low is boring...
--...better to sacrifice interest to eliminate absurdity?
local WHS = 0.50

-- Wave Size:
--Controls distance between ranges, and thickness. Too thin gives "slices"
local XRS = 40
local ZRS = 30


--Wave Influence:
-- Balancing them against each other controls which axis forms ranges, which ridges
-- Too high gives weirdness.
local XINF = 0.495		-- x axis wave
local ZINF = 0.285		-- z axis wave

--"MUP' Strength for Base layer
--'mup' is an equation for lifting the map centre, and sinking the edges.
-- it raises a central highland, and creates oceans and the edges.
-- May overwhelm the influence of the mountains where its strong (hence highlands, rather than high mountains)
-- too high creates absurdities
local MUPST = 0.5

-------------------------------
--Jagged Waves
--For more extreme basement rock mountains.

--Wave Height Strength "Jagged":
-- High values give mesas and tall pillars.
local WHSJ = 1.07
--Wave Influence:
local XINFJ = 1.79
local ZINFJ = 0.59

--Height limiter for "Jagged" Mountains
local YLIMJ = 416

-----------------------------
--Strata Thickness:
-- bigger is thicker and wider apart
local TSTRA = 17

-------------------------------
--Sedimentary Rock
--Soft stone Layered on top of basement rock.

--Height limiter for Sedimentary Rock
local YLIMS = 256

--Influence of noise on sedimentary rock
local SNOI = 0.02

--Depth of sedimentary rock over basement rock
local SRDEP = 1.05


---------------------------------
--Regolith
--gravel, clay, sand i.e. broken rock

-- height limiter for regolith
local YLIMR = 300

-- depth for regolith
local	REDEP	= 1.089

------------------------------
--Sediments
-- soils, sands, etc.
--Note... this will impact the final landscape height

-- Height limiter for Sediment
local YLIMSD = 256

--Sediment depth
local SEDEP = 1.039

	--------------------------------
	--Putting cave parameters in a table because of the >60 upvalues error

	--(note caves have a hard max height of +50)
	local PCAV = {
		-------------------------------
		--Caves 1
		--max height for fissures (+/- some noise)
		MAXFIS = 15,
		-- max height for side caves (+/- some noise)
		MAXCAV = 35,
		-- Cave size.
		BCAVTF = 0.0021, --fissures
		BCAVT = 0.89,		--blobs
		--height of magma layer, fills caves. Has precious minerals
		MAXMAG = -9000,

	-----------------------------
		--Caves 2
		--Sedimentary cave size. (the threshold. Lower means bigger.)
		SCAVT = 0.95,
		-- max height for sedimentary caves (+/- some noise)
		MAXCAV2 = 70,

		------------------
		--canyons
		--size. (the threshold. high means bigger.)
		BCANT = 0.04,

	}	--end of PCAV

------------------------------
local SEA = 0  --sealevel

local PSEA = {
	--Where does the continental shelf end?
	SHELFX = 25000,
	SHELFZ = 25000,
	--How deep are the oceans?
	SEABED = -64,
	--Strength of noise on continental shelf boundaries lines
	--no/low means a flat wall. Too much creates big overhangs. Just right...cliffs!
	CONOI = 1048,

}

-----------------
--Any new paramters will need to go in tables due to >60 upvalues limit!

--===============================================================
--NOISES

-- 3D Base .. a more generic noise
-- used by: sedimentary rocks layer. A little added to Deep caves. Magma height
--..ore thresholds, climate distribution, water in swamps
local np_base = {
  offset = 0,
  scale = 0.55,
  seed = 1234,
  spread = {x = 512, y = 384, z = 512},
  octaves = 3,
  persist = 0.5,
  lacunarity = 2,
  --flags = ""
}

-- 3D Mountain Terrain... long stretched noise.
--used by: basement layer waves. Ore distribution, climate distribution,
local np_terrain = {
   offset = 0,
   scale = 1,
   spread = {x = 2048, y = 1024, z = 4096},
   seed = 5900033,
   octaves = 7,
   persist = 0.45,
   lacunarity = 2.3,
   --flags = "eased"
}



-- 3D Strata
-- used by: waves for mountain folding. Strata layers. Blending ore strata
local np_strata = {
   offset = 0,
   scale = 1,
   spread = {x = 64, y = 64, z = 64},
   seed = 51055033,
   octaves = 2,
   persist = 0.4,
   lacunarity = 2,
   --flags = ""
}

-- 3D Caves 1
--used by: fissures in basement rock, larger side caves in basement rock
local np_cave = {
   offset = 0,
   scale = 1.1,
   spread = {x = 128, y = 512, z = 256},
   seed = -9103323,
   octaves = 4,
   persist = 0.25,
   lacunarity = 2.5,
   --flags = ""
}

-- 3D Caves 2
--used by: blobby caves in sedimentary rock, ore distribution
local np_cave2 = {
  offset = 0,
	scale = 1,
	spread = {x = 128, y = 64, z = 96},
	seed = 205301,
	octaves = 6,
	persist = 0.5,
  lacunarity = 2.2,
  --flags = ""
}


-- 3D Canyon... long stretched noise.
--used by:
local np_canyon = {
   offset = 0,
   scale = 1,
   spread = {x = 256, y = 128, z = 96},
   seed = 77331,
   octaves = 3,
   persist = 0.1,
   lacunarity = 2.1,
   --flags = "eased"
}


---=================================================================
--SINGLENODE
-- Set singlenode mapgen (air nodes only).
-- Disable the engine lighting calculation since that will be done for a
-- mapchunk of air nodes and will be incorrect after we place nodes.

minetest.set_mapgen_params({mgname = "singlenode", flags = "nolight"})



---============================================================
--ID
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
--put into a table bc of >60 upvalues error
local MISCID = {
	c_water     = minetest.get_content_id("default:water_source"),
	c_river     = minetest.get_content_id("default:river_water_source"),
	c_air = minetest.get_content_id("air"),
	c_ignore = minetest.get_content_id("ignore"),
	c_lava = minetest.get_content_id("default:lava_source"),
}

--ores
--put into a table bc of >60 upvalues error
local OREID = {
	c_diam = minetest.get_content_id("default:stone_with_diamond"),
	c_mese = minetest.get_content_id("default:stone_with_mese"),
	c_gold = minetest.get_content_id("default:stone_with_gold"),
	c_copp = minetest.get_content_id("default:stone_with_copper"),
	c_tin = minetest.get_content_id("default:stone_with_tin"),
	c_iron = minetest.get_content_id("default:stone_with_iron"),
	c_coal = minetest.get_content_id("default:stone_with_coal")
}
--[[--just here for reference
--Trees
local c_tree = minetest.get_content_id("default:tree")
local c_leaves = minetest.get_content_id("default:leaves")
local c_apple = minetest.get_content_id("default:apple")
local c_jungletree = minetest.get_content_id("default:jungletree")
local c_jungleleaves = minetest.get_content_id("default:jungleleaves")
local c_pine_tree = minetest.get_content_id("default:pine_tree")
local c_pine_needles = minetest.get_content_id("default:pine_needles")
local c_acacia_tree = minetest.get_content_id("default:acacia_tree")
local c_acacia_leaves = minetest.get_content_id("default:acacia_leaves")
local c_aspen_tree = minetest.get_content_id("default:aspen_tree")
local c_aspen_leaves = minetest.get_content_id("default:aspen_leaves")

--flora
local c_dryshrub = minetest.get_content_id("default:dry_shrub")
local c_cactus = minetest.get_content_id("default:cactus")
local c_papyrus = minetest.get_content_id("default:papyrus")
local c_bstem = minetest.get_content_id("default:bush_stem")
local c_bleaves = minetest.get_content_id("default:bush_leaves")
local c_acbush_stem = minetest.get_content_id("default:acacia_bush_stem")
local c_acbush_leaves = minetest.get_content_id("default:acacia_bush_leaves")

--flowers and mushies
local c_danwhi = minetest.get_content_id("flowers:dandelion_white")
local c_danyel = minetest.get_content_id("flowers:dandelion_yellow")
local c_rose = minetest.get_content_id("flowers:rose")
local c_tulip = minetest.get_content_id("flowers:tulip")
local c_geranium = minetest.get_content_id("flowers:geranium")
local c_viola = minetest.get_content_id("flowers:viola")
local c_shroomr = minetest.get_content_id("flowers:mushroom_red")
local c_shroomb = minetest.get_content_id("flowers:mushroom_brown")
local c_wlily = minetest.get_content_id("flowers:waterlily")

--crops
local c_wheat = minetest.get_content_id("farming:wheat")
local c_cotton = minetest.get_content_id("farming:cotton")

--grass
local c_jungrass = minetest.get_content_id("default:junglegrass")
local c_grass1 = minetest.get_content_id("default:grass_1")
local c_grass2 = minetest.get_content_id("default:grass_2")
local c_grass3 = minetest.get_content_id("default:grass_3")
local c_grass4 = minetest.get_content_id("default:grass_4")
local c_grass5 = minetest.get_content_id("default:grass_5")
local c_dgrass1 = minetest.get_content_id("default:dry_grass_1")
local c_dgrass2 = minetest.get_content_id("default:dry_grass_2")
local c_dgrass3 = minetest.get_content_id("default:dry_grass_3")
local c_dgrass4 = minetest.get_content_id("default:dry_grass_4")
local c_dgrass5 = minetest.get_content_id("default:dry_grass_5")


]]







---=============================================================
--NOISE MEMORY

-- Initialize noise object to nil. It will be created once only during the
-- generation of the first mapchunk, to minimise memory use.
local nobj_base = nil
local nobj_terrain = nil
local nobj_strata = nil
local nobj_cave = nil
local nobj_cave2 = nil
local nobj_canyon = nil


-- Localise noise buffer table outside the loop, to be re-used for all
-- mapchunks, therefore minimising memory use.
local nvals_base = {}
local nvals_terrain = {}
local nvals_strata = {}
local nvals_cave = {}
local nvals_cave2 = {}
local nvals_canyon = {}


-- Localise data buffer table outside the loop, to be re-used for all
-- mapchunks, therefore minimising memory use.
local data = {}


----===============================================================
-- GENERATION

-- 'minp' and 'maxp' are the minimum and maximum positions of the mapchunk that
-- define the 3D volume.
minetest.register_on_generated(function(minp, maxp, seed)

	--don't do out of bounds!
  if minp.y < YMIN or maxp.y > YMAX then
		return
	end

   -- Start time of mapchunk generation.
   local t0 = os.clock()

------------------------------------------------------
   -- NOISE

   -- Side length of mapchunk.
   local sidelen = maxp.x - minp.x + 1

   -- Required dimensions noise perlin map.
   local chulen = {x = sidelen, y = sidelen, z = sidelen} --3d

	 -- strides for voxelmanip
	 local ystridevm = sidelen + 32
	 local zstridevm = ystridevm ^ 2

   -- Create the perlin map noise object once only, during the generation of
   -- the first mapchunk when 'nobj_terrain' is 'nil'.
   nobj_base    = nobj_base    or minetest.get_perlin_map(np_base, chulen)
   nobj_terrain = nobj_terrain or minetest.get_perlin_map(np_terrain, chulen)
   nobj_strata = nobj_strata or minetest.get_perlin_map(np_strata, chulen)
   nobj_cave = nobj_cave or minetest.get_perlin_map(np_cave, chulen)
   nobj_cave2 = nobj_cave2 or minetest.get_perlin_map(np_cave2, chulen)
	 nobj_canyon = nobj_canyon or minetest.get_perlin_map(np_canyon, chulen)

   -- Create a flat array of noise values from the perlin map, with the
   -- minimum point being 'minp'.
   -- Set the buffer parameter to use and reuse 'nvals_X' for this.
   nobj_base:get3dMap_flat(minp, nvals_base)
   nobj_terrain:get3dMap_flat(minp, nvals_terrain)
   nobj_strata:get3dMap_flat(minp, nvals_strata)
   nobj_cave:get3dMap_flat(minp, nvals_cave)
   nobj_cave2:get3dMap_flat(minp, nvals_cave2)
	 nobj_canyon:get3dMap_flat(minp, nvals_canyon)

--------------------------------------------------------------
   -- VOXELMANIP

   -- Load the voxelmanip with the result of engine mapgen. Since 'singlenode'
   -- mapgen is used this will be a mapchunk of air nodes.
   local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")

   -- 'area' is used later to get the voxelmanip indexes for positions.
   local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}

   -- Get the content ID data from the voxelmanip in the form of a flat array.
   -- Set the buffer parameter to use and reuse 'data' for this.
   vm:get_data(data)

------------------------------------------------
   -- GENERATION LOOP

	 -----------------------------------------------
	 --Begin the Loop

   -- Noise index for the flat array of noise values.
   local nixyz = 1 -- 3D perlinmap indexes




   -- Process the content IDs in 'data'.
   -- The most useful order is a ZYX loop because:
   -- 1. This matches the order of the 3D noise flat array.
   -- 2. This allows a simple +1 incrementing of the voxelmanip index along x
   -- rows.
   for z = minp.z, maxp.z do

   for y = minp.y, maxp.y do

      -- Voxelmanip index for the flat array of content IDs.
      -- Initialise to first node in this x row.
      local vi = area:index(minp.x, y, z)

      for x = minp.x, maxp.x do

        ----------------------------------------------------
				--Welcome to the Loop


        ----------------------
        --Get the Noise values
				local n_base = nvals_base[nixyz]
				local n_terr  = nvals_terrain[nixyz]
				local n_strata = nvals_strata[nixyz]
        local n_cave = nvals_cave[nixyz]
        local n_cave2 = nvals_cave2[nixyz]
				local n_canyon = nvals_canyon[nixyz]

				local ab_stra = math.abs(n_strata)
				local ab_terr = math.abs(n_terr)
				local ab_base = math.abs(n_base)




        -----------------------
				--Wave Densities

				--First we need to find the density value...
				-- this decides the boundaries between air and land..
				-- and is used to layer rocks etc over one another.

				-----------
				-- Math

				--absolute for x and z (for symmetry on both sides of map)
				local xab = math.abs(x)
				local zab = math.abs(z)
        --x axis terrain gradient. 0 at centre. 1 at edges.
				--Used by equations to adjust along x axis
        local xtgrad = ((xab)/YMAX)
        --Move up/down along x axis. Goes from +1 to -1
        --mup raises and lowers along x axis. the two terms cancel out in middle of x range (15k).
        --aimed for equations that need to lift map centre, sink edges
        local mup = (1 - xtgrad) + (-1 * xtgrad)

				--trying it with a little bit of noise in the hope it produces some more interesting terrain.
				local mupn = mup * (MUPST + (n_base*0.2))

				------------------
				--Base Layer Waves

				-- this is the first of two sets of waves for setting the basement stone.
				--We need to do two sets of waves if we are to use stability mechanisms.
				-- We need to use stability to get natural terrain (e.g. no floating spaghetti)
				-- The first node to ever be set will have nothing under it. Therefore something must come first.

				-- This base layer therefore is meek and mild.
				-- It must have not produce floats and insanity!
				-- Wilder terrain is then layered on top of this layer and kept under control by stability checks.


				--Wave height. controls mountain hieght
				-- Reduced to 0 along x axis... eliminates mountains at edges.
				--with noise for interest
        local wavh = WHS + n_terr



				--Wave "Roll". i.e. how wide/steep and they are.
				-- Noise for interest.
				--Gradient widens the ranges towards the edges.
        local x_roll = XRS + (XRS * xtgrad) + (n_terr * 3)   --x axis
        local z_roll = ZRS + (ZRS * xtgrad) +(n_terr * 10) -- z axis,

				--The Waves!
        local xwav = (wavh*math.cos(x/x_roll))    -- north south wave (main ranges)
        local zwav = (wavh*math.sin(z/z_roll))    --east west wave (ridges)

				--Wave Influence
				-- influence of the x and z axis waves on the final density.
				--Reduced to 0 along x axis... eliminates role of mountains at edges.
				local xstr = XINF * (ab_stra) * (1 - xtgrad)
				local zstr = ZINF * (ab_stra) * (1 - xtgrad)

				--Base Wave Density.
				--This is checked against the threshold to decide where the base layer can go.
        local den_base = mupn + (xwav * xstr) + (zwav * zstr)


				---------------------
        --Jagged Layer Waves
				-- The second set of waves.
				-- This is for more extreme mountains layered on top of the base layer
        -- subject to support checks.

				--Wave height "Jagged"
        local wavhj = 0.2 + (WHSJ * n_terr)



				--The "Jagged" Waves
				--use the same roll as base layer, they need to match.
				local xwavj = (wavhj*math.cos(x/x_roll))
				local zwavj = (wavhj*math.sin(z/z_roll))

				-- "Jagged" Wave Influence
        local xstrj = XINFJ * (ab_stra) * (1 - xtgrad)
        local zstrj = ZINFJ * (ab_stra) * (1 - xtgrad)


				--Y axis gradient "Jagged"
				--limits height of mountains
				-- trends towards -1 at the denominator. Continues lower after
				-- Eventually cancels out any other influences
				local ygradj = (1 - y) / YLIMJ

				--"Jagged" Density
				--for passing to the next layer without the effect of the height limiter
				local den_jpass = mupn + (xwavj * xstrj) + (zwavj * zstrj) + n_terr
				-- the actual density
				local den_j = den_jpass + ygradj


				-----------------------------------
				--One more wave... Strata

				--strata
				local TSTRA = 15 -- changes sin thickness and spacing (bigger = thick and wide apart) (for strata)

				--A y axis wave. Used to divided the vertical space into strata layers
				--WHEN DOING ORES COME BACK HERE!!!!!
				local ysine = math.sin(y/TSTRA)    --this is also used for ore, because it's tidier...just adjust them by TSTRA?
				local ystrata = TSTRA * ysine




				--------------------------------
				-- We are finished calculating waves.
				-- now we can layer on densities...
				-- ..to figure out where the highest layer (sediments) will be.
				-- These layers are created by taking the previous density...
				-- ..and adding to it, potentially with a little noise.
				--They add more to the base of existing mountains, widening them.
        -- The trick with the values is to get them to show up at all, but not swamp everything.
				---------------------------------


				----------------------------------
				--Sedimentary Rock Layer
				--soft rock

				--height limiter for sedimentary rock
				local ygradsr = (1 - y) / YLIMS



				-- Density for Sedimentary Rock
				--local den_srpass = ((den_base + den_jpass) * SRDEP) + (n_base * SNOI)
				local den_sr = ((den_base + den_jpass) * SRDEP) + (n_base * SNOI) + ygradsr




				----------------------------------
				--Regolith Layer
				--gravel, sands, clay

				--lift with plains?
				local pllift = (xtgrad * 0.18)
				--trying to add on the xtgrad (0 to 1 with x axis,)
				-- see if it pushes it up at the coasts..
				--.Otherwise this layer never shows up. Although it can, so is'nt bugged.
				--too strong and this add several meters of dirt and regolith.
				--too weak it has no effect....but just right... and finally these layers show up!
				--also pushes coast out.

				--height limiter for regolith
				local ygradr = (1 - y) / YLIMR

				-- Density for Regolith
				--local den_regopass = (den_srpass * REDEP)
				--local den_rego = den_regopass +  ygradr
				local den_rego = den_sr +  ygradr + pllift

				--.Otherwise this layer never shows up. Although it can, so is'nt bugged.

				--------------------------------
				--Sediment Layer
				-- soil, sand, snow...
				-- biome based


				--height limiter for sediments
				local ygradsd = (1 - y) / YLIMSD


				-- Density for sediments

				--local den_sedipass = (den_regopass * SEDEP)
        --local den_sedi = den_sedipass + ygradsd
				local den_sedi = den_rego + ygradsd + pllift


				-----------------------------------
				--We are now done calculating densities.
				--We have the highest density (technically second highest, it will get "skin" latter)
				-- We can now use this to split the possibility space into definitely-not-land, and maybe-land.
				--------------------------------------


				---------------------------------
				---Thresholds
				-- if a density crosses this then... pow! It is land.(or whatever)

				-- Density threshold:
				--The great divider!
				-- This is a power curve. A "diminshing returns" curve that starts at 0, and asymptopes around +1
				-- ~ 0.5 at 50 m, ~0.95 at 250m
				-- makes it increasingly unlikely something will cross the threshold with increasing height.
				-- should help eliminate floats.
				-- A power curve means abundant small rises, and rare tall mountains. Should help splay the base of mountains.
				--Helps stop mountains being dome shaped (the natural result of the waves)?
				local den_t = 1 - (1.056 ^ (-0.25*y))


				-------------------------------------
				--Checks
				--This is so we know if we placed something.
				-- Void so we can just ask: is something been asigned?
				-- IDs for relevant layers, so we can do any needed adjustments using them.

				local void = true  -- we have yet to set anything

        local b_stone = false --basement stone..
        local s_stone = false --sedimentary stone
        local rego = 	false -- regolith and scree
        local water = 	false  --oceans, rivers, lakes
        local sedi = 		false --subsurface dirt, sand etc
				local lava = false

				local nocave = true		--basement rock caves
				local nocave2 = true	--sedimentary caves
				local basin = false   --an ocean basin
				local nocanyon = true --canyons

				----------------------------------------
				--Stability Check
				-- looks at place below the current node.
				-- For those options that require to be placed on top of something

				--Get the node underneath
					local nodu  = data[(vi - ystridevm)]
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

					--Bug issue!
					--including ignore leads to blank patches...
					--New chunks decide they are unsupported because below them hasn't been set.
					-- so the bottom layer doesn't get set. Therefore nothing else does either.
					--But...
					--leaving it out??? Possible over hangs.

					--------------------------------------------------

					--THE DECISION TREE
					-------------------------------------------------
					--The First Split
					-- divide our options into definitely not land, and maybe land.
					-- this saves us going down the rabbit hole for things that will never meet even the most extreme case.
					--... so we start with the extreme case. Sediment has the highest density.
					--(note: using the non-height limited one)




						if den_sedi > den_t then
						--we might have land!
						--now we can move up the layers.
						-- we start at the bottom, because otherwise we would always be overwritting it.

						--now we need to check for anything that would block basement rock.
						-- this means caves, and ocean basins

						--------------------
		        --Are There Caves? or Canyons

						--a hard limit so we don't waste time calculating it for the sky etc
						if y < 85 then



							--only figure this out if at the right depth
							--using some noise so don't have flat roof
							local cav_lim1 = PCAV.MAXFIS - (ab_stra*30)
							local cav_lim2 = PCAV.MAXCAV - (ab_stra*30)
							--for adding/subtracting from thresholds
							local ybig = ((y/YMAX)*0.25)



							--Fissures?
							--to get the snaking plane we need to start by emptying the world..
							nocave = false
							--now our threshold for filling back in the non-cave world
							--if the noise is above this. we have ground... lower the threshold.. more ground.
			        local cav_t1 = PCAV.BCAVTF + (den_j * 0.005) + ybig

							--check... can we fill in the non-cave?
							--extra noises break up sheet
							if math.abs(n_cave) >= cav_t1
							or math.abs(n_strata ^ 3) >= cav_t1
							or y > cav_lim1 then
								nocave = true
							end


							--Rounder caves?
							--These use the same noise as fissures, so they become side chambers.
							-- the other two seem to pull it off more or less at right angles
							-- reverse deal from fissures.
							--If the noise is above the threshold we empty out a cave
							-- lower threshold = bigger cave..
							local cav_t2 = PCAV.BCAVT - (ab_terr*0.01) - ybig

							if y < cav_lim2
			        and (n_cave >= cav_t2
						 	or n_cave2 ^ 3  >= cav_t2 -0.005
							or n_canyon ^ 3 >= cav_t2)
					 		then
			          nocave = false
							end



							--Canyons?
							--like fissures, but height limited floor
							local ab_can = math.abs(n_canyon)
							--lower the canyon floor downslope..start very high in mounts... then drop
							local canfloor = 100*math.exp(-0.00022*xab)
							nocanyon = false
							--make them bigger further down slope
							--adjust by altitude so that a y = 0 they are gone
			        local can_t = PCAV.BCANT + (xtgrad * 0.06) * (y/4)

							--check... can we fill in the non-canyon?
			        if nocave
							and ab_can >= can_t
							or y < canfloor then --if we are above the max height it has to be ground.
			          nocanyon = true
			        end



							--Lava?
							--If we did end up with these caves we need to deal with them...
							-- deep down they fill with lava
							local magdepth = PCAV.MAXMAG + (n_base * 10)

							if y < magdepth then
								--fill the caves...
								--this puts ores
								if not nocave then
									--strata splits for ore types..
									local sbl = n_strata * TSTRA --blend seam layers
									local t1 = (0.25 * TSTRA) + sbl
									local t2 = (0.5 * TSTRA) + sbl
									local t3 = (0.83 * TSTRA) + sbl

									if n_strata >= 0.32 then

										--split them by height and strata
										--coal.--doesn't make sense to be there, can use lava as fuel
										--[[
										if ystrata >= 0     --strata splits
										and ystrata < t2
										then
											data[vi] = OREID.c_coal
											b_stone = true
											void = false
											]]
										--iron
										if ystrata > -t1    --strata splits
										and ystrata < 0 then
											data[vi] = OREID.c_iron
											b_stone = true
											void = false
										--copper
										elseif ystrata > t1    --strata splits
										and ystrata < t2 then
											data[vi] = OREID.c_copp
											b_stone = true
											void = false
										--tin
										elseif ystrata > -t1    --strata splits
										and ystrata < -t2 then
											data[vi] = OREID.c_tin
											b_stone = true
											void = false
										--Gold
									  elseif ystrata > t3    --strata splits
										and ystrata < t2 then
											data[vi] = OREID.c_gold
											b_stone = true
											void = false
										--Diamonds
										elseif ystrata > -t3    --strata splits
										and ystrata < -t2 then
											data[vi] = OREID.c_diam
											b_stone = true
											void = false
											--Mese
										elseif ystrata > t3    --strata splits
										or ystrata < -t3 then
											data[vi] = OREID.c_mese
											b_stone = true
											void = false
										--end of strata splits
										end

									else
										--we have lava.
										data[vi] = MISCID.c_lava
										lava = true
										void = false
									--end of over threshold	/else lava
									end
								--end of in cave
								end
							--done with at depth
							end


						--done with basement rock caves
						end


						-------------
						--allow ores inside caves, (but not hanging in the air.?)
						--allows them to be easily discovered.
						if not nocave
						--and stab
						then
							if ore(b_stone, void, y, data, vi, ystrata, TSTRA, OREID, n_cave, n_cave2, n_strata, n_terr, n_base)
							then
								b_stone = true
								void = false
							end
						end

						---starting tunnel.. because getting a better start position has failed
						--just clear space under the mountains.
						--sometimes this gets cut by caves, isn't long enough, or has no mountain...but generally works.
						if xab <200 then
							if zab < (2+n_strata)  and y < ((xab/(2 + ab_stra)) + 4) and y > xab/(2 + ab_stra) then
								nocave = false
							end
						end

						----------------------------
						--we have figured out if it was a cave.
						--what else might block it?
						--the Ocean Basin! This is so the oceans aren't a flat 5m deep boring yawn.


						local shelfnoi = ((n_terr + n_base) * PSEA.CONOI) -- softens cliffs
						local shelfsl = (0.5*y) - (PSEA.CONOI*2) --sets slope
						--Are we in the right place for oceans?
						if (xab > (PSEA.SHELFX + shelfnoi) - shelfsl
						or zab > (PSEA.SHELFZ + shelfnoi) - shelfsl)
						and y > PSEA.SEABED then --avoids  infinitely deepening oceans
							basin = true
						end



						---------------------------
						--We have figured out what would block basement rock.
						--Now we can look and see if we can actually place it!
						if nocave					--don't fill the caves
						and not basin			--or the ocean
						and nocanyon     --not a canyon
						and void then			--or the lava and ore!
							--no blockers so...
							--is it base layer?
							if den_base > den_t then
								--wow! we have basement rock.


								--first we should check if we can place ore here.
								-- otherwise we would have to overwrite the rock latter.
								--we'll call a function because we're going to do this again.
								if ore(b_stone, void, y, data, vi, ystrata, TSTRA, OREID, n_cave, n_cave2, n_strata, n_terr, n_base)
								then
									b_stone = true
									void = false
								end

								--no ore has been set? Let there be rock!
								if void then
									--let's place the strata.

									--ystrata is sine wave. the height set by TSTRA
									--that means it goes from -TSTRA to +TSTRA
									--dividing up the space between these extremes gives us strata.
									--don't forget to make something = 0 or you get a gap!


									--strata splits..combined with noise
									--blend seam layers
									local sbl = n_strata * TSTRA

									--grey stone layer...
									if ystrata >= sbl then
										--small chance of some iron
										if math.random(1,2000) == 1 then
											data[vi] = OREID.c_iron
											b_stone = true
											void = false
										else
											data[vi] = c_stone
											b_stone = true
											void = false
										end
									--an occassional layer of obsidian
									elseif ystrata < ((TSTRA * -0.95) + sbl)
									and n_base < 0 then
										--small chance of minerals from volcanism..
										local roll = math.random(1,1000)
										if roll == 1 then
											data[vi] = OREID.c_gold
											b_stone = true
											void = false
										elseif roll == 2 then
											data[vi] = OREID.c_copp
											b_stone = true
											void = false
										elseif roll == 3 then
											data[vi] = OREID.c_tin
											b_stone = true
											void = false
										elseif roll == 4 then
											data[vi] = OREID.c_mese
											b_stone = true
											void = false
										else
											data[vi] = c_obsid
											b_stone = true
											void = false
										end
									-- red stone layer
									elseif ystrata < sbl then
				            data[vi] = c_stone2
										b_stone = true
										void = false
									end
								end
							--end of placing base layer of basement stone

							---------------------------------------
							--okay..so it wasn't the base layer...
							--lets move up a layer, to the "jagged rock"
							elseif den_j > den_t then
								--it passes the threshold... but is it stable?

								--can relax stability right down low...stop giant holes?
								if stab or y < 15 then
									--great it's stable! Lets do the ores again...
									if ore(b_stone, void, y, data, vi, ystrata, TSTRA, OREID, n_cave, n_cave2, n_strata, n_terr, n_base)
									then
										b_stone = true
										void = false
									end

									--no ore has been set? Let there be rock!
									if void then

											--let's place the strata.

										--strata splits..combined with noise
										--blend seam layers
										local sbl = n_strata * TSTRA

										--a little volcanic...
										if ystrata >= sbl
										and ystrata <= ((TSTRA * 0.05) + sbl)
										and n_base > 0 then
											--small chance of minerals from volcanism..
											--rarer than in deeper base rock
											local roll = math.random(1,5000)
											if roll == 1 then
												data[vi] = OREID.c_gold
												b_stone = true
												void = false
											elseif roll == 2 then
												data[vi] = OREID.c_copp
												b_stone = true
												void = false
											elseif roll == 3 then
												data[vi] = OREID.c_tin
												b_stone = true
												void = false
											else
												data[vi] = c_obsid
												b_stone = true
												void = false
											end
										--grey stone layer...
										elseif ystrata >= sbl then
											data[vi] = c_stone
											b_stone = true
											void = false
										-- red stone layer
										elseif ystrata < sbl then
						           data[vi] = c_stone2
											 b_stone = true
											 void = false
										end
									end
								end
							--end of placing jagged layer of basement stone

							---------------------------------------
							--Okay ...it wasn't "jagged" rock either..
							--next layer up? Sedimentary rock

							--we don't do any of the following layers deep underground!
							--lets not $%^* about down there!
							--also don't overwrite stuff...not sure that's actually possible.. but better safe..
							elseif void
							and y >-200 then
								--okay we aren't deep underground.

								--but wait... more caves!
								--Threshold uses inverse base noise,..so at bottom??
								local cav_t = PCAV.SCAVT - (n_terr * 0.0001) - (den_j*0.0001) - (n_base*0.0001)
								local cav_lim = PCAV.MAXCAV2 + (n_cave2 * 30)
								--I aint seen no caves yet!
								--second variable, nocave2 so can treat two types of cave differently

								if y < cav_lim
								and math.abs(n_cave2) >= cav_t then
									nocave2 = false
								end

								--okay here on in we don't want to fill these new caves..
								if nocave2 and nocave then

									--------------------------------------
									--Whew, now back on to the layers...
									--have we got Sedimentary rock?
									if den_sr > den_t then
										--wow! it's sedimentary. Congratulations.

										--strata time...
										--strata splits..combined with noise
										--blend seam layers
										local sbl = n_strata * TSTRA
										local t1 = (0.33 * TSTRA) + sbl

										--a little lost base rock...
										--with coal
										if ystrata >= sbl
										and ystrata <= ((TSTRA * 0.05) + sbl)
										and n_base > 0 then
											if math.random(1,500) == 1 then
												data[vi] = OREID.c_coal
												void = false
												s_stone = true
											else
												data[vi] = c_stone
												void = false
												s_stone = true
											end
										--a little more lost base rock...
										--with rare diamonds and mese
										elseif ystrata <= sbl
										and ystrata >= ((TSTRA * -0.05) + sbl)
										and n_base < 0 then
											local roll = math.random(1,3000)
											if roll == 1 then
												data[vi] = OREID.c_diam
												void = false
												s_stone = true
											elseif roll == 2 then
												data[vi] = OREID.c_mese
												void = false
												s_stone = true
											else
												data[vi] = c_stone2
												void = false
												s_stone = true
											end
										--that was fun... now the actual soft rock
										elseif ystrata >= t1 then
						           data[vi] = c_sandstone
											 void = false
	 										s_stone = true
										elseif ystrata <= -t1 then
 						           data[vi] = c_sandstone2
											 void = false
	 										 s_stone = true
										else
 											data[vi] = c_sandstone3
											void = false
											s_stone = true
										end
										--end of placing sedimentary layer stone

									--------------------------------------
									--Okay... still nothing..
									--time for Regolith.

									--herein needs to be  stable
									elseif stab then

										-- does it cross the threshold
										if den_rego > den_t then
											--It's a regolith!

											--strata splits..combined with noise
											--blend seam layers
											local sbl = n_strata * TSTRA
											local t1 = (0.4 * TSTRA) + sbl
											local t2 = (0.8 * TSTRA) + sbl

											if ystrata >= 0
											and ystrata < t1 then
												data[vi] = SEDID.c_gravel
												void = false
												rego = true
											elseif ystrata >= t1
											and ystrata < t2 then
												data[vi] = SEDID.c_clay
												void = false
												rego = true
											elseif ystrata < 0
											and ystrata > -t1 then
												data[vi] = c_dsand
												void = false
												rego = true
											elseif ystrata <= -t1
											and ystrata > -t2 then
												data[vi] = SEDID.c_sand
												void = false
												rego = true
											else
												data[vi] = SEDID.c_sand2
												void = false
												rego = true
											end

										-----------------------------------
										--So... it wasn't even that..
										-- I guess that means it's a Subsurface Sediment.
										--we already checked the threshold way back.
										--it not a cave, it's stable...
										-- bugger we'll have to do climate soon..
										-- that's time consuming so check quicker things first.
										--we do have to check the threshold, we started this whole thing with the non-limited one.
										elseif den_sedi > den_t then
											--Are we below sea level?
											if y < SEA then
												--is this some non-cave hole? Or the ocean?
												--we've already ruled out caves... what else is there?
												--fuck it.. the sea takes no prisoners.
												--we're doing sediment here... hold off on those floods.
												data[vi] = SEDID.c_sand
			                  sedi = true
												void = false
											else
												--Right... we'll that was quick.
												--We are above sea level...	now we need to know climate.
												-- This calls for a function!
												--we will have to calculate climate again...
												--... for skin which will be outside the range of nodes here.
												local temp
												local hum
												temp, hum = climate(x, z, y, n_terr, n_base)
												--okay now we have climate data.
												--Remember we are doing sub-surface sediments.
												--These can get thick... don't place surface stuff here!

												--We have some fiddly coastal stuff.
												--on a node, that is sea surface or one above
												if (y == SEA + 1 or y == SEA) then
						            	--a humid place? will make swamps
						              if hum > 67  then  --boundary for wet climates
														--let's place a swampy mire
														swamp(data, vi, 40, SEDID.c_dirt, MISCID.c_river, void, sedi, n_base)
						              --wasn't humid . Do dunes
						              else
														data[vi] = SEDID.c_sand
					                  sedi = true
														void = false
						              end

												--Okay fiddly stuff out of the way.
												--lets do Temp/humidity combos
												--we have a choice between:
												--ice  T < 5
												--snow. T < 7
												--mire: river/dirt. H > 90
												--desert sand T >75 H <25
												-- dirt: everything else
													--we also need to deal with the E/W cross over
												elseif temp < 10 or xab < (100 + math.random(-10, 50)) then
													if y > (85+ math.random(-20, 20)) then
														data[vi] = c_ice
														sedi = true
														void = false
													else
														data[vi] = SEDID.c_gravel
														sedi = true
														void = false
													end
												elseif hum > 90 then
													--let's place a swampy mire
													if temp < 7 then
														--freeze
														swamp(data, vi, 30, SEDID.c_dirt, c_ice, void, sedi, n_base)
													else
														swamp(data, vi, 1000, SEDID.c_dirt, MISCID.c_river, void, sedi, n_base)
													end

												elseif temp > 75 and hum < 25 then
													data[vi] = c_dsand
													sedi = true
													void = false
												--wasn't one of the weirdos. Must be dirt.
												--and that's the final conclusion of your epic search...
												--...to the very end.. down this branch of possibility!
												else
													data[vi] = SEDID.c_dirt
													sedi = true
													void = false
												end
												--end of climate based sediments
											end
										--end of all sediments
										end
									end
									--end of search through sedimentary rock, regolith, sediment
								end
								--end of not in cave2
							end
							----end of search through basement rock and more
						end
						--end of things not in cave or ocean basins
					end
					--end of everything that fell within the threshold for sediments
					-- that was all the stuff that could've been land...whew...

					-------------------------------------------------
					--The Second Great Split...
					--what the hell is left?
					-- Everything above the sediment threshold.
					-- And everything that failed to get set below the threshold
					-- (remember things where subject to stability limits, the true threshold was much higher than what got placed)
					-- What should be here?
					-- Air.
					-- Caves.
					-- Oceans. - waters, and the basin floors
					-- Our Surface "Skin"
					-- plants and any other decorations
					--(remember haven't necessarily been id in this branch from the previous
					-- it may have jumped straight to this one, or at any point along the previous branch)

					if void then
						--we'll start with the simpler ones, move on to those needing climate data

						--we could ask "if stab" here... but nearly everything needs to id specifically what's under anyway.
						--we also need to ban them from stacking themselves... they have no height limiter...
						--...stab check wont deal with that, it will simply id them as stable, then stack them.
						--hard to think of a good way to simplify all these checks....
						--.. But..these are the fiddly left overs from our first branch

						--if we are in caves or basins we should know.

						--water holes
						--for cave2  cover basement rock with 1 layer of river water.
						--for cave2 cover the rest with 1 layer of clay.
						-- don't do at sea surface...it's just weird... also not too high
						if not nocave2 then
							if y > 3 and y < 60 then
								if nodu == c_stone or nodu == c_stone2 then
									swamp(data, vi, 5, SEDID.c_clay, MISCID.c_river, void, sedi, n_base)
									--we are still in the cave, want to cover ores, obsidian, whatever..
									--but not the water, and no stacks!
								elseif nodu == c_sandstone or nodu == c_sandstone2 or nodu == c_sandstone3 then
									data[vi] = SEDID.c_clay
									sedi = true
									void = false
								end
							end
							--(Note. Not bothering trying to fill canyons anymore
							--Canyons..genuinly making them rivers doesn't work, they don't follow slope etc.
							--they get weird. Instead they should be like damp gulleys..but giving
							-- them special soil looks odd, let climate sort it out.)

						--So we are not in cave2? What about an ocean ?
						elseif y < SEA then
							if basin then
								--cover basin floors with gravel, then clay, then sand.
								if nodu == c_stone or nodu == c_stone2 then
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
							--give some stuff for caves... a little water and gravel
							elseif not nocave then
								if nodu == c_stone then
									--swamp(data, vi, 4200, SEDID.c_gravel, MISCID.c_river, void, sedi, n_base)
									data[vi] = SEDID.c_gravel
									sedi = true
									void = false
								end
							--just regular seabed? Remember not to fill caves!
							elseif nodu == c_stone or nodu == c_stone2 and nocave then
								data[vi] = SEDID.c_sand2
								sedi = true
								void = false
							end
						else
							--what we have left is skinning the land surface.
							--now we need climate data.
							local temp
							local hum
							temp, hum = climate(x, z, y, n_terr, n_base)
							--we aren't really doing typical biomes... but here's a guide:
							--t>67 = tropics
							--t>33 = temp
							--else cold
							--h>67 = wet
							--h>33 = moist
							-- else dry
							--t<7 moist = ice

							--Biome list
							-- 1 -- rainforest
							--2 -- savanna/tropical seasonal forest
							--3 -- desert
							--4 -- temperate rainforest
							-- 5 --  seasonal forest
							-- 6 -- temperate grassland
							-- 7 -- boreal swamp
							-- 8 -- boreal forest
							-- 9 ---- tundra
							-- 10 -- ice
							-- plus coastlines for each

							--Check if stable below
			        --using an 'acceptable block' list, rather than a ban list
							--doing this rather than stab, becasue that allows stacking
							--also allows it to cover unwanted things (e.g. plants)
							-- and can't just fill any void because it will flood everything
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
							or nodu == c_coral)
			        then
			          can_sur = true
			        end

              --is it stable?
							-- ( remember to ban self stacking where needed..
							--i.e. it is on the can_sur list )
							-- bearing in mind we don't know yet about the ignore nodes.
							if can_sur and nodu ~= MISCID.c_ignore and nocave and nocave2 then

								--Going through Temp/humidity combos
								--1st we need to deal with the E/W cross over
								if xab < (100 + math.random(-50, 50)) then
									if y > (85+ math.random(-20, 20)) then
										data[vi] = c_snowbl
										sedi = true
										void = false
									else
										data[vi] = c_snowbl
										sedi = true
										void = false
									end
								--tropical
								elseif temp > 67  then
									--hot and wet = rainforest
									if hum > 67 then
										--what's the coastline like?
										if y >= SEA -1 and y < SEA + 3 then
											--swamp
											swamp(data, vi, 40, c_dirtlit, MISCID.c_river, void, sedi, n_base)
										--not at coast
										elseif y >= SEA + 3 then
											data[vi] = c_dirtlit
											sedi = true
											void = false
										end
									--hot and moist = savanna/tropical seasonal forest
									elseif hum > 33 then
										--what's the coastline like?
										if y >= SEA-1 and y < SEA + 3 and nodu ~= c_dsand then
											--sandy desert
											data[vi] = c_dsand
											sedi = true
											void = false
										--not at coast
										elseif y >= SEA + 3 then
											--adding green ground for interest.
											if y < (10 + math.random(-3,3)) then
												data[vi] = c_dirtgr
												sedi = true
												void = false
											else
												data[vi] = c_dirtdgr
												sedi = true
												void = false
											end
										end
								--hot and dry= desert
								elseif nodu ~= c_dsand then
										--what's the coastline like? --same as the rest!
										--sandy desert
										data[vi] = c_dsand
										sedi = true
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
											swamp(data, vi, 40, c_dirtlit, MISCID.c_river, void, sedi, n_base)
											--not at coast
										elseif y >= SEA + 3 then
											data[vi] = c_dirtgr
											sedi = true
											void = false
										end

									--temperate and moist= -- seasonal forest
		              elseif hum > 33 then
		                --the coast is...?
										if y >= SEA-1 and y < SEA + 3 and nodu ~= SEDID.c_sand then
											--sandy
											data[vi] = SEDID.c_sand
											sedi = true
											void = false
										--not at coast
									elseif y >= SEA + 3 then
											data[vi] = c_dirtgr
											sedi = true
											void = false
										end
									--temperate and dry=-- grassland
		              else
		                ----the coast is...?
										if y >= SEA-1 and y < SEA + 3 and nodu ~= SEDID.c_sand then
											--sandy
											data[vi] = SEDID.c_sand
											sedi = true
											void = false
										--not at coast
										elseif y >= SEA + 3 then
											--adding some very rare greener ground for interest.
											if y < (10 + math.random(0,3))
											and math.random(0,50) == 1 then
													data[vi] = c_dirtgr
													sedi = true
													void = false
											else
												data[vi] = c_dirtdgr
												sedi = true
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
										swamp(data, vi, 15, c_ice, MISCID.c_river, void, sedi, n_base)

									--not at coast
								elseif y >= SEA + 3 and  nodu ~= c_snowbl then
										data[vi] = c_snowbl
										sedi = true
										void = false
									end
		            --Okay...merely cold
								--cold and wet=-- boreal swamp
								elseif hum > 67 and nodu ~= c_ice then
		            	--Coast?
									if y >= SEA-1 and y < SEA + 3 then
										--swamp...no actual water.. frozen. This happens on mountains. Permafrost
										swamp(data, vi, 25, c_dirtsno, c_ice, void, sedi, n_base)
									--not at coast
									elseif y >= SEA + 3 then
										swamp(data, vi, 35, c_dirtsno, c_ice, void, sedi, n_base)
									end
								--cold and moist=-- boreal forest
		            elseif hum > 33 then
	                --cold and moist=-- boreal forest
									if y >= SEA-1 and y < SEA + 3 and nodu ~= SEDID.c_gravel then
										data[vi] = SEDID.c_gravel
										sedi = true
										void = false
									--not at coast
								elseif y >= SEA + 3 then
										data[vi] = c_dirtsno
										sedi = true
										void = false
									end
								--cold and dry=-- tundra
							elseif nodu ~= SEDID.c_gravel then
									data[vi] = SEDID.c_gravel
									sedi = true
									void = false
								--End of Cold zone
	              end
							--end of places that can be surfaced by "skin"
							end
						--end of cave, oceans, skins line.
						end
					--end of voids
					end

					------------------------------------------------
					--Things to end with
					------------------------------------------------

					-------------------------------------------------
					--Fill the oceans
					--(this didn't work when nested deeper..?)
					if void and y < SEA
					and nocave then
						--flood it!
						data[vi] = MISCID.c_water
						water = true
						void = false
					end



--[[ :-( This works... unless it is a large tree. For that occassional flaw we must give it special treatment.
					-------------------------------------------------
					--Wait... Plants!
					--Our last possibility... stick a tree in it!
					-- what is left by this point?
					--should be any voids that were not in the ocean, or filled by skin.
					-- we can now pick out places that are above a suitable skin...
					--... and stick plants in them with the plants api.

					if void
					and nocave then

						--check off against a list of any possible usable supporting nodes
						--this is instead of merely "if stab" so they don't get stuck ontop of themselves
	          local plant = false
	          if nodu == c_dirtlit
	          or nodu == c_dirt
	          or nodu == c_dirtgr
	          or nodu == c_dirtdgr
	          or nodu == c_dirtsno
	          or nodu == c_sand
	          or nodu == c_dsand
	          or nodu == c_sand2
						or nodu == c_clay
						or nodu == c_gravel then
	            plant = true
	          end
	          --do we have a viable stable node?
	          if plant then

							--get climate data
							local temp
							local hum
							temp, hum = climate(x, z, y, n_terr, n_base)

	            -- pack it in a table, for plants API
	            local conditions = {
	                                temp = temp,
											            humidity = hum,
											            nodu = nodu
										              }
	            local pos = {x = x, y = y, z = z}

	            --call the api... this will create plant
							--mgtec.choose_generate_plant(conditions, pos, data, area, vi)
							mgtec.choose_generate_plant(conditions, pos, data, area, vi)
						end

					--End of the final voids. We have exhausted all possibilities.
					-- if it is still unfilled now then it is probably sky.
					end

]]
					-----------------------------------------------
					--Housekeeping before we exit the loop

         -- Increment noise index.
         nixyz = nixyz + 1

         -- Increment voxelmanip index along x row.
         -- The voxelmanip index increases by 1 when
         -- moving by 1 node in the +x direction.
         vi = vi + 1

      end
    end
   end
	 --We have left the loop!

   -----------------------------------------------
	 --The End!


	 --....ha ha! Just kidding.

	 --Plants and Decorations. Loop Number Two!
	 --Sadly these can interact with the rest of the mapgen in bad ways (cliffs growing from trees etc)
	 --the stability mechanism recognizes them as stable, and builds on them?
	 --Another loop!
	 --Being outside of the previous loop nothing should interact with it.

	 --We can also do erosion here, which needs to know the proper values of surrounding nodes...
	 --otherwise it just drills holes randomly.

	 --should probably reset that??
	 nixyz = 1

	 for z = minp.z, maxp.z do
   	for y = minp.y, maxp.y do
      -- Voxelmanip index for the flat array of content IDs.
      -- Initialise to first node in this x row.
      local vi = area:index(minp.x, y, z)
      for x = minp.x, maxp.x do
				---------------------------
				--Erosion.

				-- this is...because nature...and to add small scale features, and to help deal with floats.
				--this is an alternative to mudflow (which has failed to work for me...)..
				--...but should give more natural, interesting results e.g. gullys.
				--this possibly be split up and put earlier to avoid overwriting things...but this is less confusing.

--[[Deactivated because leaves odd hanging surface layers....not sure it achieves much meaningful
				--first we eliminate all the "this-must-die" category. - certian unsupprted under
				--mainly to kill floats
				local nodeid = data[vi]
				local nodu  = data[(vi - ystridevm)]

				if (nodeid == c_stone or nodeid == c_stone2 or nodeid == c_obsid) then
					if y > 70 and nodu == MISCID.c_air then
						data[vi] = MISCID.c_air
					end
				elseif (nodeid == c_sandstone3 or nodeid == c_sandstone2 or nodeid == c_sandstone) then
					if y > 100 and nodu == MISCID.c_air then
						data[vi] = MISCID.c_air
					end
				end
				]]
--[[
				--then we roll a dice to see if we bother with this dynamic at all.
				--some of it could be expensive to calculate, we don't want to do it heaps.
				if math.random(1,1000) == 1 then
					--local nodu  = data[(vi - ystridevm)]
					--we only look at those exposed above...
					local noda = data[(vi + ystridevm)]
					if noda == MISCID.c_air then
						--... and with at least one side-down  exposed
						--anything at a cliff...or with an exposed side (just doing cliffs is too restrictive)
						local nodue  = data[(vi - ystridevm + 1)]
						local noduw  = data[(vi - ystridevm - 1)]
						local nodun  = data[(vi - ystridevm + zstridevm)]
						local nodus  = data[(vi - ystridevm - zstridevm)]
						local node  = data[(vi + 1)]
						local nodw  = data[(vi - 1)]
						local nodn  = data[(vi + zstridevm)]
						local nods  = data[(vi - zstridevm)]
						if nodue == MISCID.c_air
						or noduw == MISCID.c_air
						or nodun == MISCID.c_air
						or nodus == MISCID.c_air
						or node == MISCID.c_air
						or nodw == MISCID.c_air
						or nodn == MISCID.c_air
						or nods == MISCID.c_air then
							--each rock, sediment etc will have a different chance of being eroded.
							--hardest to weakest?...:
							--c_obsid, c_stone, c_stone2, c_sandstone3, c_sandstone2, c_sandstone, c_clay, c_gravel,
							--c_dirtsno, c_dirtgr, c_dirtlit, c_dirtdgr, c_sand all, c_dirt, (not doing ores?)
							--what is our node?
							local nodeid = data[vi]
							--our base erosion chance 1/x
							local eroch = 10
							--how much each step in risk changes things..
							local risk = eroch * 0.02
							--let's adjust based on rock...lowering eroch (i.e. raising chance)
							--obsidian is hardest...has no adjustment. Will group stones, they are rarely exposed
							--...so not much interest in having fine distinctions
							if b_stone then
								eroch = eroch - risk
							elseif s_stone then
								eroch = eroch - (risk*2)
							--clay and piles of rocks harder to move than dirt.
							elseif nodeid == SEDID.c_clay or nodeid == SEDID.c_gravel then
								eroch = eroch - (risk*4)
							--dirt with plant or other cover.
							elseif nodeid == c_dirtsno or nodeid == c_dirtgr or nodeid == c_dirtlit then
								eroch = eroch - (risk*5)
							--parched lands are more erodable
							elseif nodeid == c_dirtdgr then
								eroch = eroch - (risk*6)
							--exposed and movable...
							elseif nodeid == SEDID.c_dirt or nodeid == SEDID.c_sand or nodeid == SEDID.c_sand2 or nodeid == c_dsand then
								eroch = eroch - (risk*10)
							end
							--chances are raised for each unprotected side ... this might set up feedback, creating gullies
							--add more risk for each side
							if node  == MISCID.c_air then
								eroch = eroch - risk
							end
							if nodw == MISCID.c_air then
								eroch = eroch - risk
							end
							if nodn == MISCID.c_air then
								eroch = eroch - risk
							end
							if nods == MISCID.c_air then
								eroch = eroch - risk
							end
							if nodue  == MISCID.c_air then
								eroch = eroch - risk
							end
							if noduw == MISCID.c_air then
								eroch = eroch - risk
							end
							if nodun == MISCID.c_air then
								eroch = eroch - risk
							end
							if nodus == MISCID.c_air then
								eroch = eroch - risk
							end
							--our max risky block therefore has risk x 18...
							if math.random(1, eroch) == 1 then
								data[vi] = MISCID.c_air
								sedi = false
								rego = false
								b_stone = false
								s_stone = false
								void = true
							end
						--done with side exposed blocks
						end
					--done with exposed blocks
					end
				--done with selected for erosion
				end
				----------------------------------
				--Notes: Does this erosion produce a good effect?
				--on simple slopes it snips out little bits leaving exposed rock...
				--..adds a little variation but nothing special.
				--The effect on mud piles is less clear. Certainly doesn't eliminate them.
				--Will keep this rare... possibly could turn it off if want to save power.
				--have turned it off, isn't worth it?
				---------------------------------]]

				---------------------------------
				--We aren't putting things deep underwater/ground. So let's start there.
				--unfortunatly we can't distinguish caves anymore :-( so this will have to do.
				if y > SEA then

					--We need to know if it is empty
					local void = false
					if data[vi] == MISCID.c_air then
						void = true
					end

					--we only go ahead if it's empty
					if void then

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
							local n_base = nvals_base[nixyz]
							local n_terr  = nvals_terrain[nixyz]

							--get climate data
							local temp
							local hum
							temp, hum = climate(x, z, y, n_terr, n_base)

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


				-------------------------------

				---------------------------
				--Final Housekeeping
				-- Increment noise index.
			 nixyz = nixyz + 1
				-- Increment voxelmanip index along x row.
		 	 vi = vi + 1
		 end
		end
	 end
	 --we have left loop 2...probably isn't the quickest solution, but it works.


   -- After processing, write content ID data back to the voxelmanip.
   vm:set_data(data)
   -- Calculate lighting for what has been created.
   vm:calc_lighting()
   -- Write what has been created to the world.
   vm:write_to_map()
   -- Liquid nodes were placed so set them flowing.
   vm:update_liquids()

   -- Print generation time of this mapchunk.
   local chugent = math.ceil((os.clock() - t0) * 1000)
   print ("[mg_tectonic] Mapchunk generation time " .. chugent .. " ms")
end)

--===============================================================



-----------------------------------------------------------
--SPAWN PLAYER

--Start under the mountain in a tunnel
function spawnplayer(player)
	local inventory = player:get_inventory()
	--give them some gear incase the tunnel is cut by a cave
	inventory:add_item("main", "default:torch 14")
	inventory:add_item("main", "default:ladder 10")
	inventory:add_item("main", "default:pick_steel")

end


-----------------------------------------------------------
minetest.register_on_newplayer(function(player)
	spawnplayer(player)
end)

--[[
minetest.register_on_respawnplayer(function(player)
	spawnplayer(player)
end)
]]

---============================================================
--FINISHED!
