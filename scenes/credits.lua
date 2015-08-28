return function(world, initial)
	local anchor = require "anchor"
	local chain = require "chain"
	local timer = require "timer"
	local cpml  = require "cpml"
	local iqe   = require "iqe"
	local lume  = require "lume"
	local tiny  = require "tiny"
	local credits = tiny.system()
	credits.world = world
	if initial then
		world:addSystem(credits)
	end

	function credits:enter(from, beat_the_game)
		self.timer = timer.new()
		self.bgm   = love.audio.newSource("assets/sounds/credits.ogg")
		self.bgm:setLooping(true)
		self.bgm:setVolume(0)
		self.bgm:play()

		self.beat_the_game = beat_the_game --or true

		self.time = 0

		self.crash = love.filesystem.read("assets/credits-crashlog.txt")

		self.lines = love.filesystem.read("assets/credits.txt")
		local font = love.graphics.getFont()
		local width, height = font:getWrap(self.lines, anchor:width())
		self.text_width  = width
		self.text_height = #height * font:getHeight()

		self.state = { opacity = 1, thanks_opacity = 0, volume = 0 }
		self.input_locked = true

		chain(function(continue, wait)
			-- prevent accidental instant skipping
			self.timer.add(0.5, function()
				self.input_locked = false
			end)
			self.timer.tween(2.0, self.state, { opacity = 0 }, 'out-quad')
			self.timer.tween(5.0, self.state, { volume = 0.25 }, 'out-quad')
			self.timer.add(60, continue())
			wait()
			self:transition_out()
		end)()

		self.ocean = self.world:addEntity {
			model          = iqe.load("assets/models/ld-ocean.iqe"),
			model_matrix   = cpml.mat4():translate(cpml.vec3(0, 0, 25)),
			rotation_speed = 0.1
		}
		self.world:addEntity {
			fov  = 55,
			near = 0.1,    -- 10cm
			far  = 1000.0, -- 1km

			position     = cpml.vec3(0, 0, 0),

			-- magic
			camera = true
		}

		if self.beat_the_game then
			self.world:addEntity {
				model        = iqe.load("assets/models/ld-boat.iqe"),
				model_matrix = cpml.mat4()
					:translate(cpml.vec3(-10, 40, -17))
					:rotate(math.pi / 1.15, {-1, 0, 0})
					:rotate(math.pi / 15, {0, 1, 0})
					:rotate(math.pi / 3, {0, 0, 1}),
				color        = { 0.8, 0.85, 1.0 },
			}
			-- Particles (bubbles)
			self.world:addEntity {
				particles  = 100,
				spawn_rate = 1/4,
				lifetime   = { 15, 30 },
				radius     = 3,
				spread     = 0.75,
				size       = 0.25,
				color      = { 0.75, 0.9, 1.0, 0.5 },
				velocity   = cpml.vec3(0, 0, 4),
				position   = cpml.vec3(-10, 40, -17),
				texture    = love.graphics.newImage("assets/textures/bubble.png")
			}
		end

		-- Particles (debris)
		self.world:addEntity {
			particles  = 800,
			spawn_rate = 1/10,
			lifetime   = { 30, 50 },
			radius     = 75,
			spread     = 2.0,
			size       = 0.25,
			color      = { 0.5, 0.8, 0.9 },
			velocity   = cpml.vec3(0, 0, 3),
			position   = cpml.vec3(0, 0, -30)
		}

		-- Particles (bubbles)
		self.world:addEntity {
			particles  = 60,
			spawn_rate = 1/5,
			lifetime   = { 30, 50 },
			radius     = 75,
			spread     = 0.75,
			size       = 0.35,
			color      = { 0.75, 0.9, 1.0 },
			velocity   = cpml.vec3(0, 0, 4),
			position   = cpml.vec3(0, 0, -30),
			texture    = love.graphics.newImage("assets/textures/bubble.png")
		}

		if self.beat_the_game then
			-- Particles (blood)
			self.world:addEntity {
				disable_depth_test = true,
				particles  = 1000,
				spawn_rate = 1/30,
				lifetime   = { 20, 50 },
				radius     = 50,
				spread     = 2,
				size       = 1.5,
				color      = { 0.6, 0.1, 0.25, 0.95 },
				velocity   = cpml.vec3(0, 0, -4),
				position   = cpml.vec3(0, 0, 40)
			}
		end

		self.camera_system = require("systems.camera")()
		self.world:addSystem(self.camera_system)
		self.world.camera_system = self.camera_system

		self.particle_system = require("systems.particle")()
		self.world:addSystem(self.particle_system)
		self.world.particle_system = self.particle_system

		self.render_system = require("systems.render")()
		self.world:addSystem(self.render_system)

		self.text = ""
		self.scroll_speed = 500

		self.font = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 12)
		self.font2 = love.graphics.newFont("assets/fonts/NotoSans-Bold.ttf", 24)

		local sound = select(2, self.world.lang("credits/thanks"))
		self.thanks = sound and love.audio.newSource(sound) or false
	end

	function credits:leave()
		self.world.camera_system = nil
		self.world:removeSystem(self.render_system)
		self.world:removeSystem(self.particle_system)
		self.world:removeSystem(self.camera_system)
		self.world:clearEntities()
	end

	function credits:transition_out()
		chain(function(continue, wait)
			self.timer.tween(1.0, self.state, { opacity = 1, volume = 0 }, 'in-out-quad', continue())
			wait()
			self.bgm:stop()
			self.timer.tween(1.0, self.state, { thanks_opacity = 1 }, 'in-out-quad')
			self.timer.add(2, continue())
			wait()
			if self.beat_the_game then
				if self.thanks then
					self.thanks:play()
				end
				self.timer.tween(3, self.state, { thanks_opacity = 0 }, 'in-out-quad')
				self.timer.add(4, continue())
				wait()
			end
			Scene.switch(require("scenes.main-menu")(self.world))
		end)()
	end

	function credits:mousepressed(x, y, button)
		if self.input_locked then
			return
		end
		if button == 1 then
			self:transition_out()
		end
	end

	function credits:update(dt)
		self.time = self.time + dt

		self.timer.update(dt)
		self.bgm:setVolume(self.state.volume)

		self.text = self.crash:sub(self.time*self.scroll_speed,self.time*self.scroll_speed+1200)
	end

	function credits:draw()
		love.graphics.setColor(255, 255, 255, 255 * (1-self.state.opacity))
		love.graphics.setFont(self.font)
		love.graphics.printf(
			self.text,
			anchor:center_x(),
			anchor:top(),
			anchor:width() / 2,
			"left"
		)
		love.graphics.printf(
			self.lines,
			anchor:left(),
			anchor:top() - 20,
			anchor:width() / 2,
			"center"
		)
		love.graphics.setColor(0, 0, 0, 255 * self.state.opacity)
		love.graphics.rectangle(
			"fill", 0, 0,
			love.graphics.getWidth(),
			love.graphics.getHeight()
		)

		love.graphics.setFont(self.font2)
		love.graphics.setColor(255, 255, 255, 255 * self.state.thanks_opacity)
		love.graphics.printf(
			(self.world.lang("credits/thanks")),
			anchor:left(),
			anchor:center_y() - 12,
			anchor:width(),
			"center"
		)

		if self.input_locked then
			return
		end

		if g_buttons.menu_back:pressed() then
			self:transition_out()
		end
	end

	return credits
end
