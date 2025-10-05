--save and load in a human-readable format
--intentionally xml-like BUT NOT XML!! spaces are significant, order is significant, etc.
local sl = {}
local Component = require("Component")

function sl.save(comp)
	local s = "<component>\n"
	s = s .. "<type>" .. comp.component_type .. "</type>\n"
	s = s .. "<x>" .. string.format("%.8f", comp.position[1]) .. "</x>\n"
	s = s .. "<y>" .. string.format("%.8f", comp.position[2]) .. "</y>\n"
	s = s .. "<layer>" .. comp.layer .. "</layer>\n"
	s = s .. "<height>" .. string.format("%.8f", comp.height) .. "</height>\n"
	s = s .. "<polygon>\n"

	for _, v in ipairs(comp.shape.vertices) do
		s = s .. v[1] .. ", " .. v[2] .. "\n"
	end

	s = s .. "</polygon>\n</component>\n"
	return s
end

function sl.load(s)
	local comps = {}
	for comp_s in s:gmatch("<component>\n(.-)</component>") do
		local type_s, x_s, y_s, layer_s, height_s, shape_s = comp_s:match(
			"^<type>(%d+)</type>\n" ..
			"<x>([%-%.%d]+)</x>\n" ..
			"<y>([%-%.%d]+)</y>\n" ..
			"<layer>(%d+)</layer>\n" ..
			"<height>([%-%.%d]+)</height>\n" ..
			"<polygon>(.-)</polygon>"
		)

		assert(type, "loading failed")

		local shape = { type = "polygon", vertices = {} }
		for px_s, py_s in shape_s:gmatch("([%-%.%d]+), ([%-%.%d]+)\n") do
			table.insert(shape.vertices, { tonumber(px_s), tonumber(py_s) })
		end

		local pos = { tonumber(x_s), tonumber(y_s) }
		local comp = Component.new(pos, shape, tonumber(layer_s))
		comp.component_type = tonumber(type_s)
		comp.height = tonumber(height_s)

		table.insert(comps, comp)
	end
	return comps
end

return sl
