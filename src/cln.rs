use color_eyre::eyre::Result;

use crate::{
    DRunnable,
    ClnArgs,
};

impl DRunnable for ClnArgs {
    fn run(&self) -> Result<()> {
        println!("Running ClnArgs");
        Ok(())
    }
}
