use color_eyre::eyre::Result;

use crate::{
    DRunnable,
    PasteArgs,
};

impl DRunnable for PasteArgs {
    fn run(&self) -> Result<()> {
        println!("Running PasteArgs");
        Ok(())
    }
}
