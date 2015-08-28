local tiny   = require "tiny"
local cpml   = require "cpml"
local anchor = require "anchor"

return function()
	local system   = tiny.system()
	system.filter  = tiny.requireAny("model", "particles")
	local function slog(fn, file)
		console.i("Loaded shader \"%s\"", file)
		return fn(file)
	end
	system.shaders = {
		simple   = slog(love.graphics.newShader, "assets/shaders/shader.glsl"),
		post     = slog(love.graphics.newShader, "assets/shaders/post.glsl"),
		particle = slog(love.graphics.newShader, "assets/shaders/particle.glsl")
	}

	system.noise = love.graphics.newImage("assets/textures/noise.png")
	system.noise:setWrap("repeat", "repeat")
	system.use_post = true
	system.debug = false

	function system:resize(w, h)
		local formats = love.graphics.getCanvasFormats()
		-- If it doesn't support HDR, it's probably also too slow for 4xMSAA.
		if formats.rg11b10f then
			self.canvas = love.graphics.newCanvas(w, h, "rg11b10f", 4, true)
		elseif formats.normal then
			self.canvas = love.graphics.newCanvas(w, h, "normal", 0, true)
		end
	end
	system:resize(love.graphics.getDimensions())

	function system:update(dt)
		if not self.world.camera_system then
			return
		end

		if love.timer.getAverageDelta() > 1/30 then
			-- self.low_performance = true
		end

		love.graphics.clearDepth()
		love.graphics.setBlendMode("replace", false)
		love.graphics.setCulling("back")
		love.graphics.setDepthTest("less")
		love.graphics.setFrontFace((not self.low_performance and self.canvas) and "ccw" or "cw")
		love.graphics.push("all")

		if not self.low_performance and self.canvas then
			love.graphics.setCanvas(self.canvas)
			love.graphics.discard()
			love.graphics.clearDepth()
		end

		local draw_last = {}

		for _, entity in ipairs(self.entities) do
			if entity.color then
				love.graphics.setColor(entity.color[1] * 255, entity.color[2] * 255, entity.color[3] * 255, (entity.color[4] or 1) * 255)
			else
				love.graphics.setColor(255, 255, 255, 255)
			end
			if entity.particles then
				table.insert(draw_last, entity)
			else
				self:draw(entity)
			end
		end

		-- Particle systems need to draw last.
		for _, entity in ipairs(draw_last) do
			if entity.color then
				love.graphics.setColor(entity.color[1] * 255, entity.color[2] * 255, entity.color[3] * 255, (entity.color[4] or 1) * 255)
			else
				love.graphics.setColor(255, 255, 255, 255)
			end
			self:draw_particles(entity)
		end

		love.graphics.pop()
		love.graphics.setCulling()
		love.graphics.setDepthTest()
		love.graphics.setFrontFace()

		if not self.low_performance and self.canvas then
			if self.use_post then
				local post = self.shaders.post
				love.graphics.setShader(post)
				post:send("u_noise", self.noise)
				post:send("u_noise_strength", love.graphics.isGammaCorrect() and 0.125 or 0.075)
			end
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.setBlendMode("replace", false)
			love.graphics.draw(self.canvas)
			love.graphics.setShader()
		end

		love.graphics.setBlendMode("alpha")

		local top = Scene.current()
		if top.draw then
			top:draw()
		end
	end

	function system:draw(entity)
		local camera = assert(self.world.camera_system)
		local shader = self.shaders.simple
		love.graphics.setShader(shader)

		local model = entity.model_matrix
		shader:send("u_model", model:to_vec4s())
		camera:send(shader)

		if entity.anim then
			entity.anim:send_pose(shader, "u_bone_matrices")
		end
		shader:sendInt("u_skinning", (entity.anim and entity.anim.current_pose) and 1 or 0)
		shader:sendInt("no_fade", entity.no_fade and 1 or 0)

		for _, buffer in ipairs(entity.model.vertex_buffer) do
			love.graphics.draw(buffer.mesh)
		end

		if entity.colliders and self.debug then
			love.graphics.setCulling()
			love.graphics.setWireframe(true)
			for _, collider in ipairs(entity.colliders) do
				for _, buffer in ipairs(entity.collider.vertex_buffer) do
					local m = cpml.mat4()
						:translate(collider.position)
						:scale(cpml.vec3(collider.radius, collider.radius, collider.radius))
					shader:send("u_model", (m * model):to_vec4s())
					shader:sendInt("u_skinning", 0)
					shader:sendInt("no_fade", entity.no_fade and 1 or 0)

					if collider.collisions > 0 then
						love.graphics.setColor(255, 0, 0)
					end

					love.graphics.draw(buffer.mesh)
					love.graphics.setColor(255, 255, 255)
				end
			end
			love.graphics.setCulling("back")
			love.graphics.setWireframe(false)
			love.graphics.setDepthWrite(true)
		end
	end

	function system:draw_particles(entity)
		local camera   = assert(self.world.camera_system)
		local particle = assert(self.world.particle_system)
		local shader = self.shaders.particle
		love.graphics.setShader(shader)
		camera:send(shader)
		particle:draw_particles(entity, shader)
	end

	return system
end
