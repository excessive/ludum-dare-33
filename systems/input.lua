local tiny = require "tiny"
local cpml = require "cpml"

return function()
	local system  = tiny.system()
	system.filter = tiny.requireAll("possessed")

	-- Fix physics timestep to 60hz so things are consistent...
	system.time        = 0
	system.last_update = 0
	system.update_rate = 1/120

	function system:update(dt)
		self.time = self.time + dt

		-- run updates until we are caught up with current time.
		while self.time - self.last_update > self.update_rate do
			for _, entity in ipairs(self.entities) do
				self:process(entity, self.update_rate)
			end
			self.last_update = self.last_update + self.update_rate
		end
	end

	function system:process(entity, dt)
		if console.visible then return end

		local force_scale = 20

		-- Back it up back it up back it up... slowly, you shitdick.
		local force = cpml.utils.clamp(g_buttons.move_y:getValue(), -1, 0.38) * force_scale

		-- F = kg * (m/s)^2
		-- a = f/m hello I am basic physics and I am here to FUCK YOUR SHIT
		local acceleration = force / entity.mass

		-- Take orientation into account.
		local direction = entity.orientation * cpml.vec3(0, 1, 0)

		entity.velocity.x = entity.velocity.x + direction.x * acceleration
		entity.velocity.y = entity.velocity.y + direction.y * acceleration
		entity.velocity.z = entity.velocity.z + direction.z * acceleration

		-- Enforce speed limit
		local speed = entity.velocity:len()
		if speed > entity.max_speed then
			local scale = speed / entity.max_speed
			entity.velocity.x = entity.velocity.x / scale
			entity.velocity.y = entity.velocity.y / scale
			entity.velocity.z = entity.velocity.z / scale
		end

		-- self.world.camera_system:move(entity.velocity, 1)

		if g_buttons.action:pressed() then
			entity.anim:play("bite", function(self)
				self:play("swim")
			end)
		end
	end

	return system
end
