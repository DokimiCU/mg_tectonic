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
--cover vs density vs priority:
--set rare species with a higher priority - so they show up.
--the larger the spacing needed the higher the cover.
--ground plants with a higher priority can help break up trees.?

--be careful of over tall trees - their heads get cut off by unloaded chunks.
--dont set too densly , impacts performamnce..leads to total darkness
--decrease by orders of magnitude for going from abundant to rare species (power laws)


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
-- 12 -- underground
-- 13 -- sink hole caves
-- 14 -- --coastal for all the above

--each of these will be split for variation, into 4 temp/humidity combos
--... so that each default type of tree/plant shows up across the map, in different forms and abundances
--this is for gameplay (access to resource), to break up the massive biomes, and aesthetics (diversity looks better).
--Each combo shall have it's dominant tree, (sub-canopy?), ground cover, "special"/aesthetic
--that leaves 1 tree, plus 2 bushes, other plants that can be a rare across the range
-- the same classes should be filled for these rare ones. +1 dominant ground cover
--this would seem to be alot of duplication, but allows for controlling densities and relative abundances

--Conditions are:
--temp
--humidity ,
--biome ,
--nodu - node under
--Nodu check needs these to make sense of what the main stuff gives it
--sediments
local c_gravel = minetest.get_content_id("default:gravel")
local c_clay = minetest.get_content_id("default:clay")
local c_sand = minetest.get_content_id("default:sand")
local c_sand2 = minetest.get_content_id("default:silver_sand")
local c_dirt = minetest.get_content_id("default:dirt")
--surfaces
local c_dirtgr = minetest.get_content_id("default:dirt_with_grass")
local c_dirtdgr = minetest.get_content_id("default:dirt_with_dry_grass")
local c_dirtsno = minetest.get_content_id("default:dirt_with_snow")
local c_dirtlit = minetest.get_content_id("default:dirt_with_rainforest_litter")
local c_snowbl = minetest.get_content_id("default:snowblock")
local c_dsand = minetest.get_content_id("default:desert_sand")
--water
local c_river = minetest.get_content_id("default:river_water_source")

--remember to set values for all the conditions...or it will go strange places

--===============================================================
--Tree densities
--Dense jungles
local juncov = 0.06
local junden = juncov/3
--Woodlands
local wodcov = 0.03
local woden = wodcov/4
--Open grasslands
local savcov = 0.004
local savden = savcov/5

--==============================================================
--REPEATS..
--These are trees and plants that are used in multiple biomes in the same form/density etc...
--and can have their range expanded to include both
--(others which have discontinuous ranges e.g. 10-20 then 50-60, or different shapes can't be dealt with here)
--this to try and improve performance, and bc they overlap anyway... you can't make them exclusive just by having two with different densities!
--having repeats does lose a little subtelty... some may need to be re-split.
--only trees are not repeated - to give different forest canopy covers, heights etc



--Dry shrub
mgtec.register_plant({
	nodes = {"default:dry_shrub"},
	cover = 0.01,
	density = 0.005,
	priority = 74,
	check = function(t, pos)
		return t.temp > 0 and t.temp < 120 and t.humidity > 0 and t.humidity < 120 and (t.nodu == c_dsand or t.nodu == c_dirtdgr or t.nodu == c_sand or t.nodu == c_dirtsno or t.nodu == c_gravel)
	end,
})
--
-- jungle grass. (make sure it get's a little out of the tropic/wet... because it is the only way to get cotton!)
mgtec.register_plant({
	nodes = {"default:junglegrass"},
	cover = 0.05,
	density = 0.025,
	priority = 75,
	check = function(t, pos)
		return t.temp > 48 and t.temp < 120 and t.humidity > 58 and t.humidity < 120 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr)
	end,
})

-- Grass. (green)
for i = 1, 5 do
	mgtec.register_plant({
		nodes = { "default:grass_"..i},
		cover = 0.05,
		density = 0.025,
		priority = 76,
		check = function(t, pos)
			return t.temp > 33 and t.temp < 120 and t.humidity > 33 and t.humidity < 120 and (t.nodu ==  c_dirtgr or t.nodu ==  c_dirtdgr or t.nodu == c_dirtlit)
		end,
	})
end

-- Grass (dry)
for i = 1, 5 do
	mgtec.register_plant({
		nodes = { "default:dry_grass_"..i},
		cover = 0.05,
		density = 0.025,
		priority = 77,
		check = function(t, pos)
			return t.temp > 16 and t.temp < 120 and t.humidity > 16 and t.humidity < 67 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr or t.nodu == c_dsand or t.nodu == c_sand or t.nodu == c_gravel)
		end,
	})
