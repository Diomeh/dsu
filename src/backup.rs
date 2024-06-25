use color_eyre::eyre;
use color_eyre::eyre::Result;
use dialoguer::Confirm;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;
use tracing::{debug, trace, warn};

use crate::{BackupArgs, DRunnable};

impl DRunnable for BackupArgs {
    fn run(&mut self) -> Result<()> {
        trace!("args: {self:?}");

        if let Err(e) = self.validate_paths() {
            warn!("Validation failed: {}", e);
            return Err(e);
        }

        self.backup()
    }
}

impl BackupArgs {
    fn validate_paths(&mut self) -> Result<()> {
        debug!("Validating paths");

        if !is_readable(&self.source) {
            return Err(eyre::eyre!("Source path is not readable"));
        }

        let target = match &self.target {
            None => PathBuf::from("."),
            Some(path) => {
                if !path.exists() {
                    // Check if the target path is a directory (i.e. doesn't have a file extension)
                    // is_file() or is_dir() imply exists() == true, and we know that's not the case
                    // INFO: possible malfunction if the target path is a file without an extension
                    if path.extension().is_none() {
                        if self.dry {
                            println!("Would create directory: {:?}", path);
                        } else {
                            match fs::create_dir_all(path) {
                                Ok(_) => {
                                    println!("Created directory: {:?}", path);
                                }
                                Err(err) => {
                                    return Err(eyre::eyre!(
                                        "Failed to create directory {:?}: {}",
                                        path,
                                        err
                                    ));
                                }
                            }
                        }
                    }
                }

                path.to_path_buf()
            }
        };

        if !self.dry && !is_readable(&target) {
            return Err(eyre::eyre!("Target path is not readable: {:?}", target));
        }

        if self.source == target {
            // TODO: see about supporting this
            return Err(eyre::eyre!("Source and target paths are the same"));
        }

        // Update self.target with the resolved path
        self.target = Some(target);

        Ok(())
    }

    fn backup(&self) -> Result<()> {
        debug!("Backing up");

        let source = &self.source;
        let target = self.target.as_ref().unwrap();

        let filename = source.file_name().unwrap();
        let timestamp = chrono::Local::now().format("%Y-%m-%d_%H-%M-%S");

        let backup_path: PathBuf;

        // is_dir() implies exists() == true
        // This may not necessarily be true when doing a dry run
        if (self.dry && !target.exists()) || target.is_dir() {
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

        debug!("Copying {:?} to {:?}", source, backup_path);

        // Check for dry run
        if self.dry {
            println!("Would back up {:?} to {:?}", source, backup_path);
            return Ok(());
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
            Err(_) => Err(eyre::eyre!("Failed to back up {:?}", source)),
        }
    }
}

fn is_readable(path: &PathBuf) -> bool {
    match fs::metadata(path) {
        Ok(metadata) => {
            let perms = metadata.permissions();

            // Check for read permission
            if !perms.mode() & 0o400 != 0 {
                return false;
            }
        }
        Err(_) => {
            return false;
        }
    }

    true
}
