use color_eyre::eyre::{eyre, Result};
use copypasta::{ClipboardContext, ClipboardProvider};
use std::io::{stdin, Read};
use tracing::trace;

use crate::cli::{CopyArgs, Runnable};

impl Runnable for CopyArgs {
    fn run(&mut self) -> Result<()> {
        trace!("args: {self:?}");

        let mut input = String::new();
        if let Err(err) = stdin().read_to_string(&mut input) {
            return Err(eyre!("Failed to read from stdin: {}", err));
        }

        ClipboardContext::new()
            .and_then(|mut ctx| ctx.set_contents(input))
            .map_err(|err| eyre!("Failed to set clipboard contents: {}", err))
    }
}
