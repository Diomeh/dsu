mod cli;
mod commands;
mod utils;

use clap::Parser;
use color_eyre::Result;

fn main() -> Result<()> {
    color_eyre::install()?;

    let mut cli = cli::Cli::parse();
    cli.run()
}
