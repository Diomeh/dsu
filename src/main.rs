mod backup;
mod cln;
mod copy;
mod hog;
mod paste;
mod xtract;

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
    fn run(&self) -> Result<()>;
}

#[derive(Subcommand, Debug, Delegate)]
#[delegate(DRunnable)]
enum DCommand {
    Backup(BackupArgs),
    Cln(ClnArgs),
    Copy(CopyArgs),
    Hog(HogArgs),
    Paste(PasteArgs),
    Xtract(XtractArgs),
}

#[derive(Args, Debug)]
pub struct BackupArgs {
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
}
