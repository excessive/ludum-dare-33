local console = {
	_LICENSE = [[
		The MIT License (MIT)

		Copyright (c) 2014 Maciej Lopacinski

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	]],
	_VERSION          = 'love-console v0.2.0',
	_DESCRIPTION      = 'Simple Love2D console overlay',
	_URL              = 'https://github.com/hamsterready/love-console',
	_KEY_TOGGLE       = "`",
	_KEY_SUBMIT       = "return",
	_KEY_CLEAR        = "escape",
	_KEY_BACKSPACE    = "backspace",
	_KEY_DELETE       = "delete",
	_KEY_UP           = "up",
	_KEY_DOWN         = "down",
	_KEY_PAGEDOWN     = "pagedown",
	_KEY_PAGEUP       = "pageup",
	_KEY_LINE_BEGIN   = "home",
	_KEY_LINE_END     = "end",
	_KEY_CURSOR_LEFT  = "left",
	_KEY_CURSOR_RIGHT = "right",

	visible = false,
	delta = 0,
	logs = {},
	history = {},
	historyPosition = 0,
	linesPerConsole = 0,
	fontSize = 20,
	font = nil,
	firstLine = 0,
	lastLine = 0,
	cursor = 0,
	input = "",
	ps = "> ",
	height_divisor = 1.5,
	motd = "Greetings, traveler!\nType \"help\" for an index of available commands.",

	-- This table has as its keys the names of commands as
	-- strings, which the user must type to run the command. The
	-- values are themselves tables with two properties:
	--
	-- 1. 'description' A string of information to show via the
	-- /help command.
	--
	-- 2. 'implementation' A function implementing the command.
	--
	-- See the function defineCommand() for examples of adding
	-- entries to this table.
	commands = {}
}

-- From: https://raw.githubusercontent.com/alexander-yakushev/awesompd/master/utf8.lua
local utf8 = {}

function utf8.charbytes (s, i)
	-- argument defaults
	i = i or 1
	local c = string.byte(s, i)

	-- determine bytes needed for character, based on RFC 3629
	if c > 0 and c <= 127 then
		-- UTF8-1
		return 1
	elseif c >= 194 and c <= 223 then
		-- UTF8-2
		local c2 = string.byte(s, i + 1)
		return 2
	elseif c >= 224 and c <= 239 then
		-- UTF8-3
		local c2 = s:byte(i + 1)
		local c3 = s:byte(i + 2)
		return 3
	elseif c >= 240 and c <= 244 then
		-- UTF8-4
		local c2 = s:byte(i + 1)
		local c3 = s:byte(i + 2)
		local c4 = s:byte(i + 3)
		return 4
	end
end

-- returns the number of characters in a UTF-8 string
function utf8.len (s)
	local pos = 1
	local bytes = string.len(s)
	local len = 0
	while pos <= bytes and len ~= chars do
		local c = string.byte(s,pos)
		len = len + 1

		pos = pos + utf8.charbytes(s, pos)
	end
	if chars ~= nil then
		return pos - 1
	end
	return len
end

-- functions identically to string.sub except that i and j are UTF-8 characters
-- instead of bytes
function utf8.sub(s, i, j)
	j = j or -1
	if i == nil then
		return ""
	end
	local pos = 1
	local bytes = string.len(s)
	local len = 0
	-- only set l if i or j is negative
	local l = (i >= 0 and j >= 0) or utf8.len(s)
	local startChar = (i >= 0) and i or l + i + 1
	local endChar = (j >= 0) and j or l + j + 1
	-- can't have start before end!
	if startChar > endChar then
		return ""
	end
	-- byte offsets to pass to string.sub
	local startByte, endByte = 1, bytes
	while pos <= bytes do
		len = len + 1
		if len == startChar then
	 		startByte = pos
		end
		pos = pos + utf8.charbytes(s, pos)
		if len == endChar then
	 		endByte = pos - 1
	 		break
		end
	end
	return string.sub(s, startByte, endByte)
end

-- used to draw the arrows
local function up(x, y, w)
	w = w * .7
	local h = w * .7
	return {
		x, y + h,
		x + w, y + h,
		x + w/2, y
	}
end

local function down(x, y, w)
	w = w * .7
	local h = w * .7
	return {
		x, y,
		x + w, y,
		x + w/2, y + h
	}
end

local function toboolean(v)
	return (type(v) == "string" and v == "true") or (type(v) == "string" and v == "1") or (type(v) == "number" and v ~= 0) or (type(v) == "boolean" and v)
end

