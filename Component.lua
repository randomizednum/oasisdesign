--Habitat component class
local Component = {}
Component.__index = Component

local switch = require("switch")
local point = require("point")
local volumes = require("volume")
local state = require("state")

local default_shape = {
	type = "polygon",
	vertices = { --relative to the position
		{ -0.5, -0.5 },
		{ 0.5, -0.5 },
		{ 0.5, 0.5 },
		{ -0.5, 0.5 }
	}
}

function Component.new(position, shape, layer)
	local t = {
		position = assert(position, "No position specified to Component.new"),
		shape = shape or default_shape,
		layer = layer or 1
		--adjacent = {}
	}

	setmetatable(t, Component)
	return t	
end

function Component:draw()
	local h = self.height
	local type = self.component_type

	if h and type then
		local br = math.min(h/2 + 0.5, 1) --brightness

		--How "less" and "more" it is
		local less_amount = math.min(1, math.max(0, 3 * (volumes.volumes[type] - self:area() * h)))
		local more_amount = math.min(1, math.max(0,  self:area() * h - volumes.volumes[type]) / 2)

		love.graphics.setLineWidth(math.min(2, h/4 + 1))

		love.graphics.setColor(
			1 * br,
			(1 - less_amount) * br,
			(1 - less_amount - more_amount) * br
			)
	else
		love.graphics.setColor(1, 1, 1)
	end

	local vs = state.view_settings

	switch(self.shape.type) {
		polygon = function()
			local x, y = self.position[1], self.position[2]

			local verts = self.shape.vertices
			local absolute_verts = {}

			for _, v in ipairs(verts) do
				local rawx, rawy = point(vs, v[1] + x, v[2] + y)
				table.insert(absolute_verts, rawx)
				table.insert(absolute_verts, rawy)
			end
			love.graphics.polygon("line", absolute_verts)
		end,
		default = function(type)
			error("Unknown type " .. tostring(type or "(no type)"))
		end
	}
end

function Component:area()
	if self.shape.area then return self.shape.area end
	if self.shape.type ~= "polygon" then error("Unknown type") end

	local sum = 0
	local verts = self.shape.vertices
	local n = #verts
	for i = 1, n do
		local next = i == n and 1 or i+1

		local nx, ny = verts[next][1], verts[next][2]
		local cx, cy = verts[i][1], verts[i][2]

		sum = sum + (cx - nx)*(cy + ny)
	end

	local area = math.abs(sum) / 2
	self.shape.area = area
	return area
end

function Component:volume()
	return self:area() * self.height
end

return Component
