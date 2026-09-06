--- @since 25.5.31

local HEX = "()#([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])()"

local function expand3(h)
	return h:sub(1, 1):rep(2) .. h:sub(2, 2):rep(2) .. h:sub(3, 3):rep(2)
end

local function contrast(hex)
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	-- relative luminance-ish
	if (0.2126 * r + 0.7152 * g + 0.0722 * b) > 140 then
		return "#111111"
	end
	return "#eeeeee"
end

local function colorize_line(text)
	local spans, last = {}, 1
	local i = 1
	while i <= #text do
		local s, e, hash = text:find("(#+[%x]+)", i)
		if not s then
			break
		end
		local body = hash:match("^#(%x+)$")
		local rgb
		if body and #body == 3 then
			rgb = expand3(body)
		elseif body and (#body == 6 or #body == 8) then
			rgb = body:sub(1, 6)
		end
		if rgb then
			if s > last then
				spans[#spans + 1] = ui.Span(text:sub(last, s - 1))
			end
			spans[#spans + 1] = ui.Span(hash):bg("#" .. rgb):fg(contrast(rgb))
			last = e + 1
			i = e + 1
		else
			i = s + 1
		end
	end
	if last <= #text then
		spans[#spans + 1] = ui.Span(text:sub(last))
	end
	if #spans == 0 then
		return ui.Line(text)
	end
	return ui.Line(spans)
end

local M = {}

function M:peek(job)
	local limit = job.area.h
	local lines, i = {}, 0
	local f = io.open(tostring(job.file.url), "r")
	if not f then
		return require("code"):peek(job)
	end

	for line in f:lines() do
		i = i + 1
		if i > job.skip and #lines < limit then
			lines[#lines + 1] = colorize_line(line)
		elseif i > job.skip + limit then
			break
		end
	end
	f:close()

	if job.skip > 0 and #lines == 0 then
		ya.emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
		return
	end

	ya.preview_widget(job, ui.Text(lines):area(job.area))
end

function M:seek(job)
	require("code"):seek(job)
end

return M
