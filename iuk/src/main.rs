use anyhow::Result;
use clap::{Parser, Subcommand};
use std::env;
mod audio;
mod client;
mod mouse;
mod run_external;
mod scratch;
mod server;

pub const DBUS_NAME: &str = "com.iukbtw.iuk";
pub const DBUS_TIMEOUT_SECONDS: u64 = 10;

fn main() -> Result<()> {
    let cli = Cli::parse();
    run(cli)
}

pub fn run(cli: Cli) -> Result<()> {
    match cli.command {
        Commands::Env => print_env(),
        Commands::Audio(args) => audio::resolve(args),
        Commands::Mouse(args) => mouse::resolve(args),
        Commands::Scratch(args) => scratch::resolve(args),
        Commands::Server(args) => server::resolve(args),
        Commands::Client(args) => client::resolve(args),
    }?;
    Ok(())
}

fn print_env() -> Result<()> {
    for v in env::vars() {
        println!("{v:?}");
    }
    Ok(())
}

#[derive(Debug, Parser)]
#[command(name = "iuk")]
#[command(about = "I use KMonad, btw.", long_about = include_str!("../ABOUT"))]
#[command(author = "https://ariel.ninja")]
pub struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    Audio(audio::Cli),
    Mouse(mouse::Cli),
    Scratch(scratch::Cli),
    Server(server::Cli),
    Client(client::Cli),
    /// Print environment variables
    Env,
}
