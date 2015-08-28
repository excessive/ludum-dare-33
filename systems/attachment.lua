local tiny = require "tiny"
local cpml = require "cpml"

return function()
	local system   = tiny.processingSystem()
	system.filter  = tiny.requireAll("attachment")

	function system:process(entity, dt)
		local m = entity.attachment.model_matrix
		if m then
			entity.parent_matrix = m
		end
	end

	return system
end
