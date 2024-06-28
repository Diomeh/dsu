use color_eyre::{eyre::eyre, Result};
use std::{
    fs::{create_dir_all, metadata},
    os::unix::fs::PermissionsExt,
    path::PathBuf,
};
use tracing::debug;

pub fn is_readable(path: &PathBuf) -> bool {
    match metadata(path) {
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

pub fn validate_paths(source: &PathBuf, target: &mut Option<PathBuf>, dry: bool) -> Result<()> {
    debug!("Validating paths");

    if !is_readable(source) {
        return Err(eyre!("Source path is not readable"));
    }

    let real_target = match target {
        None => PathBuf::from(".."),
        Some(path) => {
            if !path.exists() {
                // Check if the target path is a directory (i.e. doesn't have a file extension)
                // is_file() or is_dir() imply exists() == true, and we know that's not the case
                // INFO: possible malfunction if the target path is a file without an extension
                if path.extension().is_none() {
                    if dry {
                        println!("Would create directory: {:?}", path);
                    } else {
                        match create_dir_all(&path) {
                            Ok(_) => {
                                println!("Created directory: {:?}", path);
                            }
                            Err(err) => {
                                return Err(eyre!(
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

    if !dry && !is_readable(&real_target) {
        return Err(eyre!("Target path is not readable: {:?}", real_target));
    }

    if source.to_path_buf() == real_target {
        // TODO: see about supporting this
        return Err(eyre!("Source and target paths are the same"));
    }

    // Update target with the resolved path
    *target = Some(real_target);

    Ok(())
}
