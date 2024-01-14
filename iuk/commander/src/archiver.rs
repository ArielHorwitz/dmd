use crate::run_external::run;
use anyhow::{anyhow, Result};
use clap::{Parser, Subcommand, ValueEnum};
use std::{path::Path, process::Command};

/// Backup and restore a directory to/from a compressed archive.
#[derive(Debug, Parser)]
pub struct Args {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    Backup(BackupArgs),
    Restore(RestoreArgs),
    Home(HomeArgs),
}

/// Backup a directory recursively to a compressed archive.
#[derive(Debug, Parser)]
pub struct BackupArgs {
    /// Path to the directory to backup
    #[arg()]
    pub directory: String,
    /// Path to the output archive file
    #[arg()]
    pub archive: String,
    /// Path to filter spec.
    ///
    /// Should be a text file with a relative file path on each line, indicating
    /// which files to backup.
    #[arg(short, long)]
    pub spec: Option<String>,
    /// Set verbose output
    #[arg(short, long)]
    pub verbose: bool,
}

/// Restore a directory recursively from a compressed archive.
#[derive(Debug, Parser)]
pub struct RestoreArgs {
    /// Path to the archive file
    #[arg()]
    pub archive: String,
    /// Restore to this directory (will be created if does not exist).
    ///
    /// Leave this blank to list archive contents.
    #[arg()]
    pub directory: Option<String>,
    /// Overwrite behavior
    #[arg(short, long)]
    pub overwrite: Option<Overwrite>,
    /// Set verbose output
    #[arg(short, long)]
    pub verbose: bool,
}
/// Backup and restore your home directory.
#[derive(Debug, Parser)]
pub struct HomeArgs {
    #[command(subcommand)]
    command: HomeCommands,
    /// Set verbosity
    #[arg(short, long)]
    verbose: bool,
}

#[derive(Debug, Subcommand)]
enum HomeCommands {
    /// Backup the home directory
    Backup,
    /// Restore the home directory
    Restore,
    /// List files in the archive
    List,
    /// Print the archive file path
    Archive,
}

/// Overwrite behavior
#[derive(Debug, Clone, ValueEnum)]
pub enum Overwrite {
    /// Skip conflicting files
    Skip,
    /// Remove existing files
    Force,
    /// Backup and remove existing files
    Backup,
    /// Backup and remove existing files with numbered suffix
    Numbered,
}

pub fn resolve(args: Args) -> Result<()> {
    match args.command {
        Commands::Backup(args) => backup(args),
        Commands::Restore(args) => restore(args),
        Commands::Home(args) => home(args),
    }
}

pub fn backup(args: BackupArgs) -> Result<()> {
    let source = Path::new(&args.directory);
    let archive = Path::new(&args.archive);
    let mut cmd = Command::new("tar");
    cmd.arg("-C")
        .arg(source.as_os_str())
        .arg("-zcf")
        .arg(archive.as_os_str());
    if args.verbose {
        cmd.arg("--verbose");
    }
    if let Some(spec) = args.spec {
        let mut spec_file = Path::new(&spec);
        if !spec_file.is_file() {
            spec_file = Path::new("/etc/iukbtw/home_spec");
        }
        let spec_contents = std::fs::read_to_string(spec_file)?;
        cmd.args(spec_contents.split('\n').filter(|p| !p.is_empty()));
    } else {
        cmd.arg(".");
    }
    println!("{}", run(&mut cmd)?);
    Ok(())
}

pub fn restore(args: RestoreArgs) -> Result<()> {
    let archive = Path::new(&args.archive);
    if let Some(directory) = args.directory {
        let target = Path::new(&directory);
        let mut cmd = Command::new("tar");
        cmd.arg("-C")
            .arg(target.as_os_str())
            .arg("-zxf")
            .arg(archive.as_os_str());
        match args.overwrite.unwrap_or(Overwrite::Skip) {
            Overwrite::Skip => cmd.arg("--keep-old-files"),
            Overwrite::Force => cmd.arg("--overwrite"),
            Overwrite::Backup => cmd.arg("--backup"),
            Overwrite::Numbered => cmd.arg("--backup=numbered"),
        };
        if args.verbose {
            cmd.arg("--verbose");
        }
        if !target.exists() {
            std::fs::create_dir_all(target)?;
        }
        println!("{}", run(&mut cmd)?);
    } else {
        // only list contents of archive
        let mut cmd = Command::new("tar");
        cmd.arg("-tf").arg(archive.as_os_str());
        println!("{}", run(&mut cmd)?);
        return Ok(());
    }
    Ok(())
}

pub fn home(args: HomeArgs) -> Result<()> {
    let home_env = std::env::var("HOME")?;
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
        HomeCommands::Backup => {
            let args = BackupArgs {
                directory: home,
                archive,
                spec: Some(spec),
                verbose: args.verbose,
            };
            backup(args)
        }
        HomeCommands::Restore => {
            let args = RestoreArgs {
                directory: Some(home),
                archive,
                overwrite: Some(Overwrite::Force),
                verbose: args.verbose,
            };
            restore(args)
        }
        HomeCommands::List => {
            let args = RestoreArgs {
                directory: None,
                archive,
                overwrite: None,
                verbose: args.verbose,
            };
            restore(args)
        }
        HomeCommands::Archive => {
            println!("{archive}");
            Ok(())
        }
    }
}
