use color_eyre::eyre::Result;
use dialoguer::Confirm;
use regex::Regex;
use std::{fs::rename, path::PathBuf};

use crate::cli::{ClnArgs, Runnable};

impl Runnable for ClnArgs {
    fn run(&mut self) -> Result<()> {
        // use the current directory if no paths are provided
        if self.paths.is_empty() {
            self.paths.push(PathBuf::from("../.."));

            // set recurse to true
            // set depth to 1 if not set
            // this will make it so that only the contents of the current directory are included

            self.recursive = true;
            if self.depth.is_none() || self.depth.unwrap() == 0 {
                // set depth to 1
                self.depth = Some(1);
            }
        }

        self.clean_files(&self.paths, 0)
    }
}

impl ClnArgs {
    fn clean_files(&self, paths: &Vec<PathBuf>, depth: usize) -> Result<()> {
        let should_recurse = self.recursive && depth < self.depth.unwrap();

        for path in paths {
            if !path.exists() {
                eprintln!("File does not exist: {:?}", path);
                continue;
            }

            if path.is_dir() && should_recurse {
                let mut new_paths = Vec::new();
                for entry in path.read_dir()? {
                    let entry = entry?;
                    new_paths.push(entry.path());
                }
                self.clean_files(&new_paths, depth + 1)?;
            } else {
                self.clean_file(path);
            }
        }

        Ok(())
    }

    fn clean_file(&self, path: &PathBuf) {
        // only simple ascii pattern, no whitespaces
        let pattern = Regex::new(r"^[a-zA-Z0-9_\-.]+$").unwrap();
        let filename = match path.file_name() {
            Some(name) => name.to_string_lossy(),
            None => {
                eprintln!("Failed to get filename for {:?}", path);
                return;
            }
        };

        // nothing to do if the filename is already clean
        if pattern.is_match(&filename) {
            return;
        }

        // clean the filename by removing invalid characters
        let clean_filename: String = filename.chars()
            .map(|c| {
                if c.is_ascii_alphanumeric() || ['_', '-', '.'].contains(&c) { c } else { '_' }
            }).collect();

        // replace consecutive underscores with a single underscore
        let clean_filename = Regex::new(r"__+")
            .unwrap()
            .replace_all(&clean_filename, "_")
            .to_string();

        let clean_path = path.with_file_name(&clean_filename);

        if self.dry {
            println!("{:?} -> {:?}", path, clean_path);
            if clean_path.exists() {
                println!("Note: {:?} would overwrite existing file", clean_path);
            }
            return;
        }

        if self.force == "n" {
            if clean_path.exists() {
                eprintln!("File {:?} already exists, skipping...", clean_path);
                return;
            }
        } else if self.force == "auto" {
            // prompt and warn about single _ names and empty names

            if (clean_filename.is_empty() || clean_filename == "_")
                && !Confirm::new()
                    .with_prompt(format!(
                        "File {:?}, would rename to {:?}. Do you wish to proceed?",
                        filename, clean_filename
                    ))
                    .interact()
                    .unwrap()
            {
                return;
            }

            // prompt for confirmation if exists
            if clean_path.exists()
                && !Confirm::new()
                    .with_prompt(format!("Overwrite existing file at {:?}?", clean_path))
                    .interact()
                    .unwrap()
            {
                return;
            }
        }

        // rename the file
        match rename(path, &clean_path) {
            Ok(_) => {
                println!("{:?} -> {:?}", path, clean_path);
            }
            Err(err) => {
                eprintln!("ERROR: Failed to rename {:?} to {:?}: {}", path, clean_path, err);
            }
        }
    }
}
