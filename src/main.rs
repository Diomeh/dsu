mod backup;
mod cln;
mod copy;
mod hog;
mod paste;
mod xtract;
mod restore;

mod modules {
    pub(crate) mod file_keeper;
}

use std::path::PathBuf;
use ambassador::{delegatable_trait, Delegate};
use clap::{Args, Parser, Subcommand};
use color_eyre::eyre::Result;

#[derive(Parser)]
#[clap(name = "myapp", version = "1.0", author = "Me")]
#[clap(about = "Does awesome things")]
#[command(version, about, long_about = None)]
struct Cli {
    /// Show debug logs
    #[arg(short, long, global = true)]
    pub verbose: bool,

    #[command(subcommand)]
    pub command: DCommand,
}

#[delegatable_trait]
pub trait DRunnable {
    fn run(&mut self) -> Result<()>;
}

#[derive(Subcommand, Debug, Delegate)]
#[delegate(DRunnable)]
enum DCommand {
    /// Creates a timestamped backup of a file or directory
    Backup(BackupArgs),
    /// Restores a file or directory from a timestamped backup
    Restore(RestoreArgs),
    Cln(ClnArgs),
    Copy(CopyArgs),
    Hog(HogArgs),
    Paste(PasteArgs),
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
}

#[derive(Args, Debug)]
pub struct CopyArgs {
}

#[derive(Args, Debug)]
pub struct HogArgs {
}

#[derive(Args, Debug)]
pub struct PasteArgs {
}

#[derive(Args, Debug)]
pub struct XtractArgs {
}

fn main() {
    let mut cli = Cli::parse();
    let result = cli.command.run();
    if let Err(e) = result {
        eprintln!("Error: {}", e);
        std::process::exit(1);
    }
}
