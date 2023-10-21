use commander::{DBUS_NAME, DBUS_TIMEOUT_SECONDS};
use anyhow::{anyhow, Result};
use dbus::nonblock;
use dbus_tokio::connection;
use std::{env, time::Duration};

#[tokio::main]
async fn main() -> Result<()> {
    let user_input: String = env::args().collect::<Vec<String>>().join(" ");
    println!("User input: {user_input:?}");
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
        .method_call(DBUS_NAME, "command", (user_input,))
        .await
        .expect("switch layer method call");
    println!("{response}");

    // if let Err(e) = conn.remove_match(incoming_signal.token()).await {
    //     eprintln!("Failed to remove match: {e}");
    // };
    Ok(())
}
