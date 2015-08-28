return function(world, initial)
	local anchor = require "anchor"
	local chain  = require "chain"
	local timer  = require "timer"
	local cpml   = require "cpml"
	local iqe    = require "iqe"
	local tiny   = require "tiny"

	local menu = tiny.system()
	menu.world = world
	if initial then
		world:addSystem(menu)
	end

	function menu:enter(from)
		self.timer = timer.new()
		self.time = 0
		self.clicked = false
		self.prev = require("scenes.splash")(self.world)
		self.options = {
			cache   = {},
			default = 1,
			sfx = {
				prev = love.audio.newSource("assets/sounds/prev.wav"),
				next = love.audio.newSource("assets/sounds/next.wav"),
				pick = love.audio.newSource("assets/sounds/pick.wav")
			},
			{ text = "main/play",      screen = "scenes.play" },
			{ text = "main/options",   screen = "scenes.options" },
			{ text = "main/credits",   screen = "scenes.credits" },
			{ text = "main/exit",      screen = "scenes.exit" }
		}
		if g_flags.debug_mode then
			table.insert(self.options, 4, { text = "main/debug", screen = "scenes.love3d-test" })
			table.insert(self.options, 5, { text = "main/crash", screen = "scenes.crash-test" })
		end
		self.options.current = self.options.default
		self.font = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 18)
		self.indicator = love.graphics.newImage("assets/images/arrow.png")

		self.logo = love.graphics.newImage("assets/images/logo.png")

		self.state = { opacity = 1 }
		self.locked = true

		chain(function(continue, wait)
			-- prevent accidental instant skipping
			self.timer.add(0.5, function()
				self.locked = false
			end)
			self.timer.tween(0.5, self.state, { opacity = 0 }, 'out-quad')
		end)()

		-- Reset audio position
		love.audio.setPosition(0, 0, 0)

		love.graphics.setBackgroundColor(50, 85, 135, 255)
		love.mouse.setRelativeMode(false)

		self.ocean = self.world:addEntity {
			model          = iqe.load("assets/models/ld-ocean.iqe"),
			model_matrix   = cpml.mat4():translate(cpml.vec3(0, 0, 25)),
			rotation_speed = 0.1
		}
		self.world:addEntity {
			fov  = 55,
			near = 0.1,    -- 10cm
			far  = 1000.0, -- 1km

			position = cpml.vec3(0, 0, 0),

			-- magic
			camera = true
		}

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

		self.camera_system = require("systems.camera")()
		self.world:addSystem(self.camera_system)
		self.world.camera_system = self.camera_system

		self.particle_system = require("systems.particle")()
		self.world:addSystem(self.particle_system)
		self.world.particle_system = self.particle_system

		self.render_system = require("systems.render")()
		self.world:addSystem(self.render_system)
	end

	function menu:leave()
		self.world.camera_system = nil
		self.world:removeSystem(self.render_system)
		self.world:removeSystem(self.particle_system)
		self.world:removeSystem(self.camera_system)
		self.world:clearEntities()
	end

	function menu:prev_option()
		self.options.current = self.options.current - 1
		if self.options.current < 1 then
			self.options.current = self.options.current + #self.options
		end
		self.options.sfx.prev:stop()
		self.options.sfx.prev:play()
	end

	function menu:next_option()
		self.options.current = self.options.current % #self.options + 1
		self.options.sfx.next:stop()
		self.options.sfx.next:play()
	end

	function menu:prev_screen()
		assert(self.prev)
		Scene.switch(self.prev)
	end

	function menu:next_screen()
		local option = assert(self.options[self.options.current])
		self.selected = option
		local ok, screen = pcall(require, option.screen)
		if ok then
			Scene.switch(screen(self.world))
		else
			console.d("Unable to load screen. Here's the error: %s", screen)
			self.locked = false
			self.timer.tween(0.25, self.state, { opacity = 0 }, 'in-out-quad')
		end
	end

	function menu:transition_out(prev)
		self.locked = true
		if not prev then
			self.options.sfx.pick:stop()
			self.options.sfx.pick:play()
		end
		chain(function(continue, wait)
			self.timer.tween(1.0, self.state, { opacity = 1 }, 'in-out-quad', continue())
			wait()
			if prev then
				self:prev_screen()
			else
				self:next_screen()
			end
		end)()
	end

	local function check_hit(menu, x, y)
		for i, v in ipairs(menu.cache) do
			if cpml.intersect.point_AABB(cpml.vec3(x, y, 0), {
				position = cpml.vec3(v.x, v.y, -0.1),
				volume   = cpml.vec3(v.w, v.h,  0.1)
			}) then
				return i
			end
		end
		return false
	end

	function menu:mousepressed(x, y, button)
		if self.locked then
			return
		end
		local hit = check_hit(self.options, x, y)
		self.clicked = hit
	end

	function menu:mousereleased(x, y, button)
		if self.locked then
			return
		end
		local hit = check_hit(self.options, x, y)
		if hit and hit == self.clicked then
			self.options.current = hit
			self:transition_out()
		end
	end

	function menu:mousemoved(x, y)
		if self.locked then
			return
		end
		local hit = check_hit(self.options, x, y)
		if hit and hit ~= self.options.current then
			self.options.sfx.next:stop()
			self.options.sfx.next:play()
			self.options.current = hit
		end
	end

	local function transform(spacing, index, current, num_items)
		local nudge   = 10
		local curve   = 0
		local x = math.cos(index / 2) * curve
		if index == current then
			x = x + nudge
		end
		local y = index * spacing
		return x, y
	end

	function menu:update(dt)
		self.timer.update(dt)
		self.time = self.time + dt
		self.ocean.model_matrix = self.ocean.model_matrix:rotate(self.ocean.rotation_speed * dt, { 0, 0, 1 })
	end

	function menu:draw()
		local menu_pos = cpml.vec2(anchor:left(), anchor:center_y())
		local spacing = 52
		local offset  = -12
		menu_pos.x = menu_pos.x + 50
		menu_pos.y = math.floor(menu_pos.y - ((#self.options+1) * spacing) / 2) + offset

		love.graphics.setColor(0, 15, 25, 200)
		love.graphics.draw(
			self.logo,
			anchor:right() - self.logo:getWidth() + 4 - 50,
			anchor:center_y() - self.logo:getHeight() / 1.5 + 9
		)
		love.graphics.setColor(225, 245, 255, 255)
		love.graphics.draw(
			self.logo,
			anchor:right() - self.logo:getWidth() - 50,
			anchor:center_y() - self.logo:getHeight() / 1.5 + 5
		)

		for i, option in ipairs(self.options) do
			local x, y = transform(spacing, i, self.options.current, #self.options)
			x = menu_pos.x + x
			y = menu_pos.y + y
			if not self.options.cache[i] then
				self.options.cache[i] = {}
			end
			local cache = self.options.cache[i]
			cache.w = 320
			cache.h = 50
			cache.x = x - 10 -- box visual offset
			cache.y = y + offset

			love.graphics.setColor(0, 0, 0, 180)
			love.graphics.rectangle("fill", cache.x, cache.y, cache.w, cache.h, 5)
			if i == self.options.current then
				if math.floor(self.time * 10) % 2 == 0 then
					love.graphics.setColor(255, 240, 210, 255)
				else
					love.graphics.setColor(255, 205, 195, 255)
				end
			else
				love.graphics.setColor(255, 255, 255, 255)
			end
			love.graphics.setFont(self.font)
			love.graphics.print((world.lang(option.text)), x, y - 2)
			love.graphics.setColor(255, 255, 255, 255)
			if i == self.options.current then
				local bounce = math.sin(self.time * 10) * 5 - 15
				love.graphics.draw(self.indicator, x + bounce, y + 2, math.pi/2, 0.25, 0.25)
			end
		end

		local font = love.graphics.getFont()
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.print(
			g_flags.game_version,
			anchor:right() - font:getWidth(g_flags.game_version),
			anchor:top()
		)

		love.graphics.setColor(0, 0, 0, 255 * self.state.opacity)
		love.graphics.rectangle(
			"fill", 0, 0,
			love.graphics.getWidth(),
			love.graphics.getHeight()
		)

		if self.locked then
			return
		end

		if g_buttons.menu_up:pressed() then
			self:prev_option()
		end
		if g_buttons.menu_down:pressed() then
			self:next_option()
		end

		if g_buttons.menu_back:pressed() then
			self:transition_out(true)
		end
		if g_buttons.menu_action:pressed() then
			self:transition_out()
		end
	end

	function menu:resize(w, h)
		self.render_system:resize(w, h)
	end

	return menu
end
