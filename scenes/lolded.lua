return function(world, initial)
	local anchor = require "anchor"
	local chain = require "chain"
	local timer = require "timer"
	local cpml  = require "cpml"
	local iqe   = require "iqe"
	local lume  = require "lume"
	local tiny  = require "tiny"
	local scene = tiny.system()
	scene.world = world
	if initial then
		world:addSystem(scene)
	end

	function scene:resize(w, h)
		self.render_system:resize(w, h)
	end

	function scene:enter()
		self.timer = timer.new()
		self.state = { opacity = 0 }

		chain(function(continue, wait)
			self.timer.add(3, continue())
			wait()
			self:transition_out()
		end)()

		self.world:addEntity {
			fov  = 55,
			near = 0.1,    -- 10cm
			far  = 1000.0, -- 1km

			position = cpml.vec3(0, 0, 0),

			-- magic
			camera = true
		}

		self.world:addEntity {
			model        = iqe.load("assets/models/ld-ocean.iqe"),
			model_matrix = cpml.mat4():translate(cpml.vec3(0, 0, 25)),
			color        = { 0.6, 0.6, 0.6 },
			no_fade      = true
		}

		self.world:addEntity {
			disable_depth_test = true,
			particles  = 1000,
			spawn_rate = 1/60,
			lifetime   = { 2.5, 4.0 },
			radius     = 0.2,
			spread     = 1.75,
			size       = 2.5,
			color      = { 0.4, 0.1, 0.2, 1.0 },
			velocity   = cpml.vec3(0, 0, 0.1),
			position   = cpml.vec3(0, 0, 0)
		}

		self.camera_system = require("systems.camera")()
		self.world:addSystem(self.camera_system)
		self.world.camera_system = self.camera_system

		self.particle_system = require("systems.particle")()
		self.world:addSystem(self.particle_system)
		self.world.particle_system = self.particle_system

		self.render_system = require("systems.render")()
		self.world:addSystem(self.render_system)

		love.graphics.setBackgroundColor(lume.rgba(0x00000000))
	end

	function scene:leave()
		self.world.camera_system = nil
		self.world:removeSystem(self.render_system)
		self.world:removeSystem(self.particle_system)
		self.world:removeSystem(self.camera_system)
		self.world:clearEntities()
	end

	function scene:transition_out()
		chain(function(continue, wait)
			self.timer.tween(1.0, self.state, { opacity = 1 }, 'in-out-quad', continue())
			wait()
			self.timer.add(1.75, continue())
			wait()
			Scene.switch(require("scenes.credits")(self.world), true)
		end)()
	end

	function scene:update(dt)
		self.timer.update(dt)
	end

	function scene:draw()
		love.graphics.setColor(0, 0, 0, 255 * self.state.opacity)
		love.graphics.rectangle(
			"fill", 0, 0,
			love.graphics.getWidth(),
			love.graphics.getHeight()
		)
	end

	return scene
end
