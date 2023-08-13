# mg_tectonic
by Dokimi

Current version 0.3.1 + Odacirs improvements + experiments

# Map Outline
A naturalistic mapgen for Minetest, based around mimicking the landscape of a tectonic plate boundary.

This mapgen aims to create a world which is scientifically informed, but within the minimalist bounds of default Minetest.

It generates a landmass bounded by oceans, with a mountains running North-South down the middle. The land, and its hills and valleys rise from softer terrain on the coasts to towering mountains in the centre. A rainshadow leaves the East dry, and the West wet. Hot weather prevails in the North, cold in the South.

Rocks, sediments, and soils are arranged in strata. Ores occur in concentrated deposits. Deep fissures run along the fault lines, go down deep enough and they fill with magma.




# How Does This Work?
The generator uses a modified cosine wave to generate the underlying mountains. This creates natural rolling hills progressing to steep mountains. Layers of rock and sediment are then added one after the other, with varying conditions to build up a layered landscape and geology.


# License:

Code is licensed under GNU LGPLv2+.




# Credits:
The plants api is adapted from the Valley's mapgen by Gael-de-Sailly.


# Change Log

0.1:

- Initial release.


0.1.1:

- Adjust ocean basins to create lakes, lowland/plateaus, islands.

- tweaked tree heights

- more cave sediments


0.2:

- Random lakes and rivers (major contributions by thorn0906)

- Random start position (major contributions by thorn0906)

- Improved compatibility with mods by making climate more accesible (by thorn0906)

- Third biome factor (disturbance) for greater regional variety

- Adjusted landscape shape (larger mountains etc)

- various minor changes and additions (e.g. coral, sea ice)

- mod.conf file

- 5.0 new stuff (permafrost, conifer litter, black tulip, chrysanthemum_green, marram_grass, fern, pine bush, blueberry, kelp, corals)


0.3:

- Rebalance landscape, rivers, lakes, climate.

- Rebalance plants, and tidy code format

- custom cloud height

- Make climate function more accessible to allow its use by weather mods etc (possibly causes rare bugs in mapgen??)

- Fix conflict with beds respawn

- Thick trunks for giant trees

- Various minor fixes and improvements

0.3.0.1:

- patch lake cliff bug

0.3.1:

- fix kelp bug

- add snow dust

Odacir: spawn code, climate compatibility

Experimental:
- noise on waves (for greater landscape variety)
- add dry dirts


(Bugs/issues: kelp and corals only turning up on rocky coasts??)


0.3.2:																- by Skamiz
- add timer utility for measuring performance
- add cartography utility, showing an accurate heightmap of the island

- remove influence of 3d noise on ocaean basins, since it was negligible
- change 'xteleport' command to accept relative coordinates by proceding numbers with '~'

- massive perfomance improvements
	- mainly by adding conditions and rearanging this so it doesn't get executed more times then necessary
