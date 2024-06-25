use color_eyre::eyre::Result;

use crate::{
    DRunnable,
    CopyArgs,
};

impl DRunnable for CopyArgs {
    fn run(&mut self) -> Result<()> {
        println!("Running CopyArgs");
        Ok(())
    }
}
