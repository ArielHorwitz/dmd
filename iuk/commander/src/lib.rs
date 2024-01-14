use anyhow::Result;
use clap::{Parser, Subcommand};
mod archiver;
mod audio;
pub mod log;
mod mouse;
mod run_external;

pub const DBUS_NAME: &str = "com.iukbtw.iuk";
pub const DBUS_TIMEOUT_SECONDS: u64 = 2;

pub fn run() -> Result<()> {
    run_from_parsed(Args::parse())
}

pub fn run_from_command(command: &str) -> Result<()> {
    let args = shellwords::split(command)?;
    run_from_parsed(Args::try_parse_from(args)?)
}

fn run_from_parsed(args: Args) -> Result<()> {
    match args.command {
        Commands::Audio(args) => audio::resolve(args),
        Commands::Mouse(args) => mouse::resolve(args),
        Commands::Archiver(args) => archiver::resolve(args),
        Commands::Command(args) => run_external::resolve(args),
        Commands::Log(args) => log::resolve(args),
    }?;
    Ok(())
}

#[derive(Debug, Parser)]
#[command(name = "iuk")]
#[command(about = "I use KMonad, btw.")]
#[command(long_about = include_str!("../../ABOUT"))]
#[command(author = "https://ariel.ninja")]
#[command(version)]
struct Args {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    Log(log::Args),
    Audio(audio::Args),
    Mouse(mouse::Args),
    Archiver(archiver::Args),
    Command(run_external::Args),
}
