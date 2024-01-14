use crate::run_external::run;
use anyhow::Result;
use clap::Parser;
use std::process::Command;

/// Get and set properties of default audio device
#[derive(Debug, Parser)]
pub struct Args {
    /// Set audio volume in percentage
    #[arg(value_name = "PERCENT")]
    volume: Option<f32>,
    /// Increase volume
    #[arg(short, long, value_name = "PERCENT")]
    increase: Option<f32>,
    /// Decrease volume
    #[arg(short, long, value_name = "PERCENT")]
    decrease: Option<f32>,
    /// Mute volume
    #[arg(short, long)]
    mute: bool,
    /// Unmute volume
    #[arg(short, long)]
    unmute: bool,
    /// Set default device
    #[arg(long, value_name = "DEVICE")]
    default: Option<String>,
    /// Devices
    #[arg(long)]
    devices: bool,
}

pub fn resolve(args: Args) -> Result<()> {
    if let Some(volume) = args.volume {
        set_volume(volume)?;
    } else if let Some(increase) = args.increase {
        increment_volume(increase)?;
    } else if let Some(decrease) = args.decrease {
        increment_volume(-decrease)?;
    } else if args.mute {
        set_mute(Some(true))?;
    } else if args.unmute {
        set_mute(Some(false))?;
    } else if let Some(device) = args.default {
        set_default(device)?;
    } else if args.devices {
        print_devices()?;
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

pub fn print_devices() -> Result<()> {
    let output = run(Command::new("pactl").arg("list").arg("short"))?;
    println!("{output}");
    Ok(())
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

pub fn set_mute(value: Option<bool>) -> Result<()> {
    let set_as = match value {
        Some(true) => "1",
        Some(false) => "0",
        None => "toggle",
    };
    run(Command::new("pactl")
        .arg("set-sink-mute")
        .arg("@DEFAULT_SINK@")
        .arg(set_as))?;
    Ok(())
}

pub fn set_default(device: String) -> Result<()> {
    run(Command::new("pactl")
        .arg("set-default-sink")
        .arg(device.as_str()))?;
    Ok(())
}
