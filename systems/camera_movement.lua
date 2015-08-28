local tiny = require "tiny"
local cpml = require "cpml"

return function()
	local system  = tiny.processingSystem()
	system.filter = tiny.requireAll("camera")

	function system:process(entity, dt)
		if dt == 0 then dt = love.timer.getDelta() end

		local view_speed = cpml.vec2(600, 400) -- radians/sec?
		local invert = cpml.vec2(-1, -1)

		self.world.camera_system:rotate_xy(
			entity.velocity.x * view_speed.x * invert.x * dt,
			entity.velocity.y * view_speed.y * invert.y * dt
		)

		-- Update audio listener position as we move
		love.audio.setPosition(entity.position:unpack())
		love.audio.setOrientation(
			entity.direction.x, entity.direction.y, entity.direction.z,
			entity.up.x, entity.up.y, entity.up.z
		)
	end

	return system
end
