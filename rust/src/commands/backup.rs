use crate::{cli::Runnable, utils::file_keeper::validate_paths};
use clap::Args;
use color_eyre::{eyre::bail, eyre::Result};
use dialoguer::Confirm;
use std::{fs, path::PathBuf};

#[derive(Args, Debug)]
pub struct Backup {
    /// Source element to be backed up
    pub source: PathBuf,

    /// Destination to which the source element will be backed up (current dir by default)
    pub target: Option<PathBuf>,
}

impl Runnable for Backup {
    fn run(&mut self) -> Result<()> {
        if let Err(e) = validate_paths(&self.source, &mut self.target, false) {
            bail!("Backup validation failed: {}", e);
        }

        self.backup()
    }
}

impl Backup {
    fn backup(&self) -> Result<()> {
        let source = &self.source;
        let target = self.target.as_ref().unwrap();

        let filename = source.file_name().unwrap();
        let timestamp = chrono::Local::now().format("%Y-%m-%d_%H-%M-%S");

        let backup_path: PathBuf;

        // is_dir() implies exists() == true
        // This may not necessarily be true when doing a dry run
        if (!target.exists()) || target.is_dir() {
            // target/filename.timestamp.bak
            backup_path = target.join(format!("{}.{}.bak", filename.to_string_lossy(), timestamp));
        } else {
            // target.timestamp.bak
            let target_filename = target.file_name().unwrap();
            let target_filename = target_filename.to_string_lossy();
            let mut target_filename = target_filename.as_ref();

            // filename has .bak extension?
            if target_filename.ends_with(".bak") {
                // Remove the .bak extension
                target_filename = &target_filename[..target_filename.len() - 4];
            }

            backup_path = target.with_file_name(format!("{}.bak", target_filename));
        }

        // Check if the target path exists
        // Prompt the user to confirm overwriting the existing backup
        if backup_path.exists()
            && !Confirm::new()
                .with_prompt(format!("Overwrite existing backup at {:?}?", backup_path))
                .interact()?
        {
            return Ok(());
        }

        // Attempt to copy the source to the target
        match fs::copy(source, &backup_path) {
            Ok(_) => {
                println!("Backed up: {:?} to {:?}", source, backup_path);
                Ok(())
            }
            Err(_) => bail!("Failed to back up {:?}", source),
        }
    }
}
