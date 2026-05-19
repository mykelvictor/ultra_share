mod protocol;
mod sender;
mod receiver;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        println!("UltraShare MVP Execution Guide:");
        println!("  To Receive: ultra_share receive <port>");
        println!("  To Send   : ultra_share send <target_ip:port> <folder_path>");
        return Ok(());
    }
    match args[1].as_str() {
        "receive" => {
            let port = args.get(2).and_then(|p| p.parse().ok()).unwrap_or(8080);
            receiver::run_receiver(port).await?;
        }
        "send" => {
            let target = args.get(2).expect("Provide a target IP:Port configuration.");
            let path = args.get(3).expect("Provide target folder path to send.");
            sender::run_sender(target, path).await?;
        }
        _ => println!("Invalid selection."),
    }
    Ok(())
}

