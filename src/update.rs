use crate::cli::{Runnable, UpdateArgs};
use color_eyre::eyre::{bail, Result};
use reqwest::blocking::get;
use version_compare::Version;

impl Runnable for UpdateArgs {
    fn run(&mut self) -> Result<()> {
        let url = "https://raw.githubusercontent.com/Diomeh/dsu/master/VERSION";

        let response = get(url)?;

        if !response.status().is_success() {
            bail!("Failed to check for updates: {}", response.status());
        }

        let remote_version = response.text()?;
        let remote_version = remote_version.trim();
        let remote_version = &remote_version[1..]; // Remove the 'v' prefix
        let current_version = env!("CARGO_PKG_VERSION");

        let remote_version = Version::from(remote_version).unwrap();
        let current_version = Version::from(current_version).unwrap();

        println!("Checking for updates...");
        println!("Current version: {}", current_version);

        if remote_version > current_version {
            println!("A new version is available: {}", remote_version);
            println!("Refer to the repo README on how to update: https://github.com/Diomeh/dsu/blob/master/README.md");
        } else {
            println!("You are running the latest version: {}", current_version);
        }

        Ok(())
    }
}