end


--rare bush
mgtec.register_plant({
	nodes = {
		trunk = "default:bush_stem",
		leaves = "default:bush_leaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.002,
	density = 0.0005,
	priority = 78,
	check = function(t, pos)
		return t.temp > 16 and t.temp < 120 and t.humidity > 16 and t.humidity < 120 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = 1--math.floor(12 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
---
--Rare Acacia Bush
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_bush_stem",
		leaves = "default:acacia_bush_leaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.002,
	density = 0.0005,
	priority = 79,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 120 and t.humidity > 16 and t.humidity < 120 and (t.nodu ==  c_dirtgr or t.nodu ==  c_dirtdgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = 1--math.floor(12 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
--
--Cactus... rare arid specialist
mgtec.register_plant({
	nodes = {"default:cactus", n= math.random(1,2)},
	cover = 0.001,
	density = 0.0002,
	priority = 80,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 120 and t.humidity > 0 and t.humidity < 33 and (t.nodu ==  c_dsand or t.nodu ==  c_dirtdgr)
	end,
})
--
--Viola
mgtec.register_plant({
	nodes = { "flowers:viola"},
	cover = 0.001,
	density = 0.0005,
	priority = 81,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 120 and t.humidity > 33 and t.humidity < 83 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr)
	end,
})
--
--flowers geranium
mgtec.register_plant({
	nodes = {"flowers:geranium"},
	cover = 0.001,
	density = 0.0005,
	priority = 82,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 120 and t.humidity > 50 and t.humidity < 120 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr)
	end,
})
--
--tulip
mgtec.register_plant({
	nodes = {"flowers:tulip"},
	cover = 0.001,
	density = 0.0005,
	priority = 83,
	check = function(t, pos)
		return t.temp > 16 and t.temp < 83 and t.humidity > 50 and t.humidity < 83 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtsno)
	end,
})
--
--papyrus
mgtec.register_plant({
	nodes = {"default:papyrus", n= math.random(2,4) },
	cover = 0.05,
	density = 0.04,
	priority = 84,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 120 and t.humidity > 50 and t.humidity < 120 and (t.nodu == c_clay or t.nodu ==  c_dsand)
	end,
})
---
--Rose
--make sure it has a wide range bc need red die for beds.
mgtec.register_plant({
	nodes = {"flowers:rose"},
	cover = 0.001,
	density = 0.0005,
	priority = 85,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 120 and t.humidity > 16 and t.humidity < 67 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr)
	end,
})
--
--dandelion_yellow
mgtec.register_plant({
	nodes = {"flowers:dandelion_yellow"},
	cover = 0.001,
	density = 0.0005,
	priority = 86,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 120 and t.humidity > 16 and t.humidity < 120 and (t.nodu == c_dsand or t.nodu == c_dirtgr or t.nodu == c_dirtdgr)
	end,
})
---
--dandelion_white
mgtec.register_plant({
	nodes = {"flowers:dandelion_white"},
	cover = 0.001,
	density = 0.0005,
	priority = 87,
	check = function(t, pos)
		return t.temp > 16 and t.temp < 83 and t.humidity > 16 and t.humidity < 50 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr or t.nodu == c_dsand or t.nodu == c_dirtsno)
	end,
})
--


--
mgtec.register_plant({
	nodes = {"flowers:waterlily"},
	cover = 0.15,
	density = 0.1,
	priority = 88,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 120 and t.humidity > 67 and t.humidity < 120 and t.nodu == c_river
	end,
})

-- mushrooms
mgtec.register_plant({
	nodes = {"flowers:mushroom_brown", "flowers:mushroom_red"},
	cover = 0.001,
	density = 0.0005,
	priority = 89,
	check = function(t, pos)
		return t.temp > 16 and t.temp < 120 and t.humidity > 33 and t.humidity < 120 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtsno)
	end,
})

