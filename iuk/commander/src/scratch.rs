use anyhow::{Result, anyhow};
use crate::run_external::run;
use std::process::Command;
use clap::Args;

/// Show or send to scratchpad
#[derive(Debug, Args)]
pub struct Cli {
    /// Show pad # (toggle)
    #[arg(short, long, required = false)]
    show: Option<u16>,
    /// Move to pad #
    #[arg(short, long = "move", required = false)]
    move_to: Option<u16>,
}

pub fn resolve(cli: Cli) -> Result<()> {
    if let Some(pad) = cli.show {
        return toggle_show(pad);
    };
    if let Some(pad) = cli.move_to {
        return move_to(pad);
    };
    Err(anyhow!("Unspecified command"))
}

fn toggle_show(scratchpad: u16) -> Result<()> {
    run(Command::new("i3-msg")
        .arg(format!(r#"[class="Scratchpad {scratchpad}"] scratchpad show"#)))?;
    Ok(())
}

fn move_to(scratchpad: u16) -> Result<()> {
    // set window class name for identification by i3
    run(Command::new("xdotool")
        .arg("getactivewindow")
        .arg("set_window")
        .arg("--class")
        .arg(format!("Scratchpad {scratchpad}")))?;
    // actually move it
    run(Command::new("i3-msg").arg("move scratchpad"))?;
    Ok(())
}
