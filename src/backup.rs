use color_eyre::eyre::Result;

use crate::{
    DRunnable,
    BackupArgs,
};

impl DRunnable for BackupArgs {
    fn run(&self) -> Result<()> {
        println!("Running BackupArgs");
        Ok(())
    }
}
