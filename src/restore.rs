use color_eyre::eyre::Result;

use crate::{
    DRunnable,
    RestoreArgs,
};

impl DRunnable for RestoreArgs {
    fn run(&mut self) -> Result<()> {
        println!("Running RestoreArgs");
        Ok(())
    }
}
