use ambassador::{delegatable_trait, Delegate};
use clap::{Parser, Subcommand, ValueEnum};
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
    /// Verbosity level
    #[clap(short, long, global = true, require_equals = true, value_name = "LEVEL", default_value = "info")]
    pub verbosity: Verbosity,

    /// Suppress output
    #[clap(short, long, global = true)]
    pub quiet: bool,

    /// Set colored output
    #[clap(short, long, global = true, require_equals = true, value_name = "OPTION", default_value = "auto")]
    pub color: Color,

    /// Disable color output
    #[clap(long, global = true)]
    pub no_color: bool,

    /// Simulate execution
    #[clap(short, long, global = true)]
    pub dry_run: bool,

    /// Prompt behavior mode
    #[clap(short, long, global = true, require_equals = true, value_name = "OPTION", default_value = "ask")]
    pub prompt: Prompt,

    /// Answer "yes" to all prompts
    #[clap(short, long, global = true)]
    pub yes: bool,

    /// Answer "no" to all prompts
    #[clap(short, long, global = true)]
    pub no: bool,

    /// Command to be executed
    #[command(subcommand)]
    command: Commands,
}

impl Cli {
    pub fn run(&mut self) -> Result<()> {
        // Runnable::run cannot be public so cli.command.run() is not possible from main.rs
        self.command.run()
    }
}

#[derive(Debug, Clone, Copy, ValueEnum)]
pub enum Verbosity {
    Off,
    Error,
    Warn,
    Info,
    Debug,
}

#[derive(Debug, Clone, Copy, ValueEnum)]
pub enum Color {
    Auto,
    On,
    Off,
}

#[derive(Debug, Clone, Copy, ValueEnum)]
pub enum Prompt {
    Ask,
    Yes,
    No,
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
