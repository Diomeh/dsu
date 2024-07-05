mod backup;
mod cli;
mod cln;
mod copy;
mod file_keeper;
mod hog;
mod paste;
mod restore;
mod xtract;
mod update;

use clap::Parser;
use color_eyre::Result;

fn main() -> Result<()> {
    color_eyre::install()?;

    let mut cli = cli::Cli::parse();
    cli.run()
}