--....these aren't the right names for farming... can't find what is!
--Wheat
mgtec.register_plant({
	nodes = {"farming:wheat_8"},
	cover = 0.003,
	density = 0.002,
	priority = 90,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 67 and t.humidity > 16 and t.humidity < 50 and (t.nodu == c_dirtgr or t.nodu == c_dirtdgr)
	end,
})
---
--Cotton
mgtec.register_plant({
	nodes = {"farming:cotton_8"},
	cover = 0.01,
	density = 0.006,
	priority = 91,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 120 and t.humidity > 50 and t.humidity < 120 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr)
	end,
})

---=============================================================
--TROPICAL WET...
--t.temp >67
--t.humidity > 67 = wet
-- t.nodu == c_dirtlit, c_river
-----------------------------------##0
--Domiant Ground cover
--use repeats..

--Rare tree
---- Rare Layered aspen
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.005,
	density = 0.004,
	priority = 73,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 120 and t.humidity > 67 and t.humidity < 120 and t.nodu == c_dirtlit
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(15 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

-------------------
--Rare Ground Cover
--use repeats...

---------------
--Rare special
--use repeats..

----------------------------------------------------##1
--Hotter and wetter
--t.temp >83
--t.humidity > 83
--e.g. Rainforest Swamps
-------------------------
--Main Tree.
---- Dominant Jungle tree
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 72,
	check = function(t, pos)
		return t.temp > 83 and t.temp < 120 and t.humidity > 83 and t.humidity < 120 and t.nodu == c_dirtlit
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(22 + 4 * rand)
		local radius = 4 + 4 * rand
		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use main..

---------------
--Main special
--use rep...

--------------------------------------------------##2
--Hotter and Drier
--t.temp >83
--t.humidity > 67 and t.humidity < 83
--e.g. more open Rainforest?
--------------------------
--Main Tree.
---- Dominant Accacia tree
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 71,
	check = function(t, pos)
		return t.temp > 83 and t.temp < 120 and t.humidity > 67 and t.humidity < 83 and t.nodu == c_dirtlit
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(20 + 4 * rand)
		local radius = 4 + 4 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use main...

---------------
--Main special
--use repeats...

---------------------------------------------------##3
--Milder and Wetter
--t.temp > 67 and t.temp < 83
--t.humidity > 83
--e.g. Rainforest cloud forest.
-----------------------------
--Main Tree.
---- Dominant Fruiting  Tree
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 70,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 83 and t.humidity > 83 and t.humidity < 120 and t.nodu == c_dirtlit
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(15 + 5 * rand)
		local radius = 4 + 3 * rand
		if math.random(10) == 1 then
			mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
		else
			mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
		end
	end,
})

------------------
--Main Ground cover
--use main...
---------------
--Main special
--use repeats...

----------------------------------------------------##4
--Milder and Drier
--t.temp > 67 and t.temp < 83
--t.humidity > 67 and t.humidity < 83
--e.g. Subtropics? Not so cloud forest?
-----------------------
--Main Tree.
---- Dominant Pine tree
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 69,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 83 and t.humidity > 67 and t.humidity < 83 and t.nodu == c_dirtlit
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(18 + 4 * rand)
		local radius = 6 + 4 * rand
		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use main...
