use crate::run_external::run;
use anyhow::{anyhow, Result};
use clap::{Parser, ValueEnum};
use std::collections::HashMap;
use std::process::Command;

const PARSE_ERROR_MSG: &str = "failed to parse console output";

/// Control the mouse
#[derive(Debug, Parser)]
pub struct Args {
    /// Move mouse to center or edges of the active window (defaults to center)
    #[arg(long, value_name = "EDGE", num_args = 0..=2, value_enum)]
    window: Option<Vec<WindowEdge>>,
    /// Click a button
    #[arg(long)]
    click: Option<u8>,
}

#[derive(ValueEnum, Copy, Clone, Debug, PartialEq, Eq)]
pub enum WindowEdge {
    Top,
    Bottom,
    Left,
    Right,
}

pub fn resolve(args: Args) -> Result<()> {
    if let Some(edges) = args.window {
        move_window_corner(
            edges.contains(&WindowEdge::Top),
            edges.contains(&WindowEdge::Bottom),
            edges.contains(&WindowEdge::Left),
            edges.contains(&WindowEdge::Right),
        )?;
    }
    if let Some(click) = args.click {
        click_button(click)?;
    }
    Ok(())
}

#[derive(Debug)]
struct WindowGeometry {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
}


/// Click a mouse button.
fn click_button(button: u8) -> Result<()> {
    run(Command::new("xdotool")
        .arg("click")
        .arg(format!("{button}")))?;
    Ok(())
}

/// Move mouse to center or edges of the active window.
///
/// Top overrides bottom and left overrides right.
fn move_window_corner(top: bool, bottom: bool, left: bool, right: bool) -> Result<()> {
    let stdout = run(Command::new("xdotool")
        .arg("getactivewindow")
        .arg("getwindowgeometry")
        .arg("--shell"))?;
    let mut data: HashMap<String, String> = HashMap::new();
    for line in stdout.split('\n').filter(|line| line.contains('=')) {
        let fields: Vec<&str> = line.split('=').collect();
        let key = fields.first().ok_or_else(|| anyhow!(PARSE_ERROR_MSG))?;
        let value = fields.get(1).ok_or_else(|| anyhow!(PARSE_ERROR_MSG))?;
        data.insert(key.to_owned().to_owned(), value.to_owned().to_owned());
    }
    let wingeo = WindowGeometry {
        x: data.get("X").expect(PARSE_ERROR_MSG).parse()?,
        y: data.get("Y").expect(PARSE_ERROR_MSG).parse()?,
        h: data.get("HEIGHT").expect(PARSE_ERROR_MSG).parse()?,
        w: data.get("WIDTH").expect(PARSE_ERROR_MSG).parse()?,
    };
    let x = wingeo.x
        + match (left, right) {
            (true, _) => 1,
            (_, true) => wingeo.w - 1,
            _ => wingeo.w / 2,
        };
    let y = wingeo.y
        + match (top, bottom) {
            (true, _) => 1,
            (_, true) => wingeo.h - 1,
            _ => wingeo.h / 2,
        };
    run(Command::new("xdotool")
        .arg("mousemove")
        .arg(format!("{x}"))
        .arg(format!("{y}")))?;
    Ok(())
}
