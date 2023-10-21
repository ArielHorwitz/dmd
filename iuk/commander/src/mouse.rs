use anyhow::{anyhow, Result};
use crate::run_external::run;
use std::collections::HashMap;
use std::process::Command;
use clap::{Args, ValueEnum};

const PARSE_ERROR_MSG: &str = "failed to parse console output";

/// Control mouse
#[derive(Debug, Args)]
pub struct Cli {
    /// Move mouse to window corner
    #[arg(
        long,
        value_name = "EDGE",
        num_args = 0..=2,
        value_enum
    )]
    window: Vec<WindowEdge>,
}

#[derive(ValueEnum, Copy, Clone, Debug, PartialEq, Eq)]
pub enum WindowEdge {
    Top,
    Bottom,
    Left,
    Right,
}

pub fn resolve(cli: Cli) -> Result<()> {
    move_window_corner(
        cli.window.contains(&WindowEdge::Top),
        cli.window.contains(&WindowEdge::Bottom),
        cli.window.contains(&WindowEdge::Left),
        cli.window.contains(&WindowEdge::Right),
    )?;
    Ok(())
}


#[derive(Debug)]
struct WindowGeometry {
    x: i32,
    y: i32,
    w: i32,
    h: i32,
}

/// Move mouse to center/corner/edge of window
///
/// Top overrides bottom and left overrides right.
pub fn move_window_corner(
    top: bool,
    bottom: bool,
    left: bool,
    right: bool,
) -> Result<()> {
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