------------------
--Main special
--use repeats...


---=============================================================
--TROPICAL MOIST
--t.temp > 67
--t.humidity > 33 and t.humidity < 67
-- t.nodu == c_dsand, c_river, c_dirtgr, c_dirtdgr
-------------------------------------------------##0
--Dominant Ground cover
--use repeats..

--Rare tree
---- Rare Pine tree
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.001,
	density = 0.00025,
	priority = 68,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 120 and t.humidity > 33 and t.humidity < 67 and (t.nodu ==  c_dirtgr or t.nodu ==  c_dirtdgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(16 + 4 * rand)
		local radius = 4 + 4 * rand
		mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Rare Ground cover
--use repeats...

------------------
--Rare special
--use repeats...

----------------------------------------------------##1
--Hotter and wetter
--t.temp >83
--t.humidity > 50 and t.humidity < 67
--e.g. Lowland Seasonal Tropical forest
-------------------------
--Main Tree.
---- Dominant Jungle tree
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 67,
	check = function(t, pos)
		return t.temp > 83 and t.temp < 120 and t.humidity > 50 and t.humidity < 67 and t.nodu ==  c_dirtgr
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(16 + 4 * rand)
		local radius = 4 + 4 * rand
		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Main Ground cover
--use repeats

------------------
--Main special
--use repeats..

--------------------------------------------------##2
--Hotter and Drier
--t.temp >83
--t.humidity > 33 and t.humidity < 50
--e.g. Savannah
--------------------------
--Main Tree.
---- Dominant Acacia tree
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 66,
	check = function(t, pos)
		return t.temp > 83 and t.temp < 120 and t.humidity > 33 and t.humidity < 50 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(14 + 4 * rand)
		local radius = 4 + 4 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use repeats...

------------------
--Main special
--use repeats...

---------------------------------------------------##3
--Milder and Wetter
--t.temp > 67 and t.temp < 83
--t.humidity > 50 and t.humidity < 67
--e.g.Highland Seasonal Tropical forest.
-----------------------------
--Main Tree.
---- Dominant Aspen
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 65,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 83 and t.humidity > 50 and t.humidity < 67 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(16 + 4 * rand)
		local radius = 4 + 4 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


------------------
--Main Ground cover
--use repeats...

------------------
--Main special
--use rep..

----------------------------------------------------##4
--Milder and Drier
--t.temp > 67 and t.temp < 83
--t.humidity > 33 and t.humidity < 50
--e.g. Savannah, denser trees
-----------------------
--Main Tree.
-- Dominant Fruiting  Tree
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 64,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 83 and t.humidity > 33 and t.humidity < 50 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(15 + 5 * rand)
		local radius = 4 + 3 * rand
		if math.random(10) == 1 then
			mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
		else
			mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
		end
	end,
})

------------------
--Main Ground cover
--use repeats...

------------------
--Main special
--use repeats...


---=============================================================
--TROPICAL ARID
--t.temp > 67
--t.humidity > 0 and t.humidity < 33
-- t.nodu == c_dsand,
-------------------------------------------------##0
--Domiant Ground cover
--use repeats...

--Rare tree
--use repeats..
------------------
--Rare Ground cover
--nada!
------------------
--Rare special
--nada!

