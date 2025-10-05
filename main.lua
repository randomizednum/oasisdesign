local Component = require("Component")
local switch = require("switch")
local drawing_mode = require("drawing_mode")
local point = require("point")
local depoint = require("depoint")
local state = require("state")
local volumes = require("volume")
local sl = require("save")

local components = {}

function love.load()
	love.window.setTitle("OasisDesign")
	love.window.setMode(800, 600, {
		resizable = true
	})

	if arg[2] then
		local f = io.open(arg[2], "r")
		if f then
			local s = f:read("*a")
			components = sl.load(s)
			f:close()
		end
	end
end

function love.quit()
	if arg[2] then
		local f = io.open(arg[2], "w")
		for _, v in ipairs(components) do
			if v.layer > 0 then
				f:write(sl.save(v))
			end
		end
		f:close()
	end
end

function love.mousepressed(mx, my, button)
	switch(button) {
		[1] = function()
			local v = drawing_mode.add({mx, my})
			if v then
				table.insert(components, v)
			end
		end,
		[2] = function()
			drawing_mode.current_type = (drawing_mode.current_type + 1) % 18
		end,
		default = function() end
	}
end

function love.mousemoved(_, _, dx, dy)
	local vs = state.view_settings
	if love.mouse.isDown(3) then
--		local mx, my = love.mouse.getPosition()
--		local vx, vy = depoint(vs, mx, my)
		vs.camera_x = vs.camera_x - dx / vs.scale
		vs.camera_y = vs.camera_y - dy / vs.scale
	end
end

function love.keypressed(key)
	local lyr = state.current_layer
	switch(key) {
		up = function()
			state.current_layer = lyr + 1
		end,
		down = function()
			if lyr == 1 then return end
			state.current_layer = lyr - 1
		end,
		escape = drawing_mode.cancel,
		default = function() end
	}
end

local MOVE_RATE = 100
function love.update(dt)
	local vs = state.view_settings

	if love.keyboard.isDown("w") --[[or love.keyboard.isDown("up")]] then
		vs.camera_y = vs.camera_y - MOVE_RATE/vs.scale * dt
	end

	if love.keyboard.isDown("s") --[[or love.keyboard.isDown("down")]] then
		vs.camera_y = vs.camera_y + MOVE_RATE/vs.scale * dt
	end

	if love.keyboard.isDown("d") --[[or love.keyboard.isDown("right")]] then
		vs.camera_x = vs.camera_x + MOVE_RATE/vs.scale * dt
	end

	if love.keyboard.isDown("a") --[[or love.keyboard.isDown("left")]] then
		vs.camera_x = vs.camera_x - MOVE_RATE/vs.scale * dt
	end
end

function love.wheelmoved(x, y)
	local vs = state.view_settings
	vs.scale = vs.scale * 1.25^y
end

function love.draw()
	--Grids
	love.graphics.setLineWidth(1)
	love.graphics.setColor(0.25, 0.25, 0.25)
	local gx, gy = depoint(state.view_settings, 0, 0)

	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	for xval = math.ceil(gx), math.huge do
		local viewport_x = point(state.view_settings, xval, gy)
		if viewport_x >= w then break end
		love.graphics.line(viewport_x, 0, viewport_x, h)
	end
	for yval = math.ceil(gy), math.huge do
		local _, viewport_y = point(state.view_settings, gx, yval)
		if viewport_y >= h then break end
		love.graphics.line(0, viewport_y, w, viewport_y)
	end

	--Components
	for _, v in ipairs(components) do
		if v.layer == state.current_layer then
			v:draw()
		end
	end

	--Drawing stuff
	drawing_mode.display_partial()

	--Status
	love.graphics.setColor(1, 1, 1)
	local stat_s = "Current layer: " .. state.current_layer ..
		"\n[Up arrow] to move up a layer" ..
		"\n[Down arrow] to move down a layer" ..
		"\n[Wheel up] to zoom in" ..
		"\n[Wheel down] to zoom out" ..
		"\n[Middle click] to pan"
	if drawing_mode.enabled then
		stat_s = stat_s .. "\n\nDrawing component\n[Esc] to cancel\n"
	elseif not drawing_mode.height_component then
		stat_s = stat_s .. "\n[Left click] to begin drawing"
	end

	local hcomp = drawing_mode.height_component
	if hcomp then
		local area = hcomp:area()
		local h = hcomp.height or 0
		local type = drawing_mode.current_type
		stat_s = stat_s .. "\n\nComponent:\n    Area: " .. area .. " m²" ..
			"\n    Volume: " .. area * h .. " m³" ..
			"\n    Height: " .. h .. " m" ..
			"\n    Type: " .. volumes.names[type] .. " (" .. type+1 .. ")" ..
			"\n        Ideal volume: " .. volumes.volumes[type] .. " m³" ..
			"\n[Left click] to finalize" ..
			"\n[Right click] to change type" ..
			"\n[Esc] to cancel"
	end
	love.graphics.print(stat_s)
end
