use commander::{DBUS_NAME, DBUS_TIMEOUT_SECONDS};
use anyhow::Result;
use dbus::nonblock;
use dbus_tokio::connection;
use std::{env, time::Duration};

#[tokio::main]
async fn main() -> Result<()> {
    let user_input: String = env::args().collect::<Vec<String>>().join(" ");
    println!(">> {user_input:?}");
    let (resource, conn) = connection::new_session_sync()?;
    let _handle = tokio::spawn(async {
        let err = resource.await;
        eprintln!("Lost connection to D-Bus: {err}")
    });
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
    Ok(())
}
