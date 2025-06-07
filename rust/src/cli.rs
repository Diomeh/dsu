use ambassador::{delegatable_trait, Delegate};
use clap::{Parser, Subcommand};
use color_eyre::eyre::Result;

use crate::commands::{
    backup::Backup, cln::Cln, copy::Copy, hog::Hog, paste::Paste, restore::Restore, update::Update,
    xtract::Xtract,
};

#[derive(Parser)]
#[command(
    version,
    author,
    about,
    long_about = None
)]
/// Main CLI
pub struct Cli {
    /// Show debug logs
    #[arg(short, long, global = true)]
    pub verbose: bool,

    /// Check for updates
    #[arg(long, short = 'u')]
    pub update: bool,

    /// Utility to be executed
    #[command(subcommand)]
    command: Commands,
}

impl Cli {
    pub fn run(&mut self) -> Result<()> {
        if self.verbose {
            // TODO: Implement verbose mode
            eprintln!("WARNING: Verbose mode support is not implemented yet");
        }

        // Runnable::run cannot be public so cli.command.run() is not possible from main.rs
        self.command.run()
    }
}

#[delegatable_trait]
pub trait Runnable {
    fn run(&mut self) -> Result<()>;
}

#[derive(Subcommand, Debug, Delegate)]
#[delegate(Runnable)]
enum Commands {
    /// Creates a timestamped backup of a file or directory
    Backup(Backup),
    /// Restores a file or directory from a timestamped backup
    Restore(Restore),
    /// Removes non-ascii characters from file names
    Cln(Cln),
    /// Copy STDOUT to clipboard
    Copy(Copy),
    /// Print disk usage of a directory
    Hog(Hog),
    /// Paste clipboard to STDIN
    Paste(Paste),
    /// Archive extraction utility
    Xtract(Xtract),
    /// Check for updates
    Update(Update),
}
