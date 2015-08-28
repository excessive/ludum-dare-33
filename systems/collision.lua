local tiny = require "tiny"
local cpml = require "cpml"

return function()
	local system   = tiny.processingSystem()
	system.filter  = tiny.requireAll("model", "model_matrix", "colliders", "velocity")

	function system:process(entity, dt)
		for _, other in ipairs(self.entities) do
			if entity ~= other then
				for _, ecollider in ipairs(entity.colliders) do
					for _, ocollider in ipairs(other.colliders) do
						-- compare if ecollider is colliding with ocollider
						local e1, e2 = ecollider.position, ocollider.position
						local m1, m2 = entity.model_matrix, other.model_matrix
						local p1, p2 = m1 * { e1.x, e1.y, e1.z, 1 }, m2 * { e2.x, e2.y, e2.z, 1 }
						p1, p2 = cpml.vec3(p1[1], p1[2], p1[3]), cpml.vec3(p2[1], p2[2], p2[3])

						if p1:dist(p2) <= ecollider.radius + ocollider.radius then
							if not ecollider.hit[ocollider] then
								ecollider.hit[ocollider] = true
								ecollider.collisions     = ecollider.collisions + 1

								if not entity.hit[other] then
									entity.hit[other] = true
									entity.collisions = entity.collisions + 1
								end
							end
						else
							if ecollider.hit[ocollider] then
								ecollider.hit[ocollider] = nil
								ecollider.collisions     = ecollider.collisions - 1

								if entity.hit[other] then
									entity.hit[other] = nil
									entity.collisions = entity.collisions - 1
								end
							end
						end
					end
				end

				if entity.possessed and entity.hit[other] then
					local vel = entity.velocity
					local m   = entity.model_matrix:clone()
					m[13], m[14], m[15] = 0, 0, 0

					local v = m * { vel.x, vel.y, vel.z, 1 }
					vel = cpml.vec3(v[1], v[2], v[3])

					if other.hp and other.hp > 0 then
						local poke = math.ceil(other.hp - math.abs(vel.y))
						other.hp = cpml.utils.clamp(poke, 0, other.max_hp)

						local ouch = math.abs(vel.y) >= 5 and true or false
						self.world.conversation:say("attacked", other, ouch)
					end

					-- this is gonna break as fuck
					other.velocity.x = other.velocity.x + vel.x / 2
					other.velocity.y = other.velocity.y + vel.y / 2
					other.velocity.z = other.velocity.z + vel.z / 2

					entity.velocity.x = entity.velocity.x / 2
					entity.velocity.y = entity.velocity.y / 2
					entity.velocity.z = entity.velocity.z / 2
				end
			end
		end
	end

	return system
end
