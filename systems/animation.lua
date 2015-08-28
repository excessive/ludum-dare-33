return function()
	local tiny = require "tiny"

	local system  = tiny.processingSystem()
	system.filter = tiny.requireAll("anim")

	function system:process(entity, dt)
		if entity.possessed and entity.velocity and entity.anim.current_animation == "swim" then
			entity.anim:update(dt * math.max(entity.velocity:len() / 2.5, 0.5))
		else
			entity.anim:update(dt)
		end
	end

	return system
end
