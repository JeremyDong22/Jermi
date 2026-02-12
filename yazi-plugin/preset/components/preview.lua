Preview = {
	_id = "preview",
}

function Preview:new(area, tab)
	return setmetatable({
		_area = area,
		_tab = tab,
		_folder = tab.preview.folder,
	}, { __index = self })
end

function Preview:reflow() return { self } end

function Preview:redraw() return {} end

-- Mouse events
-- v0.2 - Fixed: use enter instead of reveal to preserve pane_urls chain
function Preview:click(event, up)
	if up or not event.is_left then
		return
	end

	ya.emit("enter", {})
end

function Preview:scroll(event, step) ya.emit("seek", { step }) end

function Preview:touch(event, step) end
