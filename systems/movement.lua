local tiny = require "tiny"
local cpml = require "cpml"

return function()
	local system  = tiny.system()
	system.filter = tiny.requireAll("position", "orientation", "velocity", "scale")
	system.time   = 0

	function system:update(dt)
		self.time = self.time + dt
		for _, entity in ipairs(self.entities) do
			self:process(entity, dt)
		end
	end

	function system:process(entity, dt)
		-- Player update
		if  entity.possessed
		and self.world.camera_system then
			entity.position.x = entity.position.x + entity.velocity.x * dt
			entity.position.y = entity.position.y + entity.velocity.y * dt
			entity.position.z = entity.position.z + entity.velocity.z * dt
			self.world.camera_system.active_camera.position = entity.position

			-- Slight bobbing, for that authentic ocean feel.
			entity.position.z = entity.position.z + (math.sin(self.time * entity.bob_speed) * 0.2 + math.cos(self.time * entity.bob_speed * 1.15) * 0.2) * dt

			local radius = 75
			local pos = entity.position:normalize() * radius
			if math.abs(entity.position.x) > math.abs(pos.x) then
				entity.position.x = pos.x
			end
			if math.abs(entity.position.y) > math.abs(pos.y) then
				entity.position.y = pos.y
			end

		-- And everything else with generic behavior.
		else
			-- Prevent creating a new position vector by writing it out!
			entity.position.x = entity.position.x + entity.velocity.x * dt
			entity.position.y = entity.position.y + entity.velocity.y * dt
			entity.position.z = entity.position.z + entity.velocity.z * dt
		end

		if entity.model_matrix then
			entity.model_matrix = cpml.mat4()
				:translate(entity.position)
				:rotate(entity.orientation)
				:scale(entity.scale)
		end

		local function falloff(axis, speed)
			local a = math.max(math.abs(axis) - speed, 0)
			if axis >= 0 then
				return a
			else
				return -a
			end
		end

		local falloff_speed = 3.5 * dt
		entity.velocity.x = falloff(entity.velocity.x, falloff_speed)
		entity.velocity.y = falloff(entity.velocity.y, falloff_speed)
		entity.velocity.z = falloff(entity.velocity.z, falloff_speed)

		if entity.diver and not entity.tethered then
			if entity.hp > 0 then
				entity.velocity.z = cpml.utils.clamp(
					entity.velocity.z + 9.81 * 0.5,
					-9.81,
					9.81 * 0.5
				)
			else
				entity.velocity.z = cpml.utils.clamp(
					entity.velocity.z - 9.81 * 0.4,
					-9.81 * 0.4,
					9.81 * 0.5
				)
			end
		elseif entity.diver then
			for _, e in ipairs(self.entities) do
				if e.rope then
					entity.position   = e.position:clone()
					entity.position.z = entity.position.z - 1.9
					break
				end
			end
		end

		if entity.cage_broken then
			entity.velocity.z = cpml.utils.clamp(
				entity.velocity.z - 9.81 * 0.4,
				-9.81 * 0.4,
				9.81 * 0.4
			)
		end

		if entity.cage then
			for _, e in ipairs(self.entities) do
				if e.rope then
					if e.hp > 0 then
						entity.position   = e.position:clone()
						entity.position.z = entity.position.z - 2.5
					else
						entity.velocity.z = cpml.utils.clamp(
							entity.velocity.z - 9.81 * 0.4,
							-9.81 * 0.4,
							9.81 * 0.4
						)
					end

					break
				end
			end
		end

		if entity.rope then
			if entity.hp <= 0 then
				entity.position.z = entity.position.z + 4 * dt
			else
				entity.position.z = cpml.utils.clamp(entity.position.z, -12, 100)
			end
		elseif entity.diver or entity.boat then
			entity.position.z = cpml.utils.clamp(entity.position.z, -17, 75)
		elseif entity.cage or entity.cage_broken then
			entity.position.z = cpml.utils.clamp(entity.position.z, -17, 65)
		elseif not entity.stop_clamping_position then
			entity.position.z = cpml.utils.clamp(entity.position.z, -17, 65)
		end
	end

	return system
end
