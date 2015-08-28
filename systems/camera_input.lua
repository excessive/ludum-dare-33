local tiny = require "tiny"
local cpml = require "cpml"

return function()
	local system  = tiny.processingSystem()
	system.filter = tiny.requireAll("camera")

	function system:process(entity, dt)
		if console.visible then return end

		if dt == 0 then dt = love.timer.getDelta() end

		entity.velocity.x = g_buttons.camera_x:getValue()
		entity.velocity.y = g_buttons.camera_y:getValue()
		entity.velocity   = entity.velocity:normalize()

		entity.orbit_offset.z = entity.orbit_offset.z + (
			-g_buttons.trigger_l:getValue() + g_buttons.trigger_r:getValue()
		) * dt * 4

		entity.orbit_offset.z = cpml.utils.clamp(entity.orbit_offset.z, -10, -4)
	end

	return system
end
