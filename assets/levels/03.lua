local cpml = require "cpml"

local level = {}

level.time_limit = 99
level.a_winner_is_you = true

level.script = {
	open = { "play_04" },
	time = { "play_13" },
	hint = { "kek" },
	ouch = { "kek" },
	kill = { "kek" },
	lose = { "kek" },
	win  = { "kek" }
}

level.models = {
	["ld-shark"]       = { animated = true },
	["ld-ocean"]       = { animated = false },
	["ld-boat"]        = { animated = false },
	["ld-cage-broken"] = { animated = false }
}

level.entities = {
	camera = love.filesystem.load("assets/entities/camera.lua")(),
	ocean  = love.filesystem.load("assets/entities/ocean.lua")(),
	boat   = love.filesystem.load("assets/entities/boat.lua")(),
	player = love.filesystem.load("assets/entities/player.lua")(),

	cagekek = {
		model        = "ld-cage-broken",
		model_matrix = cpml.mat4(),
		position     = cpml.vec3(-10, -5, -20),
		orientation  = cpml.quat(0, 0, 0, 1),
		scale        = cpml.vec3(1, 1, 1),
		velocity     = cpml.vec3(0, 0, 0),
		target       = true,
		sound        = "assets/sounds/diver-bubbles.ogg",
		mass         = 120,
		hit          = {},
		collisions   = 0,
		collider     = "ld-sphere",
		colliders    = {
			{ position=cpml.vec3(0, 0, 1.8),   radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 1.3), radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 0.8),   radius=0.6, hit={}, collisions=0 }
		}
	},

	cage1 = {
		model        = "ld-cage-broken",
		model_matrix = cpml.mat4(),
		position     = cpml.vec3(5, -5, -20),
		orientation  = cpml.quat(24, 5, 1, 5):normalize(),
		scale        = cpml.vec3(1, 1, 1),
		velocity     = cpml.vec3(0, 0, 0),
		target       = true,
		sound        = "assets/sounds/diver-bubbles.ogg",
		mass         = 120,
		hit          = {},
		collisions   = 0,
		collider     = "ld-sphere",
		colliders    = {
			{ position=cpml.vec3(0, 0, 1.8),   radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 1.3), radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 0.8),   radius=0.6, hit={}, collisions=0 }
		}
	},

	cage2 = {
		model        = "ld-cage-broken",
		model_matrix = cpml.mat4(),
		position     = cpml.vec3(20, 15, -20),
		orientation  = cpml.quat(50, 20, 100, 51):normalize(),
		scale        = cpml.vec3(1, 1, 1),
		velocity     = cpml.vec3(0, 0, 0),
		target       = true,
		sound        = "assets/sounds/diver-bubbles.ogg",
		mass         = 120,
		hit          = {},
		collisions   = 0,
		collider     = "ld-sphere",
		colliders    = {
			{ position=cpml.vec3(0, 0, 1.8),   radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 1.3), radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 0.8),   radius=0.6, hit={}, collisions=0 }
		}
	},

	cage3 = {
		model        = "ld-cage-broken",
		model_matrix = cpml.mat4(),
		position     = cpml.vec3(35, 18, -20),
		orientation  = cpml.quat(70, 28, 144, 51):normalize(),
		scale        = cpml.vec3(1, 1, 1),
		velocity     = cpml.vec3(0, 0, 0),
		target       = true,
		sound        = "assets/sounds/diver-bubbles.ogg",
		mass         = 120,
		hit          = {},
		collisions   = 0,
		collider     = "ld-sphere",
		colliders    = {
			{ position=cpml.vec3(0, 0, 1.8),   radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 1.3), radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 0.8),   radius=0.6, hit={}, collisions=0 }
		}
	},

	cage4 = {
		model        = "ld-cage-broken",
		model_matrix = cpml.mat4(),
		position     = cpml.vec3(12, 48, -20),
		orientation  = cpml.quat(86, 11, 43, 51):normalize(),
		scale        = cpml.vec3(1, 1, 1),
		velocity     = cpml.vec3(0, 0, 0),
		target       = true,
		sound        = "assets/sounds/diver-bubbles.ogg",
		mass         = 120,
		hit          = {},
		collisions   = 0,
		collider     = "ld-sphere",
		colliders    = {
			{ position=cpml.vec3(0, 0, 1.8),   radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 1.3), radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 0.8),   radius=0.6, hit={}, collisions=0 }
		}
	},

	cage5 = {
		model        = "ld-cage-broken",
		model_matrix = cpml.mat4(),
		position     = cpml.vec3(-17, -18, -20),
		orientation  = cpml.quat(-50, 76, 210, 77):normalize(),
		scale        = cpml.vec3(1, 1, 1),
		velocity     = cpml.vec3(0, 0, 0),
		target       = true,
		sound        = "assets/sounds/diver-bubbles.ogg",
		mass         = 120,
		hit          = {},
		collisions   = 0,
		collider     = "ld-sphere",
		colliders    = {
			{ position=cpml.vec3(0, 0, 1.8),   radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 1.3), radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 0.8),   radius=0.6, hit={}, collisions=0 }
		}
	},

	cage6 = {
		model        = "ld-cage-broken",
		model_matrix = cpml.mat4(),
		position     = cpml.vec3(-44, 34, -20),
		orientation  = cpml.quat(78, 36, 62, 51):normalize(),
		scale        = cpml.vec3(1, 1, 1),
		velocity     = cpml.vec3(0, 0, 0),
		target       = true,
		sound        = "assets/sounds/diver-bubbles.ogg",
		mass         = 120,
		hit          = {},
		collisions   = 0,
		collider     = "ld-sphere",
		colliders    = {
			{ position=cpml.vec3(0, 0, 1.8),   radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 1.3), radius=0.6, hit={}, collisions=0 },
			{ position=cpml.vec3(0, 0, 0.8),   radius=0.6, hit={}, collisions=0 }
		}
	},

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
