use anyhow::Result;
use clap::{Parser, Subcommand};
use std::env;
mod audio;
mod mouse;
mod run_external;
mod scratch;

pub const DBUS_NAME: &str = "com.iukbtw.iuk";
pub const DBUS_TIMEOUT_SECONDS: u64 = 2;

pub fn run() -> Result<()> {
    run_from_parsed(Cli::parse())
}

pub fn run_from_command(command: &str) -> Result<()> {
    let args = shellwords::split(command)?;
    run_from_parsed(Cli::try_parse_from(args)?)
}

fn run_from_parsed(cli: Cli) -> Result<()> {
    match cli.command {
        Commands::Env => print_env(),
        Commands::Audio(args) => audio::resolve(args),
        Commands::Mouse(args) => mouse::resolve(args),
        Commands::Scratch(args) => scratch::resolve(args),
    }?;
    Ok(())
}

fn print_env() -> Result<()> {
    for v in env::vars() {
        println!("{}={:?}", v.0, v.1);
    }
    Ok(())
}

#[derive(Debug, Parser)]
#[command(name = "iuk")]
#[command(about = "I use KMonad, btw.", long_about = include_str!("../../ABOUT"))]
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
    /// Print environment variables
    Env,
}
