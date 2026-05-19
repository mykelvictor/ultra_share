use tokio::net::TcpListener;
use tokio::io::AsyncReadExt;
use std::fs::{self, OpenOptions};
use std::io::{Write, Seek, SeekFrom};

pub async fn run_receiver(port: u16) -> Result<(), Box<dyn std::error::Error>> {
    let listener = TcpListener::bind(format!("0.0.0.0:{}", port)).await?;
    println!("Receiver active on port {}... Streaming pipeline open.", port);

    let (mut socket, _) = listener.accept().await?;
    
    // Read the metadata manifest layout length prefix
    let mut size_buf = [0u8; 4];
    socket.read_exact(&mut size_buf).await?;
    let manifest_len = u32::from_be_bytes(size_buf) as usize;

    let mut manifest_buf = vec![0u8; manifest_len];
    socket.read_exact(&mut manifest_buf).await?;
    let manifest: crate::protocol::FolderManifest = bincode::deserialize(&manifest_buf)?;

    // Create the blank target framework on storage instantly
    println!("Pre-allocating folder framework layouts for {} files...", manifest.files.len());
    let mut open_files = Vec::new();
    for file_meta in &manifest.files {
        if let Some(parent) = std::path::Path::new(&file_meta.relative_path).parent() {
            fs::create_dir_all(parent)?;
        }
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open(&file_meta.relative_path)?;
        file.set_len(file_meta.file_size)?; // Pre-allocates space to eliminate disk fragmentation
        open_files.push(file);
    }

    // Process incoming live file chunks from network stream
    let mut chunk_buffer = vec![0u8; 1024 * 1024]; // 1MB read buffer
    loop {
        // Read next frame header size packet
        if socket.read_exact(&mut size_buf).await.is_err() { break; }
        let header_len = u32::from_be_bytes(size_buf) as usize;

        let mut header_buf = vec![0u8; header_len];
        socket.read_exact(&mut header_buf).await?;
        let header_frame: crate::protocol::PacketHeader = bincode::deserialize(&header_buf)?;

        match header_frame {
            crate::protocol::PacketHeader::DataChunk { file_index, offset, chunk_size } => {
                let target_len = chunk_size as usize;
                socket.read_exact(&mut chunk_buffer[..target_len]).await?;
                
                // Universal cross-platform high-speed write (Works on Windows, Mac, & Linux)
                let mut target_file = &open_files[file_index as usize];
                target_file.seek(SeekFrom::Start(offset))?;
                target_file.write_all(&chunk_buffer[..target_len])?;
            }
            crate::protocol::PacketHeader::TransferComplete => {
                println!("✓ Transfer finished! Folder successfully assembled natively.");
                break;
            }
            _ => {}
        }
    }

    Ok(())
}

