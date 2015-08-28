local cpml = require "cpml"

return {
	rope         = true,
	model        = "ld-rope",
	model_matrix = cpml.mat4(),
	position     = cpml.vec3(0, 0, 14.5),
	orientation  = cpml.quat(0, 0, 0, 1),
	scale        = cpml.vec3(1, 1, 1),
	velocity     = cpml.vec3(0, 0, 0),
	color        = { 0.7, 0.8, 1.0 },
	mass         = 10,
	max_hp       = 10,
	hp           = 10,
	hit          = {},
	collisions   = 0,
	collider     = "ld-sphere",
	colliders    = {
		{ position=cpml.vec3(0, 0, 4), radius=0.5, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 3), radius=0.5, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 2), radius=0.5, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 1), radius=0.5, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 0), radius=0.5, hit={}, collisions=0 },
	}
}
