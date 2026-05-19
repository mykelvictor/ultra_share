use std::env;
use qrcode::QrCode;

mod protocol;
mod sender;
mod receiver;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        println!("UltraShare Engine Usage:");
        println!("  ultra_share receive <port>");
        println!("  ultra_share send <target_ip:port> <folder_path>");
        return Ok(());
    }

    match args[1].as_str() {
        "receive" => {
            let port: u16 = args.get(2).cloned().unwrap_or_else(|| "8080".to_string()).parse()?;
            let local_ip = "127.0.0.1"; 
            let connection_string = format!("{}:{}", local_ip, port);

            println!("\n=== SCAN TO CONNECT ===");
            let code = QrCode::new(connection_string.as_bytes())?;
            let string_render = code.render::<char>().quiet_zone(false).build();
            println!("{}", string_render);
            println!("=======================\n");

            receiver::run_receiver(port).await?;
        }
        "send" => {
            if args.len() < 4 {
                println!("Usage: ultra_share send <target_ip:port> <folder_path>");
                return Ok(());
            }
            let target = &args[2];
            let folder = &args[3];
            sender::run_sender(target, folder).await?;
        }
        _ => println!("Unknown command configuration structure."),
    }

    Ok(())
}

