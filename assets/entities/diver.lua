local cpml = require "cpml"

return {
	diver        = true,
	tethered     = false,
	model        = "ld-diver",
	model_matrix = cpml.mat4(),
	position     = cpml.vec3(0, 0, 10),
	orientation  = cpml.quat(0, 0, 0, 1),
	scale        = cpml.vec3(1, 1, 1),
	velocity     = cpml.vec3(0, 0, 0),
	color        = { 0.7, 0.8, 1.0 },
	mass         = 75,
	sound        = "assets/sounds/diver-bubbles.ogg",
	max_hp       = 1,
	hp           = 1,
	hit          = {},
	collisions   = 0,
	collider     = "ld-sphere",
	colliders    = {
		{ position=cpml.vec3(0, 0, 1.35), radius=0.3, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 0.82), radius=0.3, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 0.27), radius=0.3, hit={}, collisions=0 }
	}
}
