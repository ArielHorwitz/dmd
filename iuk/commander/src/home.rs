use anyhow::{anyhow, Result};
use crate::archiver::{backup, restore, BackupArgs, RestoreArgs, Overwrite};
use std::{env, path::Path};
use clap::{Args, Subcommand};

/// Backup and restore your home directory.
#[derive(Debug, Args)]
pub struct CliArgs {
    #[command(subcommand)]
    command: Commands,
    /// Set verbosity
    #[arg(short, long)]
    verbose: bool,
}

#[derive(Debug, Subcommand)]
enum Commands {
    /// Backup the home directory
    Backup,
    /// Restore the home directory
    Restore,
    /// List files in the archive
    List,
    /// Print the archive file path
    Archive,
}

pub fn resolve(args: CliArgs) -> Result<()> {
    let home_env = env::var("HOME")?;
    let home_path = Path::new(&home_env);
    if !home_path.is_dir() {
        return Err(anyhow!("invalid home directory: {home_path:?}"));
    }
    let home = home_path
        .to_str()
        .ok_or_else(|| anyhow!("invalid home directory: {home_path:?}"))?
        .to_owned();
    let archive = format!("{home}/.local/share/iukbtw/home.tgz");
    let mut spec = format!("{home}/.local/share/iukbtw/home_spec");
    if !Path::new(&spec).is_file() {
        spec = String::from("/etc/iukbtw/home_spec");
    }
    match args.command {
        Commands::Backup => {
            let args = BackupArgs {
                directory: home,
                archive,
                spec: Some(spec),
                verbose: args.verbose,
            };
            backup(args)
        }
        Commands::Restore => {
            let args = RestoreArgs {
                directory: Some(home),
                archive,
                overwrite: Some(Overwrite::Force),
                verbose: args.verbose,
            };
            restore(args)
        }
        Commands::List => {
            let args = RestoreArgs {
                directory: None,
                archive,
                overwrite: None,
                verbose: args.verbose,
            };
            restore(args)
        }
        Commands::Archive => {
            println!("{archive}");
            Ok(())
        }
    }
}

