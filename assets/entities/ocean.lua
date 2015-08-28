local cpml = require "cpml"

return {
	model        = "ld-ocean",
	model_matrix = cpml.mat4():translate(cpml.vec3(0, 0, 25))
}