----------------------------------------------------##1
--Hotter and wetter
--t.temp >83
--t.humidity > 16 and t.humidity < 33
--e.g. scrub land
-------------------------
--Main Tree.
--- Dominant Cactus "tree"
mgtec.register_plant({
	nodes = {
		trunk = "default:cactus",
		leaves = "default:cactus",
		air = "air", ignore = "ignore",
	},
	cover = 0.001,
	density = 0.00025,
	priority = 63,
	check = function(t, pos)
		return t.temp > 83 and t.temp < 120 and t.humidity > 16 and t.humidity < 33 and t.nodu == c_dsand
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(3 + 2 * rand)
		local radius = 1 + 1 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Main Ground cover
--use repeats...
------------------
--Main special
--use repeats..


--------------------------------------------------##2
--Hotter and Drier
--t.temp >83
--t.humidity > 0 and t.humidity < 16
--e.g. desolate desert
--------------------------
--Main Tree.
--nada!
------------------
--Main Ground cover
--nada!
------------------
--Main special
--nada!

---------------------------------------------------##3
--Milder and Wetter
--t.temp > 67 and t.temp < 83
--t.humidity > 16 and t.humidity < 33
--e.g.scrub land
-----------------------------
--Main Tree.
---- Dominant Acacia tree
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.001,
	density = 0.00025,
	priority = 62,
	check = function(t, pos)
		return t.temp > 67 and t.temp < 83 and t.humidity > 16 and t.humidity < 33 and t.nodu == c_dsand
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(4 + 2 * rand)
		local radius = 2 + 2 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use repeats...

------------------
--Main special
--use repeats...

----------------------------------------------------##4
--Milder and Drier
--t.temp > 67 and t.temp < 83
--t.humidity > 0 and t.humidity < 16
--e.g. slightly less desolate desert
-----------------------
--Main Tree.
--use repeats..
------------------
--Main Ground cover
--nada!
------------------
--Main special
--nada!

---=========================================================================
--TEMPERATE WET
--t.temp > 33 and t.temp < 67
--t.humidity > 67 and t.humidity < 120
-- t.nodu == c_dirtgr, c_dirtlit
-------------------------------------------------##0
--Dominant Ground Cover
--use repeats..

--Rare tree
-- Rare Fruiting  Tree
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = 0.04,
	density = 0.01,
	priority = 61,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 67 and t.humidity > 67 and t.humidity < 120 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(6 + 2 * rand)
		local radius = 2 + 2 * rand
		if math.random(5) == 1 then
			mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
		else
			mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
		end
	end,
})
------------------
--Rare Ground cover
--use repeats...
------------------
--Rare special
--use repeats..

----------------------------------------------------##1
--Hotter and wetter
--t.temp > 50 and t.temp < 67
--t.humidity > 83 and t.humidity < 120
--e.g. Temperate Rainforest
-------------------------
--Main Tree.
-- Dominant Jungle tree
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 60,
	check = function(t, pos)
		return t.temp > 50 and t.temp < 67 and t.humidity > 83 and t.humidity < 120 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(20 + 4 * rand)
		local radius = 4 + 4 * rand
		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use repeats..

------------------
--Main special
--use repeats...


--------------------------------------------------##2
--Hotter and Drier
--t.temp > 50 and t.temp < 67
--t.humidity > 67 and t.humidity < 83
--e.g. Subtropical Woodland?
--------------------------
--Main Tree.
---- Dominant Accacia tree
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 59,
	check = function(t, pos)
		return t.temp > 50 and t.temp < 67 and t.humidity > 67 and t.humidity < 83 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(14 + 4 * rand)
		local radius = 4 + 2 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use repeats..
------------------
--Main special
--use repeats..

---------------------------------------------------##3
--Milder and Wetter
--t.temp > 33 and t.temp < 50
--t.humidity > 83 and t.humidity < 120
--e.g. Aspens?
-----------------------------
--Main Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 58,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 50 and t.humidity > 83 and t.humidity < 120 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(16 + 4 * rand)
		local radius = 4 + 4 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use repeats...

------------------
--Main special
--use repeats..


----------------------------------------------------##4
--Milder and Drier
--t.temp > 33 and t.temp < 50
--t.humidity > 67 and t.humidity < 83
--e.g. Pines ?
-----------------------
--Main Tree.
-- Dominant Pine tree
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 57,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 50 and t.humidity > 67 and t.humidity < 83 and t.nodu == c_dirtgr
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(20 + 2 * rand)
		local radius = 4 + 4 * rand
		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use repeats...

