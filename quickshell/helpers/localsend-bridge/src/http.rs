use anyhow::Result;
use axum::{
    Json, Router,
    body::Body,
    extract::{Query, State, connect_info::ConnectInfo},
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{get, post},
};
use futures_util::StreamExt;
use std::{
    collections::HashMap,
    net::SocketAddr,
    time::{Duration, Instant},
};
use tokio::{
    fs::{self, File},
    io::AsyncWriteExt,
};
use uuid::Uuid;

use crate::{
    clipboard::{copy_text_to_clipboard, is_clipboard_text},
    discovery::{add_device, device_from_info},
    events::emit,
    types::{
        AppState, CancelQuery, DeviceInfo, Event, IncomingRequest, IncomingSession,
        PrepareUploadRequest, PrepareUploadResponse, TransferStatus, UploadQuery,
    },
    utils::{ratio, unique_path},
};

pub async fn spawn_http_servers(
    state: AppState,
    port: u16,
    cert_pem: String,
    key_pem: String,
) -> Result<()> {
    let app = Router::new()
        .route("/api/localsend/v2/register", post(register))
        .route("/api/localsend/v2/prepare-upload", post(prepare_upload))
        .route("/api/localsend/v2/upload", post(upload))
        .route("/api/localsend/v2/cancel", post(cancel))
        .route("/api/localsend/v2/info", get(info))
        .with_state(state);

    let cert_path = std::env::temp_dir().join("quickshell-localsend-cert.pem");
    let key_path = std::env::temp_dir().join("quickshell-localsend-key.pem");
    fs::write(&cert_path, cert_pem).await?;
    fs::write(&key_path, key_pem).await?;
    let config = axum_server::tls_rustls::RustlsConfig::from_pem_file(&cert_path, &key_path).await;
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    tokio::spawn(async move {
        match config {
            Ok(config) => {
                let _ = axum_server::bind_rustls(addr, config)
                    .serve(app.into_make_service_with_connect_info::<SocketAddr>())
                    .await;
            }
            Err(err) => eprintln!("https server failed: {err}"),
        }
    });
    Ok(())
}

async fn register(
    State(state): State<AppState>,
    ConnectInfo(peer): ConnectInfo<SocketAddr>,
    Json(info): Json<DeviceInfo>,
) -> Json<DeviceInfo> {
    if info.fingerprint != state.identity.fingerprint {
        let device = device_from_info(&info, peer.ip().to_string(), Instant::now());
        add_device(&state.tx, &state.devices, device).await;
    }
    Json(state.identity)
}

async fn info(State(state): State<AppState>) -> Json<DeviceInfo> {
    Json(state.identity)
}

async fn prepare_upload(
    State(state): State<AppState>,
    Json(req): Json<PrepareUploadRequest>,
) -> Response {
    let request_id = Uuid::new_v4().to_string();
    let total_size = req.files.values().map(|f| f.size).sum();
    let files = req.files.values().cloned().collect::<Vec<_>>();
    let kind = if files.len() == 1 && files.iter().all(is_clipboard_text) {
        "clipboard"
    } else {
        "files"
    };
    let (response_tx, response_rx) = tokio::sync::oneshot::channel();
    let tokens = req
        .files
        .keys()
        .map(|id| (id.clone(), Uuid::new_v4().to_string()))
        .collect::<HashMap<_, _>>();
    state.incoming.lock().await.insert(
        request_id.clone(),
        IncomingSession {
            files: req.files.clone(),
            tokens: tokens.clone(),
            responder: if state.auto_accept { None } else { Some(response_tx) },
        },
    );
    emit(
        &state.tx,
        Event::IncomingRequest {
            request: IncomingRequest {
                id: request_id.clone(),
                sender: req.info.alias,
                kind: kind.to_string(),
                file_count: files.len(),
                total_size,
                files,
            },
        },
    );

    if state.auto_accept {
        let body = PrepareUploadResponse {
            session_id: request_id,
            files: tokens,
        };
        return (StatusCode::OK, Json(body)).into_response();
    }

    match tokio::time::timeout(Duration::from_secs(120), response_rx).await {
        Ok(Ok(true)) => {
            let body = PrepareUploadResponse {
                session_id: request_id,
                files: tokens,
            };
            (StatusCode::OK, Json(body)).into_response()
        }
        _ => {
            state.incoming.lock().await.remove(&request_id);
            (StatusCode::FORBIDDEN, "Rejected").into_response()
        }
    }
}

