-- Pane component for dynamic panes
-- v0.1 - Displays a folder from history by URL
Pane = {
	_id = "pane",
}

function Pane:new(area, tab, url)
	-- Look up folder from history using the url
	local folder = tab:history(url)
	return setmetatable({
		_area = area,
		_tab = tab,
		_folder = folder,
		_url = url,
	}, { __index = self })
end

function Pane:reflow() return { self } end

function Pane:redraw()
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
function Pane:click(event, up)
	if up or not event.is_left then
		return
	end

	local y = event.y - self._area.y + 1
	local window = self._folder and self._folder.window or {}
	if window[y] then
		ya.emit("reveal", { window[y].url })
	end
end

function Pane:scroll(event, step) end

function Pane:touch(event, step) end
