local cpml = require "cpml"

return {
	boat         = true,
	model        = "ld-boat",
	model_matrix = cpml.mat4(),
	position     = cpml.vec3(0, 0, 80),
	orientation  = cpml.quat(0, 0, 0, 1),
	scale        = cpml.vec3(1, 1, 1),
	velocity     = cpml.vec3(0, 0, 0),
	target       = true,
	mass         = 1000,
	max_hp       = 8047,
	hp           = 8047
}
