use color_eyre::eyre::{eyre, Result};
use copypasta::{ClipboardContext, ClipboardProvider};
use tracing::trace;

use crate::{Runnable, PasteArgs};

impl Runnable for PasteArgs {
    fn run(&mut self) -> Result<()> {
        trace!("args: {self:?}");

        let mut ctx = match ClipboardContext::new() {
            Ok(ctx) => ctx,
            Err(err) => {
                return Err(eyre!("Failed to create clipboard context: {}", err));
            }
        };

        let contents = match ctx.get_contents() {
            Ok(contents) => contents,
            Err(err) => {
                return Err(eyre!("Failed to get clipboard contents: {}", err));
            }
        };

        println!("{}", contents);
        Ok(())
    }
}
