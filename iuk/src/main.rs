use anyhow::Result;
use clap::{Parser, Subcommand};
mod audio;
mod mouse;
mod scratch;
mod run_external;

pub const DBUS_NAME: &str = "com.iukbtw.iuk";
pub const DBUS_TIMEOUT_SECONDS: u64 = 10;

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Commands::Audio(args) => audio::resolve(args)?,
        Commands::Mouse(args) => mouse::resolve(args)?,
        Commands::Scratch(args) => scratch::resolve(args)?,
    }
    Ok(())
}

#[derive(Debug, Parser)]
#[command(name = "iuk")]
#[command(about = "I use KMonad, btw.", long_about = include_str!("../ABOUT"))]
#[command(author = "https://ariel.ninja")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    Audio(audio::Cli),
    Mouse(mouse::Cli),
    Scratch(scratch::Cli),
}
