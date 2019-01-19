---MG TECTONIC adapted plants register.
---adapted from valleys_mapgen

--[[
Many syntaxes are possible, with their default behaviour (see *grow*):
* `nodes = "default:dry_shrub"`: simply generate a dry shrub.
* `nodes = {"default:papyrus", n=4}`: generate 4 papyrus nodes vertically.
* `nodes = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5"}`: generate one grass node, randomly chosen between the 5 nodes.
* `nodes = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5, n=3"}`: generate 3 grass nodes vertically (my example is a bit sillyâ€¦), randomly chosen between the 5 nodes (chosen once, not 3 times).
--anything more needs a grow function
--]]

----------------------------------------------------
--Notes on species set up:


------------

--Temperature
-- >80 Tropical
-- 60-80   Sub-tropical
-- 40-60 Temperate
-- 20-40	Sub-polar
-- 0-20 Polar

--middle of range
local tropic = 90
local stropic = 70
local temper = 50
local spolar = 30
local polar = 10

--Humidity
-- >80 Swamp
-- 60-80   Damp
-- 40-60 Average
-- 20-40	Dry
-- 0-20 Arid

--middle of range
local swamp = 90
local damp = 70
local average = 50
local dry = 30
local arid = 10

--add on to the above to create a range
--tolerance
local htol = 30
local mtol = 20
local ltol = 10

--Disturbance
-- >50 Disturbed
-- <50	Stable

--Combos:
-- Tropical Swamp Disturbed
-- Tropical Swamp Stable
-- Tropical Damp Disturbed
-- Tropical Damp Stable
-- Tropical Average Disturbed
-- Tropical Average Stable
-- Tropical Dry Disturbed
-- Tropical Dry Stable
-- Tropical Arid Disturbed
-- Tropical Arid Stable


-- Sub-tropical Swamp Disturbed
-- Sub-tropical Swamp Stable
-- Sub-tropical Damp Disturbed
-- Sub-tropical Damp Stable
-- Sub-tropical Average Disturbed
-- Sub-tropical Average Stable
-- Sub-tropical Dry Disturbed
-- Sub-tropical Dry Stable
-- Sub-tropical Arid Disturbed
-- Sub-tropical Arid Stable

-- Temperate Swamp Disturbed
-- Temperate Swamp Stable
-- Temperate Damp Disturbed
-- Temperate Damp Stable
-- Temperate Average Disturbed
-- Temperate Average Stable
-- Temperate Dry Disturbed
-- Temperate Dry Stable
-- Temperate Arid Disturbed
-- Temperate Arid Stable

-- Sub-polar Swamp Disturbed
-- Sub-polar Swamp Stable
-- Sub-polar Damp Disturbed
-- Sub-polar Damp Stable
-- Sub-polar Average Disturbed
-- Sub-polar Average Stable
-- Sub-polar Dry Disturbed
-- Sub-polar Dry Stable
-- Sub-polar Arid Disturbed
-- Sub-polar Arid Stable

-- Polar Swamp Disturbed
-- Polar Swamp Stable
-- Polar Damp Disturbed
-- Polar Damp Stable
-- Polar Average Disturbed
-- Polar Average Stable
-- Polar Dry Disturbed
-- Polar Dry Stable
-- Polar Arid Disturbed
-- Polar Arid Stable


--Conditions are:
--temp  - temperature
--humidity ,
--disturb, - disturbance regime (e.g low = slow stable forest, high = fast early colonizers)
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
local juncov = 0.1
local junden = 0.02
--Woodlands
local wodcov = juncov/3
local woden = wodcov/4
--Open grasslands
local savcov = wodcov/5
local savden = savcov/6

--==============================================================
-- Grasses

-- jungle grass.
-- temp to tropic, favours medium to low disturbance
mgtec.register_plant({
	nodes = {"default:junglegrass"},
	cover = 0.05,
	density = 0.055,
	priority = 65,
	check = function(t, pos)
		return t.temp > 50 and t.humidity > 40 and t.disturb < 80 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr)
	end,
})


