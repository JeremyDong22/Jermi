// Refresh command
// v1.1 - Added support for loading pane_urls folders (dynamic panes)
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

		// Collect all directories that need to be loaded
		let mut dirs_to_load = vec![self.current()];
		if let Some(p) = self.parent() {
			dirs_to_load.push(p);
		}

		// Dynamic panes: also load folders from pane_urls
		for url in &self.active().pane_urls {
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
