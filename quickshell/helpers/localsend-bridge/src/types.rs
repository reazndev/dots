use serde::{Deserialize, Serialize};
use std::{collections::HashMap, path::PathBuf, sync::Arc};
use tokio::sync::{Mutex, mpsc, oneshot};

pub const VERSION: &str = "2.0";
pub const DEFAULT_PORT: u16 = 53317;

fn default_port() -> u16 {
    DEFAULT_PORT
}

fn default_protocol() -> String {
    "https".to_string()
}

#[derive(Clone)]
pub struct AppState {
    pub tx: mpsc::UnboundedSender<Event>,
    pub identity: DeviceInfo,
    pub receive_dir: PathBuf,
    pub incoming: Arc<Mutex<HashMap<String, IncomingSession>>>,
    pub devices: Arc<Mutex<HashMap<String, Device>>>,
    pub auto_accept: bool,
}

pub struct IncomingSession {
    pub files: HashMap<String, FileMeta>,
    pub tokens: HashMap<String, String>,
    pub responder: Option<oneshot::Sender<bool>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceInfo {
    pub alias: String,
    pub version: String,
    #[serde(rename = "deviceModel")]
    pub device_model: Option<String>,
    #[serde(rename = "deviceType")]
    pub device_type: Option<String>,
    pub fingerprint: String,
    #[serde(default = "default_port")]
    pub port: u16,
    #[serde(default = "default_protocol")]
    pub protocol: String,
    #[serde(default)]
    pub download: bool,
    #[serde(
        default,
        alias = "announcement",
        skip_serializing_if = "Option::is_none"
    )]
    pub announce: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Device {
    pub id: String,
    pub alias: String,
    pub address: String,
    pub port: u16,
    pub protocol: String,
    #[serde(rename = "deviceType")]
    pub device_type: Option<String>,
    pub fingerprint: String,
    pub download: bool,
    pub last_seen_ms: u128,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileMeta {
    pub id: String,
    #[serde(rename = "fileName")]
    pub file_name: String,
    pub size: u64,
    #[serde(rename = "fileType")]
    pub file_type: String,
    pub sha256: Option<String>,
    pub preview: Option<String>,
    pub metadata: Option<serde_json::Value>,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "cmd", rename_all = "snake_case")]
pub enum Command {
    Scan,
    AddFiles { files: Vec<String> },
    RemoveFile { path: String },
    Send { device_id: String },
    AcceptIncoming { request_id: String },
    RejectIncoming { request_id: String },
    Cancel { transfer_id: Option<String> },
    Clear,
}

#[derive(Debug, Serialize, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Event {
    Ready {
        alias: String,
        protocol: String,
        port: u16,
    },
    DeviceFound {
        device: Device,
    },
    ScanStarted,
    ScanFinished {
        count: usize,
    },
    FilesSet {
        files: Vec<SelectedFile>,
        total_size: u64,
    },
    IncomingRequest {
        request: IncomingRequest,
    },
    TransferProgress {
        transfer: TransferStatus,
    },
    TransferComplete {
        transfer_id: String,
        direction: String,
        message: String,
    },
    TransferError {
        transfer_id: Option<String>,
        message: String,
    },
    State {
        status: String,
    },
}

#[derive(Debug, Serialize, Clone)]
pub struct SelectedFile {
    pub path: String,
    pub name: String,
    pub size: u64,
}

#[derive(Debug, Serialize, Clone)]
pub struct IncomingRequest {
    pub id: String,
    pub sender: String,
    pub kind: String,
    pub file_count: usize,
    pub total_size: u64,
    pub files: Vec<FileMeta>,
}

#[derive(Debug, Serialize, Clone)]
pub struct TransferStatus {
    pub id: String,
    pub direction: String,
    pub device: String,
    pub file_name: String,
    pub progress: f64,
    pub transferred: u64,
    pub total: u64,
    pub status: String,
}

#[derive(Debug, Deserialize)]
pub struct PrepareUploadRequest {
    pub info: DeviceInfo,
    pub files: HashMap<String, FileMeta>,
}

#[derive(Debug, Serialize)]
pub struct PrepareUploadResponse {
    #[serde(rename = "sessionId")]
    pub session_id: String,
    pub files: HashMap<String, String>,
}

#[derive(Debug, Deserialize)]
pub struct UploadQuery {
    #[serde(rename = "sessionId")]
    pub session_id: String,
    #[serde(rename = "fileId")]
    pub file_id: String,
    pub token: String,
}

#[derive(Debug, Deserialize)]
pub struct CancelQuery {
    #[serde(rename = "sessionId")]
    pub session_id: String,
}

#[derive(Debug, Serialize)]
pub struct PrepareUploadBody {
    pub info: DeviceInfo,
    pub files: HashMap<String, FileMeta>,
}

#[derive(Debug, Deserialize)]
pub struct PrepareUploadResult {
    #[serde(rename = "sessionId")]
    pub session_id: String,
    pub files: HashMap<String, String>,
}