async fn upload(
    State(state): State<AppState>,
    Query(query): Query<UploadQuery>,
    body: Body,
) -> Response {
    let session = {
        let map = state.incoming.lock().await;
        let Some(session) = map.get(&query.session_id) else {
            return (StatusCode::FORBIDDEN, "Invalid session").into_response();
        };
        if session.tokens.get(&query.file_id) != Some(&query.token) {
            return (StatusCode::FORBIDDEN, "Invalid token").into_response();
        }
        let Some(meta) = session.files.get(&query.file_id) else {
            return (StatusCode::BAD_REQUEST, "Invalid file").into_response();
        };
        meta.clone()
    };

    if is_clipboard_text(&session) {
        return upload_clipboard(state, query, body, session).await;
    }

    let path = unique_path(&state.receive_dir, &session.file_name).await;
    let mut out = match File::create(&path).await {
        Ok(f) => f,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Cannot save").into_response(),
    };
    let mut written = 0u64;
    let mut stream = body.into_data_stream();
    while let Some(chunk) = stream.next().await {
        let Ok(bytes) = chunk else {
            return (StatusCode::INTERNAL_SERVER_ERROR, "Upload failed").into_response();
        };
        if out.write_all(&bytes).await.is_err() {
            return (StatusCode::INTERNAL_SERVER_ERROR, "Write failed").into_response();
        }
        written += bytes.len() as u64;
        emit_receive_progress(
            &state,
            &query,
            &session.file_name,
            written,
            session.size,
            "receiving",
        );
    }
    emit(
        &state.tx,
        Event::TransferComplete {
            transfer_id: query.session_id.clone(),
            direction: "receive".to_string(),
            message: format!("Saved {}", path.display()),
        },
    );
    state.incoming.lock().await.remove(&query.session_id);
    StatusCode::OK.into_response()
}

async fn upload_clipboard(
    state: AppState,
    query: UploadQuery,
    body: Body,
    session: crate::types::FileMeta,
) -> Response {
    let mut data = Vec::new();
    let mut stream = body.into_data_stream();
    while let Some(chunk) = stream.next().await {
        let Ok(bytes) = chunk else {
            return (StatusCode::INTERNAL_SERVER_ERROR, "Upload failed").into_response();
        };
        data.extend_from_slice(&bytes);
        emit_receive_progress(
            &state,
            &query,
            &session.file_name,
            data.len() as u64,
            session.size,
            "copying",
        );
    }

    let text = String::from_utf8_lossy(&data).to_string();
    if let Err(err) = copy_text_to_clipboard(&text).await {
        emit(
            &state.tx,
            Event::TransferError {
                transfer_id: Some(query.session_id.clone()),
                message: format!("Clipboard copy failed: {err}"),
            },
        );
        return (StatusCode::INTERNAL_SERVER_ERROR, "Clipboard copy failed").into_response();
    }

    emit(
        &state.tx,
        Event::TransferComplete {
            transfer_id: query.session_id.clone(),
            direction: "receive".to_string(),
            message: "Copied to clipboard".to_string(),
        },
    );
    state.incoming.lock().await.remove(&query.session_id);
    StatusCode::OK.into_response()
}

fn emit_receive_progress(
    state: &AppState,
    query: &UploadQuery,
    file_name: &str,
    transferred: u64,
    total: u64,
    status: &str,
) {
    emit(
        &state.tx,
        Event::TransferProgress {
            transfer: TransferStatus {
                id: query.session_id.clone(),
                direction: "receive".to_string(),
                device: "Remote".to_string(),
                file_name: file_name.to_string(),
                progress: ratio(transferred, total),
                transferred,
                total,
                status: status.to_string(),
            },
        },
    );
}

async fn cancel(State(state): State<AppState>, Query(query): Query<CancelQuery>) -> StatusCode {
    state.incoming.lock().await.remove(&query.session_id);
    StatusCode::OK
}

pub async fn respond_incoming(state: &AppState, request_id: &str, accepted: bool) {
    if let Some(session) = state.incoming.lock().await.get_mut(request_id) {
        if let Some(responder) = session.responder.take() {
            let _ = responder.send(accepted);
        }
    }
}
