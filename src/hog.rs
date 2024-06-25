use color_eyre::eyre::{eyre, Result};
use tracing::trace;

use crate::{DRunnable, HogArgs};

impl DRunnable for HogArgs {
    fn run(&mut self) -> Result<()> {
        trace!("args: {self:?}");

        if !self.dir.is_dir() {
            return Err(eyre!("Not a directory: {:?}", self.dir));
        }

        let mut total_size: usize = 0;
        let mut items: Vec<(String, String, usize)> = Vec::new();

        for entry in self.dir.read_dir()? {
            let entry = entry?;
            let path = entry.path();
            let metadata = entry.metadata()?;
            let size = metadata.len() as usize;
            let humman_size = self.human_size(size);

            total_size += size;

            items.push((path.to_string_lossy().to_string(), humman_size, size));
        }

        items.sort_by(|a, b| {
            let (_, _, size_a) = a;
            let (_, _, size_b) = b;
            size_b.cmp(size_a)
        });

        println!("Total size: {}", if self.human_readable { self.human_size(total_size) } else { total_size.to_string() });
        let mut i: usize = 0;
        for (path, hsize, size) in items {
            println!("{}: {}", path, if self.human_readable { hsize } else { size.to_string() });

            if i == self.limit {
                break;
            } else {
                i += 1;
            }
        }

        Ok(())
    }
}

impl HogArgs {
    fn human_size(&self, size: usize) -> String {
        match size {
            s if s < 1024 => format!("{} B", s),
            s if s < 1024 * 1024 => format!("{:.2} KB", s as f64 / 1024.0),
            s if s < 1024 * 1024 * 1024 => format!("{:.2} MB", s as f64 / 1024.0 / 1024.0),
            s => format!("{:.2} GB", s as f64 / 1024.0 / 1024.0 / 1024.0),
        }
    }
}
