---MG TECTONIC adapted plants register.
---adapted from valleys_mapgen

--[[
Many syntaxes are possible, with their default behaviour (see *grow*):
* `nodes = "default:dry_shrub"`: simply generate a dry shrub.
* `nodes = {"default:papyrus", n=4}`: generate 4 papyrus nodes vertically.
* `nodes = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5"}`: generate one grass node, randomly chosen between the 5 nodes.
* `nodes = {"default:grass_1", "default:grass_2", "default:grass_3", "default:grass_4", "default:grass_5, n=3"}`: generate 3 grass nodes vertically (my example is a bit sillyâ€¦), randomly chosen between the 5 nodes (chosen once, not 3 times).
--anything more needs a grow function

#### cover
Decimal number between 0 and 1, which determines the proportion of surface nodes that are "reserved" for the plant. This doesn't necessarily mean that there is a plant on the node (see *density*), but this "cover" prevents other plants with lower priority from spawning on said nodes.

#### density
Number between 0 and cover. Proportion of nodes that are effectively covered by the plant.

Examples:
* `cover = 0.8 ; density = 0.8`: the plant is present on 80% of the nodes, so extremely dense. Other plants can't take more than the remaining 20% if they have a lower `priority`.
* `cover = 0.8 ; density = 0.1`: the plant is present on 10% of the nodes, so more scattered, but other plants can't take more than 20% if they have a lower `priority`. Params like this are suitable for a plant that naturally needs much space.
* `cover = 0.1 ; density = 0.1`: the plant is present on 10% of the nodes as in the previous case, but other plants are much more common (max 90% of the nodes).

#### priority
Integer generally between 0 and 100 (no strict rule :) to determine which plants are dominating the others. The dominant plants (with higher priority) impose their *cover* on the others.

#### check
Function to check the conditions. Should return a boolean: true, the plant can spawn here ; false, the plant can't spawn and doesn't impose its *cover*. It takes 2 parameters:
* `t`: table containing all possible conditions: all noises (`t.v1` to `t.v20`), dirt thickness `t.thickness`, temperature `t.temp`, humidity `t.humidity`, humidity from sea `t.sea_water`, from rivers `t.river_water`, from sea and rivers `t.water`.
* `pos`: position of the future plant, above the dirt node.

```
check = function(t, pos)
	return t.v15 < 0.7 and t.temp >= 1.9 and t.humidity > 2 and t.v16 > 2
end,
```


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


--Humidity
-- >80 Swamp
-- 60-80   Damp
-- 40-60 Average
-- 20-40	Dry
-- 0-20 Arid


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
local c_dirtconlit = minetest.get_content_id("default:dirt_with_coniferous_litter")
local c_snowbl = minetest.get_content_id("default:snowblock")
local c_dsand = minetest.get_content_id("default:desert_sand")
local c_permamoss = minetest.get_content_id("default:permafrost_with_moss")
local c_permastone = minetest.get_content_id("default:permafrost_with_stones")

--water
local c_river = minetest.get_content_id("default:river_water_source")

--remember to set values for all the conditions...or it will go strange places

--===============================================================

--Climate
--Temperature
local tropic = 90
local stropic = 70
local temper = 50
local spolar = 30
local polar = 10

--Humidity
local swamp = 90
local damp = 70
local average = 50
local dry = 30
local arid = 10

--disturbance.
local barren = 90
local open = 70
local transition = 50
local young = 30
local old = 10

--add on to the above to create a range
--tolerance
local htol = 24
local mtol = 12
local ltol = 6


--==============================================================
--priority..higher exclude lower
--everything lower must survive in the remaining uncovered space.

--covers
-- 0 - 1. Proportion of space saved for plant.
--Blocks lower priority plants in area. Competitiveness
local includer = 0.001
local vlo_cov = 0.002
local lo_cov = 0.045
local mid_cov = 0.09
local hi_cov = 0.18
local vhi_cov = 0.36
local excluder = 0.50


--density
--0 - 1. Proportion of space covered by the plant.
local super_rare = 0.0001
local rare = 0.001
local scattered = 0.01
local uncommon = 0.04
local common = 0.07
local abundant = 0.16
local plague = 0.32

--cover should likely be higher than density?

--==============================================================

--Normal (for soils).. forests and grasslands and cold
local plantlist1 = {
	--Green grass ..higher numbered grass is taller
	{"default:grass_1", lo_cov, uncommon, 26, (spolar - htol), (tropic + htol), (average - ltol), (swamp + htol), (old - ltol), (open + htol)},
	{"default:grass_2", lo_cov, uncommon, 27, (spolar - mtol), (tropic + htol), (average), (swamp + htol), (young - mtol), (open + htol)},
	{"default:grass_3", lo_cov, uncommon, 28, (spolar - ltol), (tropic + htol), (average), (swamp + htol), (young - ltol), (open + mtol)},
	{"default:grass_4", lo_cov, common, 29, (spolar), (tropic + htol), (average + ltol), (swamp + htol), (young), (open)},
	{"default:grass_5", lo_cov, abundant, 30, (spolar + ltol), (tropic + htol), (average + mtol), (swamp + htol), (young), (open - ltol)},
	----
	{"default:junglegrass", lo_cov, abundant, 31, (stropic - mtol), (tropic + mtol), (damp - mtol), (swamp + mtol), (young - mtol), (transition + ltol)},
	--ferns...higher numbered is taller
	{"default:fern_1", lo_cov, scattered, 33, (spolar - mtol), (tropic + htol), (average - mtol), (swamp + htol), -1, (young + mtol)},
	{"default:fern_2", lo_cov, common, 34, (spolar - mtol), (tropic + htol), (average - ltol), (swamp + htol), -1, (young + ltol)},
	{"default:fern_3", lo_cov, abundant, 35, (spolar - ltol), (tropic + htol), average, (swamp + htol), -1, young},
	--flowers
	{"flowers:viola", vlo_cov, rare, 38, (temper - htol), (temper + htol), (average - htol), (average + ltol), open, (open + htol)},
	{"flowers:tulip", vlo_cov, rare, 39, (spolar - htol), (temper + ltol), arid, average, transition, open},
	{"flowers:geranium", vlo_cov, rare, 40, (spolar - mtol), (temper + mtol), (damp - htol), (damp + ltol), transition, open},
	{"flowers:tulip_black", includer, super_rare, 41, (polar - mtol), (polar + htol), arid, damp, young, open},
	{"flowers:rose", vlo_cov, rare, 42, (spolar - htol), (temper + htol), arid, damp, (open - ltol), (open + ltol)},
	{"flowers:dandelion_yellow", vlo_cov, uncommon, 43, (spolar - mtol), (temper + htol), (arid - mtol), (arid + mtol), (open - ltol), (open + htol)},
	{"flowers:dandelion_white", vlo_cov, uncommon, 44, 2, (temper + htol), (average - htol), (damp + htol), (open - ltol), (open + htol)},
	{"flowers:chrysanthemum_green", includer, super_rare, 45, temper, (stropic + htol), (damp - htol), damp, young, transition},
	--crops
	{"farming:wheat_8", super_rare, includer, 49, (temper - mtol), (temper + htol), (dry - ltol), (dry + htol), open, (open + ltol)},
	{"farming:cotton_8", super_rare, includer, 50, (stropic - mtol), (stropic + htol), (damp - htol), (damp + mtol), open, (open + ltol)},
}


for i in ipairs(plantlist1) do
	local lnodes = plantlist1[i][1]
	local lcover = plantlist1[i][2]
	local ldensity = plantlist1[i][3]
	local lpriority = plantlist1[i][4]
	local temp_min = plantlist1[i][5]
	local temp_max = plantlist1[i][6]
	local hum_min = plantlist1[i][7]
	local hum_max = plantlist1[i][8]
	local dist_min = plantlist1[i][9]
	local dist_max = plantlist1[i][10]

	mgtec.register_plant({
		nodes = lnodes,
		cover = lcover,
		density = ldensity,
		priority = lpriority,
		check = function(t, pos)
			return
			t.temp > temp_min
			and t.temp < temp_max
			and t.humidity > hum_min
			and t.humidity < hum_max
			and t.disturb > dist_min
			and t.disturb < dist_max
			and (t.nodu == c_dirtlit
				or t.nodu == c_dirtconlit
			  or t.nodu == c_dirtgr
				or t.nodu == c_dirtdgr
				or t.nodu == c_dirtsno
				or t.nodu == c_permamoss)
		end,
	})
end





--Normal soils and desert sands,
local plantlist2 = {
	--Dry grass ..higher numbered grass is taller
	{"default:dry_grass_1", lo_cov, uncommon, 21, (spolar - htol), (tropic + htol), (arid - mtol), (average + ltol), (old - ltol), (open + htol)},
	{"default:dry_grass_2", lo_cov, uncommon, 22, (spolar - mtol), (tropic + htol), (arid - ltol), (average), (young - mtol), (open + htol)},
	{"default:dry_grass_3", lo_cov, uncommon, 23, (spolar - ltol), (tropic + htol), (arid), (average - ltol), (young - ltol), (open + mtol)},
	{"default:dry_grass_4", lo_cov, common, 24, (spolar), (tropic + htol), (arid + ltol), (average - ltol), (young), (open)},
	{"default:dry_grass_5", lo_cov, abundant, 25, (spolar + ltol), (tropic + htol), (arid + mtol), (average - ltol), (young), (open- ltol)},

}

for i in ipairs(plantlist2) do
	local lnodes = plantlist2[i][1]
	local lcover = plantlist2[i][2]
	local ldensity = plantlist2[i][3]
	local lpriority = plantlist2[i][4]
	local temp_min = plantlist2[i][5]
	local temp_max = plantlist2[i][6]
	local hum_min = plantlist2[i][7]
	local hum_max = plantlist2[i][8]
	local dist_min = plantlist2[i][9]
	local dist_max = plantlist2[i][10]

	mgtec.register_plant({
		nodes = lnodes,
		cover = lcover,
		density = ldensity,
		priority = lpriority,
		check = function(t, pos)
			return
			t.temp > temp_min
			and t.temp < temp_max
			and t.humidity > hum_min
			and t.humidity < hum_max
			and t.disturb > dist_min
			and t.disturb < dist_max
			and (t.nodu == c_dirtlit
				or t.nodu == c_dirtconlit
			  or t.nodu == c_dirtgr
				or t.nodu == c_dirtdgr
				or t.nodu == c_dsand)
		end,
	})
end


--Sea Shore Sand
local plantlist3 = {
	--Marram ..higher numbered grass is taller
	{"default:marram_grass_1", lo_cov, uncommon, 51, (spolar - htol), (tropic + htol), arid, swamp, 2, barren},
	{"default:marram_grass_2", lo_cov, common, 52, (spolar - mtol), (tropic + mtol), (arid + ltol), (swamp - ltol), 1, barren},
	{"default:marram_grass_3", lo_cov, abundant, 53, (spolar - ltol), (tropic + ltol), (arid + mtol), (swamp - mtol), -1, barren},
}

for i in ipairs(plantlist3) do
	local lnodes = plantlist3[i][1]
	local lcover = plantlist3[i][2]
	local ldensity = plantlist3[i][3]
	local lpriority = plantlist3[i][4]
	local temp_min = plantlist3[i][5]
	local temp_max = plantlist3[i][6]
	local hum_min = plantlist3[i][7]
	local hum_max = plantlist3[i][8]
	local dist_min = plantlist3[i][9]
	local dist_max = plantlist3[i][10]

	mgtec.register_plant({
		nodes = lnodes,
		cover = lcover,
		density = ldensity,
		priority = lpriority,
		check = function(t, pos)
			return
			t.temp > temp_min
			and t.temp < temp_max
			and t.humidity > hum_min
			and t.humidity < hum_max
			and t.disturb > dist_min
			and t.disturb < dist_max
			and t.nodu == c_sand
			and pos.y < 5
			and pos.y > 0
		end,
	})
end


--Weirdos Plants
--Dry shrub
-- dead stuff turns up all over the place
mgtec.register_plant({
	nodes = {"default:dry_shrub"},
	cover = vlo_cov,
	density = rare,
	priority = 54,
	check = function(t, pos)
		return t.nodu == c_permamoss or t.nodu == c_permastone or t.nodu == c_dsand or t.nodu == c_sand2 or t.nodu == c_dirtdgr or t.nodu == c_dirtgr or t.nodu == c_sand or t.nodu == c_dirtsno or t.nodu == c_gravel or t.nodu == c_dirtconlit
	end,
})

--Cactus... arid specialist... low disturbance
mgtec.register_plant({
	nodes = {"default:cactus", n= math.random(1,4)},
	cover = lo_cov,
	density = rare,
	priority = 55,
	check = function(t, pos)
		return t.temp > (stropic - htol) and t.humidity > 1 and t.humidity < arid and t.disturb < transition and (t.nodu ==  c_dsand or t.nodu ==  c_dirtdgr or t.nodu ==  c_gravel)
	end,
})

--papyrus
mgtec.register_plant({
	nodes = {"default:papyrus", n= math.random(3,5) },
	cover = lo_cov,
	density = plague,
	priority = 56,
	check = function(t, pos)
		return t.temp > temper and t.humidity > average and pos.y < 5 and pos.y > 1 and t.disturb > young and t.disturb < (open + ltol) and (t.nodu == c_clay or t.nodu == c_dirtgr or t.nodu ==  c_dirt or t.nodu ==  c_dirtlit or t.nodu ==  c_sand)
	end,
})

--waterlily
mgtec.register_plant({
	nodes = {"flowers:waterlily"},
	cover = vlo_cov,
	density = abundant,
	priority = 57,
	check = function(t, pos)
		return t.temp > (stropic-mtol) and t.humidity > average and t.disturb > young and t.disturb < open and t.nodu == c_river
	end,
})

-- mushrooms
--anywhere with enough warmth and moisture to allow it
mgtec.register_plant({
	nodes = {"flowers:mushroom_brown", "flowers:mushroom_red"},
	cover = vlo_cov,
	density = rare,
	priority = 58,
	check = function(t, pos)
		return t.temp > 1 and t.humidity > arid and (t.nodu == c_dirtlit or t.nodu == c_dirtgr or t.nodu == c_dirtdgr or t.nodu == c_dirtsno or t.nodu == c_dirtconlit or t.nodu == c_permamoss or t.nodu == c_permastone or t.nodu == c_clay)
	end,
})



--Tree type trees. Trees and Bushes ..Normal (for soils).. forests and grasslands and cold
local bushlist1 = {
	--giant aspen
	{"default:aspen_tree", "default:aspen_leaves", vhi_cov, common, 8, (spolar - mtol), (spolar + mtol), (damp - mtol), (swamp + htol), -1, (old + ltol), 16, 4},
	--adult jungletree
	{"default:jungletree", "default:jungleleaves", hi_cov, common, 10, (stropic - htol), (tropic + htol), (damp - htol), (swamp + htol), (old - ltol), transition,  13, 5},
	--giant jungletree
	{"default:jungletree", "default:jungleleaves", vhi_cov, common, 11, (stropic - htol), (tropic + htol), (damp - htol), (swamp + htol), -1, (old + mtol), 19, 1},
	--juvenile acacia_tree---
	{"default:acacia_tree", "default:acacia_leaves", vhi_cov, scattered, 12, (stropic - htol), (tropic + mtol), (dry - htol), (dry + htol), (old + ltol), (young + ltol),  5, 2},
	--adult acacia_tree
	{"default:acacia_tree", "default:acacia_leaves", vhi_cov, scattered, 13, (stropic - htol), (tropic + mtol), (dry - htol), (dry + htol), old, young, 12, 3},
	--giant acacia_tree
	{"default:acacia_tree", "default:acacia_leaves", vhi_cov, uncommon, 14, (stropic - ltol), (tropic + mtol), dry, (dry + htol), -1, (old + ltol), 16, 3},

}


for i in ipairs(bushlist1) do
	local lnodes_tr = bushlist1[i][1]
	local lnodes_le = bushlist1[i][2]
	local lcover = bushlist1[i][3]
	local ldensity = bushlist1[i][4]
	local lpriority = bushlist1[i][5]
	local temp_min = bushlist1[i][6]
	local temp_max = bushlist1[i][7]
	local hum_min = bushlist1[i][8]
	local hum_max = bushlist1[i][9]
	local dist_min = bushlist1[i][10]
	local dist_max = bushlist1[i][11]
	local lheight = bushlist1[i][12]
	local hvar = bushlist1[i][13]

	mgtec.register_plant({
		nodes = {
			trunk = lnodes_tr,
			leaves = lnodes_le,
			air = "air", ignore = "ignore",
		},
		cover = lcover,
		density = ldensity,
		priority = lpriority,
		check = function(t, pos)
			return
			t.temp > temp_min
			and t.temp < temp_max
			and t.humidity > hum_min
			and t.humidity < hum_max
			and t.disturb > dist_min
			and t.disturb < dist_max
			and (t.nodu == c_dirtlit
				or t.nodu == c_dirtconlit
			  or t.nodu == c_dirtgr
				or t.nodu == c_dirtdgr
				or t.nodu == c_dirtsno
				or t.nodu == c_permamoss)
		end,
		grow = function(nodes, pos, data, data2,area)
			local rand = math.random()
			local height = math.floor(lheight + (hvar * rand))
			local radius = 3 + (1 * rand)

			mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)

		end,
	})
end


--Layered ...Trees and Bushes ..Normal (for soils).. forests and grasslands and cold
local bushlist2 = {
	--bushes
	{"default:bush_stem", "default:bush_leaves", vhi_cov, scattered, 1, (spolar - mtol), (stropic - mtol), (average - htol), (damp + mtol), (transition - mtol), (open + ltol), 1,0},
	{"default:acacia_bush_stem", "default:acacia_bush_leaves", vhi_cov, scattered, 2, (temper - mtol), (tropic + htol), (dry - htol), (average + ltol), (transition - mtol), (open + ltol), 1, 0},
	{"default:pine_bush_stem", "default:pine_bush_needles", vhi_cov, scattered, 3, (spolar - htol), (temper + ltol), (dry - htol), (average + mtol), (transition - mtol), (open + ltol), 1, 0},
	{"default:blueberry_bush_leaves", "default:blueberry_bush_leaves_with_berries", lo_cov, rare, 4, (spolar - mtol), (temper + htol), (damp - mtol), (damp + htol), (young - ltol), (transition + ltol), 1, 0},
	--juvenile aspen---
	{"default:aspen_tree", "default:aspen_leaves", hi_cov, common, 6, (spolar - mtol), (temper + mtol), (average - mtol), (swamp + htol), (young - ltol), (transition + ltol), 6, 2},
	--adult aspen
	{"default:aspen_tree", "default:aspen_leaves", hi_cov, common, 7, (spolar - mtol), (spolar + htol), (average - mtol), (swamp + htol), (old - ltol), (young + mtol), 13, 3},
	--juvenile jungletree---
	{"default:jungletree", "default:jungleleaves", hi_cov, common, 9, (stropic - htol), (tropic + htol), (damp - htol), (swamp + htol), (young - ltol), (transition + ltol), 12, 5},
	--juvenile pine---
	{"default:pine_tree", "default:pine_needles", vhi_cov, scattered, 18, (spolar - htol), (temper + mtol), (dry - htol), (average + ltol), (young - ltol), (young + ltol), 6, 1},
	--adult pine
	{"default:pine_tree", "default:pine_needles", vhi_cov, uncommon, 19, (spolar - htol), (temper + mtol), (dry - htol), (average + ltol), (old - ltol), young, 15, 1},
	--giant pine
	{"default:pine_tree", "default:pine_needles", vhi_cov, uncommon, 20, (spolar - htol), (temper + mtol), (dry - ltol), (average + ltol), -1, (old + ltol), 18, 1},

}


for i in ipairs(bushlist2) do
	local lnodes_tr = bushlist2[i][1]
	local lnodes_le = bushlist2[i][2]
	local lcover = bushlist2[i][3]
	local ldensity = bushlist2[i][4]
	local lpriority = bushlist2[i][5]
	local temp_min = bushlist2[i][6]
	local temp_max = bushlist2[i][7]
	local hum_min = bushlist2[i][8]
	local hum_max = bushlist2[i][9]
	local dist_min = bushlist2[i][10]
	local dist_max = bushlist2[i][11]
	local lheight = bushlist2[i][12]
	local hvar = bushlist2[i][13]


	mgtec.register_plant({
		nodes = {
			trunk = lnodes_tr,
			leaves = lnodes_le,
			air = "air", ignore = "ignore",
		},
		cover = lcover,
		density = ldensity,
		priority = lpriority,
		check = function(t, pos)
			return
			t.temp > temp_min
			and t.temp < temp_max
			and t.humidity > hum_min
			and t.humidity < hum_max
			and t.disturb > dist_min
			and t.disturb < dist_max
			and (t.nodu == c_dirtlit
				or t.nodu == c_dirtconlit
			  or t.nodu == c_dirtgr
				or t.nodu == c_dirtdgr
				or t.nodu == c_dirtsno
				or t.nodu == c_permamoss)
		end,
		grow = function(nodes, pos, data, data2,area)
			local rand = math.random()
			local height = math.floor(lheight + (hvar * rand))
			local radius = 3 + (1 * rand)

			mgtec.make_layered_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)

		end,
	})
