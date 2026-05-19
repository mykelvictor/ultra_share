use crate::sender::run_sender;
use crate::receiver::run_receiver;

pub fn start_native_send(target_address: String, folder_path: String) {
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let _ = run_sender(&target_address, &folder_path).await;
    });
}

pub fn start_native_receive(port: u16) {
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let _ = run_receiver(port).await;
    });
}

