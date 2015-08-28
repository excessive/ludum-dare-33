local anchor = require "anchor"
local cpml   = require "cpml"
local tiny   = require "tiny"

return function()
	local system       = tiny.processingSystem()
	system.filter      = tiny.requireAll("camera")
	system.camera_data = {}
	system.defaults = {
		fov  = 45,
		near = 0.1,    -- 10cm
		far  = 1000.0, -- 1km

		position     = cpml.vec3(0, 0, 0),
		orientation  = cpml.quat(0, 0, 0, 1),
		scale        = cpml.vec3(1, 1, 1),
		velocity     = cpml.vec3(0, 0, 0),
		direction    = cpml.vec3(0, 1, 0),
		orbit_offset = cpml.vec3(0, 0, -6),
		offset       = cpml.vec3(0, 0, -1),
		up           = cpml.vec3(0, 0, 1),

		-- up/down limit (radians)
		pitch_limit_up    = math.pi / 2.05,
		pitch_limit_down  = math.pi / 2.05,

		mouse_sensitivity = 1 / 15, -- radians/px
	}
	system.active_camera = false

	function system:onAdd(entity)
		-- if not self.active_camera then
		self.active_camera = entity

		-- end
		system.camera_data[entity] = {
			view       = cpml.mat4(),
			projection = cpml.mat4()
		}
	end

	function system:onRemove(entity)
		system.camera_data[entity] = nil
	end

	function system:process(entity, dt)
		local data = self.camera_data[entity]
		if not entity.forced_transforms and not entity.tracking then
			local pos    = entity.position     or self.defaults.position
			local dir    = entity.direction    or self.defaults.direction
			local up     = entity.up           or self.defaults.up
			local orbit  = entity.orbit_offset or self.defaults.orbit_offset
			local offset = entity.offset       or self.defaults.offset
			data.view = cpml.mat4()
				:translate(orbit)
				:look_at(
					pos,
					pos + dir, up)
				:translate(offset)
		elseif entity.tracking then
			data.view = cpml.mat4()
				:translate(orbit)
				:look_at(pos, entity.tracking, up)
				:translate(offset)
		end
		local fov  = entity.fov  or self.defaults.fov
		local near = entity.near or self.defaults.near
		local far  = entity.far  or self.defaults.far
		data.projection = data.projection:identity()
		data.projection = data.projection:perspective(fov, anchor:aspect(), near, far)
	end

	function system:move(vector, speed, normal)
		local entity = self.active_camera
		if not entity then
			console.e("No active camera.")
			return
		end
		local forward   = entity.direction:normalize()
		local up        = (normal or entity.up):normalize()
		local side      = forward:cross(up):normalize()

		if not entity.position then
			entity.position = self.defaults.position:clone()
		end

		entity.position.x = entity.position.x + vector.x * side.x * speed
		entity.position.y = entity.position.y + vector.x * side.y * speed
		entity.position.z = entity.position.z + vector.x * side.z * speed

		entity.position.x = entity.position.x + vector.y * forward.x * speed
		entity.position.y = entity.position.y + vector.y * forward.y * speed
		entity.position.z = entity.position.z + vector.y * forward.z * speed

		entity.position.x = entity.position.x + vector.z * up.x * speed
		entity.position.y = entity.position.y + vector.z * up.y * speed
		entity.position.z = entity.position.z + vector.z * up.z * speed
	end

	function system:rotate_xy(mx, my)
		local entity = self.active_camera
		if not entity then
			console.e("No active camera.")
			return
		end
		local sensitivity = entity.mouse_sensitivity or self.defaults.mouse_sensitivity
		local mouse_direction = {
			x = math.rad(mx * sensitivity),
			y = math.rad(my * sensitivity)
		}
		--print("mouse move in radians: " .. tostring(mouse_direction.x) .. tostring(mouse_direction.y))
		entity.current_pitch = (entity.current_pitch or 0) + mouse_direction.y

		local pitch_limit_up   = entity.pitch_limit_up   or self.defaults.pitch_limit_up
		local pitch_limit_down = entity.pitch_limit_down or self.defaults.pitch_limit_down

		-- don't rotate up/down more than entity.pitch_limit
		if entity.current_pitch > pitch_limit_up then
			entity.current_pitch = pitch_limit_up
			mouse_direction.y    = 0
		elseif entity.current_pitch < -pitch_limit_down then
			entity.current_pitch = -pitch_limit_down
			mouse_direction.y    = 0
		end

		if not entity.direction then
			entity.direction = self.defaults.direction:clone()
		end

		if not entity.up then
			entity.up = self.defaults.up:clone()
		end

		-- get the axis to rotate around the x-axis.
		local axis = entity.direction:cross(entity.up)
		axis = axis:normalize()

		if not entity.orientation then
			entity.orientation = self.defaults.orientation:clone()
		end

		-- NB: For quaternions a, b, a*b means "first apply rotation a, then apply rotation b".
		-- NB: This is the reverse of how matrices are applied.

		-- First, we apply a left/right rotation.
		-- NB: "self.up" is somewhat misleading. "self.up" is really just the world up vector, it is
		-- NB: independent of the cameras pitch. Since left/right rotation is around the worlds up-vector
		-- NB: rather than around the cameras up-vector, it always has to be applied first.
		entity.orientation = cpml.quat.rotate(mouse_direction.x, entity.up) * entity.orientation

		-- Next, we apply up/down rotation.
		-- up/down rotation is applied after any other rotation (so that other rotations are not affected by it),
		-- hence we post-multiply it.
		entity.orientation = entity.orientation * cpml.quat.rotate(mouse_direction.y, cpml.vec3(1, 0, 0))

		-- Apply rotation to camera direction
		entity.direction = entity.orientation * cpml.vec3(0, 1, 0)
	end

	function system:send(shader, view_name, proj_name)
		local entity = self.active_camera
		if not entity then
			console.e("No active camera.")
			return
		end
		shader:send(view_name or "u_view", self.camera_data[entity].view:to_vec4s())
		local proj = self.camera_data[entity].projection
		if flip or love.graphics.getCanvas() then
			proj = proj:scale(cpml.vec3(1, -1, 1))
		end
		shader:send(proj_name or "u_projection", proj:to_vec4s())
	end

	return system
end
