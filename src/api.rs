use crate::sender::run_sender;
use crate::receiver::run_receiver;

// This function will be callable directly from your Flutter Dart files!
pub fn start_native_send(target_address: String, folder_path: String) -> Result<(), String> {
    tokio::runtime::Runtime::new()
        .map_err(|e| e.to_string())?
        .block_on(async {
            run_sender(&target_address, &folder_path)
                .await
                .map_err(|e| e.to_string())
        })
}

pub fn start_native_receive(port: u16) -> Result<(), String> {
    tokio::runtime::Runtime::new()
        .map_err(|e| e.to_string())?
        .block_on(async {
            run_receiver(port)
                .await
                .map_err(|e| e.to_string())
        })
}
