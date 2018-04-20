---MG TECTONIC adapted plants register.
---adapted from valleys_mapgen

--[[
Many syntaxes are possible, with their default behaviour (see *grow*):
* `nodes = "default:dry_shrub"`: simply generate a dry shrub.
* `nodes = {"default:papyrus", n=4}`: generate 4 papyrus nodes vertically.
* `nodes = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5"}`: generate one grass node, randomly chosen between the 5 nodes.
* `nodes = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5, n=3"}`: generate 3 grass nodes vertically (my example is a bit sillyâ€¦), randomly chosen between the 5 nodes (chosen once, not 3 times).
--anything more needs a grow function
]]

----------------------------------------------------
--Notes on species set up:

--be careful of over tall trees - their heads get cut off by unloaded chunks.
--dont set too densly , impacts performamnce..
--decrease by orders of magnitude for going from abundant to rare species (power laws)

--species will mostly be decided by climate tolerances...
--should give the most natural pattern, as that varies across the map.
--this means they can go outside 1 biome... we dont actaully have defined biomes

--Possible species types:
-- specialists, generalists.
-- common, rare

--temperatures and humidities used to set biomes /soils
--t>67 = tropics
--t>33 = temp
--else cold
--h>67 = wet
--h>33 = moist
-- else dry
--t<7 moist = ice

--Some 'Biomes'
-- 1 -- rainforest
--2 -- savanna
--3 -- desert
--4 -- temperate rainforest
-- 5 -- -- seasonal forest
-- 6 -- temperate grassland
-- 7 -- boreal swamp forest
-- 8 -- boreal forest
-- 9 ---- tundra
-- 10 -- ice
-- 11 -- in the ocean
-- 14 -- underground
-- 17 -- sink hole caves
-- 12 -- --coastal for all the above

--Conditions are:
--temp
--humidity ,
--biome ,
--nodu
--[[
nodu == c_dirtlit
or nodu == c_dirt
or nodu == c_dirtgr
or nodu == c_dirtdgr
or nodu == c_dirtsno
or nodu == c_sand
or nodu == c_dsand
or nodu == c_sand2
c_clay
c_gravel
]]

---------------------------------------------------
--GENERALISTS ...occur almost everywhere

--mushrooms
--rare
mgtec.register_plant({
	nodes = {"flowers:mushroom_red", "flowers:mushroom_brown"},
	cover = 0.01,
	density = 0.005,
	priority = 61,
	check = function(t, pos)
		return t.temp > 10 and t.humidity > 33 and (t.nodu == c_dirtgr or t.nodu == c_dirtlit)
	end,
})


-- Grass. (green)
--common generalist. Agressive
for i = 1, 5 do
	mgtec.register_plant({
		nodes = { "default:grass_"..i},
		cover = 0.1,
		density = 0.05,
		priority = 52,
		check = function(t, pos)
			return t.temp > 38 and t.temp < 75 and t.humidity >35 and t.humidity < 80 and t.nodu ~= c_sand
		end,
	})
end

-- Grass (dry)
--a warmer arider version of green
for i = 1, 5 do
	mgtec.register_plant({
		nodes = { "default:dry_grass_"..i},
		cover = 0.1,
		density = 0.05,
		priority = 51,
		check = function(t, pos)
			return t.temp > 50 and t.temp < 80 and t.humidity >25 and t.humidity < 50
		end,
	})
end

--Dry shrub
--Because theres always something near dead where ever you are.
mgtec.register_plant({
	nodes = {"default:dry_shrub"},
	cover = 0.01,
	density = 0.005,
	priority = 22,

	check = function(t, pos)
		return t.temp > 8 and t.temp < 100 and t.humidity > 5 and t.humidity < 100
	end,
})


---- Generic rare Tiny apple  tree ..so most everywhere has some fruit
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = 0.001,
	density = 0.0005,
	priority = 60,
	check = function(t, pos)
		return t.temp > 15 and t.temp < 77 and t.humidity > 0 and t.humidity < 100 and nodu ~= c_sand
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(4 + 1 * rand)
		local radius = 2 + 1 * rand

		if math.random(4) == 1 then
			mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
		else
			mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
		end
	end,
})



