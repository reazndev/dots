use anyhow::{Context, Result};
use percent_encoding::{NON_ALPHANUMERIC, utf8_percent_encode};
use reqwest::Client;
use std::collections::HashMap;
use tokio::{fs::File, io::AsyncReadExt, sync::mpsc};
use uuid::Uuid;

use crate::{
    events::emit,
    types::{
        Device, DeviceInfo, Event, FileMeta, PrepareUploadBody, PrepareUploadResult, SelectedFile,
        TransferStatus,
    },
    utils::ratio,
};

pub async fn send_files(
    tx: mpsc::UnboundedSender<Event>,
    client: Client,
    identity: DeviceInfo,
    device: Device,
    files: Vec<SelectedFile>,
) -> Result<()> {
    if files.is_empty() {
        anyhow::bail!("No files selected");
    }
    let transfer_id = Uuid::new_v4().to_string();
    let mut metas = HashMap::new();
    let mut ordered = Vec::new();
    for file in &files {
        let id = Uuid::new_v4().to_string();
        let meta = FileMeta {
            id: id.clone(),
            file_name: file.name.clone(),
            size: file.size,
            file_type: mime_guess::from_path(&file.name)
                .first_or_octet_stream()
                .to_string(),
            sha256: None,
            preview: None,
            metadata: None,
        };
        metas.insert(id.clone(), meta);
        ordered.push((file.clone(), id));
    }

    let base = format!("{}://{}:{}", device.protocol, device.address, device.port);
    let prepare_url = format!("{base}/api/localsend/v2/prepare-upload");
    let body = PrepareUploadBody {
        info: identity,
        files: metas.clone(),
    };
    let prepare: PrepareUploadResult = client
        .post(prepare_url)
        .json(&body)
        .send()
        .await?
        .error_for_status()?
        .json()
        .await?;

    let total: u64 = files.iter().map(|f| f.size).sum();
    let mut aggregate = 0u64;
    for (file, file_id) in ordered {
        let token = prepare
            .files
            .get(&file_id)
            .context("Receiver did not accept file")?;
        let upload_url = format!(
            "{base}/api/localsend/v2/upload?sessionId={}&fileId={}&token={}",
            enc(&prepare.session_id),
            enc(&file_id),
            enc(token)
        );
        let mut file_handle = File::open(&file.path).await?;
        let mut bytes = Vec::with_capacity(file.size.min(16 * 1024 * 1024) as usize);
        file_handle.read_to_end(&mut bytes).await?;
        client
            .post(upload_url)
            .body(bytes)
            .send()
            .await?
            .error_for_status()?;
        aggregate += file.size;
        emit(
            &tx,
            Event::TransferProgress {
                transfer: TransferStatus {
                    id: transfer_id.clone(),
                    direction: "send".to_string(),
                    device: device.alias.clone(),
                    file_name: file.name.clone(),
                    progress: ratio(aggregate, total),
                    transferred: aggregate,
                    total,
                    status: "sending".to_string(),
                },
            },
        );
    }
    emit(
        &tx,
        Event::TransferComplete {
            transfer_id,
            direction: "send".to_string(),
            message: format!("Sent to {}", device.alias),
        },
    );
    Ok(())
}

pub async fn register_with(
    client: &Client,
    device: &Device,
    identity: &DeviceInfo,
) -> Result<DeviceInfo> {
    let url = format!(
        "{}://{}:{}/api/localsend/v2/register",
        device.protocol, device.address, device.port
    );
    let res = client
        .post(url)
        .json(identity)
        .send()
        .await?
        .error_for_status()?
        .json::<DeviceInfo>()
        .await?;
    Ok(res)
}

fn enc(value: &str) -> String {
    utf8_percent_encode(value, NON_ALPHANUMERIC).to_string()
}
