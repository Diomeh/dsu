mod backup;
mod cln;
mod copy;
mod file_keeper;
mod hog;
mod paste;
mod restore;
mod xtract;
mod cli;

use clap::Parser;
use std::process::exit;

fn main() {
    let mut cli = cli::Cli::parse();
    let result = cli.run();
    if let Err(e) = result {
        eprintln!("Error: {}", e);
        exit(1);
    }
}
