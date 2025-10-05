--Converts points in viewport pixels to points in actual meters

return function(vs, point_x, point_y)
	local xc = math.floor(love.graphics.getWidth() / 2)
	local yc = math.floor(love.graphics.getHeight() / 2)

	local xoff = point_x - xc
	local yoff = point_y - yc

	return xoff / vs.scale + vs.camera_x, yoff / vs.scale + vs.camera_y
end

