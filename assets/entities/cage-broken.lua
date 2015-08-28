local cpml = require "cpml"

return {
	cage_broken  = true,
	model        = "ld-cage-broken",
	model_matrix = cpml.mat4(),
	position     = cpml.vec3(0, 0, 0),
	orientation  = cpml.quat(0, 0, 0, 1),
	scale        = cpml.vec3(1, 1, 1),
	velocity     = cpml.vec3(0, 0, 0),
	target       = true,
	mass         = 120,
	hit          = {},
	collisions   = 0,
	collider     = "ld-sphere",
	colliders    = {
		{ position=cpml.vec3(0, 0, 1),   radius=0.6, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 0.5), radius=0.6, hit={}, collisions=0 },
		{ position=cpml.vec3(0, 0, 0),   radius=0.6, hit={}, collisions=0 }
	}
}
