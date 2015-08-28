local anchor   = require "anchor"
local anim9    = require "anim9"
local chain    = require "chain"
local cpml     = require "cpml"
local iqe      = require "iqe"
local lume     = require "lume"
local tactile  = require "tactile"
local talkback = require "talkback"
local timer    = require "timer"
local tiny     = require "tiny"

return function(world, initial)
	local scene              = tiny.system()
	scene.systems            = {}
	scene.world              = world
	scene.world.conversation = talkback.new()
	scene.first_update       = true

	if initial then
		world:addSystem(scene)
	end

	function scene:enter(from, level)
		self.timer     = timer.new()
		self.locked    = true
		self.win       = false

		local next_level = {
			["01"] = "02",
			["02"] = "03",
			["03"] = "win",
			["win"] = false -- THERE'S JUST NO WINNING.
		}
		self.level      = level or "01"
		self.next_level = next_level[self.level]

		-- if not self.next_level then
		-- 	self.world.notify("You beat the game!")
		-- 	Scene.switch(require("scenes.main-menu")(self.world))
		-- 	return
		-- end

		love.filesystem.isFile(string.format("assets/levels/%s", self.next_level))

		self.time      = 0
		self.font      = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 18)
		self.indicator = love.graphics.newImage("assets/images/arrow.png")
		self.subtitle  = {
			text    = "",
			opacity = 0,
			font    = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 18)
		}

		self.bone = love.audio.newSource("assets/sounds/bones.ogg")

		self.prompt = {
			cache   = {},
			open    = false,
			current = 1,
			sfx     = {
				prev = love.audio.newSource("assets/sounds/prev.wav"),
				next = love.audio.newSource("assets/sounds/next.wav"),
				pick = love.audio.newSource("assets/sounds/pick.wav")
			}, {
				"pause/continue",
				function()
					love.mouse.setRelativeMode(true)
					self.paused = false
					self.prompt.open = false
					self.systems.input.active = true
					self.prompt.current = 1
					self.level_entities.camera.direction = self.prompt.direction
					self.level_entities.camera.orientation = self.prompt.orientation
				end
			}, {
				"pause/reset",
				function()
					Scene.switch(require("scenes.play")(self.world), self.level)
				end,
			}, {
				"pause/exit",
				function()
					Scene.switch(require("scenes.main-menu")(self.world))
				end
			}
		}

		self.sfx = {
			ocean = love.audio.newSource("assets/sounds/water.wav")
		}
		self.sfx.ocean2 = self.sfx.ocean:clone()

		chain(function(continue, wait)
			self.sfx.ocean:setLooping(true)
			self.sfx.ocean:setVolume(0.75)
			self.sfx.ocean2:setLooping(true)
			self.sfx.ocean:setPitch(0.5)
			self.sfx.ocean2:setPitch(0.75)
			self.sfx.ocean:play()
			self.timer.add(2, continue())
			wait()
			self.sfx.ocean2:play()
		end)()

		self.show_collisions = tactile.newButton(tactile.key "f8")

		self.hud = {
			shader = love.graphics.newShader("assets/shaders/shader.glsl"),
			arrow  = iqe.load("assets/models/ld-arrow.iqe"),
			target = false
		}

		self.state = {
			opacity = 1
		}
		chain(function(continue, wait)
			self.timer.tween(1.0, self.state, { opacity = 0 }, 'in-out-quad')
			self.timer.add(0.5, continue())
			wait()
			self.locked = false
		end)()

		love.mouse.setRelativeMode(true)

		-- Load level
		-- Load it with l.fs.load so that it doesn't get cached by require.
		-- Caching breaks reloading levels and there's no reason we should fuss
		-- with package.loaded over the level - just do this.
		local level = love.filesystem.load(string.format("assets/levels/%s.lua", self.level))()

		-- Add Time Limit
		self.time_limit = level.time_limit

		self.beat_the_game = level.a_winner_is_you

		if self.beat_the_game then
			self.font2 = love.graphics.newFont("assets/fonts/NotoSans-Bold.ttf", 24)
		end

		-- Add Script
		self.script = level.script

		--== Add models ==--

		self.models = {}

		for name, params in pairs(level.models) do
			local path  = string.format("assets/models/%s%s", name, ".iqe")
			local model = iqe.load(path)
			console.i("Loaded model \"%s\"", path)

			-- Load animations
			if params.animated then
				model.anim = anim9(model.anims)
			end

			self.models[name] = model
		end

		--== Add level entities ==--

		self.level_entities = {}

		for name, entity in pairs(level.entities) do
			self:process_entity(name, entity)
		end

		-- This can't be in the above loop due to dependency problems.
		for name, entity in pairs(level.entities) do
			if entity.attachment then
				entity.attachment = self.level_entities[entity.attachment]
			end
		end

		--== Setup Entites ==--
		self.level_entities.player.anim:play("swim")
		if self.level_entities.cage and self.level_entities.cage.anim then
			self.level_entities.cage.anim:play("idle")
		elseif self.level_entities.diver then
			self.level_entities.diver.anim:play("swim") -- switch to idle?
			self.level_entities.diver.tethered = true
		end

		--== Add systems ==--

		-- Input system
		self.systems.input = require("systems.input")()
		self.world:addSystem(self.systems.input)

		-- Camera input system
		self.systems.camera_input = require("systems.camera_input")()
		self.world:addSystem(self.systems.camera_input)

		-- Movement system
		self.systems.movement = require("systems.movement")()
		self.world:addSystem(self.systems.movement)

		-- Camera movement system
		self.systems.camera_movement = require("systems.camera_movement")()
		self.world:addSystem(self.systems.camera_movement)

		-- Camera system
		self.systems.camera = require("systems.camera")()
		self.world:addSystem(self.systems.camera)
		self.world.camera_system = self.systems.camera
		self.level_entities.camera.position = self.level_entities.player.position

		-- Attachment system
		self.systems.attachment = require("systems.attachment")()
		self.world:addSystem(self.systems.attachment)

		-- Particle system
		self.systems.particle = require("systems.particle")()
		self.world:addSystem(self.systems.particle)
		self.world.particle_system = self.systems.particle

		-- Collision system
		self.systems.collision = require("systems.collision")()
		self.world:addSystem(self.systems.collision)

		-- Animation system
		self.systems.animation = require("systems.animation")()
		self.world:addSystem(self.systems.animation)

		-- Audio system
		self.systems.audio = require("systems.audio")()
		self.world:addSystem(self.systems.audio)

		-- Render system
		self.systems.render = require("systems.render")()
		self.world:addSystem(self.systems.render)

		--== Add Event Listeners ==--

		local function play_sound(sound)
			if sound == "kek" then return end

			local sound = select(2, self.world.lang(sound))
			if sound then
				love.audio.play(love.audio.newSource(sound))
			end
		end

		local function draw_text(text, len)
			self.subtitle.text    = select(1, self.world.lang(text))
			self.subtitle.opacity = 0

			chain(function(continue, wait)
				self.timer.tween(0.5, self.subtitle, { opacity=255 }, 'out-cubic', continue())
				wait()

				self.timer.add(len, continue())
				wait()

				self.timer.tween(0.5, self.subtitle, { opacity=0 }, 'out-cubic', continue())
				wait()

				self.subtitle.text = ""
			end)()
		end

		self.world.conversation:listen("open", function()
			chain(function(continue, wait)
				local choice = lume.randomchoice(self.script.open)
				self.timer.add(1, continue())
				wait()

				draw_text(choice, 2)
				play_sound(choice)
			end)()
		end)

		self.world.conversation:listen("time", function()
			chain(function(continue, wait)
				self.timer.add(15, continue())
				wait()

				if  self.level_entities.rope
				and self.level_entities.rope.hp <= 0 then
					return
				end

				local choice = lume.randomchoice(self.script.time)
				draw_text(choice, 2)
				play_sound(choice)
				self.world.conversation:say("time")
			end)()
		end)

		self.world.conversation:listen("hint", function(first)
			first = first and 7 or 0
			chain(function(continue, wait)
				self.timer.add(15 + first, continue())
				wait()

				if  self.level_entities.rope
				and self.level_entities.rope.hp <= 0 then
					return
				end

				local choice = lume.randomchoice(self.script.hint)
				draw_text(choice, 2)
				play_sound(choice)
				self.world.conversation:say("hint")
			end)()
		end)

		self.world.conversation:listen("ouch", function()
			local choice = lume.randomchoice(self.script.ouch)
			draw_text(choice, 2)
			play_sound(choice)
		end)

		self.world.conversation:listen("attacked", function(entity, ouch)
			if ouch then
				self.world.conversation:say("ouch")
			end

			if entity.cage then
				if entity.hp <= 0 then
					self.world:removeEntity(entity)

					self.level_entities.rope.hp = 0

					local name    = "cage_broken"
					local cage    = love.filesystem.load("assets/entities/cage-broken.lua")()
					cage.position = entity.position:clone()
					self:process_entity(name, cage)

					local name     = "diver"
					local diver    = love.filesystem.load("assets/entities/diver.lua")()
					diver.position = entity.position:clone()
					self:process_entity(name, diver)
					diver.anim:play("swim")
				elseif entity.hp <= entity.max_hp * 0.30 then
					entity.model = self.models["ld-cage-damage-2"]
				elseif entity.hp <= entity.max_hp * 0.70 then
					entity.model = self.models["ld-cage-damage-1"]
				end
			end

			if entity.hp <= 0 and entity.diver then
				self.world.conversation:say("kill")
			end

			if entity.hp <= 0 and entity.rope then
				if not self.level_entities.cage then
					self.level_entities.diver.tethered = false
				end

				chain(function(continue, wait)
					self.timer.do_for(self.time_limit, function(dt)
						self.time_limit = cpml.utils.clamp(
							self.time_limit - dt,
							0,
							self.time_limit
						)
					end, continue())
					wait()

					self.world.conversation:say("lose")
				end)()
			end
		end)

		self.world.conversation:listen("kill", function()
			chain(function(continue, wait)
				local choice = lume.randomchoice(self.script.kill)
				if self.level_entities.diver then
					self:process_entity("bloooood", {
						attachment = self.level_entities.diver,
						disable_depth_test = true,
						particles  = 1000,
						spawn_rate = 1/50,
						lifetime   = { 2.5, 4.0 },
						radius     = 0.2,
						spread     = 1,
						size       = 2,
						color      = { 0.5, 0.1, 0.3, 1.0 },
						velocity   = cpml.vec3(0, 0, 0),
						position   = cpml.vec3(0, 0, 0)
					})
					love.audio.play(self.bone)
				else
					console.d("wat")
				end
				draw_text(choice, 6)
				play_sound(choice)
				self.timer.add(2, continue())
				wait()

				self.world.conversation:say("lose", true)
			end)()
		end)

		self.world.conversation:listen("lose", function(kill)
			chain(function(continue, wait)
				if not kill then
					local choice = lume.randomchoice(self.script.lose)
					draw_text(choice, 2)
					play_sound(choice)

					if self.level_entities.cage then
						self:process_entity("bloooood", {
							attachment = self.level_entities.cage_broken and self.level_entities.diver or self.level_entities.cage,
							disable_depth_test = true,
							particles  = 1000,
							spawn_rate = 1/50,
							lifetime   = { 2.5, 4.0 },
							radius     = 0.2,
							spread     = 1,
							size       = 2,
							color      = { 0.5, 0.1, 0.3, 1.0 },
							velocity   = cpml.vec3(0, 0, 0),
							position   = cpml.vec3(0, 0.5, 0)
						})
					else
						console.d("wat")
					end
				end

				self.world:removeSystem(self.systems.input)
				self.timer.add(4, continue())
				wait()

				table.remove(self.prompt, 1)
				self.prompt.lose = true
				self.prompt.open = true
				self.paused      = true
			end)()
		end)

		self.world.conversation:listen("win", function()
			chain(function(continue, wait)
				-- do return end
				local choice = lume.randomchoice(self.script.win)
				draw_text(choice, 2)
				play_sound(choice)
				self.world:removeSystem(self.systems.input)
				self.win = true
				self.timer.add(4, continue())
				wait()

				Scene.switch(require("scenes.play")(self.world), self.next_level)
			end)()
		end)

		self.world.conversation:say("open")
		self.world.conversation:say("time")
		self.world.conversation:say("hint", true)
	end

	function scene:update(dt)
		if not self.next_level then
			return
		end

		self.time = self.time + dt

		if self.first_update then
			self.first_update = false
			return
		end

		if g_flags.debug_mode then
			self.show_collisions:update()
			if self.show_collisions:pressed() then
				self.systems.render.debug = not self.systems.render.debug
			end
		end

		if self.prompt.open then
			-- Make sure menu sounds are properly audible.
			for _, sfx in pairs(self.prompt.sfx) do
				sfx:setPosition(self.level_entities.player.position:unpack())
			end
			if  g_buttons.menu_back:pressed()
			and not self.prompt.lose then
				self.prompt[1][2]()
				return
			end
			if g_buttons.menu_action:pressed() then
				self.prompt.sfx.pick:stop()
				self.prompt.sfx.pick:play()
				self.prompt[self.prompt.current][2]()
				return
			end
			if g_buttons.menu_up:pressed() then
				self.prompt.sfx.prev:stop()
				self.prompt.sfx.prev:play()
				self.prompt.current = self.prompt.current - 1
			end
			if g_buttons.menu_down:pressed() then
				self.prompt.sfx.next:stop()
				self.prompt.sfx.next:play()
				self.prompt.current = self.prompt.current + 1
			end
			self.prompt.current = cpml.utils.clamp(self.prompt.current, 1, #self.prompt)
			return
		elseif g_buttons.menu:pressed() then
			self.systems.input.active = false
			self.paused               = true
			self.prompt.open          = true
			self.prompt.direction     = self.level_entities.camera.direction:clone()
			self.prompt.orientation   = self.level_entities.camera.orientation:clone()
			love.mouse.setRelativeMode(false)
			return
		end

		if self.beat_the_game and g_buttons.action:pressed() then
			self.locked = true
			self.level_entities.player.stop_clamping_position = true
			self.level_entities.player.anim:play("launch")
			chain(function(continue, wait)
				self.timer.tween(0.25, self.level_entities.player.position, self.level_entities.boat.position + cpml.vec3(0, 0, 50), 'in-quad')
				self.timer.add(3, continue())
				wait()
				self.beat_the_game = false -- disable things why not
				self.timer.tween(1.0, self.state, { opacity = 1 }, 'in-out-quad', continue())
				wait()
				self.world.notify((self.world.lang "You Won!"))
				Scene.switch(require("scenes.lolded")(self.world))
			end)()
		end

		self.timer.update(dt)
		self.level_entities.player.orientation = self.systems.camera.active_camera.orientation * cpml.quat.rotate(math.pi, cpml.vec3(0, 0, 1))

		-- Stick the bgm to the player position.
		for _, sfx in pairs(self.sfx) do
			sfx:setPosition(self.level_entities.player.position:unpack())
		end

		if  self.level_entities.diver
		and self.level_entities.diver.position.z >= 75
		and self.level_entities.diver.hp > 0
		and not self.win then
			self.world.conversation:say("win")
		end
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

	-- HUD
	function scene:draw()
		if not self.next_level then
			return
		end

		if self.prompt.open then
			-- Hack around paused game.
			self.time = self.time + (console.visible and 0 or love.timer.getDelta())

			local menu_pos = cpml.vec2(anchor:center_x(), anchor:center_y())
			local spacing  = 52
			local offset   = -12
			menu_pos.x = menu_pos.x + 50
			menu_pos.y = math.floor(menu_pos.y - ((#self.prompt+1) * spacing) / 2) + offset

			for i, option in ipairs(self.prompt) do
				local x, y = transform(spacing, i, self.prompt.current, #self.prompt)
				x = menu_pos.x + x
				y = menu_pos.y + y
				if not self.prompt.cache[i] then
					self.prompt.cache[i] = {}
				end
				local cache = self.prompt.cache[i]
				cache.w = 320
				cache.h = 50
				cache.x = x - 10 -- box visual offset
				cache.y = y + offset

				love.graphics.setColor(0, 0, 0, 180)
				love.graphics.rectangle("fill", cache.x, cache.y, cache.w, cache.h, 5)
				if i == self.prompt.current then
					if math.floor(self.time * 10) % 2 == 0 then
						love.graphics.setColor(255, 240, 210, 255)
					else
						love.graphics.setColor(255, 205, 195, 255)
					end
				else
					love.graphics.setColor(255, 255, 255, 255)
				end
				love.graphics.setFont(self.font)
				love.graphics.print((world.lang(option[1])), x, y - 2)
				love.graphics.setColor(255, 255, 255, 255)
				if i == self.prompt.current then
					local bounce = math.sin(self.time * 10) * 5 - 15
					love.graphics.draw(self.indicator, x + bounce, y + 2, math.pi/2, 0.25, 0.25)
				end
			end
			return
		end

		-- local camera   = self.systems.camera.active_camera
		-- if camera then
		-- 	local w, h = love.graphics.getDimensions()
		-- 	local view = cpml.mat4():ortho(0, w, 0, h, -100, 100)
		--
		-- 	local shader   = self.hud.shader
		-- 	local model    = self.hud.arrow
		-- 	local position = cpml.vec3(
		-- 		anchor:left(),
		-- 		anchor:bottom(),
		-- 		0
		-- 	)
		-- 	local player   = self.level_entities.player
		-- 	local target   = self.hud.target
		-- 	local scale    = cpml.vec3(50, 50, 50)
		-- 	local dir      = camera.direction + (player.position - target.position)
		-- 	local rotation = cpml.quat(0, 0, 1, 0) * cpml.quat(dir.x, dir.y, dir.z, 0)
		--
		-- 	love.graphics.setShader(shader)
		-- 	shader:send("u_projection", view:to_vec4s())
		-- 	shader:send("u_view", cpml.mat4():to_vec4s())
		-- 	shader:send("u_model", cpml.mat4()
		-- 		:translate(position)
		-- 		:rotate(rotation)
		-- 		:scale(scale)
		-- 		:to_vec4s()
		-- 	)
		-- 	shader:sendInt("u_skinning", 0)
		--
		-- 	love.graphics.clearDepth()
		-- 	love.graphics.setDepthTest("less")
		-- 	love.graphics.setCulling("back")
		-- 	love.graphics.setFrontFace("cw")
		-- 	love.graphics.setBlendMode("replace", false)
		--
		-- 	love.graphics.setColor(255, 255, 255, 255)
		-- 	for _, buffer in ipairs(model.vertex_buffer) do
		-- 		love.graphics.draw(buffer.mesh)
		-- 	end
		--
		-- 	love.graphics.setShader()
		-- 	love.graphics.setCulling()
		-- 	love.graphics.setFrontFace()
		-- 	love.graphics.setDepthTest()
		-- 	love.graphics.setBlendMode("alpha")
		-- end

		-- Draw timer
		local o = love.graphics.getFont()
		local f = self.font
		local w = f:getWidth(math.ceil(self.time_limit))
		local c = anchor:center_x()
		local t = anchor:top()

		love.graphics.setFont(f)
		love.graphics.print(math.ceil(self.time_limit), c - w/2, t + 20)
		love.graphics.setFont(o)

		-- Draw subtitles
		local o = love.graphics.getFont()
		local f = self.subtitle.font
		local w = f:getWidth(self.subtitle.text)
		local c = anchor:center_x()
		local b = anchor:bottom()

		love.graphics.setColor(255, 255, 255, self.subtitle.opacity)
		love.graphics.setFont(f)
		if self.subtitle.text == "kek" then
			self.subtitle.text = ""
		end
		love.graphics.print(self.subtitle.text, c - w/2, b - 50)
		love.graphics.setFont(o)
		love.graphics.setColor(255, 255, 255, 255)

		if self.beat_the_game then
			love.graphics.setFont(self.font2)
			love.graphics.setColor(0, 0, 0, 200)
			love.graphics.printf(
				(self.world.lang("PRESS A TO BEAT THE GAME")),
				anchor:left(),
				anchor:center_y() - 10,
				anchor:width(),
				"center"
			)
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.printf(
				(self.world.lang("PRESS A TO BEAT THE GAME")),
				anchor:left() - 2,
				anchor:center_y() - 12,
				anchor:width(),
				"center"
			)
		end

		-- overlay fade
		love.graphics.setColor(0, 0, 0, 255 * self.state.opacity)
		love.graphics.rectangle(
			"fill", 0, 0,
			love.graphics.getWidth(),
			love.graphics.getHeight()
		)
	end

	-- XXX: Fix this shit.
	function scene:keypressed(k)
		if k == "g" then
			love.mouse.setRelativeMode(not love.mouse.getRelativeMode())
		end
	end

	function scene:mousepressed(x, y, button)
		if self.locked then
			return
		end
		local hit = check_hit(self.prompt, x, y)
		self.clicked = hit
	end

	function scene:mousereleased(x, y, button)
		if self.locked then
			return
		end
		local hit = check_hit(self.prompt, x, y)
		if hit and hit == self.clicked then
			self.prompt.current = hit
			self.prompt[self.prompt.current][2]()
		end
	end

	function scene:mousemoved(x, y, dx, dy)
		if self.locked then
			return
		end

		if not love.mouse.getRelativeMode() then
			local hit = check_hit(self.prompt, x, y)
			if hit and hit ~= self.prompt.current then
				self.prompt.sfx.next:stop()
				self.prompt.sfx.next:play()
				self.prompt.current = hit
			end
			return
		end
		local relative_speed_hack = false
		local camera = self.systems.camera
		local speed = relative_speed_hack and 0.1 or 2

		if camera.active_camera then
			camera:rotate_xy(-dx * speed, -dy * speed)
		end
	end

	function scene:resize(w, h)
		if not self.next_level then
			return
		end

		self.systems.render:resize(w, h)
	end

	function scene:process_entity(name, entity)
		if entity.model then
			entity.model = self.models[entity.model]
			if entity.model.anim then
				entity.anim = entity.model.anim
			end
		end
		if entity.collider then
			entity.collider = self.models[entity.collider]
		end
		if entity.texture then
			entity.texture = love.graphics.newImage(entity.texture)
		end
		if entity.sound then
			entity.sound = love.audio.newSource(entity.sound)
		end
		if entity.target then
			self.hud.target = entity
		end
		self.level_entities[name] = entity
		self.world:addEntity(entity)
	end

	function scene:leave()
		if not self.next_level then
			return
		end

		self.world.talkback      = nil
		self.world.active_camera = nil
		self.world.camera_system = nil
		self.world:clearEntities()

		love.mouse.setRelativeMode(false)

		for _, sfx in pairs(self.sfx) do
			sfx:stop()
		end

		love.audio.stop()

		-- Remove systems
		for _, system in pairs(self.systems) do
			world:removeSystem(system)
		end

		-- Reset audio position
		love.audio.setPosition(0, 0, 0)
	end

	return scene
end
