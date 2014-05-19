-- path 0.1.2 by paramat
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- x overgeneration
-- desert sand, cacti
-- width parameter
-- tune diagonal width

-- Parameters

local WID = 3 -- Lane width
local CACCHA = 1 / 128 ^ 2 -- Cactus chance per node

-- 2D noise for base terrain

local np_base = {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=1024, z=1024},
	seed = -9111,
	octaves = 5,
	persist = 0.67
}

-- Nodes

minetest.register_node("path:roadblack", {
	description = "Road Black",
	tiles = {"path_roadblack.png"},
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

local rad = WID ^ 2 + 4

-- Set mapgen parameters

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
end)

-- Spawn player

function spawnplayer(player)
	player:setpos({x=0, y=2, z=0})
end

minetest.register_on_newplayer(function(player)
	spawnplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	spawnplayer(player)
	return true
end)

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	if minp.y > -32 then
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
	
	local c_desand = minetest.get_content_id("default:desert_sand")
	local c_roadblack = minetest.get_content_id("path:roadblack")
	local c_roadwhite = minetest.get_content_id("path:roadwhite")
	local c_cactus = minetest.get_content_id("path:cactus")
	
	local sidelen = x1 - x0 + 1
	local chulens = {x=sidelen+1, y=sidelen, z=sidelen}
	local minposxz = {x=x0-1, y=z0}
	
	local nvals_base = minetest.get_perlin_map(np_base, chulens):get2dMap_flat(minposxz)
	
	local nixz = 1
	for z = z0, z1 do
		for y = y0, y1 do
			local vi = area:index(x0-1, y, z)
			local n_xprebase = false
			for x = x0-1, x1 do
				local nodid = data[vi]
				local n_base = nvals_base[nixz]
				local n_zprebase = nvals_base[(nixz - 81)]
				local chunk = x >= x0
				if chunk then
					if y == 1 then
						if ((n_base >= 0 and n_xprebase < 0)
						or (n_base < 0 and n_xprebase >= 0))
						or (z > z0
						and ((n_base >= 0 and n_zprebase < 0)
						or (n_base < 0 and n_zprebase >= 0))) then
							data[vi] = c_roadwhite
							for i = -WID, WID do
							for k = -WID, WID do
								if (math.abs(i)) ^ 2 + (math.abs(k)) ^ 2 <= rad then
									local vi = area:index(x+i, y, z+k)
									local nodid = data[vi]
									if nodid ~= c_roadwhite then
										data[vi] = c_roadblack
									end
								end
							end
							end
						elseif nodid ~= c_roadblack and nodid ~= c_roadwhite then
							data[vi] = c_desand
							if math.random() < CACCHA then
								for j = -1, 5 do
								for i = -2, 2 do
									if i == 0 or j == 3 or (j == 4 and math.abs(i) == 2) then
										local vi = area:index(x + i, y + j, z)
										data[vi] = c_cactus
									end
								end
								end
							end
						end
					elseif y <= 0 then
						data[vi] = c_desand
					end
				end
				n_xprebase = n_base
				nixz = nixz + 1
				vi = vi + 1
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