-- http://lua-users.org/wiki/StringTrim trim2
local function trim(s)
	s = s or ""
	return s:match "^%s*(.-)%s*$"
end

-- http://wiki.interfaceware.com/534.html
local function string_split(s, d)
	local t = {}
	local i = 0
	local f
	local match = '(.-)' .. d .. '()'

	if string.find(s, d) == nil then
		return {s}
	end

	for sub, j in string.gmatch(s, match) do
		i = i + 1
		t[i] = sub
		f = j
	end

	if i ~= 0 then
		t[i+1] = string.sub(s, f)
	end

	return t
end

local function merge_quoted(t)
	local ret = {}
	local merging = false
	local buf = ""
	for k, v in ipairs(t) do
		local f, l = v:sub(1,1), v:sub(v:len())
		if f == "\"" and l ~= "\"" then
			merging = true
			buf = v
		else
			if merging then
				buf = buf .. " " .. v
				if l == "\"" then
					merging = false
					table.insert(ret, buf:sub(2,-2))
				end
			else
				if f == "\"" and l == f then
					table.insert(ret, v:sub(2, -2))
				else
					table.insert(ret, v)
				end
			end
		end
	end
	return ret
end

function console.load(font, keyRepeat, inputCallback)
	love.keyboard.setKeyRepeat(keyRepeat or false)

	console.font		= font or love.graphics.newFont(console.fontSize)
	console.fontSize	= font and font:getHeight() or console.fontSize
	console.margin		= console.fontSize
	console.lineSpacing	= 1.25
	console.lineHeight	= console.fontSize * console.lineSpacing
	console.x, console.y = 0, 0

	console.colors = {}
	console.colors["I"] = {r = 251, g = 241, b = 213, a = 255}
	console.colors["D"] = {r = 235, g = 197, b =  50, a = 255}
	console.colors["E"] = {r = 222, g =  69, b =  61, a = 255}
	console.colors["C"] = {r = 150, g = 150, b = 150, a = 255}
	console.colors["P"] = {r = 200, g = 200, b = 200, a = 255}

	console.colors["background"] = {r = 23, g = 55, b = 86, a = 240}
	console.colors["editing"]    = {r = 80, g = 140, b = 200, a = 200}
	console.colors["input"]      = {r = 23, g = 55, b = 86, a = 255}
	console.colors["default"]    = {r = 215, g = 213, b = 174, a = 255}

	console.inputCallback = inputCallback or console.defaultInputCallback

	console.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

function console.newHotkeys(toggle, submit, clear, backspace, delete, left, right)
	console._KEY_TOGGLE = toggle or console._KEY_TOGGLE
	console._KEY_SUBMIT = submit or console._KEY_SUBMIT
	console._KEY_CLEAR = clear or console._KEY_CLEAR
	console._KEY_BACKSPACE = backspace or console._KEY_BACKSPACE
	console._KEY_DELETE = delete or console._KEY_DELETE
	console._KEY_CURSOR_LEFT = left or console._KEY_CURSOR_LEFT
	console._KEY_CURSOR_RIGHT = right or console._KEY_CURSOR_RIGHT
end

function console.setMotd(message)
	console.motd = message
end

function console.resize(w, h)
	console.w, console.h = w, h / console.height_divisor
	console.y = console.lineHeight - console.lineHeight * console.lineSpacing

	console.linesPerConsole = math.floor((console.h - console.margin * 2) / console.lineHeight) - 1

	console.h = math.floor(console.linesPerConsole * console.lineHeight + console.margin * 2)

	console.firstLine = console.lastLine - console.linesPerConsole
	console.lastLine = console.firstLine + console.linesPerConsole
end

local function get_position()
	local prefix = console.ps .. " "
	local x = console.x + console.margin + console.font:getWidth(prefix)
	local y = console.y + console.h + (console.lineHeight - console.fontSize) / 2 -1
	local h = console.font:getHeight()
	local text_l = utf8.sub(console.input, 1, console.cursor)
	local text_r = utf8.sub(console.input, console.cursor+1, -1)
	local pos = x + console.font:getWidth(text_l)
	local w = console.w - x - 3
	return pos, y, w, h
end

local function start_editing()
	local x, y, w, h = get_position()
	love.keyboard.setTextInput(console.visible, x, y, w, h)
	love.keyboard.setKeyRepeat(true)
end

local function stop_editing()
	console.editBuffer = nil
	love.keyboard.setTextInput(false)
	love.keyboard.setKeyRepeat(false)
end

local function update_ime()
	start_editing()
end

-- 0.9 compat
-- function console.textedit(...)
-- 	return console.textedited(...)
-- end