-- Grass. (green)
-- cold to tropics with average or more water, high to medium disturbance
for i = 1, 5 do
	mgtec.register_plant({
		nodes = { "default:grass_"..i},
		cover = 0.05,
		density = 0.045,
		priority = 64,
		check = function(t, pos)
			return t.temp > 18 and t.humidity > 45 and t.disturb > 10 and (t.nodu ==  c_dirtgr or t.nodu ==  c_dirtdgr or t.nodu == c_dirtlit)
		end,
	})
end

-- Grass (dry)
-- cold to tropics with average or less water (but not none), high to medium disturbance
for i = 1, 5 do
	mgtec.register_plant({
		nodes = { "default:dry_grass_"..i},
		cover = 0.05,
		density = 0.045,
		priority = 63,
		check = function(t, pos)
			return t.temp > 18 and t.humidity > 10 and t.humidity < 55 and t.disturb > 10 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr or t.nodu == c_dsand or t.nodu == c_sand or t.nodu == c_gravel or t.nodu == c_dirtlit)
		end,
	})
end


--Dry shrub
-- dead stuff turns up all over the place
mgtec.register_plant({
	nodes = {"default:dry_shrub"},
	cover = 0.01,
	density = 0.005,
	priority = 62,
	check = function(t, pos)
		return t.nodu == c_dsand or t.nodu == c_dirtdgr or t.nodu == c_dirtgr or t.nodu == c_sand or t.nodu == c_dirtsno or t.nodu == c_gravel
	end,
})



----================================================================
--Bushes

