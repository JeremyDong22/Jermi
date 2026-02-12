use yazi_fs::{File, FilesOp, expand_path};
use yazi_proxy::MgrProxy;
use yazi_shared::{event::CmdCow, url::Url};

use crate::tab::Tab;

struct Opt {
	target:   Url,
	no_dummy: bool,
	pane_nav: bool,
}

impl From<CmdCow> for Opt {
	fn from(mut c: CmdCow) -> Self {
		let mut target = c.take_first_url().unwrap_or_default();
		if target.is_regular() {
			target = Url::from(expand_path(&target));
		}

		Self { target, no_dummy: c.bool("no-dummy"), pane_nav: c.bool("pane-nav") }
	}
}
impl From<Url> for Opt {
	fn from(target: Url) -> Self { Self { target, no_dummy: false, pane_nav: false } }
}

impl Tab {
	#[yazi_codegen::command]
	pub fn reveal(&mut self, opt: Opt) {
		let Some((parent, child)) = opt.target.pair() else {
			return;
		};

		// Use PaneNav source when pane-nav flag is set to preserve pane chain
		let source = if opt.pane_nav { super::cd::OptSource::PaneNav } else { super::cd::OptSource::Reveal };
		self.cd((parent.clone(), source));
		self.current.hover(child.as_urn());

		if !opt.no_dummy && self.hovered().is_none_or(|f| &child != f.urn()) {
			let op = FilesOp::Creating(parent, vec![File::from_dummy(opt.target.clone(), None)]);
			self.current.update_pub(self.id, op);
		}

		self.hover(Some(opt.target));
		MgrProxy::peek(false);
		MgrProxy::watch();
	}
}
