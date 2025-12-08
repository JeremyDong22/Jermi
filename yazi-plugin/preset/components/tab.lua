-- Tab component with dynamic panes support
-- v1.1 - Fixed: all modes use consistent x(1) padding
Tab = {
	_id = "tab",
}

function Tab:new(area, tab)
	local me = setmetatable({ _area = area, _tab = tab }, { __index = self })
	me:layout()
	me:build()
	return me
end

function Tab:layout()
	local ratio = rt.mgr.ratio
	local pane_urls = self._tab.pane_urls or {}
	local pane_count = #pane_urls

	-- Dynamic panes mode: pane_urls has entries (navigated away from anchor)
	if pane_count > 0 then
		-- Calculate constraints: each pane gets equal ratio, preview gets same
		local constraints = {}
		local total_parts = pane_count + 1  -- panes + preview

		for i = 1, pane_count do
			constraints[#constraints + 1] = ui.Constraint.Ratio(1, total_parts)
		end
		-- Preview pane (rightmost)
		constraints[#constraints + 1] = ui.Constraint.Ratio(1, total_parts)

		self._chunks = ui.Layout()
			:direction(ui.Layout.HORIZONTAL)
			:constraints(constraints)
			:split(self._area)

		self._pane_urls = pane_urls
		self._dynamic_mode = true
		self._anchor_mode = false
	elseif self._tab.parent == nil then
		-- At anchor: parent is nil, so only current + preview (2 panes)
		self._chunks = ui.Layout()
			:direction(ui.Layout.HORIZONTAL)
			:constraints({
				ui.Constraint.Ratio(ratio.current, ratio.current + ratio.preview),
				ui.Constraint.Ratio(ratio.preview, ratio.current + ratio.preview),
			})
			:split(self._area)

		self._pane_urls = {}
		self._dynamic_mode = false
		self._anchor_mode = true
	else
		-- Default: 3-column layout with parent pane
		self._chunks = ui.Layout()
			:direction(ui.Layout.HORIZONTAL)
			:constraints({
				ui.Constraint.Ratio(ratio.parent, ratio.all),
				ui.Constraint.Ratio(ratio.current, ratio.all),
				ui.Constraint.Ratio(ratio.preview, ratio.all),
			})
			:split(self._area)

		self._pane_urls = {}
		self._dynamic_mode = false
		self._anchor_mode = false
	end
end

function Tab:build()
	if self._dynamic_mode then
		-- Dynamic panes mode (navigated away from anchor)
		-- v0.8: Fixed history lookup with tab:history(url) method
		self._children = {}
		local pane_count = #self._pane_urls
		local pane_folders = {}

		for i, url in ipairs(self._pane_urls) do
			local is_current = (i == pane_count)
			local is_parent_pane = (i == pane_count - 1)

			if is_current then
				-- Last pane: use Current (active folder with full features)
				-- Use x(1) padding for consistency with other panes
				self._children[#self._children + 1] = Current:new(self._chunks[i]:pad(ui.Pad.x(1)), self._tab)
				pane_folders[i] = self._tab.current
			elseif is_parent_pane and self._tab.parent then
				-- Second-to-last pane: use Parent component (uses tab.parent folder)
				self._children[#self._children + 1] = Parent:new(self._chunks[i]:pad(ui.Pad.x(1)), self._tab)
				pane_folders[i] = self._tab.parent
			else
				-- Earlier panes: look up from history using tab:history() method
				local folder = self._tab:history(url)
				self._children[#self._children + 1] = Pane:new(self._chunks[i]:pad(ui.Pad.x(1)), self._tab, url)
				pane_folders[i] = folder
			end
		end

		-- Preview pane (always last chunk)
		self._children[#self._children + 1] = Preview:new(self._chunks[pane_count + 1]:pad(ui.Pad.x(1)), self._tab)
		-- Rail with dynamic borders (pane_count borders for pane_count+1 chunks)
		self._children[#self._children + 1] = Rail:new(self._chunks, self._tab, pane_folders)
	elseif self._anchor_mode then
		-- At anchor: only current + preview (2 panes)
		-- v1.0: Use x(1) padding to match Pane padding (prevents jitter on first enter)
		self._children = {
			Current:new(self._chunks[1]:pad(ui.Pad.x(1)), self._tab),
			Preview:new(self._chunks[2]:pad(ui.Pad.x(1)), self._tab),
			Rail:new(self._chunks, self._tab, { self._tab.current }),
		}
	else
		-- Default 3-column layout
		-- v1.1: Add x(1) padding to Current for consistency
		self._children = {
			Parent:new(self._chunks[1]:pad(ui.Pad.x(1)), self._tab),
			Current:new(self._chunks[2]:pad(ui.Pad.x(1)), self._tab),
			Preview:new(self._chunks[3]:pad(ui.Pad.x(1)), self._tab),
			Rail:new(self._chunks, self._tab, { self._tab.parent, self._tab.current }),
		}
	end
end

function Tab:reflow()
	local components = { self }
	for _, child in ipairs(self._children) do
		components = ya.list_merge(components, child:reflow())
	end
	return components
end

function Tab:redraw()
	local elements = self._base or {}
	for _, child in ipairs(self._children) do
		elements = ya.list_merge(elements, ui.redraw(child))
	end
	return elements
end

-- Mouse events
function Tab:click(event, up) end

function Tab:scroll(event, step) end

function Tab:touch(event, step) end