--Bush
-- cold to subtropics, medium water, medium disturbance
mgtec.register_plant({
	nodes = {
		trunk = "default:bush_stem",
		leaves = "default:bush_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = woden,
	priority = 69,
	check = function(t, pos)
		return t.temp > 15 and t.temp < 65 and t.humidity > 25 and t.disturb > 20 and t.disturb < 85 and (t.nodu == c_gravel or t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = 1--math.floor(12 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
---
-- Acacia Bush
-- temperate to tropics, medium water or lo, high disturbance
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_bush_stem",
		leaves = "default:acacia_bush_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = woden,
	priority = 68,
	check = function(t, pos)
		return t.temp > 55 and t.humidity > 15 and t.humidity < 80 and t.disturb > 28 and t.disturb < 90 and (t.nodu ==  c_dirtgr or t.nodu ==  c_dirtdgr or t.nodu == c_dirtlit)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = 1--math.floor(12 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


--
--Cactus... arid specialist... low disturbance
mgtec.register_plant({
	nodes = {"default:cactus", n= math.random(1,4)},
	cover = savcov,
	density = savden,
	priority = 67,
	check = function(t, pos)
		return t.temp > 55 and t.humidity < 20 and t.disturb < 60 and (t.nodu ==  c_dirtlit or t.nodu ==  c_dsand or t.nodu ==  c_dirtdgr or t.nodu ==  c_gravel)
	end,
})

--- Cactus "tree" ...arid specialist... low disturbance... (more restricted)
mgtec.register_plant({
	nodes = {
		trunk = "default:cactus",
		leaves = "default:cactus",
		air = "air", ignore = "ignore",
	},
	cover = savcov,
	density = savden,
	priority = 66,
	check = function(t, pos)
		return t.temp > 45 and t.humidity > 5 and t.humidity < 25 and t.disturb < 5 and (t.nodu ==  c_dirtlit or t.nodu == c_dsand or t.nodu ==  c_dirtdgr or t.nodu ==  c_gravel)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(3 + 2 * rand)
		local radius = 2 + 1 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


---========================================================
--Flowers

--
--Viola
-- temperate to cold, medium to dry, high disturbance
mgtec.register_plant({
	nodes = { "flowers:viola"},
	cover = 0.001,
	density = 0.005,
	priority = 75,
	check = function(t, pos)
		return t.temp > 25 and t.temp < 75 and t.humidity > 21 and t.humidity < 50 and t.disturb > 30 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtsno or t.nodu == c_dirtdgr)
	end,
})
--
--flowers geranium
-- cold temperate to cold, medium wet, medium disturbance
mgtec.register_plant({
	nodes = {"flowers:geranium"},
	cover = 0.001,
	density = 0.005,
	priority = 74,
	check = function(t, pos)
		return t.temp > 15 and t.temp < 60 and t.humidity > 45 and t.humidity < 80 and t.disturb > 20 and t.disturb < 80 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtsno or t.nodu == c_dirtdgr)
	end,
})
--
--tulip
-- cold to temperate, arid, high disturbance
mgtec.register_plant({
	nodes = {"flowers:tulip"},
	cover = 0.001,
	density = 0.005,
	priority = 73,
	check = function(t, pos)
		return t.temp > 10 and t.temp < 70 and t.humidity > 15 and t.humidity < 40 and t.disturb > 60 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtsno or t.nodu == c_dirtdgr)
	end,
})
--

---
--Rose
--make sure it has a wide range bc need red dye for beds.
-- cold to  subtropic... average to arid, high half of disturbance
mgtec.register_plant({
	nodes = {"flowers:rose"},
	cover = 0.001,
	density = 0.005,
	priority = 72,
	check = function(t, pos)
		return t.temp > 15 and t.temp < 75 and t.humidity > 15 and t.humidity < 55 and t.disturb > 30 and t.disturb < 90 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr or t.nodu == c_gravel or t.nodu == c_dirtsno or t.nodu == c_dirtlit)
	end,
})
--
--dandelion_yellow
-- temperate (broad), average to dry, high disturbance
mgtec.register_plant({
	nodes = {"flowers:dandelion_yellow"},
	cover = 0.001,
	density = 0.005,
	priority = 71,
	check = function(t, pos)
		return t.temp > 25 and t.temp < 75 and t.humidity > 15 and t.humidity < 65 and t.disturb > 40 and (t.nodu == c_dsand or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno or t.nodu == c_dirtlit)
	end,
})
---
--dandelion_white
-- daisy... subpolar to temperate, damp, high disturbance
mgtec.register_plant({
	nodes = {"flowers:dandelion_white"},
	cover = 0.001,
	density = 0.005,
	priority = 70,
	check = function(t, pos)
		return t.temp > 15 and t.temp < 70 and t.humidity > 55 and t.humidity < 85 and t.disturb > 40 and t.disturb < 90 and (t.nodu == c_dirtdgr or t.nodu == c_dirtgr or t.nodu == c_gravel or t.nodu == c_dirtsno or t.nodu == c_dirtlit)
	end,
})
--

--===============================================
--MISC
--

--
--papyrus
-- warm temperate to tropic, wet, higher half of disturbance
mgtec.register_plant({
	nodes = {"default:papyrus", n= math.random(2,4) },
	cover = 0.06,
	density = 0.05,
	priority = 94,
	check = function(t, pos)
		return t.temp > 55 and t.humidity > 65 and pos.y < 20 and t.disturb > 25 and (t.nodu == c_clay or t.nodu ==  c_dirt or t.nodu ==  c_dirtlit)
	end,
})


--temperate to tropical, swamp
mgtec.register_plant({
	nodes = {"flowers:waterlily"},
	cover = 0.15,
	density = 0.1,
	priority = 61,
	check = function(t, pos)
		return t.temp > 80 and t.humidity > 80 and t.nodu == c_river
	end,
})

-- mushrooms
--anywhere with enough warmth and moisture to allow it
mgtec.register_plant({
	nodes = {"flowers:mushroom_brown", "flowers:mushroom_red"},
	cover = 0.001,
	density = 0.001,
	priority = 93,
	check = function(t, pos)
		return t.temp > 16 and t.humidity > 25 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno)
	end,
})


--Wheat
-- temperate, dry, high disturbance
mgtec.register_plant({
	nodes = {"farming:wheat_8"},
	cover = 0.003,
	density = 0.002,
	priority = 92,
	check = function(t, pos)
		return t.temp > 30 and t.temp < 80 and t.humidity > 20 and t.humidity < 40 and t.disturb > 70 and t.disturb < 80 and (t.nodu == c_dirtgr or t.nodu == c_dirtdgr)
	end,
})
---
--Cotton
-- sub to tropical, average to damp, medium disturb
mgtec.register_plant({
	nodes = {"farming:cotton_8"},
	cover = 0.01,
	density = 0.006,
	priority = 91,
	check = function(t, pos)
		return t.temp > 65 and t.humidity > 55 and t.disturb > 15 and t.disturb < 65 and (t.nodu == c_dirtlit or t.nodu == c_dirtdgr or t.nodu == c_dirtgr)
	end,
})


---===============================================================
--Tree Species.
-- juvenile. (smaller and possibly different form. mgtec.make_layered_tree,  or mgtec.make_tree2, or mgtec.make_apple_tree for apple )
-- adult (medium size and possibly different form. mgtec.make_layered_tree,  or mgtec.make_tree2, or mgtec.make_apple_tree for apple )
-- giant. (tall, mgtec.make_tree ... adds roots)

-- Juveniles have a broader range, giants more restricted to ideal sites. Juveniles dominate in disturbed areas, giants in stable areas.
--
--forest disturbance. base
local fdist = 40
--juvenile...
local fdistj = 50
--giant
local fdistg = 20


------------------------------------------------------
-- Aspen. (that looks like birch!)
-- dense forest, temperate to subpolar, medium to wet, high to medium disturbance.

--Adult Aspen Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 77,
	check = function(t, pos)
		return t.temp > (spolar - mtol) and t.temp < (spolar + mtol) and t.humidity > (damp - htol) and t.disturb > (fdist - 20) and t.disturb < (fdist + 20) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtsno or t.nodu == c_dirt)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(13 + 3 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

--juvenile Aspen Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 76,
	check = function(t, pos)
		return t.temp > (spolar - htol) and t.temp < (temper + mtol) and t.humidity > (damp - htol) and t.disturb > (fdistj - 30) and t.disturb < (fdistj + 20) and  (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtsno or t.nodu == c_dirt)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(6 + 2 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


--Giant Aspen Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:aspen_tree",
		leaves = "default:aspen_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 78,
	check = function(t, pos)
		return t.temp > (spolar - ltol) and t.temp < (spolar + ltol) and t.humidity > (damp - ltol) and t.disturb > (fdistg - 20) and t.disturb < (fdistg + 20) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtsno or t.nodu == c_dirt)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(16 + 4 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

------------------------------------------------------------
-- jungletree
-- dense forest, warm temperate to tropic, medium to wet, low to medium disturbance.

--Adult Jungle Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 80,
	check = function(t, pos)
		return t.temp > (stropic - htol) and t.humidity > (damp - mtol) and t.disturb > (fdist - 40) and t.disturb < (fdist + 30) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirt)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(13 + 5 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

--juvenile Jungle Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 79,
	check = function(t, pos)
		return t.temp > (stropic - htol) and t.humidity > (damp - htol) and t.disturb > (fdistj - 40) and t.disturb < (fdistj + 20) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_clay or t.nodu == c_dirt)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(10 + 5 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

--Giant Jungle Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:jungletree",
		leaves = "default:jungleleaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 81,
	check = function(t, pos)
		return t.temp > (stropic - ltol) and t.humidity > (damp - ltol) and t.disturb > (fdistg - 20) and t.disturb < (fdistg + 30) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirt)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(19 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

--------------------------------------------------------
-- acacia_tree
-- woodland forest, warm temperate to tropic, medium to dry, low disturbance.

--Acacia Adult
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 83,
	check = function(t, pos)
		return t.temp > (stropic - mtol) and t.temp < (stropic + htol) and t.humidity > (dry - mtol) and t.humidity < (average + ltol) and t.disturb > (fdist - 30) and t.disturb < (fdist + 5) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirt)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(15 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

--Acacia Juvenile
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 82,
	check = function(t, pos)
		return t.temp > (stropic - mtol) and t.temp < (stropic + htol) and t.humidity > (dry - htol) and t.humidity < (average + mtol) and t.disturb > (fdistg - 30) and t.disturb < (fdistg + 10) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirt)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(5 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_tree2(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


--Acacia Giant
mgtec.register_plant({
	nodes = {
		trunk = "default:acacia_tree",
		leaves = "default:acacia_leaves",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 84,
	check = function(t, pos)
		return t.temp > (stropic - ltol) and t.temp < (stropic + htol) and t.humidity > (dry - ltol) and t.humidity < (damp + htol) and t.disturb > (fdistg - 18) and t.disturb < (fdistg + 5) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirt)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(15 + 5 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


--------------------------------------------------------------
-- Apple
-- dense forest, temperate, medium disturbance.



--Adult Apple.
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 89,
	check = function(t, pos)
		return t.temp > (temper - htol) and t.temp < (temper + htol) and t.humidity > (average - mtol) and t.humidity < (average + mtol) and t.disturb > (fdist - 10) and t.disturb < (fdist + 10) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(12 + 5 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
	end,
})

--Juvenile Apple.
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 88,
	check = function(t, pos)
		return t.temp > (stropic - htol) and t.temp < (spolar + htol) and t.humidity > (dry - ltol) and t.humidity < (damp + htol) and t.disturb > (fdistj - 30) and t.disturb < (fdistj + 20) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(5 + 2 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
	end,
})

--Giant Apple.
mgtec.register_plant({
	nodes = {
		trunk = "default:tree",
		leaves = "default:leaves",
		fruit = "default:apple",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 90,
	check = function(t, pos)
		return t.temp > (temper - htol) and t.temp < (temper + htol) and t.humidity > (average - ltol) and t.humidity < (average + ltol) and t.disturb > (fdistg - 10) and t.disturb < (fdistg + 5) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(18 + 2 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)
	end,
})

-----------------------------------------------------------------
-- pine_tree
-- dense forest, temperate to subpolar, medium to arid, low disturbance.

--Adult Pine Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 86,
	check = function(t, pos)
		return t.temp > (spolar - htol) and t.temp < (spolar + htol) and t.humidity > (dry - htol) and t.humidity < (average + mtol) and t.disturb > (fdist - 20) and t.disturb < (fdist - 10) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(15 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

--Juvenile Pine Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 85,
	check = function(t, pos)
		return t.temp > (spolar - htol) and t.temp < (spolar + htol) and t.humidity > (dry - htol) and t.humidity < (average + htol) and t.disturb > (fdistg - 20) and t.disturb < (fdistg + 30) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(15 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})

--Giant Pine Tree.
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_tree",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = juncov,
	density = junden,
	priority = 87,
	check = function(t, pos)
		return t.temp > (spolar - htol) and t.temp < (spolar + ltol) and t.humidity > (dry - ltol) and t.humidity < (average + ltol) and t.disturb > (fdistg - 20) and t.disturb < (fdistg + 30) and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(18 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})


--[[
-- BUGGE Fixer Test TREE
mgtec.register_plant({
	nodes = {
		trunk = "default:pine_needles",
		leaves = "default:pine_needles",
		air = "air", ignore = "ignore",
	},
	cover = wodcov,
	density = woden,
	priority = 87,
	check = function(t, pos)
		return t.temp > 40 and t.temp < 70 and t.humidity > 50 and t.humidity < 100 and t.disturb < 60 and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno or t.nodu == c_gravel)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(18 + 1 * rand)
		local radius = 3 + 1 * rand

		mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
	end,
})
]]

---=====================================================================
