// Anchor manipulation command
// v1.3 - Shift+Left/Right to move anchor position
// Fixed: anchor_left derives pane_urls from new anchor + cwd (matches
//        cd.rs logic) AND actually keeps earlier-pane folders in
//        history. `history.remove_or()` removes the entry; the previous
//        code discarded the returned folder, leaving tab:history(url)
//        returning nil → blank panes.
use yazi_macro::render;
use yazi_proxy::MgrProxy;
use yazi_shared::{event::{CmdCow, Data}, url::Url};

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

	fn anchor_left(&mut self, current_anchor: Url) {
		// Get parent of current anchor
		let Some(new_anchor) = current_anchor.parent_url() else {
			return; // Already at filesystem root
		};

		// Update anchor to parent
		self.anchor = Some(new_anchor.clone());

		// Rebuild pane_urls by walking up from cwd to the new anchor,
		// mirroring the derivation logic in cd.rs so the chain is always
		// [new_anchor, ..., cwd] without duplicates.
		let mut chain = Vec::new();
		let mut cursor = Some(self.cwd().clone());
		let mut reached = false;
		while let Some(u) = cursor {
			let is_anchor = u == new_anchor;
			chain.push(u.clone());
			if is_anchor {
				reached = true;
				break;
			}
			cursor = u.parent_url();
		}
		self.pane_urls = if reached && chain.len() > 1 {
			chain.reverse();
			chain
		} else {
			Vec::new()
		};

		// Update parent pane since view composition changed
		if let Some(parent) = self.cwd().parent_url() {
			self.parent = Some(self.history.remove_or(&parent));
		}

		// Earlier panes (everything except current and parent) must live in
		// `history` so Lua's `tab:history(url)` can render them. `remove_or`
		// either takes the existing folder out or creates a fresh empty one
		// — either way we must put it BACK into history.
		let parent_url = self.parent.as_ref().map(|f| f.url.clone());
		let cwd = self.cwd().clone();
		let urls: Vec<Url> = self.pane_urls.clone();
		for url in urls {
			if url == cwd {
				continue;
			}
			if parent_url.as_ref() == Some(&url) {
				continue;
			}
			let folder = self.history.remove_or(&url);
			self.history.insert(url, folder);
		}

		// Trigger folder refresh to load contents
		MgrProxy::refresh();
		render!();
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

		// Trigger refresh for consistency
		MgrProxy::refresh();
		render!();
	}
}
