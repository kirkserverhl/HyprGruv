--- @since 26.1.22
-- Paint #hex / rgb() color literals with their actual background color.

local M = {}

local function fail(job, s)
	ya.preview_widget(job, ui.Text.parse(s):area(job.area):wrap(ui.Wrap.YES))
end

local function is_hex_token(token)
	local n = #token - 1
	return n == 3 or n == 4 or n == 6 or n == 8
end

local function is_word_end(ch)
	return ch == "" or not ch:match("[%w_]")
end

local function hex_to_rgb6(token)
	local h = token:sub(2)
	if #h == 3 or #h == 4 then
		local r, g, b = h:sub(1, 1), h:sub(2, 2), h:sub(3, 3)
		return "#" .. r .. r .. g .. g .. b .. b
	end
	return "#" .. h:sub(1, 6)
end

local function channel(value)
	if value:sub(-1) == "%" then
		local n = tonumber(value:sub(1, -2))
		if not n then
			return nil
		end
		return math.max(0, math.min(255, math.floor(n * 2.55 + 0.5)))
	end
	local n = tonumber(value)
	if not n then
		return nil
	end
	return math.max(0, math.min(255, math.floor(n)))
end

local function rgb_to_hex6(r, g, b)
	return string.format("#%02x%02x%02x", r, g, b)
end

local function parse_rgb_call(s)
	local r, g, b = s:match("^[Rr][Gg][Bb][Aa]?%(%s*([%d.]+%%?)%s*[, ]%s*([%d.]+%%?)%s*[, ]%s*([%d.]+%%?)")
	if not r then
		return nil
	end
	r, g, b = channel(r), channel(g), channel(b)
	if not (r and g and b) then
		return nil
	end
	return rgb_to_hex6(r, g, b)
end

local function luminance(hex6)
	local function lin(c)
		c = c / 255
		if c <= 0.04045 then
			return c / 12.92
		end
		return ((c + 0.055) / 1.055) ^ 2.4
	end
	local r = tonumber(hex6:sub(2, 3), 16)
	local g = tonumber(hex6:sub(4, 5), 16)
	local b = tonumber(hex6:sub(6, 7), 16)
	return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
end

local function swatch(text, hex6)
	local fg = luminance(hex6) > 0.45 and "#000000" or "#ffffff"
	return ui.Span(text):bg(hex6):fg(fg)
end

local function paint_line(line)
	if not (line:find("#", 1, true) or line:lower():find("rgb", 1, true)) then
		return ui.Line(line)
	end

	local spans = {}
	local i, last, n = 1, 1, #line

	while i <= n do
		local ch = line:sub(i, i)
		if ch == "#" then
			local j = i + 1
			while j <= n and line:sub(j, j):match("[%x]") do
				j = j + 1
			end
			local token = line:sub(i, j - 1)
			if is_hex_token(token) and is_word_end(line:sub(j, j)) then
				if i > last then
					spans[#spans + 1] = ui.Span(line:sub(last, i - 1))
				end
				spans[#spans + 1] = swatch(token, hex_to_rgb6(token))
				last = j
				i = j
			else
				i = i + 1
			end
		else
			local rest = line:sub(i)
			local call = rest:match("^[Rr][Gg][Bb][Aa]?%b()")
			local hex6 = call and parse_rgb_call(call)
			if hex6 then
				if i > last then
					spans[#spans + 1] = ui.Span(line:sub(last, i - 1))
				end
				spans[#spans + 1] = swatch(call, hex6)
				last = i + #call
				i = last
			else
				i = i + 1
			end
		end
	end

	if last <= n then
		spans[#spans + 1] = ui.Span(line:sub(last))
	end
	if #spans == 0 then
		return ui.Line(line)
	end
	return ui.Line(spans)
end

function M:peek(job)
	local path = tostring(job.file.url)
	local f, err = io.open(path, "r")
	if not f then
		return fail(job, "hex-swatch: " .. tostring(err))
	end

	local limit = job.area.h
	local skip = job.skip or 0
	local i, lines = 0, {}
	for line in f:lines() do
		i = i + 1
		if i > skip then
			lines[#lines + 1] = paint_line(line:gsub("\r$", ""))
			if #lines >= limit then
				break
			end
		end
	end
	f:close()

	if skip > 0 and i < skip + limit then
		ya.emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
		return
	end

	ya.preview_widget(job, ui.Text(lines):area(job.area))
end

function M:seek(job)
	require("code"):seek(job)
end

return M
