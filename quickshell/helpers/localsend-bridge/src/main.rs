mod clipboard;
mod discovery;
mod events;
mod http;
mod transfer;
mod types;
mod utils;

use anyhow::Result;
use rcgen::{CertifiedKey, generate_simple_self_signed};
use reqwest::Client;
use std::{collections::HashMap, sync::Arc, time::Duration};
use tokio::{
    fs,
    sync::{Mutex, mpsc},
};

use crate::{
    discovery::{multicast_announce, spawn_udp_listener, subnet_scan},
    events::{emit, emit_files_set, spawn_stdin_reader, spawn_stdout_writer},
    http::{respond_incoming, spawn_http_servers},
    transfer::send_files,
    types::{
        AppState, Command, DEFAULT_PORT, Device, DeviceInfo, Event, IncomingSession, SelectedFile,
        VERSION,
    },
    utils::{available_port, dirs_download, hex_sha256, normalize_file_url, persisted_fingerprint},
};

#[tokio::main]
async fn main() -> Result<()> {
    let _ = rustls::crypto::ring::default_provider().install_default();
    let auto_accept = std::env::args().any(|arg| arg == "--auto-accept");

    let alias = hostname::get()
        .ok()
        .and_then(|h| h.into_string().ok())
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| "Quickshell".to_string());
    let _http_fingerprint = persisted_fingerprint().await?;
    let (tx, mut rx) = mpsc::unbounded_channel::<Event>();
    let (cmd_tx, mut cmd_rx) = mpsc::unbounded_channel::<Command>();
    let headless_keepalive = if auto_accept {
        Some(cmd_tx.clone())
    } else {
        None
    };
    let devices = Arc::new(Mutex::new(HashMap::<String, Device>::new()));
    let selected_files = Arc::new(Mutex::new(Vec::<SelectedFile>::new()));
    let receive_dir = dirs_download().unwrap_or_else(|| ".".into());
    fs::create_dir_all(&receive_dir).await.ok();

    let CertifiedKey { cert, key_pair } =
        generate_simple_self_signed(vec![alias.clone(), "localhost".to_string()])?;
    let cert_der = cert.der().as_ref().to_vec();
    let cert_pem = cert.pem();
    let key_pem = key_pair.serialize_pem();
    let bind_port = available_port(DEFAULT_PORT).await.unwrap_or(DEFAULT_PORT);

    let identity = DeviceInfo {
        alias: alias.clone(),
        version: VERSION.to_string(),
        device_model: Some("Linux".to_string()),
        device_type: Some("desktop".to_string()),
        fingerprint: hex_sha256(&cert_der),
        port: bind_port,
        protocol: "https".to_string(),
        download: false,
        announce: None,
    };

    let state = AppState {
        tx: tx.clone(),
        identity: identity.clone(),
        receive_dir,
        incoming: Arc::new(Mutex::new(HashMap::<String, IncomingSession>::new())),
        devices: devices.clone(),
        auto_accept,
    };

    spawn_stdout_writer(&mut rx);
    spawn_stdin_reader(cmd_tx);
    spawn_http_servers(state.clone(), bind_port, cert_pem, key_pem).await?;
    spawn_udp_listener(state.clone(), devices.clone());

    emit(
        &tx,
        Event::Ready {
            alias,
            protocol: identity.protocol.clone(),
            port: bind_port,
        },
    );

    let client = Client::builder()
        .danger_accept_invalid_certs(true)
        .timeout(Duration::from_secs(30))
        .build()?;

    while let Some(cmd) = cmd_rx.recv().await {
        match cmd {
            Command::Scan => {
                let tx = tx.clone();
                let devices = devices.clone();
                let identity = identity.clone();
                let client = client.clone();
                tokio::spawn(async move {
                    emit(&tx, Event::ScanStarted);
                    if let Err(err) = multicast_announce(&identity).await {
                        emit(
                            &tx,
                            Event::TransferError {
                                transfer_id: None,
                                message: format!("Discovery failed: {err}"),
                            },
                        );
                    }
                    tokio::time::sleep(Duration::from_secs(2)).await;
                    if devices.lock().await.is_empty() {
                        subnet_scan(&tx, &devices, &client, &identity).await;
                    }
                    let count = devices.lock().await.len();
                    emit(&tx, Event::ScanFinished { count });
                });
            }
            Command::AddFiles { files } => {
                let mut current = selected_files.lock().await;
                for raw in files {
                    if let Some(path) = normalize_file_url(&raw) {
                        match fs::metadata(&path).await {
                            Ok(meta) if meta.is_file() => {
                                let size = meta.len();
                                let path_text = path.to_string_lossy().to_string();
                                if current.iter().any(|file| file.path == path_text) {
                                    continue;
                                }
                                current.push(SelectedFile {
                                    path: path_text,
                                    name: path
                                        .file_name()
                                        .and_then(|n| n.to_str())
                                        .unwrap_or("file")
                                        .to_string(),
                                    size,
                                });
                            }
                            _ => {}
                        }
                    }
                }
                emit_files_set(&tx, &current);
            }
            Command::RemoveFile { path } => {
                let mut current = selected_files.lock().await;
                current.retain(|file| file.path != path);
                emit_files_set(&tx, &current);
            }
            Command::Send { device_id } => {
                let maybe_device = devices.lock().await.get(&device_id).cloned();
                let files = selected_files.lock().await.clone();
                let tx = tx.clone();
                let client = client.clone();
                let identity = identity.clone();
                tokio::spawn(async move {
                    if let Some(device) = maybe_device {
                        if let Err(err) =
                            send_files(tx.clone(), client, identity, device, files).await
                        {
                            emit(
                                &tx,
                                Event::TransferError {
                                    transfer_id: None,
                                    message: err.to_string(),
                                },
                            );
                        }
                    } else {
                        emit(
                            &tx,
                            Event::TransferError {
                                transfer_id: None,
                                message: "Device not found".to_string(),
                            },
                        );
                    }
                });
            }
            Command::AcceptIncoming { request_id } => {
                respond_incoming(&state, &request_id, true).await
            }
            Command::RejectIncoming { request_id } => {
                respond_incoming(&state, &request_id, false).await
            }
            Command::Cancel { transfer_id } => emit(
                &tx,
                Event::TransferError {
                    transfer_id,
                    message: "Cancel requested".to_string(),
                },
            ),
            Command::Clear => {
                selected_files.lock().await.clear();
                emit(
                    &tx,
                    Event::State {
                        status: "idle".to_string(),
                    },
                );
            }
        }
    }

    drop(headless_keepalive);
    Ok(())
}
