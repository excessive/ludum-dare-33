return function(world, initial)
	local tiny  = require "tiny"
	local lume  = require "lume"
	local timer = require "timer"
	local chain = require "chain"
	local anchor = require "anchor"

	local splash = tiny.system()
	splash.world = world

	if initial then
		world:addSystem(splash)
	end

	function splash:enter(from)
		love.graphics.setBackgroundColor(lume.rgba(0xFF1E1E2C))
		self.logos = {
			l3d   = love.graphics.newImage("assets/splash/logo-love3d.png"),
			exmoe = love.graphics.newImage("assets/splash/logo-exmoe.png")
		}
		self.timer   = timer.new()
		self.delay   = 5.5 -- seconds before fade out
		self.overlay = {
			opacity = 255
		}
		self.bgm = {
			volume = 0.5,
			music  = love.audio.newSource("assets/splash/love.ogg")
		}
		self.bgm.music:play()
		love.mouse.setVisible(false)

		-- BGM
		chain(function(continue, wait)
			self.bgm.music:setVolume(self.bgm.volume)
			self.bgm.music:play()
			self.timer.add(self.delay, continue())
			wait()
			self.timer.tween(1.5, self.bgm, {volume = 0}, 'in-quad', continue())
			wait()
			self.bgm.music:stop()
		end)()

		-- Overlay fade
		chain(function(continue, wait)
			-- Fade in
			self.timer.tween(1.5, self.overlay, {opacity=0}, 'cubic', continue())
			wait()
			-- Wait a little bit
			self.timer.add(self.delay, continue())
			wait()
			-- Fade out
			self.timer.tween(1.25, self.overlay, {opacity=255}, 'out-cubic', continue())
			wait()
			-- Wait briefly
			self.timer.add(0.25, continue())
			wait()
			-- Switch
			Scene.switch(require("scenes.main-menu")(self.world))
		end)()
	end

	function splash:leave()
		love.mouse.setVisible(true)
	end

	function splash:update(dt)
		local cx, cy = anchor:center()

		local lw, lh = self.logos.exmoe:getDimensions()
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.draw(self.logos.exmoe, cx-lw/2, cy-lh/2 - 84)

		local lw, lh = self.logos.l3d:getDimensions()
		love.graphics.draw(self.logos.l3d, cx-lw/2, cy-lh/2 + 64)

		self.timer.update(dt)

		-- Full screen fade, we don't care about logical positioning for this.
		local w, h = love.graphics.getDimensions()
		love.graphics.setColor(0, 0, 0, self.overlay.opacity)
		love.graphics.rectangle("fill", 0, 0, w, h)

		self.bgm.music:setVolume(self.bgm.volume)

		-- Skip if user wants to get the hell out of here.
		if g_buttons.action:pressed() then
			self.bgm.music:stop()
			Scene.switch(require("scenes.main-menu")(self.world))
		end
	end

	return splash
end
