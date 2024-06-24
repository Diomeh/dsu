use color_eyre::eyre::Result;

use crate::{
    DRunnable,
    HogArgs,
};

impl DRunnable for HogArgs {
    fn run(&self) -> Result<()> {
        println!("Running HogArgs");
        Ok(())
    }
}
