--[[
timer utility
]]

local archive = {}
local current = {}
local timer = {}

local function to_ms(time)
	return math.ceil(time / 1000) .. " ms"
end
local function print_sample(sample)
	for k, v in pairs(sample) do
		print("[timer] " .. k .. ": " .. to_ms(v.total))
	end
end
local function print_category(category)
	print("[timer] " .. category.name .. " - min: " .. to_ms(category.min) .. "    max: " .. to_ms(category.max) .. "    avg: " .. to_ms(category.avg))
end
timer.print_summary = function()
	if #archive == 0 then return end
	local sum = {}
	for name, time in pairs(archive[1]) do
		sum[name] = {
			total = 0,
			count = 0,
			min = time.total,
			max = time.total,
			name = name,
		}
	end
	for _, sample in pairs(archive) do
		for name, time in pairs(sample) do
			local category = sum[name]
			if category then
				category.total = category.total + time.total
				category.count = category.count + 1
				if time.total < category.min then category.min = time.total end
				if time.total > category.max then category.max = time.total end
			end
		end
	end
	for _, category in pairs(sum) do
		category.avg = category.total / category.count
		print_category(category)
	end
end
timer.new_sample = function()
	current = {}
end
timer.finish_sample = function()
	-- uncomment this to see timer data for individual chunks
	-- print_sample(current)
	table.insert(archive, current)
end

-- a start|stop for each of a chunks 80*80*80 positions costs ~26 ms just by itself
timer.start = function(name)
	if not current[name] then
		current[name] = {
			total = 0,
			start = nil,
		}
	end
	current[name].start = minetest.get_us_time()
end
timer.stop = function(name)
	current[name].total = current[name].total + (minetest.get_us_time() - current[name].start)
	current[name].start = nil
end


minetest.register_on_shutdown(function()
	timer.print_summary()
end)


return timer
