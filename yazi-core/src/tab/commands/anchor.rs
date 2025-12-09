// Anchor manipulation command
// v1.5 - Use AppProxy::reflow() to update LAYOUT before peek (no hardcoded delay)
use yazi_macro::render;
use yazi_proxy::{AppProxy, MgrProxy};
use yazi_shared::event::{CmdCow, Data};

use crate::tab::Tab;

struct Opt {
	direction: i8,  // -1 for left (expand), 1 for right (shrink)
}

impl From<CmdCow> for Opt {
	fn from(c: CmdCow) -> Self {
		let direction = c.first().map(|d| match d {
			Data::Integer(i) => *i as i8,
			Data::String(s) => s.parse().unwrap_or(0),
			_ => 0,
		}).unwrap_or(0);
		Self { direction }
	}
}

impl Tab {
	#[yazi_codegen::command]
	pub fn anchor(&mut self, opt: Opt) {
		if opt.direction == 0 {
			return;
		}

		let Some(current_anchor) = self.anchor.clone() else {
			return;
		};

		if opt.direction < 0 {
			// Shift+Left: Move anchor to parent (expand root)
			self.anchor_left(current_anchor);
		} else {
			// Shift+Right: Move anchor to current directory (shrink root)
			self.anchor_right();
		}
	}

	fn anchor_left(&mut self, current_anchor: yazi_shared::url::Url) {
		// Get parent of current anchor
		let Some(new_anchor) = current_anchor.parent_url() else {
			return;  // Already at filesystem root
		};

		// Update anchor to parent
		self.anchor = Some(new_anchor.clone());

		// Ensure new anchor folder is in history (triggers loading)
		let _ = self.history.ensure(&new_anchor);

		// Rebuild pane_urls: insert new anchor at the beginning
		if self.pane_urls.is_empty() {
			// At anchor position: create panes [new_anchor, cwd]
			self.pane_urls.push(new_anchor.clone());
			self.pane_urls.push(self.cwd().clone());
		} else {
			// Already have panes, insert new anchor at beginning
			self.pane_urls.insert(0, new_anchor.clone());
		}

		// Ensure all pane folders are in history
		for url in &self.pane_urls {
			let _ = self.history.ensure(url);
		}

		// Need to update parent pane since we changed the view
		if let Some(parent) = self.cwd().parent_url() {
			self.parent = Some(self.history.remove_or(&parent));
		}

		// Reset preview to clear old image before layout change
		self.preview.reset();

		// Trigger folder refresh and reflow to update LAYOUT
		MgrProxy::refresh();
		render!();
		AppProxy::reflow();
	}

	fn anchor_right(&mut self) {
		// Move anchor to current directory
		let new_anchor = self.cwd().clone();

		// If already at this position, do nothing
		if self.anchor.as_ref() == Some(&new_anchor) {
			return;
		}

		// Update anchor
		self.anchor = Some(new_anchor);

		// Clear pane_urls since we're now at anchor
		self.pane_urls.clear();

		// At anchor, no parent pane
		self.parent = None;

		// Reset preview to clear old image before layout change
		self.preview.reset();

		// Trigger folder refresh and reflow to update LAYOUT
		MgrProxy::refresh();
		render!();
		AppProxy::reflow();
	}
}