function console.textedited(t, s, l)
	if not console.visible then
		return
	end
	if t == "" then
		console.editBuffer = nil
	else
		console.editBuffer = { text = t, sel = s }
	end
	update_ime()
end

function console.focus(f)
	if not console.visible then
		return
	end
	if f then
		stop_editing()
		start_editing()
	else
		stop_editing()
	end
end

function console.textinput(t)
	if t ~= console._KEY_TOGGLE and console.visible then
		local text_l = utf8.sub(console.input, 1, console.cursor)
		local text_r = utf8.sub(console.input, console.cursor+1, -1)
		console.input = text_l .. t .. text_r
		console.cursor = console.cursor + utf8.len(t)
		update_ime()
		return true
	end
	return false
end

function console.keypressed(key)
	local function push_history(input)
		local trimmed = trim(console.input)
		local valid = trimmed ~= ""
		if valid then
			table.insert(console.history, trimmed)
			console.historyPosition = #console.history+1
		end
		console.input = ""
		return valid
	end
	if key ~= console._KEY_TOGGLE and console.visible then
		if key == console._KEY_SUBMIT and not console.editBuffer then
			local msg = console.input
			if push_history() then
				console.cursor = 0
				console.inputCallback(msg)
			end
		elseif key == console._KEY_CLEAR then
			console.historyPosition = #console.history+1
			console.cursor = 0
			console.input = ""
			update_ime()
		elseif key == console._KEY_LINE_BEGIN then
			console.cursor = 0
			update_ime()
		elseif key == console._KEY_LINE_END then
			console.cursor = utf8.len(console.input)
			update_ime()
		elseif key == console._KEY_BACKSPACE and not console.editBuffer then
			local text_l = utf8.sub(console.input, 1, console.cursor-1)
			local text_r = utf8.sub(console.input, console.cursor+1, -1)
			console.input = text_l .. text_r
			console.cursor = math.max(console.cursor - 1, 0)
			update_ime()
		elseif key == console._KEY_DELETE then
			local text_l = utf8.sub(console.input, 1, console.cursor)
			local text_r = utf8.sub(console.input, console.cursor+2, -1)
			console.input = text_l .. text_r
			update_ime()
		end

		-- TODO: Functable for multiple hotkeys on same action...
		if ((love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) and key == "v") or
		   ((love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) and key == "insert") then
			console.textinput(love.system.getClipboardText())
			update_ime()
		end

		-- history traversal
		if #console.history > 0 then
			if key == console._KEY_UP then
				console.historyPosition = math.max(console.historyPosition - 1, 1)
				console.input = console.history[console.historyPosition] or ""
			elseif key == console._KEY_DOWN then
				local pushing = console.historyPosition + 1 == #console.history + 1
				console.historyPosition = math.min(console.historyPosition + 1, #console.history+1)
				console.input = console.history[console.historyPosition] or ""
				if pushing then
					console.input = ""
				end
			end
		end

		if key == console._KEY_CURSOR_LEFT then
			console.cursor = math.max(console.cursor - 1, 0)
			update_ime()
		elseif key == console._KEY_CURSOR_RIGHT then
			console.cursor = math.min(console.cursor + 1, utf8.len(console.input))
			update_ime()
		end

		if key == console._KEY_PAGEUP then
			console.firstLine = math.max(0, console.firstLine - console.linesPerConsole)
			console.lastLine = console.firstLine + console.linesPerConsole
		elseif key == console._KEY_PAGEDOWN then
			console.firstLine = math.min(console.firstLine + console.linesPerConsole, #console.logs - console.linesPerConsole)
			console.lastLine = console.firstLine + console.linesPerConsole
		end

		return true
	elseif key == console._KEY_TOGGLE then
		-- IME support stuff.
		if console.visible and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")) then
			return true
		end
		console.visible = not console.visible
		if console.visible then start_editing() else stop_editing() end
		return true
	end
	return false
end

function console.update(dt)
	console.delta = console.delta + dt
end

function console.draw()
	if not console.visible then
		return
	end

	-- backup
	local r, g, b, a = love.graphics.getColor()
	local font = love.graphics.getFont()

	-- draw console
	local color = console.colors.background
	love.graphics.setColor(color.r, color.g, color.b, color.a)
	love.graphics.rectangle("fill", console.x, console.y, console.w, console.h)
	color = console.colors.input
	love.graphics.setColor(color.r, color.g, color.b, color.a)
	love.graphics.rectangle("fill", console.x, console.y + console.h, console.w, console.lineHeight)
	color = console.colors.default
	love.graphics.setColor(color.r, color.g, color.b, color.a)
	love.graphics.setFont(console.font)
	local prefix = console.ps .. " "
	local x, y = console.x + console.margin, console.y + console.h + (console.lineHeight - console.fontSize) / 2 -1
	love.graphics.print(prefix, x, y)
	x = x + console.font:getWidth(prefix)

	local current = console.input
	local h = console.font:getHeight()
	local text_l = utf8.sub(console.input, 1, console.cursor)
	local text_r = utf8.sub(console.input, console.cursor+1, -1)
	local cursor_pos = console.font:getWidth(text_l)
	love.graphics.print(text_l, x, y)
	if console.editBuffer then
		local pos = console.font:getWidth(text_l)
		local buf = console.editBuffer
		local w = console.font:getWidth(buf.text)
		local edit = console.colors.editing
		-- love.keyboard.setTextInput(true, pos, y, w, h) -- NOTE: Added in Love 0.10
		love.graphics.setColor(edit.r, edit.g, edit.b, edit.a)
		love.graphics.rectangle("fill", x + pos, y, w, h)
		love.graphics.setColor(color.r, color.g, color.b, color.a)
		love.graphics.print(buf.text, x + pos, y)
		x = x + console.font:getWidth(buf.text)
	end
	love.graphics.print(text_r, x + console.font:getWidth(text_l), y)
	if math.floor(console.delta * 2) % 2 == 0 then
		love.graphics.setColor(color.r, color.g, color.b, color.a)
	else
		love.graphics.setColor(color.r, color.g, color.b, 0)
	end
	love.graphics.rectangle("fill", x + cursor_pos, y, 2, h)
	love.graphics.setColor(255, 0, 0, 255)
	-- local a, b, c, d = get_position()
	-- print(a, b, c, d)
	-- love.graphics.rectangle("fill", a, b, c, d)

	love.graphics.setColor(color.r, color.g, color.b, color.a)
	if console.firstLine > 0 then
		love.graphics.polygon("fill", up(console.x + console.w - console.margin - (console.margin * 0.3), console.y + console.margin, console.margin))
	end

	if console.lastLine < #console.logs then
		love.graphics.polygon("fill", down(console.x + console.w - console.margin - (console.margin * 0.3), console.y + console.h - console.margin, console.margin))
	end

	for i, t in pairs(console.logs) do
		if i > console.firstLine and i <= console.lastLine then
			local color = console.colors[t.level]
			love.graphics.setColor(color.r, color.g, color.b, color.a)
			love.graphics.print(t.msg, console.x + console.margin, console.y + (i - console.firstLine)*console.lineHeight)
		end
	end

	-- rollback
	love.graphics.setFont(font)
	love.graphics.setColor(r, g, b, a)
end

local function in_window(x, y)
	if not (x >= console.x and x <= (console.x + console.w)) then
		return false
	end
	if not (y >= console.y and y <= (console.y + console.h + console.lineHeight)) then
		return false
	end
	return true
end

-- eat all mouse events over the console
function console.mousemoved(x, y, rx, ry)
	if not console.visible then
		return false
	end

	local x, y = love.mouse.getPosition()

	if not in_window(x, y) then
		return false
	end

	return true
end

function console.wheelmoved(wx, wy)
	if not console.visible then
		return false
	end

	local x, y = love.mouse.getPosition()

	if not in_window(x, y) then
		return false
	end

	local consumed = false

	if wy == 1 then
		console.firstLine = math.max(0, console.firstLine - 1)
		consumed = true
	end

	if wy == -1 then
		console.firstLine = math.min(#console.logs - console.linesPerConsole, console.firstLine + 1)
		consumed = true
	end
	console.lastLine = console.firstLine + console.linesPerConsole

	return consumed
end

function console.mousepressed(x, y, button)
	if not console.visible then
		return false
	end

	if not in_window(x, y) then
		return false
	end

	return true
end

local function tagged_print(tag, fmt, ...)
	local str = tostring(fmt)
	if select("#", ...) > 0 then
		str = string.format(fmt, ...)
	end
	a(tostring(str), tag:upper())
end

local function debug_tagged_print(tag, fmt, ...)
	local str = tostring(fmt)
	local info = debug.getinfo(3, "nSl")
	if select("#", ...) > 0 then
		str = string.format(fmt, ...)
	end
	local add
	if info.name then
		add = string.format("[%s#%s:%d] ", info.short_src, info.name, info.currentline)
	else
		add = string.format("[%s:%d] ", info.short_src, info.currentline)
	end
	str = add .. str
	a(tostring(str), tag:upper())
end

-- server debug provides line info itself
function console.ds(fmt, ...) tagged_print("d", fmt, ...) end
function console.is(fmt, ...) tagged_print("i", fmt, ...) end
function console.es(fmt, ...) tagged_print("e", fmt, ...) end

-- normal prints
function console.d(fmt, ...) debug_tagged_print("d", fmt, ...) end
function console.i(fmt, ...) tagged_print("i", fmt, ...) end
function console.e(fmt, ...)
	debug_tagged_print("e", fmt, ...)
	console.visible = true
end

function console.clearCommand(name)
	console.commands[name] = nil
end

function console.defineCommand(name, description, implementation, hidden)
	console.commands[name] = {
		description = description,
		implementation = implementation,
		hidden = hidden or false
	}
end

-- private stuff

console.defineCommand(
	"help",
	"Shows information on all commands.",
	function ()
		console.i("Available commands are:")
		for name,data in pairs(console.commands) do
			if not data.hidden then
				console.i(string.format("  %s - %s", name, data.description))
			end
		end
	end
)

console.defineCommand(
	"quit",
	"Quits your application.",
	function () love.event.quit() end
)

console.defineCommand(
	"clear",
	"Clears the console.",
	function ()
		console.firstLine = 0
		console.lastLine = 0
		console.logs = {}
	end
)

console.defineCommand(
	"sv_cheats",
	"~It is a mystery~",
	function(enable)
		local change = toboolean(dopefish)
		dopefish = toboolean(enable)
		change = dopefish ~= change
		if not change then
			console.e("No change")
			return
		end
		if dopefish then
			console.e("The rain in spain stays mainly in the plain.")
		else
			console.i("How now brown cow.")
		end
	end,
	true
)

console.defineCommand(
	"motd",
	"Shows/sets the intro message.",
	function(motd)
		if motd then
			console.motd = motd
			console.i("Motd updated.")
		else
			console.i(console.motd)
		end
	end
)

console.defineCommand(
	"flush",
	"Flush console history to disk",
	function(file)
		if file then
			local t = love.timer.getTime()

			love.filesystem.write(file, "")
			local buffer = ""
			local lines = 0
			for _, v in ipairs(console.logs) do
				buffer = buffer .. v.msg .. "\n"
				lines = lines + 1
				if lines >= 2048 then
					love.filesystem.append(file, buffer)
					lines = 0
					buffer = ""
				end
			end
			love.filesystem.append(file, buffer)

			t = love.timer.getTime() - t
			console.i(string.format("Successfully flushed console logs to \"%s\" in %fs.", love.filesystem.getSaveDirectory() .. "/" .. file, t))
		else
			console.e("Usage: flush <filename>")
		end
	end
)

function console.hasCommand(name)
	return console.commands[name] ~= nil
end

function console.invokeCommand(name, ...)
	local args = {...}
	if console.commands[name] ~= nil then
		local status, error = pcall(function()
			console.commands[name].implementation(unpack(args))
		end)
		if not status then
			console.es(error)
			console.es(debug.traceback())
		end
	else
		console.es("Command \"" .. name .. "\" not supported, type help for help.")
	end
end

function console.defaultInputCallback(input)
	local commands = string_split(input, ";")
	a(input, 'C')

	for _, line in ipairs(commands) do
		local args = merge_quoted(string_split(trim(line), " "))
		local name = args[1]
		table.remove(args, 1)
		console.invokeCommand(name, unpack(merge_quoted(args)))
	end
end

local original_print = print

function a(str, level)
	str = tostring(str)
	for _, str in ipairs(string_split(str, "\n")) do
		local msg = string.format("%07.02f [".. level .. "] %s", console.delta, str)
		-- XXX: This is totally inflexible.
		if level == "C" then
			msg = string.format("%07.02f -> %s", console.delta, str)
		end
		table.insert(console.logs, #console.logs + 1, {level = level, msg = msg})
		if #console.logs > 512 then
			table.remove(console.logs, 1)
		end
		console.lastLine = #console.logs
		console.firstLine = console.lastLine - console.linesPerConsole
		original_print(msg)
	end
end

print = function(...)
	local str = ""
	local num = select("#", ...)
	for i = 1, num do
		str = str .. tostring(select(i, ...))
		if i < num then
			local len = utf8.len(str) + 1
			local tab = 8
			str = str .. string.rep(" ", tab - len % tab)
		end
	end
	tagged_print("p", str)
end

-- auto-initialize so that console.load() is optional
if love.window and love.window.isOpen() then
	console.load()
end
console.is(console.motd)

return console
