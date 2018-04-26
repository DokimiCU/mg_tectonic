# mg_tectonic
by Dokimi

Current version 0.1 - development

This is a work in progress. Currently functional, but untested. May contain game breaking bugs, and be unbalanced, or incomplete in areas.

# Map Outline
A naturalistic mapgen for Minetest, based around mimicking the landscape of a tectonic plate boundary.

This mapgen aims to create a world which is scientifically informed, but within the minimalist bounds of default Minetest.

It generates a landmass bounded by oceans, with a mountain range running North-South down the middle. The land, and its hills and valleys rise from gentle plains towards these snow capped mountains. A rainshadow leaves the East dry, and the West wet. Hot weather prevails in the North, cold in the South. 

Rocks, sediments, and soils are arranged in strata. Ores occur in concentrated deposits. Deep fissures run along the fault lines, go down deep enough and they fill with mineral rich magma. The uplift also leads to sea at the edges, which past a certain point drop away into deep ocean basins.

The player starts in a tunnel beneath the mountains, faced with a choice of going east into the badlands, or west into the cloud forests.


# How Does This Work?
The generator uses the interference pattern between two waves. These are then modulated with noise, and by distance from the central axis of the map. This creates natural rolling hills progressing to steep mountains. Layers of rock and sediment are then added one after the other, with varying conditions to build up a layered landscape and geology.


# License:

Code is licensed under GNU LGPLv2+.




# Credits:
The plants api is adapted from the Valley's mapgen by Gael-de-Sailly.


# Change Log
0.1
