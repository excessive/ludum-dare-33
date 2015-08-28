local cpml = require "cpml"

local level = {}

level.time_limit = 30

level.script = {
	open = { "play_01", "play_02" },
	time = { "play_11", "play_12", "play_13", "play_14" },
	hint = { "play_21" },
	ouch = { "play_31", "play_32", "play_33" },
	kill = { "play_41" },
	lose = { "play_42", "play_43", "play_44" },
	win  = { "play_51", "play_52" }
}

level.models = {
	["ld-shark"]  = { animated = true  },
	["ld-ocean"]  = { animated = false },
	["ld-rope"]   = { animated = false },
	["ld-diver"]  = { animated = true  },
	["ld-boat"]   = { animated = false },
	["ld-sphere"] = { animated = false }
}

level.entities = {
	camera = love.filesystem.load("assets/entities/camera.lua")(),
	ocean  = love.filesystem.load("assets/entities/ocean.lua")(),
	boat   = love.filesystem.load("assets/entities/boat.lua")(),
	rope   = love.filesystem.load("assets/entities/rope.lua")(),
	diver  = love.filesystem.load("assets/entities/diver.lua")(),
	player = love.filesystem.load("assets/entities/player.lua")(),

	-- Particles (debris)
	debris = {
		particles  = 800,
		spawn_rate = 1/10,
		lifetime   = { 30, 50 },
		radius     = 75,
		spread     = 2.0,
		size       = 0.25,
		color      = { 0.5, 0.8, 0.9 },
		velocity   = cpml.vec3(0, 0, 3),
		position   = cpml.vec3(0, 0, -30)
	},

	-- Particles (bubbles)
	bubbles = {
		particles  = 60,
		spawn_rate = 1/5,
		lifetime   = { 30, 50 },
		radius     = 75,
		spread     = 0.75,
		size       = 0.35,
		color      = { 0.75, 0.9, 1.0 },
		velocity   = cpml.vec3(0, 0, 4),
		position   = cpml.vec3(0, 0, -30),
		texture    = "assets/textures/bubble.png"
	},

	-- Fin Particles
	fin1 = {
		attachment = "player",
		-- ignore_parent_velocity = true,
		particles  = 60,
		spawn_rate = 1/30,
		lifetime   = { 2.0, 3.0 },
		radius     = 0.1,
		spread     = 0.125,
		size       = 0.05,
		color      = { 0.6, 0.7, 0.9, 0.5 },
		velocity   = cpml.vec3(0, 2, 0),
		position   = cpml.vec3(-0.75, 0, 0.25)
	},

	fin2 = {
		attachment = "player",
		-- ignore_parent_velocity = true,
		particles  = 60,
		spawn_rate = 1/30,
		lifetime   = { 2.0, 3.0 },
		radius     = 0.1,
		spread     = 0.125,
		size       = 0.05,
		color      = { 0.6, 0.7, 0.9, 0.5 },
		velocity   = cpml.vec3(0, 2, 0),
		position   = cpml.vec3(0.75, 0, 0.25)
	},

	-- Gill Particles
	gill1 = {
		attachment = "player",
		ignore_parent_velocity = true,
		particles  = 10,
		spawn_rate = 1/5,
		lifetime   = { 5, 7 },
		radius     = 0.01,
		spread     = 0.125,
		size       = 0.04,
		color      = { 0.6, 0.8, 1.0, 0.75 },
		velocity   = cpml.vec3(0, 0, 1),
		position   = cpml.vec3(-0.25, 0.7, 0.35),
		texture    = "assets/textures/bubble.png",
	},

	gill2 = {
		attachment = "player",
		ignore_parent_velocity = true,
		particles  = 10,
		spawn_rate = 1/3,
		lifetime   = { 5, 7 },
		radius     = 0.01,
		spread     = 0.125,
		size       = 0.04,
		color      = { 0.6, 0.8, 1.0, 0.75 },
		velocity   = cpml.vec3(0, 0, 1),
		position   = cpml.vec3(0.25, 0.7, 0.35),
		texture    = "assets/textures/bubble.png"
	}
}

return level
