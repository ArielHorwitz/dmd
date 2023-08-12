use crate::{DBUS_NAME, DBUS_TIMEOUT_SECONDS};
use anyhow::{anyhow, Result};
use clap::Args;
use dbus::nonblock;
use dbus_tokio::connection;
use std::time::Duration;
use tokio::runtime::Runtime;

/// Send a message to the iuk server
#[derive(Debug, Args)]
pub struct Cli {
    #[arg(value_name = "COMMAND")]
    command: String,
}

pub fn resolve(args: Cli) -> Result<()> {
    Runtime::new().expect("tokio runtime").block_on(run(args))
}

async fn run(args: Cli) -> Result<()> {
    let (resource, conn) = connection::new_session_sync()?;
    let _handle = tokio::spawn(async {
        let err = resource.await;
        anyhow!("Lost connection to D-Bus: {err}")
    });

    // let mr = MatchRule::new_signal(DBUS_NAME, "LayerSwitch");
    // let incoming_signal = conn.add_match(mr).await?.cb(|_, (layer,): (String,)| {
    //     println!("Layer switch to {layer} (from bus)");
    //     true
    // });

    let proxy = nonblock::Proxy::new(
        DBUS_NAME,
        "/",
        Duration::from_secs(DBUS_TIMEOUT_SECONDS),
        conn.clone(),
    );
    let (response,): (String,) = proxy
        .method_call(DBUS_NAME, "command", (args.command,))
        .await
        .expect("switch layer method call");
    println!("{response}");

    // if let Err(e) = conn.remove_match(incoming_signal.token()).await {
    //     eprintln!("Failed to remove match: {e}");
    // };
    Ok(())
}