------------------
--Main special
--use repeats...

---=============================================================
--TEMPERATE MOIST
--t.temp > 33 and t.temp < 67
--t.humidity > 33 and t.humidity < 67
-- t.nodu == c_dirtgr, c_sand
-------------------------------------------------##0

--Dominant Ground cover
--use repeats..

--Rare tree
-- Rare Jungle tree
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = 0.0001,
	density = 0.00005,
	priority = 56,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 67 and t.humidity > 33 and t.humidity < 67 and t.nodu == c_dirtgr
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(4 + 2 * rand)
		local radius = 2 + 2 * rand
		mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Rare Ground cover
--use repeats..

------------------
--Rare special
--use repeats..

----------------------------------------------------##1
--Hotter and wetter
--t.temp > 50 and t.temp < 67
--t.humidity > 50 and t.humidity < 67
--e.g. Forest
-------------------------
--Main Tree.
---- Dominant Fruiting  Tree
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 55,
	check = function(t, pos)
		return t.temp > 50 and t.temp < 67 and t.humidity > 50 and t.humidity < 67 and t.nodu == c_dirtgr
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(20 + 4 * rand)
		local radius = 4 + 4 * rand
		if math.random(5) == 1 then
			mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
		else
			mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
		end
	end,
})

------------------
--Main Ground cover
--use repeats..
------------------
--Main special
--use repeats..
--------------------------------------------------##2
--Hotter and Drier
--t.temp > 50 and t.temp < 67
--t.humidity > 33 and t.humidity < 50
--e.g. Mediterranean?
--------------------------
--Main Tree.
---- Dominant Accacia tree
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 54,
	check = function(t, pos)
		return t.temp > 50 and t.temp < 67 and t.humidity > 33 and t.humidity < 50 and t.nodu == c_dirtgr
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(10 + 4 * rand)
		local radius = 4 + 2 * rand

		mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use repeats...

------------------
--Main special
--use rep...

---------------------------------------------------##3
--Milder and Wetter
--t.temp > 33 and t.temp < 50
--t.humidity > 50 and t.humidity < 67
--e.g. Forest
-----------------------------
--Main Tree.
-- Dominant Pine tree
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 53,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 50 and t.humidity > 50 and t.humidity < 67 and t.nodu == c_dirtgr
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(14 + 4 * rand)
		local radius = 4 + 2 * rand
		mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use repeats...

------------------
--Main special


----------------------------------------------------##4
--Milder and Drier
--t.temp > 33 and t.temp < 50
--t.humidity > 33 and t.humidity < 50
--e.g. Deciduous woodland
-----------------------
--Main Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 52,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 50 and t.humidity > 33 and t.humidity < 50 and t.nodu == c_dirtgr
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(10 + 4 * rand)
		local radius = 4 + 2 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------
--Main Ground cover
--use repeats..

------------------
--Main special
--use rep...

---=============================================================
--TEMPERATE DRY
--t.temp > 33 and t.temp < 67
--t.humidity > 0 and t.humidity < 33
-- t.nodu == c_dirtgr, c_dirtdgr, c_sand
-------------------------------------------------##0
--Dominant grass...this is the main ground cover for all
--use repeats..


--Rare tree
--..nada
------------------
--Rare Ground cover
--use repeats...

