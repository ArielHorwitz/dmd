use anyhow::Result;
use clap::Parser;
use std::process::Command;
use iuk::run;

#[derive(Parser, Debug)]
#[command(name = "iukbtw")]
#[command(author = "https://ariel.ninja")]
#[command(about)]
#[command(version)]
struct Args {
    /// List binaries
    #[arg(short, long)]
    list: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();
    if args.list {
        run(Command::new("ls")
            .arg("-1")
            .arg("/usr/bin/iukbtw/"))?;
    }
    Ok(())
}
