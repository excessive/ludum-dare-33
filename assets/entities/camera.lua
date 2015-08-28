local cpml = require "cpml"

return {
	fov  = 55,
	near = 0.1,    -- 10cm
	far  = 1000.0, -- 1km

	position     = cpml.vec3(0, 0, 0),
	orientation  = cpml.quat(0, 0, 0, 1),
	velocity     = cpml.vec3(0, 0, 0),
	direction    = cpml.vec3(0, 1, 0),
	orbit_offset = cpml.vec3(0, 0, -6),
	offset       = cpml.vec3(0, 0, -1),
	up           = cpml.vec3(0, 0, 1),

	-- up/down limit (radians)
	pitch_limit_up    = math.pi / 2.05,
	pitch_limit_down  = math.pi / 2.05,
	current_pitch     = 0,
	mouse_sensitivity = 1 / 15, -- radians/px

	-- position vector to track
	tracking = false,

	-- magic
	camera = true
}
