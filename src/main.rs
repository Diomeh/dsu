mod backup;
mod cln;
mod copy;
mod file_keeper;
mod hog;
mod paste;
mod restore;
mod xtract;

use ambassador::{delegatable_trait, Delegate};
use clap::{Args, Parser, Subcommand};
use color_eyre::eyre::Result;
use std::{path::PathBuf, process::exit};

#[derive(Parser)]
#[command(
    version,
    author,
    about,
    long_about = None
)]
struct Cli {
    /// Show debug logs
    /// TODO: Implement
    // #[arg(short, long, global = true)]
    // pub verbose: bool,

    #[command(subcommand)]
    pub command: Utilities,
}

#[delegatable_trait]
pub trait Runnable {
    fn run(&mut self) -> Result<()>;
}

#[derive(Subcommand, Debug, Delegate)]
#[delegate(Runnable)]
enum Utilities {
    /// Creates a timestamped backup of a file or directory
    Backup(BackupArgs),
    /// Restores a file or directory from a timestamped backup
    Restore(RestoreArgs),
    /// Removes non-ascii characters from file names
    Cln(ClnArgs),
    /// Copy STDOUT to clipboard
    Copy(CopyArgs),
    /// Print disk usage of a directory
    Hog(HogArgs),
    /// Paste clipboard to STDIN
    Paste(PasteArgs),
    /// Archive extraction utility
    Xtract(XtractArgs),
}

#[derive(Args, Debug)]
pub struct BackupArgs {
    /// Source element to be backed up
    pub source: PathBuf,

    /// Destination to which the source element will be backed up (current dir by default)
    pub target: Option<PathBuf>,

    /// Only print actions, without performing them
    #[arg(long, short = 'n')]
    pub dry: bool,
}

#[derive(Args, Debug)]
pub struct RestoreArgs {
    /// Source element to be restored
    source: PathBuf,

    /// Destination to which the source element will be restored (current dir by default)
    target: Option<PathBuf>,

    /// Only print actions, without performing them
    #[arg(long, short = 'n')]
    pub dry: bool,
}

#[derive(Args, Debug)]
pub struct ClnArgs {
    /// Paths to be cleaned
    #[arg(default_value = ".")]
    paths: Vec<PathBuf>,

    /// Only print actions, without performing them
    #[arg(long, short = 'n')]
    pub dry: bool,

    /// Clean directories recursively
    #[arg(long, short = 'r', default_value = "true")]
    pub recursive: bool,

    /// Recurse depth
    #[arg(long, short = 'd', default_value = "1")]
    pub depth: Option<usize>,

    /// Overwrite existing files without prompting
    #[arg(long, short = 'f', default_value = "auto", value_parser = ["y", "n", "auto"])]
    pub force: String,
}

#[derive(Args, Debug)]
pub struct CopyArgs {}

#[derive(Args, Debug)]
pub struct HogArgs {
    /// Directory to analyze
    #[arg(default_value = ".")]
    dir: PathBuf,

    /// Human readable sizes
    #[arg(long, short = 'H', default_value = "false")]
    pub human_readable: bool,

    /// Number of items to show
    #[arg(long, short = 'n', default_value = "10")]
    pub limit: usize,
}

#[derive(Args, Debug)]
pub struct PasteArgs {}

#[derive(Args, Debug)]
pub struct XtractArgs {
    /// Archive to extract
    archive: PathBuf,

    /// Destination directory
    #[arg(default_value = ".")]
    destination: PathBuf,

    /// Only print actions, without performing them
    #[arg(long, short = 'n')]
    pub dry: bool,

    /// List files in archive
    #[arg(long, short = 'l')]
    pub list: bool,
}

fn main() {
    let mut cli = Cli::parse();
    let result = cli.command.run();
    if let Err(e) = result {
        eprintln!("Error: {}", e);
        exit(1);
    }
}
