-- path 0.2.0 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- Parameters

local TERSCA = 32 -- Vertical terrain scale
local CACCHA = 1 / 192 ^ 2 -- Cactus chance per node

-- 2D noise for terrain

local np_terrain = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	seed = -9111,
	octaves = 4,
	persist = 0.4
}

-- 2D noise for path

local np_path = {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=1024, z=1024},
	seed = 11,
	octaves = 4,
	persist = 0.4
}

-- Nodes

minetest.register_node("path:roadblack", {
	description = "Road Black",
	tiles = {"default_obsidian.png"},
	groups = {cracky=2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("path:roadslab", {
	description = "Road Slab",
	tiles = {"default_obsidian.png"},
	drawtype = "nodebox",
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	buildable_to = false,
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
	description = "Road White",
	tiles = {"path_roadwhite.png"},
	groups = {cracky=2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("path:cactus", {
	description = "Cactus",
	tiles = {"default_cactus_top.png", "default_cactus_top.png", "default_cactus_side.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy=1, choppy=3, flammable=2},
	drop = "default:cactus",
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

-- Stuff

path = {}

-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode", water_level=-32})
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

function path_cactus(x, y, z, area, data)
	local c_cactus = minetest.get_content_id("path:cactus")
	for j = -2, 4 do
	for i = -2, 2 do
		if i == 0 or j == 2 or (j == 3 and math.abs(i) == 2) then
			local vi = area:index(x + i, y + j, z)
			data[vi] = c_cactus
		end
	end
	end
end

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y > 48 then
		return
	end

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
	local c_desand = minetest.get_content_id("default:desert_sand")
	local c_destone = minetest.get_content_id("default:desert_stone")
	local c_roadblack = minetest.get_content_id("path:roadblack")
	local c_roadslab = minetest.get_content_id("path:roadslab")
	local c_roadwhite = minetest.get_content_id("path:roadwhite")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen+1, y=sidelen+1, z=sidelen} -- x = coord x, y = coord z
	local minposxz = {x=x0-1, y=z0-1}
	
	local nvals_terrain = minetest.get_perlin_map(np_terrain, chulens):get2dMap_flat(minposxz)
	local nvals_path = minetest.get_perlin_map(np_path, chulens):get2dMap_flat(minposxz)
	
	local nixz = 1
	for z = z0-1, z1 do
		for y = y0, y1 do
			local vi = area:index(x0-1, y, z)
			local viu = area:index(x0-1, y-1, z)
			local n_xprepath = false
			for x = x0-1, x1 do
				local nodid = data[vi]
				local nodidu = data[viu]
				local n_zprepath = nvals_path[(nixz - 81)]
				local chunk = (x >= x0 and z >= z0)
				
				local n_path = nvals_path[nixz]
				local n_abspath = math.abs(n_path)
				local n_terrain = nvals_terrain[nixz]
				local ysurf = math.floor(n_terrain * TERSCA)
				
				if chunk then
					if y == ysurf then
						if ((n_path >= 0 and n_xprepath < 0)
						or (n_path < 0 and n_xprepath >= 0))
						or ((n_path >= 0 and n_zprepath < 0)
						or (n_path < 0 and n_zprepath >= 0)) then
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
										if nodida == c_desand then
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
									and nodid ~= c_desand then
										data[vi] = c_roadslab
										if nodida == c_desand then
											data[via] = c_air
										end
									end
								end
							end
							end
						elseif nodid ~= c_roadblack
						and nodid ~= c_roadwhite
						and nodidu ~= c_roadblack
						and nodidu ~= c_roadslab then
							data[vi] = c_desand
							if math.random() < CACCHA then
								path_cactus(x, y+1, z, area, data)
							end
						end
					elseif y <= ysurf - 8 then
						data[vi] = c_destone
					elseif y < ysurf and nodid ~= c_roadblack then
						data[vi] = c_desand
					end
				end
				n_xprepath = n_path
				nixz = nixz + 1
				vi = vi + 1
				viu = viu + 1
			end
			nixz = nixz - 81
		end
		nixz = nixz + 81
	end
	
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[path] "..chugent.." ms")
end)