---- Generic rare thick... thing
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.001,
	density = 0.0005,
	priority = 60,
	check = function(t, pos)
		return t.temp > 15 and t.temp < 77 and t.humidity > 0 and t.humidity < 100 and nodu ~= c_sand
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(19 + 1 * rand)
		local radius = 4 + 1 * rand
		mgtec.make_thick_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
-----------------------------------------------------
--TROPICAL RAINFOREST...
--t>67 = tropics
--h>67 = wet


---- Generic Jungle tree
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.01,
	density = 0.005,
	priority = 73,
	check = function(t, pos)
		return t.temp > 62 and t.temp < 105 and t.humidity > 61 and t.humidity < 105
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(15 + 3 * rand)
		local radius = 10 + 6 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


--jungle grass.
-- common specialist
-- high water and temp needs. Very dense. Middling dominant.
mgtec.register_plant({
	nodes = {"default:junglegrass"},
	cover = 0.1,				--how much space will be reserved for this species. 0 to 1. e.g. 0.6 = 60% will be reserved.
	density = 0.005,			-- 0 to Cover. How much gets filled. e.g 0.25 = 25%
	priority = 50,				--plants of lower priority will not spawn in reserved space. 0 to 100
	--this is called by the main function
	check = function(t, pos) --t is the table of conditions, pos is where it will be placed
		return t.temp > 60 and t.temp < 95 and t.humidity > 65 and t.humidity < 100
	end,
})


--flowers geranium
-- rarer, colder
mgtec.register_plant({
	nodes = {"flowers:geranium"},
	cover = 0.01,
	density = 0.005,
	priority = 11,
	check = function(t, pos)
		--return t.biome == 1
		return t.temp > 50 and t.temp < 85 and t.humidity > 60 and t.humidity < 100
		--return t.temp > 0 and t.temp < 100
	end,
})

--Cotton
mgtec.register_plant({
	nodes = {"farming:cotton"},
	cover = 0.01,
	density = 0.005,
	priority = 23,

	check = function(t, pos)
		return t.temp > 58 and t.temp < 77 and t.humidity > 58 and t.humidity < 80
	end,
})

--------------------------------------------------------------
--2 -- SAVANNA
--t>67 = tropics
--h 67< >33 = moist


---- Generic Savannah tree
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.001,
	density = 0.0005,
	priority = 63,
	check = function(t, pos)
		return t.temp > 62 and t.temp < 105 and t.humidity > 28 and t.humidity < 62 and t.nodu ~= c_sand
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(6 + 2 * rand)
		local radius = 5 + 6 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


--Wheat
mgtec.register_plant({
	nodes = {"farming:wheat"},
	cover = 0.01,
	density = 0.005,
	priority = 23,

	check = function(t, pos)
		return t.temp > 50 and t.temp < 75 and t.humidity > 20 and t.humidity < 50
	end,
})



--Rose
mgtec.register_plant({
	nodes = {"flowers:rose"},
	cover = 0.01,
	density = 0.005,
	priority = 41,
	check = function(t, pos)
		return t.temp > 50 and t.temp < 77 and t.humidity > 25 and t.humidity < 40
	end,
})

--------------------------------------------------------------
--3 -- DESERT
--t>67 = tropics
--h<33


