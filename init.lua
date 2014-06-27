-- path 0.3.2 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- 2 path systems
-- dark pathslab side textures
-- simpler mapgen: amplify terrain noise

-- Parameters

local YCEN = 40 -- Terrain centre
local YWAT = 1 -- Water level
local TERSCA = 24 -- Vertical roads terrain scale
local YBTOP = 5 -- Beach top
local YROCK = 256 -- Dirt thins to 1 node at this distance above YWAT
local DEPSEL = 8 -- Depth of dirt at sea level
local APPCHA = 1 / 4 ^ 2 -- Maximum appletree chance per node
local TFLO = 0.015 -- Flora threshold. Keeps flora away from roads.
local TPFLO = 0.02 -- Flora path threshold. Keeps flora away from paths.

-- 2D noise for roads terrain

local np_terrain = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -9111,
	octaves = 4,
	persist = 0.5
}

-- 2D noise for patha

local np_patha = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048},
	seed = 11,
	octaves = 4,
	persist = 0.33
}

-- 2D noise for pathb

local np_pathb = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048},
	seed = -80033,
	octaves = 4,
	persist = 0.33
}

-- 2D noise for pathc

local np_pathc = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -80,
	octaves = 4,
	persist = 0.33
}

-- 2D noise for pathd

local np_pathd = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = 300707,
	octaves = 4,
	persist = 0.33
}

-- 2D noise for trees

local np_tree = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = 133338,
	octaves = 3,
	persist = 0.4
}

-- Nodes

