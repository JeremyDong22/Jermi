Current = {
	_id = "current",
}

function Current:new(area, tab)
	return setmetatable({
		_area = area,
		_tab = tab,
		_folder = tab.current,
	}, { __index = self })
end

-- v0.2: Empty folder shows highlighted "No items" for cursor visibility
function Current:empty()
	local s
	if self._folder.files.filter then
		s = "No filter results"
	else
		local done, err = self._folder.stage()
		s = not done and "Loading..." or not err and "No items" or string.format("Error: %s", err)
	end

	-- Show with hovered style so user knows where cursor is
	return {
		ui.Line(" " .. s):area(self._area):style(th.mgr.hovered),
	}
end

function Current:reflow() return { self } end

function Current:redraw()
	local files = self._folder.window
	if #files == 0 then
		return self:empty()
	end

	local left, right = {}, {}
	for _, f in ipairs(files) do
		local entity = Entity:new(f)
		left[#left + 1], right[#right + 1] = entity:redraw(), Linemode:new(f):redraw()

		local max = math.max(0, self._area.w - right[#right]:width())
		left[#left]:truncate { max = max, ellipsis = entity:ellipsis(max) }
	end

	return {
		ui.List(left):area(self._area),
		ui.Text(right):area(self._area):align(ui.Align.RIGHT),
	}
end

-- Mouse events
-- v0.4: Delegate to Entity:click (matches upstream PR #2925). Click now emits
-- `reveal` instead of `arrow`, which does cd + cursor + preview refresh in one
-- shot — fixes the case where clicking a file in a freshly cd'd folder left
-- the preview blank because peek raced the mime fetcher.
function Current:click(event, up)
	local y = event.y - self._area.y + 1
	if self._folder.window[y] then
		Entity:new(self._folder.window[y]):click(event, up)
	end
end

function Current:scroll(event, step) ya.emit("arrow", { step }) end

function Current:touch(event, step) end
