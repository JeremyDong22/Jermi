// Reflow command - handles layout recalculation
// v1.1 - Added image_hide before peek for proper image clearing on resize
use mlua::Value;
use ratatui::layout::Position;
use tracing::error;
use yazi_adapter::ADAPTOR;
use yazi_config::LAYOUT;
use yazi_macro::render;
use yazi_proxy::MgrProxy;
use yazi_shared::event::CmdCow;

use crate::{Root, app::App, lives::Lives};

struct Opt;

impl From<CmdCow> for Opt {
	fn from(_: CmdCow) -> Self { Self }
}

impl From<()> for Opt {
	fn from(_: ()) -> Self { Self }
}

impl App {
	#[yazi_codegen::command]
	pub fn reflow(&mut self, _: Opt) {
		let Some(size) = self.term.as_ref().and_then(|t| t.size().ok()) else { return };
		let mut layout = LAYOUT.get();

		let result = Lives::scope(&self.cx, || {
			let comps = Root::reflow((Position::ORIGIN, size).into())?;

			for v in comps.sequence_values::<Value>() {
				let Value::Table(t) = v? else {
					error!("`reflow()` must return a table of components");
					continue;
				};

				let id: mlua::String = t.get("_id")?;
				match id.as_bytes().as_ref() {
					b"current" => layout.current = *t.raw_get::<yazi_plugin::elements::Rect>("_area")?,
					b"preview" => layout.preview = *t.raw_get::<yazi_plugin::elements::Rect>("_area")?,
					b"progress" => layout.progress = *t.raw_get::<yazi_plugin::elements::Rect>("_area")?,
					_ => {}
				}
			}
			Ok(())
		});

		let old_layout = LAYOUT.get();
		if layout != old_layout {
			LAYOUT.set(layout);
			render!();
			// Always refresh preview when layout changes (dynamic panes resize)
			ADAPTOR.get().image_hide().ok();
			MgrProxy::peek(true);
		}

		if let Err(e) = result {
			error!("Failed to `reflow()` the `Root` component:\n{e}");
		}
	}
}