end


--Fruiting....Trees and Bushes ..Normal (for soils).. forests and grasslands and cold
local bushlist3 = {
	--juvenile apple---
	{"default:tree", "default:leaves", hi_cov, uncommon, 15, (temper - htol), (stropic + ltol), (average - htol), (damp + mtol), (young + ltol), (transition + mtol), 6, 2, "default:apple"},
	--adult apple
	{"default:tree", "default:leaves", vhi_cov, common, 16, (temper - htol), (temper + htol), (average - htol), (damp + mtol), (old + mtol), (young + mtol), 12, 5, "default:apple"},
	--giant apple
	{"default:tree", "default:leaves", vhi_cov, uncommon, 17, (temper - htol), (temper + mtol), (average - htol), (damp + mtol), -1, (old + ltol), 16, 3, "default:apple"},

}


for i in ipairs(bushlist3) do
	local lnodes_tr = bushlist3[i][1]
	local lnodes_le = bushlist3[i][2]
	local lcover = bushlist3[i][3]
	local ldensity = bushlist3[i][4]
	local lpriority = bushlist3[i][5]
	local temp_min = bushlist3[i][6]
	local temp_max = bushlist3[i][7]
	local hum_min = bushlist3[i][8]
	local hum_max = bushlist3[i][9]
	local dist_min = bushlist3[i][10]
	local dist_max = bushlist3[i][11]
	local lheight = bushlist3[i][12]
	local hvar = bushlist3[i][13]
	local lnodes_fr = bushlist3[i][14]

	mgtec.register_plant({
		nodes = {
			trunk = lnodes_tr,
			leaves = lnodes_le,
			fruit = lnodes_fr,
			air = "air", ignore = "ignore",
		},
		cover = lcover,
		density = ldensity,
		priority = lpriority,
		check = function(t, pos)
			return
			t.temp > temp_min
			and t.temp < temp_max
			and t.humidity > hum_min
			and t.humidity < hum_max
			and t.disturb > dist_min
			and t.disturb < dist_max
			and (t.nodu == c_dirtlit
				or t.nodu == c_dirtconlit
			  or t.nodu == c_dirtgr
				or t.nodu == c_dirtdgr
				or t.nodu == c_dirtsno
				or t.nodu == c_permamoss)
		end,
		grow = function(nodes, pos, data, data2,area)
			local rand = math.random()
			local height = math.floor(lheight + (hvar * rand))
			local radius = 3 + (1 * rand)

			mgtec.make_apple_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.fruit, nodes.air, nodes.ignore)

		end,
	})
end




--Weirdo Trees
--- Cactus "tree" ...arid specialist...
mgtec.register_plant({
	nodes = {
		trunk = "default:cactus",
		leaves = "default:cactus",
		air = "air", ignore = "ignore",
	},
	cover = lo_cov,
	density = super_rare,
	priority = 5,
	check = function(t, pos)
		return t.temp > stropic and t.humidity > arid and t.humidity < dry and t.disturb < old and (t.nodu == c_dsand or t.nodu ==  c_dirtdgr)
	end,
	grow = function(nodes, pos, data, data2,area)
		local rand = math.random()
		local height = math.floor(3 + 2 * rand)
		local radius = 2 + 1 * rand

		mgtec.make_tree(pos, data, area, height, radius, nodes.trunk, nodes.leaves, nodes.air, nodes.ignore)
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
