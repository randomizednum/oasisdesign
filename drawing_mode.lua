local drawing_mode = {}
local depoint = require("depoint")
local point = require("point")
local Component = require("Component")
local state = require("state")

drawing_mode.enabled = false
drawing_mode.height_component = nil --the component to set the height of
drawing_mode.current_type = 0 --the type of the component
drawing_mode.sequence = {}

local function adapt_seq(cx, cy)
	local t = {}
	for i, v in ipairs(drawing_mode.sequence) do
		t[i] = { v[1] - cx, v[2] - cy }	
	end
	return t
end

local function finalize()
	local approx_x = 0
	local approx_y = 0

	local n = #drawing_mode.sequence
	for _, v in ipairs(drawing_mode.sequence) do
		approx_x = approx_x + v[1] / n
		approx_y = approx_y + v[2] / n
	end

	local pos = { approx_x, approx_y }
	local shape = { type = "polygon", vertices = adapt_seq(approx_x, approx_y) }
	return Component.new(pos, shape, state.current_layer)
end

function drawing_mode.add(p) --adds a point
	local vs = assert(state.view_settings, "No view settings in drawing mode module")
	local x, y = depoint(vs, p[1], p[2])

	local hcomp = drawing_mode.height_component
	if hcomp then
		assert(hcomp.shape.type == "polygon")
		local height = (hcomp.shape.vertices[1][2] + hcomp.position[2]) - y
		if height > 0 then
			hcomp.height = height
			hcomp.component_type = drawing_mode.current_type
			drawing_mode.height_component = nil
		end
		return
	end

	if not drawing_mode.enabled then
		drawing_mode.current_type = 0
		drawing_mode.enabled = true
	end

	local first = drawing_mode.sequence[1]
	if first then
		local vx, vy = point(vs, first[1], first[2])
		if (p[1] - vx)^2 + (p[2] - vy)^2 <= 15^2 then
			if #drawing_mode.sequence <= 2 then
				drawing_mode.cancel()
				return
			end

			local v = finalize()
			drawing_mode.sequence = {}
			drawing_mode.enabled = false
			drawing_mode.height_component = v
			--print("created component with area", v:area())
			return v
		end
	end

	table.insert(drawing_mode.sequence, {x, y})
end

function drawing_mode.cancel()
	if drawing_mode.height_component then
		drawing_mode.height_component.layer = -1 --mark deleted
		drawing_mode.height_component = nil
	end

	drawing_mode.sequence = {}
	drawing_mode.enabled = false
end

function drawing_mode.display_partial()
	love.graphics.setLineWidth(1)

	local mx, my = love.mouse.getPosition()
	local vs = assert(state.view_settings, "No view settings in drawing mode module")
	local hcomp = drawing_mode.height_component
	if hcomp then
		love.graphics.setColor(0, 0.5, 1)
		local compx = hcomp.shape.vertices[1][1] + hcomp.position[1]
		local compy = hcomp.shape.vertices[1][2] + hcomp.position[2]

		local _, plane_my = depoint(vs, mx, my)
		hcomp.height = math.max(0, compy - plane_my)
		hcomp.component_type = drawing_mode.current_type

		local vcompx, vcompy = point(vs, compx, compy)
		love.graphics.line(vcompx, vcompy, vcompx, my)
		return
	end

	if not drawing_mode.enabled then return end
	love.graphics.setColor(0, 1, 0)

	for i = 2, #drawing_mode.sequence do
		local cx, cy = point(vs, unpack(drawing_mode.sequence[i])) --current
		local px, py = point(vs, unpack(drawing_mode.sequence[i-1])) --previous
		love.graphics.line(px, py, cx, cy)
	end
	love.graphics.setColor(0.5, 0.5, 0.5)

	local last = drawing_mode.sequence[#drawing_mode.sequence]
	local lx, ly = point(vs, unpack(last))

	love.graphics.line(lx, ly, mx, my)
end

return drawing_mode