------------------
--Rare special
--use rep..
-------------------------------------------------##1
--Hotter and wetter
--t.temp > 50 and t.temp < 67
--t.humidity > 16 and t.humidity < 33
--e.g. open woodland
-------------------------
--Main Tree.
--- Dominant Accacia tree
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = savcov,
	density = savden,
	priority = 51,
	check = function(t, pos)
		return t.temp > 50 and t.temp < 67 and t.humidity > 16 and t.humidity < 33 and (t.nodu == c_dirtgr or t.nodu == c_dirtdgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(10 + 4 * rand)
		local radius = 4 + 2 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Main Ground cover
--above...
------------------
--Main special
--use repeats...
--------------------------------------------------##2
--Hotter and Drier
--t.temp > 50 and t.temp < 67
--t.humidity > 0 and t.humidity < 16
--e.g. Mediterranean
--------------------------
--Main Tree.
-- Dominant Pine tree
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = savcov,
	density = savden,
	priority = 50,
	check = function(t, pos)
		return t.temp > 50 and t.temp < 67 and t.humidity > 0 and t.humidity < 16 and (t.nodu == c_dirtgr or t.nodu == c_dirtdgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(10 + 4 * rand)
		local radius = 2 + 2 * rand
		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


------------------
--Main Ground cover
--above...
------------------
--Main special
--use repeatss...
---------------------------------------------------##3
--Milder and Wetter
--t.temp > 33 and t.temp < 50
--t.humidity > 16 and t.humidity < 33
--e.g. open woodland
-----------------------------
--Main Tree.
---- Dominant Fruiting  Tree
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = savcov,
	density = savden,
	priority = 49,
	check = function(t, pos)
		return t.temp > 33 and t.temp < 50 and t.humidity > 16 and t.humidity < 33 and (t.nodu == c_dirtgr or t.nodu == c_dirtdgr)
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(10 + 4 * rand)
		local radius = 4 + 4 * rand
		if math.random(12) == 1 then
			mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
		else
			mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
		end
	end,
})

------------------
--Main Ground cover
--use repeats...
------------------
--Main special
--use repeats..
----------------------------------------------------##4
--Milder and Drier
--t.temp > 33 and t.temp < 50
--t.humidity > 0 and t.humidity < 16
--e.g. steppe
-----------------------
--Main Tree.
--use repeats..
------------------
--Main Ground cover
--above...
------------------
--Main special
--use repeats...


---=============================================================
--FRIGID and WET
--t.temp > 0 and t.temp < 33
--t.humidity > 67 and t.humidity < 120
-- t.nodu == c_dirtsno, c_river, c_ice (cant place on that!)
-------------------------------------------------##0
--main ground cover
--use repeats..

--Rare tree
-- Rare Pine tree
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = 0.02,
	density = 0.005,
	priority = 48,
	check = function(t, pos)
		return t.temp > 0 and t.temp < 33 and t.humidity > 67 and t.humidity < 120 and t.nodu == c_dirtsno
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(6 + 2 * rand)
		local radius = 2 + 1 * rand
		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Rare Ground cover
--use repeats
------------------
--Rare special
--use repeats

----------------------------------------------------##1
--Hotter and wetter
--t.temp > 16 and t.temp < 33
--t.humidity > 83 and t.humidity < 120
--e.g. swamp
-------------------------
--Main Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 47,
	check = function(t, pos)
		return t.temp > 16 and t.temp < 33 and t.humidity > 83 and t.humidity < 120 and t.nodu == c_dirtsno
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(6 + 4 * rand)
		local radius = 2 + 2 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Main Ground cover
--above..
------------------
--Main special
--nada...
--------------------------------------------------##2
--Hotter and Drier
--t.temp > 16 and t.temp < 33
--t.humidity > 67 and t.humidity < 83
--e.g. still swamp
--------------------------
--Main Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 46,
	check = function(t, pos)
		return t.temp > 16 and t.temp < 33 and t.humidity > 67 and t.humidity < 83 and t.nodu == c_dirtgsno
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(6 + 2 * rand)
		local radius = 2 + 2 * rand
		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Main Ground cover
--above...
------------------
--Main special
--nada...
---------------------------------------------------##3
--Milder and Wetter
--t.temp > 0 and t.temp < 16
--t.humidity > 83 and t.humidity < 120
--e.g. Permafrost
-----------------------------
--Main Tree.
--use repeats...
------------------
--Main Ground cover
--above...
------------------
--Main special
--nada...
----------------------------------------------------##4
--Milder and Drier
--t.temp > 0 and t.temp < 16
--t.humidity > 67 and t.humidity < 83
--e.g. Permafrost
-----------------------
--Main Tree.
--merged with previous (bush)
------------------
--Main Ground cover
--above...
------------------
--Main special
--nada...


