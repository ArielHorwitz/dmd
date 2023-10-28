use anyhow::Result;
use chrono::Utc;
use clap::Parser;
use std::{
    env,
    fmt::Display,
    fs::{OpenOptions, remove_file},
    io::{Write, Read},
    path::Path,
};

const LOGFILE_NAME: &str = "/.iuklog";

fn logfile_path() -> Result<String> {
    Ok(format!("{}/{LOGFILE_NAME}", env::var("HOME")?))
}

/// Log a message or manage the log file
#[derive(Debug, Parser)]
pub struct Args {
    /// Message to log
    #[arg(value_name = "MESSAGE")]
    message: Option<String>,
    /// Do not print message to stdout
    #[arg(short='p', long)]
    no_print: bool,
    /// Do not prefix timestamp to message
    #[arg(short='t', long)]
    no_timestamp: bool,
    /// Reset the log file
    #[arg(short, long)]
    reset: bool,
}

pub fn resolve(args: Args) -> Result<()> {
    if args.reset {
        let log_path = logfile_path()?;
        if Path::new(&log_path).exists() {
            remove_file(log_path.clone())?;
            OpenOptions::new().create(true).open(log_path)?;
        };
    };
    if let Some(message) = args.message {
        log(message, !args.no_timestamp, !args.no_print)?;
    } else if !args.reset {
        print_logfile()?;
    };
    Ok(())
}


pub fn print_logfile() -> Result<()> {
    let mut file = std::fs::File::open(logfile_path()?)?;
    let mut contents = String::new();
    file.read_to_string(&mut contents)?;
    print!("{contents}");
    Ok(())
}

pub fn log<T>(message: T, timestamp: bool, print: bool) -> Result<()>
where
    String: From<T>,
    T: Display,
{
    // Format
    let mut log_message = String::default();
    if timestamp {
        let timestamp = Utc::now().format("%Y-%m-%d %H:%M:%S");
        log_message.push_str(format!("{timestamp} | ").as_str());
    }
    log_message.push_str(format!("{message}\n").as_str());
    // Write
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(logfile_path()?)?;
    file.write_all(log_message.as_bytes())?;
    // Print
    if print {
        print!("{log_message}");
    };
    Ok(())
}

