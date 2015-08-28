return function(world, initial)
	local tiny = require "tiny"
	local o = {}
	o.world = world
	if initial then
		world:addSystem(o)
	end
	function o:update()
		error("give me my wallet back")
	end
	return o
end
