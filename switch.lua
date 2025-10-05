return function(v)
	return function(t)
		if t[v] then return t[v](v)
		elseif t.default then return t.default(v)
		else error("Invalid value in switch")
		end
	end
end
