use color_eyre::eyre::{bail, eyre, Result};
use copypasta::{ClipboardContext, ClipboardProvider};
use std::io::{stdin, Read};

use crate::cli::{CopyArgs, Runnable};

impl Runnable for CopyArgs {
    fn run(&mut self) -> Result<()> {
        let mut input = String::new();
        if let Err(err) = stdin().read_to_string(&mut input) {
            bail!("Failed to read from stdin: {}", err);
        }

        ClipboardContext::new()
            .and_then(|mut ctx| ctx.set_contents(input))
            .map_err(|err| eyre!("Failed to set clipboard contents: {}", err))
    }
}
