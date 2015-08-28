-- Game metadata (beyond love's own)
g_flags = {
	game_version = "1.0-LD33-FINAL",
	debug_mode   = not love.filesystem.isFused()
}

-- Specify window flags here because we use some of them for the error screen.
local flags = {
	title          = "Shark Swimulator - LD33",
	width          = 1280,
	height         = 720,
	fullscreen     = false,
	fullscreentype = "desktop",
	msaa           = 0,
	vsync          = true,
	resizable      = true,
	highdpi        = true
}

local use = {
	love_draw = false,
	-- Don't use the hot reloader if we're running fused.
	hot_reloader = g_flags.debug_mode,
}

function love.conf(t)
	t.version = "0.10.0"
	for k, v in pairs(flags) do
		t.window[k] = v
	end

	-- We want to use gamma correction whenever possible
	t.gammacorrect = true

	-- Don't use the accelerometer as a joystick (for mobile)
	t.accelerometerjoystick = false

	-- Box2D is useless for 3D
	t.modules.physics = false

	-- Disable buffering text to console
	io.stdout:setvbuf("no")
end

--------------------------------------------------
-- /!\ Here be dragons. Thou art forewarned /!\ --
--------------------------------------------------

-- Add libs folder to require search path
love.filesystem.setRequirePath(
	love.filesystem.getRequirePath() .. ";libs/?.lua;libs/?/init.lua"
)

-- Helpers for hot reloading the whole game.
-- I apologize for the global, but thou must.
local fire = {}
package.loaded.fire = fire
local pkg_cache = {}
local callbacks = {}

-- Save packages from startup so we can reset to this state at a later time
function fire.save_the_world()
	pkg_cache = {}
	callbacks = {}
	for k, v in pairs(package.loaded) do
		pkg_cache[k] = v
	end
	for k, v in pairs(love) do
		callbacks[k] = v
	end
	pkg_cache.main = nil
end

-- Restore saved cache so Lua has to reload everything.
function fire.reset_the_world()
	for k, v in pairs(package.loaded) do
		package.loaded[k] = pkg_cache[k]
	end
	for _, k in ipairs {
		'focus', 'keypressed', 'keyreleased', 'mousefocus', 'mousemoved',
		'mousepressed', 'mousereleased', 'resize', 'textedit', 'textinput',
		'visible', 'gamepadaxis', 'gamepadpressed', 'gamepadreleased',
		'joystickadded', 'joystickaxis', 'joystickhat', 'joystickpressed',
		'joystickreleased', 'joystickremoved', 'update', 'quit', 'load', 'draw'
	} do
		love[k] = nil
	end
	for k, v in pairs(callbacks) do
		love[k] = v
	end
	love.audio.stop()

	-- Clean out everything, just to be sure.
	collectgarbage("collect")

	require "main"

	print "Reloading game!"

	return love.run()
end

function love.run()
	local fire = require "fire"

	local reset = false

	if console then
		console.clearCommand("restart")
		console.defineCommand("restart", "Reload game files and restart the game.", function() reset = true end)
	end

	if love.math then
		love.math.setRandomSeed(os.time())
		for i=1,3 do love.math.random() end
	end

	if love.event then
		love.event.pump()
	end

	if love.load then love.load(arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	while true do
		Scene.do_switch()

		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "keypressed" and a == "f5" then
					reset = true
				end
				if name == "quit" then
					if not love.quit or not love.quit() then
						return
					end
				end
				if not console[name] or not (type(console[name]) == "function" and console[name](a,b,c,d,e,f)) then
					love.handlers[name](a,b,c,d,e,f)
				end
			end
		end

		if use.hot_reloader and reset then
			break
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
			if love.keyboard.isDown "tab" then
				dt = dt * 4
			else
				-- Cap dt to 30hz - this results in slowmo, but that's less bad than
				-- the things that enormous deltas can cause.
				dt = math.min(dt, 1/30)
			end
		end

		-- Call update and draw
		if love.graphics and love.graphics.isActive() then
			love.graphics.discard()
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()

			-- make sure the console is always updated
			if console then console.update(dt) end
			 -- will pass 0 if love.timer is disabled
			if love.update then love.update(dt) end

			if use.love_draw and love.draw then love.draw() end

			if console then console.draw() end


			love.graphics.present()

			-- Run a fast GC cycle so that it happens at predictable times.
			-- This prevents GC work from building up and causing hitches.
			collectgarbage("step")

			-- surrender just a little bit of CPU time to the OS
			if love.timer then love.timer.sleep(0.001) end
		end
	end

	if use.hot_reloader and reset then
		return fire.reset_the_world()
	end
end

local debug, print = debug, print

local function error_printer(msg, layer)
	local filename = "crash.log"
	local file     = ""
	local time     = os.date("%Y-%m-%d %H:%M:%S", os.time())
	local err      = debug.traceback(
		"Error: " .. tostring(msg), 1+(layer or 1)
	):gsub("\n[^\n]+$", "")

	if love.filesystem.isFile(filename) then
		file = love.filesystem.read(filename)
	end

	if file == "" then
		file = [[
Please report this on GitHub at https://github.com/excessive/Ludum-Dare-33 or
send an email to LManning17@gmail.com or send a DM on Twitter to @LandonManning.

]]
	else
		file = file .. "\n\n"
	end

	file = file .. string.format([[
=========================
== %s ==
=========================

%s]], time, err)

	love.filesystem.write(filename, file)
	print(err)
end

function love.errhand(msg)
	function rgba(color)
		local a = math.floor((color / 16777216) % 256)
		local r = math.floor((color /    65536) % 256)
		local g = math.floor((color /      256) % 256)
		local b = math.floor((color) % 256)
		return r, g, b, a
	end

	msg = tostring(msg)

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, flags.width, flags.height)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end
	love.graphics.reset()
	local head = love.graphics.setNewFont("assets/fonts/NotoSans-Regular.ttf", math.floor(love.window.toPixels(22)))
	local font = love.graphics.setNewFont("assets/fonts/NotoSans-Regular.ttf", math.floor(love.window.toPixels(14)))

	love.graphics.setBackgroundColor(rgba(0xFF1E1E2C))
	love.graphics.setColor(255, 255, 255, 255)

	-- Don't show conf.lua in the traceback.
	local trace = debug.traceback("", 2)

	love.graphics.clear(love.graphics.getBackgroundColor())
	love.graphics.origin()

	local err = {}

	table.insert(err, msg.."\n")

	for l in string.gmatch(trace, "(.-)\n") do
		if not string.match(l, "boot.lua") then
			l = string.gsub(l, "stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local c = string.format("Please locate the crash.log file at: %s\n\nI can try to open the folder for you if you press F11!", love.filesystem.getSaveDirectory())
	local h = "Oh no, it's broken!"
	local p = table.concat(err, "\n")

	p = string.gsub(p, "\t", "")
	p = string.gsub(p, "%[string \"(.-)\"%]", "%1")

	local function draw()
		local pos = love.window.toPixels(70)
		love.graphics.clear(love.graphics.getBackgroundColor())
		love.graphics.setColor(rgba(0xFFF0A3A3))
		love.graphics.setFont(head)
		love.graphics.printf(h, pos, pos, love.graphics.getWidth() - pos)
		love.graphics.setFont(font)
		love.graphics.setColor(rgba(0xFFD2D5D0))
		love.graphics.printf(c, pos, pos + love.window.toPixels(40), love.graphics.getWidth() - pos)
		love.graphics.setColor(rgba(0xFFA2A5A0))
		love.graphics.printf(p, pos, pos + love.window.toPixels(120), love.graphics.getWidth() - pos)
		love.graphics.present()
	end

	local reset = false

	while true do
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return
			elseif e == "keypressed" and a == "f11" then
				love.system.openURL("file://" .. love.filesystem.getSaveDirectory())
			elseif e == "keypressed" and a == "f5" then
				reset = true
				break
			elseif e == "keypressed" and a == "escape" and (love.window.getFullscreen()) then
				return
			elseif e == "keypressed" and a == "escape" then --or e == "mousereleased" then
				local name = love.window.getTitle()
				if #name == 0 then name = "Game" end
				local buttons = {"OK", "Cancel"}
				local pressed = love.window.showMessageBox("Quit?", "Quit "..name.."?", buttons)
				if pressed == 1 then
					return
				end
			end
		end

		if use.hot_reloader and reset then
			break
		end

		draw()

		if love.timer then
			love.timer.sleep(0.1)
		end
	end

	if use.hot_reloader and reset then
		return xpcall(fire.reset_the_world, love.errhand)
	end
end
