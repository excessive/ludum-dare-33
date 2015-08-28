local cpml = require "cpml"

return {
	model            = "ld-shark",
	model_matrix     = cpml.mat4(),
	position         = cpml.vec3(0, 0, 0),
	orientation      = cpml.quat(0, 0, 0, 1) * cpml.quat.rotate(math.pi, cpml.vec3(0, 0, 1)),
	scale            = cpml.vec3(1, 1, 1),
	velocity         = cpml.vec3(0, 0, 0),
	real_orientation = cpml.quat(0, 0, 0, 1) * cpml.quat.rotate(math.pi, cpml.vec3(0, 0, 1)),
	bob_speed        = 1.25,
	possessed        = true,
	speed            = 0,
	max_speed        = 9,
	mass             = 180,
	color            = { 0.8, 0.85, 1.0 }, -- blue tint for watery look
	hit              = {},
	collisions       = 0,
	collider         = "ld-sphere",
	colliders        = {
		{ position=cpml.vec3(0, -1.15, 0.4), radius=0.3,  hit={}, collisions=0 },
		{ position=cpml.vec3(0, -0.1, 0.5),  radius=0.7,  hit={}, collisions=0 },
		{ position=cpml.vec3(0, 1, 0.4),     radius=0.28, hit={}, collisions=0 }
	}
}
