# mg_tectonic
by Dokimi

Current version 0.1 - development

This is a work in progress. Currently functional, but untested. May contain game breaking bugs, and be unbalanced, or incomplete in areas.

# Map Outline
A naturalistic mapgen for Minetest, based around mimicking the landscape of a tectonic plate boundary.

This mapgen aims to create a world which is scientifically informed, but within the minimalist bounds of default Minetest.

It generates a landmass bounded by oceans, with a mountains running North-South down the middle. The land, and its hills and valleys rise from softer terrain on the coasts to towering mountains in the centre. A rainshadow leaves the East dry, and the West wet. Hot weather prevails in the North, cold in the South. 

Rocks, sediments, and soils are arranged in strata. Ores occur in concentrated deposits. Deep fissures run along the fault lines, go down deep enough and they fill with magma.

The player starts at the centre of the map, on an island in a large caldera. Two rivers drain this lake and provide access through the often impassable terrain. One river leads East into the badlands, the other river heads West into the cloud forests. 


# How Does This Work?
The generator uses a modified sine wave to generate the underlying mountains. This creates natural rolling hills progressing to steep mountains. Layers of rock and sediment are then added one after the other, with varying conditions to build up a layered landscape and geology.


# License:

Code is licensed under GNU LGPLv2+.




# Credits:
The plants api is adapted from the Valley's mapgen by Gael-de-Sailly.


# Change Log
0.1
