use crate::{cli::Runnable, utils::file_keeper::validate_paths};
use clap::Args;
use color_eyre::{eyre::bail, eyre::Result};
use dialoguer::Confirm;
use regex::Regex;
use std::fs::copy;
use std::path::PathBuf;

#[derive(Args, Debug)]
pub struct Restore {
    /// Source element to be restored
    pub source: PathBuf,

    /// Destination to which the source element will be restored (current dir by default)
    pub target: Option<PathBuf>,
}

impl Runnable for Restore {
    fn run(&mut self) -> Result<()> {
        if let Err(e) = validate_paths(&self.source, &mut self.target, false) {
            bail!("Restore validation failed: {}", e);
        }

        self.restore()
    }
}

impl Restore {
    fn restore(&self) -> Result<()> {
        let source = &self.source;
        let target = self.target.as_ref().unwrap();

        let filename = source.file_name().unwrap();
        let filename = filename.to_string_lossy();

        // bak extension?
        if !filename.ends_with(".bak") {
            bail!("Source file is not a backup file: {:?}", filename);
        }

        // Check if source matches backup pattern
        let pattern = Regex::new(r"^(.*)\.(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})\.bak$")?;
        let target_filename = match pattern.captures(&filename) {
            None => &filename[..filename.len() - 4], // filename.ext.bak
            Some(captures) => captures.get(1).unwrap().as_str(), // filename.ext.timestamp.bak
        };

        let target_path = if target.is_dir() {
            target.join(target_filename)
        } else {
            target.with_file_name(target_filename)
        };

        // Prompt for confirmation
        if target_path.exists()
            && !Confirm::new()
                .with_prompt(format!("Overwrite existing file at {:?}?", target_path))
                .interact()?
        {
            return Ok(());
        }

        // Attempt to copy the source to the target
        match copy(source, &target_path) {
            Ok(_) => {
                println!("Restored: {:?} to {:?}", source, target_path);
                Ok(())
            }
            Err(err) => bail!("Failed to restore {:?}: {}", source, err),
        }
    }
}
