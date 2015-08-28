local l3d = require "love3d"
console   = require "console"
if not perfhud then
	l3d.import(true)
	perfhud = require("linegraph")(10, 110, 200, 100, 1/30)
end

-- Note: The point in the file in which you call this is where the world will be
-- restored to. As such, because we want the console to remain persistent, we
-- require it before doing this. -ss
require("fire").save_the_world()

Scene = require "scene"
-- local talkback = require "talkback"
-- Conversation = talkback.new()

local sys_inputs
local volume = love.audio.getVolume()
local show_overscan = false
local muted
local notifications
local languages = {
	"en", "fr", "de", "gr", "it", "pl", "pt_br", "ru", "phpceo",
	current = 1
}

function love.load()
	console.load(love.graphics.newFont("assets/fonts/unifont-7.0.06.ttf", 16))
	console.update(0)

	console.defineCommand("initial-screen", "(debug) Set initial screen for reloads", function(screen)
		initial_screen = screen ~= "" and "scenes." .. screen or false
	end)
	console.defineCommand("language", "Change UI language", function(id)
		id = tonumber(id)
		if not id then
			console.i("Languages:")
			for i, lang in ipairs(languages) do
				console.i(" %d) %s", i, lang)
			end
			return
		end
		local lang = languages[id]
		local top = Scene.current()
		if lang and top.world then
			languages.current = id
			top.world.lang:set_locale(lang)
			console.i("Set language to %s", lang)
		end
	end)

	local anchor  = require "anchor"
	anchor:set_overscan(0.1)

	local tactile = require "tactile"
	local i18n    = require "i18n"
	local tiny    = require "tiny"

	local world = tiny.world()

	local cpml  = require "cpml"
	local timer = require "timer"
	local chain = require "chain"
	local json  = require "dkjson"

	notifications = tiny.system()
	notifications.active = false
	notifications.ding = love.audio.newSource("assets/sounds/ding.wav")
	notifications.notifications = {}
	notifications.timer = timer.new()
	notifications.size  = cpml.vec2(200, 50)
	notifications.font  = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 14)
	function notifications:add(msg, icon)
		assert(type(msg) == "string")

		table.insert(self.notifications, { icon = icon, text = msg, opacity=1.0 })

		chain(function(continue, wait)
			self.timer.add(5, continue())
			wait()
			self.timer.tween(0.5, self.notifications[1], {opacity=0}, 'out-cubic', continue())
			wait()
			table.remove(self.notifications, 1)
		end)()
	end
	local function transform(index)
		local spacing = 60
		local x = love.graphics.getWidth() - 210
		local y = spacing * index + 10
		return x, y
	end
	function notifications:update(dt)
		self.timer.update(dt)
		for i, n in ipairs(self.notifications) do
			local x, y = transform(i-1)
			local pad = 5
			love.graphics.setColor(0, 0, 0, 200*n.opacity)
			love.graphics.rectangle("fill", x, y, self.size.x, self.size.y, 4)
			love.graphics.setColor(20, 90, 127, 255*n.opacity)
			love.graphics.rectangle("line", x, y, self.size.x, self.size.y, 4)
			love.graphics.setColor(255, 255, 255, 255*n.opacity)
			love.graphics.setFont(self.font)
			love.graphics.printf(n.text, x + pad, y + pad, 200)
		end
		love.graphics.setColor(255, 255, 255, 255)
	end
	world.notify = function(msg, ding, icon)
		if ding then
			notifications.ding:stop()
			notifications.ding:play()
		end
		notifications:add(msg, icon)
	end
	world:addSystem(notifications)

	local input_system = tiny.system()
	input_system.active = true
	function input_system:update()
		for k, v in pairs(sys_inputs) do
			if v.update then
				v:update()
			end
		end
		if console.visible then
			return
		end
		for k, v in pairs(g_buttons) do
			-- Only need to update buttons.
			if v.update then
				v:update()
			end
		end
	end
	world:addSystem(input_system)

	local k = tactile.key
	local m = tactile.mouseButton
	local g = function(button)
		return tactile.gamepadButton(button, 1)
	end

	-- Keyboard as axes
	local kb_ad = tactile.binaryAxis(k "a",    k "d")
	local kb_ws = tactile.binaryAxis(k "w",    k "s")
	local kb_lr = tactile.binaryAxis(k "left", k "right")
	local kb_ud = tactile.binaryAxis(k "up",   k "down")

	local kb_q  = tactile.binaryAxis(k "kp9", k "q")
	local kb_rs = tactile.binaryAxis(k "kp9", k "rshift")
	local kb_e  = tactile.binaryAxis(k "kp9", k "e")
	local kb_k0 = tactile.binaryAxis(k "kp9", k "kp0")

	-- Gamepad axes
	local move_x    = tactile.analogStick("leftx",        1)
	local move_y    = tactile.analogStick("lefty",        1)
	local camera_x  = tactile.analogStick("rightx",       1)
	local camera_y  = tactile.analogStick("righty",       1)
	local trigger_l = tactile.analogStick("triggerleft",  1)
	local trigger_r = tactile.analogStick("triggerright", 1)

	local kb_return = function()
		return love.keyboard.isDown("return") and
			not (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"))
	end

	local kb_fullscreen = function()
		return love.keyboard.isDown("return") and
			(love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt"))
	end

	local function next_lang()
		languages.current = (languages.current % #languages) + 1
		local lang = languages[languages.current]
		local top = Scene.current()
		top.world.lang:set_locale(lang)
		top.world.notify(string.format("Changed locale to %s", lang))

		preferences.language = lang
		love.filesystem.write("preferences.json", json.encode(preferences))
	end
	g_change_language = next_lang

	sys_inputs = {
		open_screenshots = tactile.newButton(k "f11"),
		screenshot       = tactile.newButton(k "f12"),
		enter            = tactile.newButton(kb_return),
		escape           = tactile.newButton(k "escape"),
		mute             = tactile.newButton(k "pause"),
		change_language  = tactile.newButton(k "f9"),
		show_overscan    = tactile.newButton(k "f10"),
		fullscreen       = tactile.newButton(kb_fullscreen)
	}

	g_buttons = {
		move_x      = tactile.newAxis(kb_ad, kb_lr, move_x),
		move_y      = tactile.newAxis(kb_ws, kb_ud, move_y),
		camera_x    = tactile.newAxis(camera_x),
		camera_y    = tactile.newAxis(camera_y),
		trigger_l   = tactile.newAxis(kb_q, kb_rs, trigger_l),
		trigger_r   = tactile.newAxis(kb_e, kb_k0, trigger_r),
		action      = tactile.newButton(kb_return,  m(1),      g "a"),
		menu        = tactile.newButton(k "escape", m(2),      g "back",  g "start", g "y"),
		menu_back   = tactile.newButton(k "escape", m(3),      g "back",  g "b"),
		menu_action = tactile.newButton(kb_return,  k "space", g "a"),
		menu_up     = tactile.newButton(k "up",     k "w",     g "dpup"),
		menu_down   = tactile.newButton(k "down",   k "s",     g "dpdown"),
		menu_left   = tactile.newButton(k "left",   k "a",     g "dpleft"),
		menu_right  = tactile.newButton(k "right",  k "d",     g "dpright")
	}

	local lang = i18n()
	lang:set_fallback("en")
	lang:set_locale("en")
	local base = "assets/lang"
	for _, path in ipairs(love.filesystem.getDirectoryItems(base)) do
		lang:load(string.format("%s/%s", base, path))
	end
	world.lang = lang

	if love.filesystem.isFile("preferences.json") then
		local p = love.filesystem.read("preferences.json")
		preferences = json.decode(p)
	else
		preferences = {
			language = "en",
			volume   = 0.7
		}
	end

	world.lang:set_locale(preferences.language)
	love.audio.setVolume(preferences.volume)

	local default_screen = g_flags.debug_mode and "scenes.main-menu" or "scenes.splash"
	Scene.switch(require(initial_screen or default_screen)(world, true))
	Scene.register_callbacks()
end

function love.update(dt)
	local anchor = require "anchor"
	anchor:update()

	local top = Scene.current()
	local paused = top.paused or console.visible
	if top.world then
		top.world:update(paused and 0 or dt)
		notifications:update(dt)
	end
	if g_flags.debug_mode then
		perfhud:update(dt)
		perfhud:draw()
		if sys_inputs.show_overscan:pressed() then
			show_overscan = not show_overscan
		end
	end

	if show_overscan then
		love.graphics.setColor(180, 180, 180, 200)
		love.graphics.setLineStyle("rough")
		love.graphics.line(anchor:left(), anchor:center_y(), anchor:right(), anchor:center_y())
		love.graphics.line(anchor:center_x(), anchor:top(), anchor:center_x(), anchor:bottom())
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.rectangle("line", anchor:bounds())
	end

	if sys_inputs.screenshot:pressed() then
		love.filesystem.createDirectory("Screenshots")

		local ss = love.graphics.newScreenshot()
		local path = "Screenshots/" .. os.date("%Y-%m-%d_%H-%M-%S", os.time()) .. ".png"
		local f = love.filesystem.newFile(path)
		ss:encode("png", path)
	end
	if sys_inputs.open_screenshots:pressed() then
		love.system.openURL("file://" .. love.filesystem.getSaveDirectory())
	end
	if sys_inputs.fullscreen:pressed() then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
	-- Quick exit for debug mode.
	if g_flags.debug_mode then
		if (love.keyboard.isDown "lshift" or love.keyboard.isDown "rshift") and sys_inputs.escape:pressed() then
			love.event.quit()
		end
	end
	if sys_inputs.mute:pressed() then
		if love.audio.getVolume() < 0.01 then
			muted = false
			love.audio.setVolume(volume)
		else
			volume = love.audio.getVolume()
			muted = true
			love.audio.setVolume(0)
		end
		top.world.notify(muted and "Muted" or "Unmuted", true)
	end
	if sys_inputs.change_language:pressed() then
		g_change_language()
	end
end
