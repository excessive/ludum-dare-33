--[[
	MeshGraph, a library to draw meshes as graphs.

	@TODOS: a whole bunch of stuff
	* canvas optimization?
	* can't relocate, changes must propagate through the entire list of points
]]

local cpml = require "cpml"

local LineGraph = {}
LineGraph.__index = LineGraph

local function new(x, y, width)
	local t = setmetatable({}, LineGraph)
	t:initialize(x, y, width)
	return t
end

function LineGraph:initialize(x, y, width, height, max, target)
	-- == location
	self.x      = x or 400
	self.y      = y or 500
	self.width  = width or 100
	self.height = height or 100
	self.max    = max or 1/30
	self.target = target or 1 / select(3, love.window.getMode()).refreshrate

	-- == update info
	self.delay = self.target
	self.points = self.width
	self.pointSpacing = self.width / self.points

	-- == draw options
	self.graphColor = {50, 50, 255, 255}
	self.font = love.graphics.newFont("assets/fonts/NotoSans-Regular.ttf", 12)

	-- == internal values
	self.average = 0
	self.verts = {}

	-- fill out the points with initial values for visibility
	for i=1,(self.points)*2,2 do
		self.verts[i] = self.x + i*self.pointSpacing
		self.verts[i+1] = self.y - i
	end

	-- call the police, I have a number that never stops growing integer
	-- (this could probably be gotten from the x value of the last vertex or something)
	--self.valuesRecorded = 0
	self.currentTime = 0
end

function LineGraph:getValues(dt, reps)
	-- if our update rate somehow stalls us for more than a single reporting period,
	-- pad the graph by reporting the same FPS we had previously
	reps = reps or 0
	local retVals = {}
	for i=1,reps do
		--uncomment for more useful statistics
		--table.insert(retVals, love.timer.getAverageDelta()*1000*30)
		-- table.insert(retVals, love.timer.getFPS())
		table.insert(retVals, love.timer.getDelta())
	end
	-- not averaging these could probably make things look inaccurate in the event of immense lag
	return retVals, love.timer.getAverageDelta()
end

function LineGraph:updateClock(dt)
	self.currentTime = self.currentTime + dt
	local reps = math.floor(self.currentTime/self.delay)
	self.currentTime = self.currentTime - self.delay*reps

	return reps
end

function LineGraph:update(dt)
	-- update the current time of the graph
	local reps = self:updateClock(dt)

	-- get values, we pass dt & reps for the sake of the program
	local newVals, average = self:getValues(dt, reps)
	self.average = average

	if newVals and #newVals > 0 then
		-- add any new values as verts

		--[[
			shift the Y values back a single position
			start at the Nth+1 Y, to prevent nestling loops
		]]
		for j=2+(#newVals*2),self.points*2,2 do
			self.verts[j-2] = self.verts[j]
		end
		--[[
			the verts table contains twice as many entries as we do points
			get to the end, step back by X values * 2 to align ourself to the actual "point"
			we do not need to add or subtract because this aligns us with the final value

			invert the value because our Y is flipped
		]]
		for i=1,#newVals do
			self.verts[self.points*2 - (i-1)*2] = self.y - cpml.utils.map(
				newVals[i], 0, self.max, 0, self.height
			)
		end
	end
end

-- draws all the graphs in your list
function LineGraph:draw(dt)
	local function remap(v)
		return cpml.utils.map(
			v, 0, self.max, 0, self.height
		)
	end
	love.graphics.setColor(0, 0, 0, 150)
	love.graphics.rectangle("fill", self.x, self.y - self.height, self.width * 2, self.height)
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.line(self.x, self.y - remap(self.target), self.x + self.width * 2, self.y - remap(self.target))
	love.graphics.setColor(0, 127, 0, 255)
	love.graphics.line(self.x, self.y - remap(self.average), self.x + self.width * 2, self.y - remap(self.average))
	love.graphics.setColor(self.graphColor)
	love.graphics.line(self.verts)

	love.graphics.setFont(self.font)
	love.graphics.setColor(127, 127, 255, 255)
	love.graphics.print(string.format("%2.3fms", love.timer.getDelta()*1000), self.x + 5, self.y - self.height + 5)
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.print(string.format("%2.3fms", self.target*1000), self.x + 85, self.y - self.height + 5)
	love.graphics.setColor(0, 127, 0, 255)
	love.graphics.print(string.format("%2.3fms", self.average*1000), self.x + 165, self.y - self.height + 5)
end

return setmetatable({new=new}, {__call=function(_,...) return new(...) end})
