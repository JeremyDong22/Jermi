-- Rail component: renders border lines between panes
-- v2.0 - Dynamic borders: supports any number of panes (2+)
Rail = {
	_id = "rail",
}

function Rail:new(chunks, tab, pane_folders)
	local me = setmetatable({
		_chunks = chunks,
		_tab = tab,
		_pane_folders = pane_folders or {},  -- Optional: folders for each pane (for markers)
	}, { __index = self })
	me:build()
	return me
end

function Rail:build()
	local chunk_count = #self._chunks
	self._base = {}
	self._children = {}

	-- Create borders between each pair of adjacent panes
	-- For N chunks, we need N-1 borders
	for i = 1, chunk_count - 1 do
		-- Border on right edge of chunk[i] (separates chunk[i] from chunk[i+1])
		self._base[#self._base + 1] = ui.Bar(ui.Edge.RIGHT)
			:area(self._chunks[i])
			:symbol(th.mgr.border_symbol)
			:style(th.mgr.border_style)
	end

	-- Create markers for panes that have folders
	-- Markers show selection state on the border
	if self._pane_folders then
		for i, folder in ipairs(self._pane_folders) do
			if folder and self._chunks[i] then
				self._children[#self._children + 1] = Marker:new(self._chunks[i], folder)
			end
		end
	else
		-- Fallback: use parent and current (legacy 3-pane mode)
		if self._tab.parent and self._chunks[1] then
			self._children[#self._children + 1] = Marker:new(self._chunks[1], self._tab.parent)
		end
		if self._tab.current and self._chunks[2] then
			self._children[#self._children + 1] = Marker:new(self._chunks[2], self._tab.current)
		end
	end
end

function Rail:reflow() return {} end

function Rail:redraw()
	local elements = self._base or {}
	for _, child in ipairs(self._children) do
		elements = ya.list_merge(elements, ui.redraw(child))
	end
	return elements
end

-- Mouse events
function Rail:click(event, up) end

function Rail:scroll(event, step) end

function Rail:touch(event, step) end
