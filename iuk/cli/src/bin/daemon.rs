use anyhow::{anyhow, Result};
use clap::Args;
use commander::{DBUS_NAME, run_from_command, log::log};
use dbus::channel::MatchingReceiver;
use dbus::message::MatchRule;
use dbus_crossroads::Crossroads;
use dbus_tokio::connection;
use futures::future;

#[derive(Debug, Args)]
pub struct Cli {}

struct State;

#[tokio::main]
pub async fn main() -> Result<()> {
    let (resource, dbus_conn) = connection::new_session_sync()?;
    let _handle = tokio::spawn(async {
        let err = resource.await;
        anyhow!("Lost connection to D-Bus: {err}")
    });
    dbus_conn.request_name(DBUS_NAME, false, true, false).await?;
    let mut cross = Crossroads::new();
    cross.set_async_support(Some((
        dbus_conn.clone(),
        Box::new(|x| {
            tokio::spawn(x);
        }),
    )));
    let interface_token = cross.register(DBUS_NAME, |dbus| {
        // Arbitrary command
        dbus.method_with_cr_async(
            "command",
            ("command",),
            ("errors",),
            |mut ctx, _cr, (command,): (String,)| {
                async move {
                    let log_msg = format!("iukdaemon: received command {command:?}");
                    if let Err(e) = log(log_msg, true, true) {
                        return ctx.reply(Ok((e.to_string(),)));
                    };
                    match run_from_command(command.as_str()) {
                        Ok(_) => ctx.reply(Ok(("success".to_owned(),))),
                        Err(e) => ctx.reply(Ok((e.to_string(),))),
                    }
                }
            },
        );
    });
    // Register interface token
    cross.insert("/", &[interface_token], State);
    // Start listening
    dbus_conn.start_receive(
        MatchRule::new_method_call(),
        Box::new(move |msg, conn| {
            cross.handle_message(msg, conn).expect("handle message");
            true
        }),
    );
    log("Running iuk daemon.", true, true)?;
    future::pending::<()>().await;
    unreachable!()
}