minetest.register_node("path:grass", {
	description = "Grass",
	tiles = {"default_grass.png", "default_dirt.png", "default_grass.png"},
	is_ground_content = false,
	groups = {crumbly=3,soil=1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})

minetest.register_node("path:dirt", {
	description = "Dirt",
	tiles = {"default_dirt.png"},
	is_ground_content = false,
	groups = {crumbly=3,soil=1},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("path:path", {
	description = "Path",
	tiles = {"path_path.png"},
	is_ground_content = false,
	groups = {crumbly=2},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("path:pathslab", { -- pathside texture darker because sunlight propagates = true
	description = "Path slab",
	tiles = {"path_path.png", "path_pathside.png", "path_pathside.png"},
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
	},
	selection_box = {
		type = "fixed",
		fixed = {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
	},
	groups = {crumbly=2},
	drop = "default:dirt",
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("path:stone", {
	description = "Stone",
	tiles = {"default_stone.png"},
	is_ground_content = false,
	groups = {cracky=3},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("path:appleleaf", {
	description = "Appletree leaves",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {"default_leaves.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {snappy=3, flammable=2},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("path:roadblack", {
	description = "Road black",
	tiles = {"path_roadblack.png"},
	groups = {cracky=2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("path:roadslab", {
	description = "Road slab",
	tiles = {"path_roadblack.png"},
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	node_box = {
		type = "fixed",
		fixed = {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
	},
	selection_box = {
		type = "fixed",
		fixed = {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
	},
	groups = {cracky=2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("path:roadwhite", {
	description = "Road white",
	tiles = {"path_roadwhite.png"},
	groups = {cracky=2},
	sounds = default.node_sound_stone_defaults(),
})

-- Stuff

path = {}

-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
end)

-- Spawn player

function spawnplayer(player)
	player:setpos({x=0, y=48, z=0})
end

minetest.register_on_newplayer(function(player)
	spawnplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	spawnplayer(player)
	return true
end)

-- Function

function path_appletree(x, y, z, area, data)
	local c_tree = minetest.get_content_id("default:tree")
	local c_apple = minetest.get_content_id("default:apple")
	local c_appleaf = minetest.get_content_id("path:appleleaf")
	local top = 3 + math.random(2)
	for j = -2, top do
		if j == top - 1 or j == top then
			for i = -2, 2 do
			for k = -2, 2 do
				local vi = area:index(x + i, y + j, z + k)
				if j == top - 1 and math.random() < 0.04 then
					data[vi] = c_apple
				elseif math.random(5) ~= 2 then
					data[vi] = c_appleaf
				end
			end
			end
		elseif j == top - 2 then
			for i = -1, 1 do
			for k = -1, 1 do
				if math.abs(i) + math.abs(k) == 2 then
					local vi = area:index(x + i, y + j, z + k)
					data[vi] = c_tree
				end
			end
			end
		else
			local vi = area:index(x, y + j, z)
			data[vi] = c_tree
		end
	end
end

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)

	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	print ("[path] chunk minp ("..x0.." "..y0.." "..z0..")")
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")
	local c_water = minetest.get_content_id("default:water_source")
	local c_sand = minetest.get_content_id("default:sand")

	local c_path = minetest.get_content_id("path:path")
	local c_pathslab = minetest.get_content_id("path:pathslab")
	local c_grass = minetest.get_content_id("path:grass")
	local c_dirt = minetest.get_content_id("path:dirt")
	local c_stone = minetest.get_content_id("path:stone")
	local c_roadblack = minetest.get_content_id("path:roadblack")
	local c_roadslab = minetest.get_content_id("path:roadslab")
	local c_roadwhite = minetest.get_content_id("path:roadwhite")
	
	local sidelen = x1 - x0 + 1
	local overlen = sidelen + 1 -- horizontal overgeneration
	local chulensxyz = {x=overlen, y=sidelen, z=overlen}
	local minposxyz = {x=x0-1, y=y0, z=z0-1}
	local chulensxz = {x=overlen, y=overlen, z=sidelen} -- different because here x=x, y=z
	local minposxz = {x=x0-1, y=z0-1}
	
	local nvals_terrain = minetest.get_perlin_map(np_terrain, chulensxz):get2dMap_flat(minposxz)
	local nvals_patha = minetest.get_perlin_map(np_patha, chulensxz):get2dMap_flat(minposxz)
	local nvals_pathb = minetest.get_perlin_map(np_pathb, chulensxz):get2dMap_flat(minposxz)
	local nvals_pathc = minetest.get_perlin_map(np_pathc, chulensxz):get2dMap_flat(minposxz)
	local nvals_pathd = minetest.get_perlin_map(np_pathd, chulensxz):get2dMap_flat(minposxz)
	local nvals_tree = minetest.get_perlin_map(np_tree, chulensxz):get2dMap_flat(minposxz)
	
	local nixz = 1
	local nixyz = 1
	for z = z0-1, z1 do
		for y = y0, y1 do
			local vi = area:index(x0-1, y, z)
			local viu = area:index(x0-1, y-1, z)
			local n_xprepatha = false
			local n_xprepathb = false
			local n_xprepathc = false
			local n_xprepathd = false
			local fimadep = math.max(DEPSEL * (1 - (y - YWAT) / YROCK), 1)
			for x = x0-1, x1 do
				local nodid = data[vi]
				local nodidu = data[viu]
				local n_zprepatha = nvals_patha[(nixz - overlen)]
				local n_zprepathb = nvals_pathb[(nixz - overlen)]
				local n_zprepathc = nvals_pathc[(nixz - overlen)]
				local n_zprepathd = nvals_pathd[(nixz - overlen)]
				local chunk = (x >= x0 and z >= z0)
				local n_tree = math.min(math.max(nvals_tree[nixz], 0), 1)
				
				local n_patha = nvals_patha[nixz]
				local n_abspatha = math.abs(n_patha)

				local n_pathb = nvals_pathb[nixz]
				local n_abspathb = math.abs(n_pathb)

				local n_pathc = nvals_pathc[nixz]
				local n_abspathc = math.abs(n_pathc)

				local n_pathd = nvals_pathd[nixz]
				local n_abspathd = math.abs(n_pathd)

				local n_terrain = nvals_terrain[nixz]
				local ysurf = YCEN
				+ math.floor(n_terrain * (1 + n_abspatha ^ 2 * n_abspathb ^ 2 * 32) * TERSCA)

				if chunk then
					if y == ysurf and y > YBTOP then
						if ((n_patha >= 0 and n_xprepatha < 0)
						or (n_patha < 0 and n_xprepatha >= 0))
						or ((n_patha >= 0 and n_zprepatha < 0)
						or (n_patha < 0 and n_zprepatha >= 0)) then
							data[vi] = c_roadwhite
							for i = -4, 4 do
							for k = -4, 4 do
								local radsq = (math.abs(i)) ^ 2 + (math.abs(k)) ^ 2
								if radsq <= 13 then
									local vi = area:index(x+i, y, z+k)
									local via = area:index(x+i, y+1, z+k)
									local nodid = data[vi]
									local nodida = data[via]
									if nodid ~= c_roadwhite then
										data[vi] = c_roadblack
										if nodida == c_grass then
											data[via] = c_air
										end
									end
								elseif radsq <= 20 then
									local vi = area:index(x+i, y, z+k)
									local via = area:index(x+i, y+1, z+k)
									local nodid = data[vi]
									local nodida = data[via]
									if nodid ~= c_roadblack
									and nodid ~= c_roadwhite
									and nodid ~= c_grass
									and nodid ~= c_dirt
									and nodid ~= c_path then
										data[vi] = c_roadslab
										if nodida == c_grass then
											data[via] = c_air
										end
									end
								end
							end
							end
						elseif ((n_pathb >= 0 and n_xprepathb < 0)
						or (n_pathb < 0 and n_xprepathb >= 0))
						or ((n_pathb >= 0 and n_zprepathb < 0)
						or (n_pathb < 0 and n_zprepathb >= 0)) then
							data[vi] = c_roadwhite
							for i = -4, 4 do
							for k = -4, 4 do
								local radsq = (math.abs(i)) ^ 2 + (math.abs(k)) ^ 2
								if radsq <= 13 then
									local vi = area:index(x+i, y, z+k)
									local via = area:index(x+i, y+1, z+k)
									local nodid = data[vi]
									local nodida = data[via]
									if nodid ~= c_roadwhite then
										data[vi] = c_roadblack
										if nodida == c_grass then
											data[via] = c_air
										end
									end
								elseif radsq <= 20 then
									local vi = area:index(x+i, y, z+k)
									local via = area:index(x+i, y+1, z+k)
									local nodid = data[vi]
									local nodida = data[via]
									if nodid ~= c_roadblack
									and nodid ~= c_roadwhite
									and nodid ~= c_grass
									and nodid ~= c_dirt
									and nodid ~= c_path then
										data[vi] = c_roadslab
										if nodida == c_grass then
											data[via] = c_air
										end
									end
								end
							end
							end
						elseif ((n_pathc >= 0 and n_xprepathc < 0)
						or (n_pathc < 0 and n_xprepathc >= 0))
						or ((n_pathc >= 0 and n_zprepathc < 0)
						or (n_pathc < 0 and n_zprepathc >= 0)) then
							for i = -2, 2 do
							for k = -2, 2 do
								local radsq = (math.abs(i)) ^ 2 + (math.abs(k)) ^ 2
								if radsq <= 2 then
									local vi = area:index(x+i, y, z+k)
									local via = area:index(x+i, y+1, z+k)
									local nodid = data[vi]
									local nodida = data[via]
									if nodid ~= c_roadblack
									and nodid ~= c_roadwhite then
										data[vi] = c_path
										if nodida == c_grass then
											data[via] = c_air
										end
									end
								elseif radsq <= 5 then
									local vi = area:index(x+i, y, z+k)
									local via = area:index(x+i, y+1, z+k)
									local nodid = data[vi]
									local nodida = data[via]
									if nodid ~= c_roadblack
									and nodid ~= c_roadwhite
									and nodid ~= c_path
									and nodid ~= c_grass
									and nodid ~= c_dirt then
										data[vi] = c_pathslab
										if nodida == c_grass then
											data[via] = c_air
										end
									end
								end
							end
							end
						elseif ((n_pathd >= 0 and n_xprepathd < 0)
						or (n_pathd < 0 and n_xprepathd >= 0))
						or ((n_pathd >= 0 and n_zprepathd < 0)
						or (n_pathd < 0 and n_zprepathd >= 0)) then
							for i = -2, 2 do
							for k = -2, 2 do
								local radsq = (math.abs(i)) ^ 2 + (math.abs(k)) ^ 2
								if radsq <= 2 then
									local vi = area:index(x+i, y, z+k)
									local via = area:index(x+i, y+1, z+k)
									local nodid = data[vi]
									local nodida = data[via]
									if nodid ~= c_roadblack
									and nodid ~= c_roadwhite then
										data[vi] = c_path
										if nodida == c_grass then
											data[via] = c_air
										end
									end
								elseif radsq <= 5 then
									local vi = area:index(x+i, y, z+k)
									local via = area:index(x+i, y+1, z+k)
									local nodid = data[vi]
									local nodida = data[via]
									if nodid ~= c_roadblack
									and nodid ~= c_roadwhite
									and nodid ~= c_path
									and nodid ~= c_grass
									and nodid ~= c_dirt then
										data[vi] = c_pathslab
										if nodida == c_grass then
											data[via] = c_air
										end
									end
								end
							end
							end
						elseif nodid ~= c_roadblack
						and nodid ~= c_roadwhite
						and nodid ~= c_path
						and nodidu ~= c_roadblack
						and nodidu ~= c_roadslab
						and nodidu ~= c_pathslab then
							data[vi] = c_grass
							if n_abspatha > TFLO and n_abspathb > TFLO
							and n_abspathc > TPFLO and n_abspathd > TPFLO
							and math.random() < APPCHA * n_tree and fimadep >= 2 then
								path_appletree(x, y+1, z, area, data)
							end
						end
					elseif y <= ysurf - fimadep then
						data[vi] = c_stone
					elseif y <= YBTOP and y <= ysurf then
						data[vi] = c_sand
					elseif y < ysurf and nodid ~= c_roadblack and nodid ~= c_path then
						data[vi] = c_dirt
					elseif y <= YWAT and y > ysurf then -- water
						data[vi] = c_water
					end
				end
				n_xprepatha = n_patha
				n_xprepathb = n_pathb
				n_xprepathc = n_pathc
				n_xprepathd = n_pathd
				nixz = nixz + 1
				nixyz = nixyz + 1
				vi = vi + 1
				viu = viu + 1
			end
			nixz = nixz - overlen
		end
		nixz = nixz + overlen
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[path] "..chugent.." ms")
end)
