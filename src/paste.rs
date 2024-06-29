use color_eyre::eyre::{bail, Result};
use copypasta::{ClipboardContext, ClipboardProvider};

use crate::cli::{PasteArgs, Runnable};

impl Runnable for PasteArgs {
    fn run(&mut self) -> Result<()> {
        let mut ctx = match ClipboardContext::new() {
            Ok(ctx) => ctx,
            Err(err) => {
                bail!("Failed to create clipboard context: {}", err);
            }
        };

        let contents = match ctx.get_contents() {
            Ok(contents) => contents,
            Err(err) => {
                bail!("Failed to get clipboard contents: {}", err);
            }
        };

        println!("{}", contents);
        Ok(())
    }
}
