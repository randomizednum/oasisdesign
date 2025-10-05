--Converts points in actual meters to points in viewport pixels
--vs: view_settings
return function(vs, point_x, point_y)
	local xoff = (point_x - vs.camera_x) * vs.scale
	local yoff = (point_y - vs.camera_y) * vs.scale

	local xc = math.floor(love.graphics.getWidth() / 2)
	local yc = math.floor(love.graphics.getHeight() / 2)
	return xc + xoff, yc + yoff
end