---=============================================================
--FRIGID and MOIST
--t.temp > 0 and t.temp < 33
--t.humidity > 33 and t.humidity < 67
-- t.nodu == c_dirtsno, c_gravel
-------------------------------------------------##0
--main ground cover
--use repeats...

--Rare tree
--use repeats..
------------------
--Rare Ground cover

------------------
--Rare special
--Rare Ground cover
--use repeats..
----------------------------------------------------##1
--Hotter and wetter
--t.temp > 16 and t.temp < 33
--t.humidity > 50 and t.humidity < 67
--e.g. Pine forest
-------------------------
--Main Tree.
--Dominant aspen
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 45,
	check = function(t, pos)
		return t.temp > 16 and t.temp < 33 and t.humidity > 50 and t.humidity < 67 and t.nodu == c_dirtsno
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(14 + 2 * rand)
		local radius = 3 + 1 * rand
		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Main Ground cover
--above..
------------------
--Main special

--------------------------------------------------##2
--Hotter and Drier
--t.temp > 16 and t.temp < 33
--t.humidity > 33 and t.humidity < 50
--e.g. open forest?
--------------------------
--Main Tree.
--Dominant pine
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 44,
	check = function(t, pos)
		return t.temp > 16 and t.temp < 33 and t.humidity > 33 and t.humidity < 50 and t.nodu == c_dirtsno
	end,
	grow = function(nodes, pos, data, area)
		local rand = math.random()
		local height = math.floor(14 + 2 * rand)
		local radius = 3 + 1 * rand
		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
------------------
--Main Ground cover
--above..
------------------
--Main special

---nothing else here....
---------------------------------------------------##3
--Milder and Wetter
--t.temp > 0 and t.temp < 16
----t.humidity > 50 and t.humidity < 67
--e.g. tundra?
-----------------------------
--Main Tree.
------------------
--Main Ground cover
------------------
--Main special
----------------------------------------------------##4
--Milder and Drier
--t.temp > 0 and t.temp < 16
--t.humidity > 33 and t.humidity < 50
--e.g. tundra?
-----------------------
--Main Tree.
------------------
--Main Ground cover
------------------
--Main special


---=============================================================
--FRIGID and DRY
--t.temp > 0 and t.temp < 33
--t.humidity > 0 and t.humidity < 33
-- t.nodu == c_gravel
-------------------------------------------------##0
--main ground cover
--use repeats...

--....nothing else here.
------------------
--Rare Ground cover

------------------
--Rare special

----------------------------------------------------##1
--Hotter and wetter
--t.temp > 16 and t.temp < 33
--t.humidity > 50 and t.humidity < 67
--e.g. Tundra
-------------------------
--Main Tree.
------------------
--Main Ground cover
------------------
--Main special

--------------------------------------------------##2
--Hotter and Drier
--t.temp > 16 and t.temp < 33
--t.humidity > 0 and t.humidity < 16
--e.g. Tundra
--------------------------
--Main Tree.
------------------
--Main Ground cover
------------------
--Main special

---------------------------------------------------##3
--Milder and Wetter
--t.temp > 0 and t.temp < 16
----t.humidity > 16 and t.humidity < 33
--e.g. Tundra
-----------------------------
--Main Tree.
------------------
--Main Ground cover
------------------
--Main special
----------------------------------------------------##4
--Milder and Drier
--t.temp > 0 and t.temp < 16
--t.humidity > 0 and t.humidity < 16
--e.g. Tundra of a fairly desolate sort
-----------------------
--Main Tree.
------------------
--Main Ground cover
------------------
--Main special



---=====================================================================
