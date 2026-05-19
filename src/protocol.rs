   use serde::{Serialize, Deserialize};

   #[derive(Serialize, Deserialize, Debug, Clone)]
   pub struct FileMetadata {
       pub relative_path: String,
       pub file_size: u64,
   }

   #[derive(Serialize, Deserialize, Debug)]
   pub struct FolderManifest {
       pub files: Vec<FileMetadata>,
   }

   #[derive(Serialize, Deserialize, Debug)]
   pub enum PacketHeader {
       Manifest(FolderManifest),
       DataChunk {
           file_index: u32,
           offset: u64,
           chunk_size: u32,
       },
       TransferComplete,
   }
