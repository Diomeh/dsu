use color_eyre::{eyre::eyre, eyre::Result};
use dialoguer::Confirm;
use regex::Regex;
use std::fs::copy;
use tracing::{debug, trace, warn};

use crate::{
    cli::{RestoreArgs, Runnable},
    file_keeper::validate_paths,
};

impl Runnable for RestoreArgs {
    fn run(&mut self) -> Result<()> {
        trace!("args: {:?}", self);

        if let Err(e) = validate_paths(&self.source, &mut self.target, self.dry) {
            warn!("Validation failed: {}", e);
            return Err(e);
        }

        self.restore()
    }
}

impl RestoreArgs {
    fn restore(&self) -> Result<()> {
        debug!("Restoring");

        let source = &self.source;
        let target = self.target.as_ref().unwrap();

        let filename = source.file_name().unwrap();
        let filename = filename.to_string_lossy();

        // bak extension?
        if !filename.ends_with(".bak") {
            return Err(eyre!("Source file is not a backup file: {:?}", filename));
        }

        // Check if source matches backup pattern
        let pattern = Regex::new(r"^(.*)\.(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})\.bak$").unwrap();
        let target_filename = match pattern.captures(&filename) {
            None => &filename[..filename.len() - 4], // filename.ext.bak
            Some(captures) => captures.get(1).unwrap().as_str(), // filename.ext.timestamp.bak
        };

        let target_path = if target.is_dir() {
            target.join(target_filename)
        } else {
            target.with_file_name(target_filename)
        };

        debug!("Copying {:?} to {:?}", source, target_path);

        // Check for dry run
        if self.dry {
            println!("Would restore {:?} to {:?}", source, target_path);
            return Ok(());
        }

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
            Err(err) => Err(eyre!("Failed to restore {:?}: {}", source, err)),
        }
    }
}
