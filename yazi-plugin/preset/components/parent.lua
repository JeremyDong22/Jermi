Parent = {
	_id = "parent",
}

function Parent:new(area, tab)
	return setmetatable({
		_area = area,
		_tab = tab,
		_folder = tab.parent,
	}, { __index = self })
end

function Parent:reflow() return { self } end

function Parent:redraw()
	if not self._folder then
		return {}
	end

	local items = {}
	for _, f in ipairs(self._folder.window) do
		local entity = Entity:new(f)
		items[#items + 1] = entity:redraw():truncate {
			max = self._area.w,
			ellipsis = entity:ellipsis(self._area.w),
		}
	end

	return ui.List(items):area(self._area)
end

-- Mouse events
-- v0.2 - Fixed: use leave + arrow instead of reveal to preserve pane_urls chain
function Parent:click(event, up)
	if up or not event.is_left then
		return
	end

	local f = self._folder
	local y = event.y - self._area.y + 1
	local window = f and f.window or {}
	if window[y] and f.hovered then
		-- Compute delta before leave; after leave, hover stays at same position
		local delta = y + f.offset - f.hovered.idx
		ya.emit("leave", {})
		if delta ~= 0 then
			ya.emit("arrow", { delta })
		end
	else
		ya.emit("leave", {})
	end
end

function Parent:scroll(event, step) end

function Parent:touch(event, step) end