---- Generic Cactus "tree"
mgtec.register_plant({
	nodes = {
		trunk = "default:cactus",
		leaves = "default:cactus",
		air = "air", ignore = "ignore",
	},
	cover = 0.001,
	density = 0.0001,
	priority = 12,
	check = function(t, pos)
		return t.temp > 62 and t.temp < 85 and t.humidity > 5 and t.humidity < 38
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(2 + 2 * rand)
		local radius = 1 + 2 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

--Cactus... rare arid specialist
mgtec.register_plant({
	nodes = {"default:cactus", n= math.random(1,6)},
	cover = 0.01,
	density = 0.005,
	priority = 10,

	check = function(t, pos)
		return t.temp > 80 and t.humidity < 20
	end,
})

--------------------------------------------------------------
--4 -- TEMPERATE RAINFOREST
--t <67 >33
--h>67 = wet


---- Generic  T Rainf tree
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.01,
	density = 0.005,
	priority = 63,
	check = function(t, pos)
		return t.temp > 28 and t.temp < 72 and t.humidity > 62 and t.humidity < 105
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(13 + 3 * rand)
		local radius = 7 + 6 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

--papyrus
mgtec.register_plant({
	nodes = {"default:papyrus", n= math.random(1,6) },
	cover = 0.01,
	density = 0.005,
	priority = 29,
	check = function(t, pos)
		return t.temp > 35 and t.temp < 85 and t.humidity > 25 and t.humidity < 90 and (t.nodu == c_dirtlit or t.nodu == c_clay)
	end,
})


------------------------------------------------------------------
--5 TEMPERATE SEASONAL FOREST
--t>67 = tropics
--t>33 = temp
--else cold
--h>67 = wet
--h>33 = moist
-- else dry
--t<7 moist = ice

---- Generic  Temp Apple
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = 0.01,
	density = 0.005,
	priority = 63,
	check = function(t, pos)
		return t.temp > 28 and t.temp < 72 and t.humidity > 28 and t.humidity < 72 and t.nodu ~= c_sand
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(6 + 2 * rand)
		local radius = 3 --+ 6 * rand

		if math.random(4) == 1 then
				mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
			else
				mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
			end
	end,
})




--Viola
mgtec.register_plant({
	nodes = {"flowers:viola"},
	cover = 0.01,
	density = 0.002,
	priority = 29,
	check = function(t, pos)
		return t.temp > 35 and t.temp < 77 and t.humidity > 25 and t.humidity < 77
	end,
})

--Tulip
mgtec.register_plant({
	nodes = {"flowers:tulip"},
	cover = 0.01,
	density = 0.001,
	priority = 50,
	check = function(t, pos)
		return t.temp > 40 and t.temp < 60 and t.humidity > 50 and t.humidity < 60
	end,
})


--------------------------------------------------------------
--6 -- TEMPERATE GRASSLAND
--t>67 = tropics
--t>33 = temp
--else cold
--h>67 = wet
--h>33 = moist
-- else dry
--t<7 moist = ice




--dandelion_white
mgtec.register_plant({
	nodes = {"flowers:dandelion_white"},
	cover = 0.01,
	density = 0.006,
	priority = 55,
	check = function(t, pos)
		return t.temp > 40 and t.temp < 62 and t.humidity > 35 and t.humidity < 55
	end,
})

--dandelion_yellow
mgtec.register_plant({
	nodes = {"flowers:dandelion_yellow"},
	cover = 0.01,
	density = 0.006,
	priority = 55,
	check = function(t, pos)
		return t.temp > 25 and t.temp < 52 and t.humidity > 25 and t.humidity < 45
	end,
})


-----------------------------------------------------------------
--7 BOREAL SWAMP
--t>67 = tropics
--t>33 = temp
--else cold
--h>67 = wet
--h>33 = moist
-- else dry
--t<7 moist = ice

---- Generic  Cold Swamp tree
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.01,
	density = 0.005,
	priority = 65,
	check = function(t, pos)
		return t.temp > 7 and t.temp < 38 and t.humidity > 62 and t.humidity < 105
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(15 + 5 * rand)
		local radius = 7 + 4 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

-----------------------------------------------------------------
--8 BOREAL FOREST
--t>67 = tropics
--t>33 = temp
--else cold
--h>67 = wet
--h>33 = moist
-- else dry
--t<7 moist = ice

---- Generic  Cold tree
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = 0.01,
	density = 0.005,
	priority = 63,
	check = function(t, pos)
		return t.temp > 6 and t.temp < 38 and t.humidity > 28 and t.humidity < 72
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(12 + 2 * rand)
		local radius = 3 + 2 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


-----------------------------------------------------------------
--9 TUNDRA
--t>67 = tropics
--t>33 = temp
--else cold
--h>67 = wet
--h>33 = moist
-- else dry
--t<7 moist = ice
