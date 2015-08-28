local cpml = require "cpml"

return {
	model        = "ld-cage",
	model_matrix = cpml.mat4(),
	position     = cpml.vec3(0, 0, 10),
	orientation  = cpml.quat(0, 0, 0, 1),
	scale        = cpml.vec3(1, 1, 1),
	velocity     = cpml.vec3(0, 0, 0),
	target       = true,
	sound        = "assets/sounds/diver-bubbles.ogg",
	mass         = 120,
	max_hp       = 20,
	hp           = 20,
	hit          = {},
	cage         = true,
	collisions   = 0,
	collider     = "ld-sphere",
	colliders    = {
		{ position=cpml.vec3(0, 0, 1.8),   radius=0.6, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 1.3), radius=0.6, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 0.8),   radius=0.6, hit={}, collisions=0 }
	}
}
