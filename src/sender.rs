use tokio::net::TcpStream;
use tokio::io::AsyncWriteExt;
use tokio::fs::File;
use tokio::io::AsyncReadExt;
use walkdir::WalkDir;
use std::path::Path;

pub async fn run_sender(target_address: &str, folder_path: &str) -> Result<(), Box<dyn std::error::Error>> {
    println!("Connecting to receiver at {}...", target_address);
    let mut socket = TcpStream::connect(target_address).await?;
    
    let mut files = Vec::new();
    let base_path = Path::new(folder_path);

    // 1. Scan the folder directory structure
    for entry in WalkDir::new(base_path).into_iter().filter_map(|e| e.ok()) {
        if entry.file_type().is_file() {
            let relative_path = entry.path().strip_prefix(base_path)?.to_string_lossy().into_owned();
            let file_size = entry.metadata()?.len();
            files.push(crate::protocol::FileMetadata { relative_path, file_size });
        }
    }

    // 2. Send the manifest blueprint first
    let manifest = crate::protocol::FolderManifest { files: files.clone() };
    let serialized_manifest = bincode::serialize(&manifest)?;
    let manifest_len = serialized_manifest.len() as u32;
    socket.write_all(&manifest_len.to_be_bytes()).await?;
    socket.write_all(&serialized_manifest).await?;
    println!("Folder blueprint transmitted. Starting extreme speed data pipeline...");

    // 3. Blasting File Chunks (The Payload Engine)
    const CHUNK_SIZE: usize = 1024 * 1024; // 1MB packet blocks
    let mut buffer = vec![0u8; CHUNK_SIZE];

    for (file_idx, meta) in files.iter().enumerate() {
        let full_path = base_path.join(&meta.relative_path);
        let mut file = File::open(full_path).await?;
        let mut offset = 0u64;

        loop {
            let bytes_read = file.read(&mut buffer).await?;
            if bytes_read == 0 { break; } // Finished reading this file

            // Create binary chunk header frame
            let header = crate::protocol::PacketHeader::DataChunk {
                file_index: file_idx as u32,
                offset,
                chunk_size: bytes_read as u32,
            };
            let serialized_header = bincode::serialize(&header)?;
            let header_len = serialized_header.len() as u32;

            // Frame Assembly: [Header Size] -> [Header Payload] -> [Raw File Bytes]
            socket.write_all(&header_len.to_be_bytes()).await?;
            socket.write_all(&serialized_header).await?;
            socket.write_all(&buffer[..bytes_read]).await?;

            offset += bytes_read as u64;
        }
    }

    // 4. Send end-of-transfer signal frame
    let closing_header = crate::protocol::PacketHeader::TransferComplete;
    let serialized_close = bincode::serialize(&closing_header)?;
    let close_len = serialized_close.len() as u32;
    socket.write_all(&close_len.to_be_bytes()).await?;
    socket.write_all(&serialized_close).await?;

    println!("✓ All chunks successfully blasted across the network!");
    Ok(())
}

