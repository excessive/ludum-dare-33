return function(world, initial)
	local exit = {}
	exit.world = world
	-- why would you do this to exit?
	if initial then
		world:addSystem(exit)
	end
	function exit:update()
		love.event.quit()
	end
	return exit
end
