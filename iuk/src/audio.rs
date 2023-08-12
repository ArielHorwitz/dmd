use anyhow::{anyhow, Result};
use clap::Args;
use crate::run_external::run;
use std::process::Command;

/// Get and set properties of default audio device
#[derive(Debug, Args)]
pub struct Cli {
    /// Set audio volume in percentage
    #[arg(value_name = "PERCENT")]
    volume: Option<f32>,
    /// Increase volume
    #[arg(short = 'i', long = "increase", value_name = "PERCENT")]
    increase: Option<f32>,
    /// Decrease volume
    #[arg(short = 'd', long = "decrease", value_name = "PERCENT")]
    decrease: Option<f32>,
    /// Mute volume
    #[arg(short, long)]
    mute: bool,
    /// Unmute volume
    #[arg(short, long)]
    unmute: bool,
}

pub fn resolve(cli: Cli) -> Result<()> {
    if let Some(volume) = cli.volume {
        set_volume(volume)?;
    } else if let Some(increase) = cli.increase {
        increment_volume(increase)?;
    } else if let Some(decrease) = cli.decrease {
        increment_volume(-decrease)?;
    } else if cli.mute {
        set_mute(Some(true))?;
    } else if cli.unmute {
        set_mute(Some(false))?;
    } else {
        println!("{}", get_volume()?);
    };
    Ok(())
}

pub fn get_volume() -> Result<u32> {
    let average = run(Command::new("pactl")
        .arg("get-sink-volume")
        .arg("@DEFAULT_SINK@"))?
    .split('/')
    .filter_map(|substr| {
        substr
            .trim()
            .strip_suffix('%')
            .unwrap_or("n/a")
            .parse::<u32>()
            .ok()
    })
    .sum::<u32>()
        / 2;
    Ok(average)
}

pub fn set_volume(value: f32) -> Result<()> {
    run(Command::new("pactl")
        .arg("set-sink-volume")
        .arg("@DEFAULT_SINK@")
        .arg(format!("{value}%")))?;
    Ok(())
}

pub fn increment_volume(value: f32) -> Result<()> {
    run(Command::new("pactl")
        .arg("set-sink-volume")
        .arg("@DEFAULT_SINK@")
        .arg(format!("{value:+}%")))?;
    Ok(())
}

pub fn get_mute() -> Result<bool> {
    let s = run(Command::new("pactl")
        .arg("get-sink-mute")
        .arg("@DEFAULT_SINK@"))?;
    let s = s
        .split(':')
        .collect::<Vec<&str>>()
        .get(1)
        .ok_or_else(|| anyhow!("parsing error"))?
        .trim();
    match s {
        "no" => Ok(false),
        "yes" => Ok(true),
        _ => Err(anyhow!("unknown value")),
    }
}

pub fn set_mute(value: Option<bool>) -> Result<()> {
    let value = match value {
        Some(v) => v,
        None => get_mute()?,
    };
    let set_as = match value {
        true => 1,
        false => 0,
    };
    run(Command::new("pactl")
        .arg("set-sink-mute")
        .arg("@DEFAULT_SINK@")
        .arg(format!("{set_as}")))?;
    Ok(())
}
