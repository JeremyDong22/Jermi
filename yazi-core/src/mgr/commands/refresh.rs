// Refresh command
// v1.2 - Fixed: ensure pane_urls folders are created in history before loading
use crossterm::{execute, terminal::SetTitle};
use yazi_config::YAZI;
use yazi_fs::CWD;
use yazi_shared::event::CmdCow;
use yazi_term::tty::TTY;

use crate::{mgr::Mgr, tasks::Tasks};

impl Mgr {
	pub fn refresh(&mut self, _: CmdCow, tasks: &Tasks) {
		if let (_, Some(s)) = (CWD.set(self.cwd()), YAZI.mgr.title()) {
			execute!(TTY.writer(), SetTitle(s)).ok();
		}

		self.active_mut().apply_files_attrs();

		// Dynamic panes: ensure all pane_urls folders exist in history
		let pane_urls: Vec<_> = self.active().pane_urls.clone();
		for url in &pane_urls {
			let _ = self.active_mut().history.ensure(url);
		}

		// Collect all directories that need to be loaded
		let mut dirs_to_load = vec![self.current()];
		if let Some(p) = self.parent() {
			dirs_to_load.push(p);
		}

		// Dynamic panes: add folders from pane_urls (now guaranteed to exist)
		for url in &pane_urls {
			if let Some(folder) = self.active().history.get(url) {
				dirs_to_load.push(folder);
			}
		}

		self.watcher.trigger_dirs(&dirs_to_load);

		self.peek(false);
		self.watch(());
		self.update_paged((), tasks);

		tasks.prework_sorted(&self.current().files);
	}
}
