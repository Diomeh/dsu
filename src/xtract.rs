use color_eyre::eyre::{bail, eyre, Result};
use flate2::read::GzDecoder;
use std::{
    fs::{create_dir_all, read_dir, set_permissions, File, Permissions},
    io::{copy, BufReader, BufWriter},
    path::PathBuf,
};
use tempfile::tempdir;

use crate::cli::{Runnable, XtractArgs};

impl Runnable for XtractArgs {
    fn run(&mut self) -> Result<()> {
        // implies exists() == true
        if !self.archive.is_file() {
            bail!("Archive does not exist: {:?}", self.archive);
        }

        self.process()
    }
}

impl XtractArgs {
    fn get_destination(&self) -> Result<PathBuf> {
        let filename = self.archive.file_name().unwrap();
        let filename = filename.to_string_lossy();

        // only allow directories as destination
        let destination = match self.destination.extension() {
            None => self.destination.join(filename.to_string()),
            Some(ext) => bail!("Destination is not a directory: {:?}", ext),
        };

        // attempt to create the destination directory if needed
        if !destination.exists() {
            create_dir_all(&destination)?;
        }

        Ok(destination)
    }

    fn process(&self) -> Result<()> {
        let extension = self
            .archive
            .extension()
            .and_then(|ext| ext.to_str())
            .ok_or_else(|| {
                eyre!(
                    "Unable to determine the file extension for {:?}",
                    self.archive
                )
            })?;

        match extension.to_lowercase().as_str() {
            "tar" => self.extract_tar(None),
            "zip" => self.extract_zip(),
            "rar" => self.extract_rar(),
            "7z" => self.extract_7z(),
            "tar.7z" => self.extract_tar7z(),
            "gz" => self.extract_gz(),
            "tgz" | "tar.gz" => self.extract_targz(),
            "bz2" | "tbz" | "tbz2" | "tar.bz2" => self.unsupported(extension, true),
            "xz" | "txz" | "tar.xz" => self.unsupported(extension, true),
            "lz4" | "tlz4" | "tar.lz4" => self.unsupported(extension, true),
            "zst" | "tzst" | "tar.zst" => self.unsupported(extension, true),
            _ => self.unsupported(extension, false),
        }
    }

    fn unsupported(&self, extension: &str, planned: bool) -> Result<()> {
        if planned {
            bail!(
                "Support for {} files is planned but not yet implemented",
                extension
            )
        } else {
            bail!("Unsupported file extension: {}", extension)
        }
    }

    fn extract_tar(&self, archive: Option<PathBuf>) -> Result<()> {
        let destination = self.get_destination()?;
        let archive = match archive {
            Some(archive) => File::open(archive)?,
            None => File::open(&self.archive)?,
        };

        let mut archive = tar::Archive::new(BufReader::new(archive));
        archive.unpack(&destination)?;

        Ok(())
    }

    fn extract_zip(&self) -> Result<()> {
        let destination = self.get_destination()?;
        let archive = File::open(&self.archive)?;
        let mut archive = zip::ZipArchive::new(BufReader::new(archive))?;

        for i in 0..archive.len() {
            let mut file = archive.by_index(i)?;
            let outpath = match file.enclosed_name() {
                None => continue,
                Some(path) => destination.join(path),
            };

            {
                let comment = file.comment();
                if !comment.is_empty() {
                    println!("File {} comment: {}", i, comment);
                }
            }

            if file.name().ends_with('/') {
                println!("File {} extracted to {:?}", i, outpath.display());
                create_dir_all(&outpath)?;
            } else {
                println!(
                    "File {} extracted to {:?} ({} bytes)",
                    i,
                    outpath.display(),
                    file.size()
                );
                if let Some(p) = outpath.parent() {
                    if !p.exists() {
                        create_dir_all(p)?;
                    }
                }
                let mut outfile = File::create(&outpath)?;
                copy(&mut file, &mut outfile)?;
            }

            // set unix permissions
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                if let Some(mode) = file.unix_mode() {
                    set_permissions(&outpath, Permissions::from_mode(mode))?;
                }
            }
        }

        Ok(())
    }

    fn extract_rar(&self) -> Result<()> {
        let destination = self.get_destination()?;

        let mut archive = unrar::Archive::new(&self.archive).open_for_processing()?;
        while let Some(header) = archive.read_header()? {
            let entry = header.entry();
            let entry_path = destination.join(entry.filename.to_string_lossy().as_ref());

            println!(
                "{} bytes: {}",
                entry.unpacked_size,
                entry.filename.to_string_lossy(),
            );

            archive = if entry.is_file() {
                if let Some(parent) = entry_path.parent() {
                    create_dir_all(parent)?;
                }
                header.extract_to(&entry_path)?
            } else {
                create_dir_all(&entry_path)?;
                header.skip()?
            }
        }

        Ok(())
    }

    fn extract_7z(&self) -> Result<()> {
        let destination = self.get_destination()?;
        let archive = self.archive.as_path();

        sevenz_rust::decompress_file(archive, destination)?;
        Ok(())
    }

    fn extract_tar7z(&self) -> Result<()> {
        let archive = self.archive.as_path();
        let tpmdir = tempdir()?;

        // Decompress 7z file into the temporary directory
        sevenz_rust::decompress_file(archive, &tpmdir)?;

        // Find the extracted .tar file in the temporary directory
        let mut tar_path = None;
        for entry in read_dir(&tpmdir)? {
            let entry = entry?;
            let path = entry.path();
            if path.extension().and_then(|ext| ext.to_str()) == Some("tar") {
                tar_path = Some(path);
                break;
            }
        }

        // Ensure a .tar file was found
        let tar_path =
            tar_path.ok_or_else(|| eyre!("No .tar file found in the decompressed 7z archive"))?;

        // Extract the .tar file into the destination directory
        self.extract_tar(Some(tar_path))?;

        Ok(())
    }

    fn extract_gz(&self) -> Result<()> {
        let destination = self.get_destination()?;
        let archive = BufReader::new(File::open(&self.archive)?);

        let mut decoder = GzDecoder::new(archive);
        let mut buf_writer = BufWriter::new(File::create(destination)?);

        copy(&mut decoder, &mut buf_writer)?;
        Ok(())
    }

    fn extract_targz(&self) -> Result<()> {
        // Open the .tar.gz file
        let tar_gz = File::open("file.tar.gz")?;
        let tar = GzDecoder::new(BufReader::new(tar_gz));
        let mut archive = tar::Archive::new(tar);

        // Extract the archive to the current directory
        archive.unpack(".")?;

        Ok(())
    }
}
