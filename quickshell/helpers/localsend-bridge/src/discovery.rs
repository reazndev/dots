use anyhow::Result;
use futures_util::{StreamExt, stream::FuturesUnordered};
use reqwest::Client;
use std::{
    collections::HashMap,
    net::{Ipv4Addr, SocketAddrV4},
    sync::Arc,
    time::{Duration, Instant},
};
use tokio::{
    net::UdpSocket,
    sync::{Mutex, mpsc},
};

use crate::{
    events::emit,
    transfer::register_with,
    types::{AppState, DEFAULT_PORT, Device, DeviceInfo, Event},
};

pub const MULTICAST_ADDR: Ipv4Addr = Ipv4Addr::new(224, 0, 0, 167);

pub fn spawn_udp_listener(state: AppState, devices: Arc<Mutex<HashMap<String, Device>>>) {
    tokio::spawn(async move {
        let socket = match UdpSocket::bind(("0.0.0.0", DEFAULT_PORT)).await {
            Ok(s) => s,
            Err(err) => {
                emit(
                    &state.tx,
                    Event::TransferError {
                        transfer_id: None,
                        message: format!("UDP bind failed: {err}"),
                    },
                );
                return;
            }
        };
        let _ = socket.join_multicast_v4(MULTICAST_ADDR, Ipv4Addr::UNSPECIFIED);
        let mut buf = vec![0u8; 4096];
        loop {
            let Ok((len, addr)) = socket.recv_from(&mut buf).await else {
                continue;
            };
            let Ok(info) = serde_json::from_slice::<DeviceInfo>(&buf[..len]) else {
                continue;
            };
            if info.fingerprint == state.identity.fingerprint {
                continue;
            }
            let device = device_from_info(&info, addr.ip().to_string(), Instant::now());
            add_device(&state.tx, &devices, device.clone()).await;
            if info.announce.unwrap_or(false) {
                let Ok(client) = Client::builder().danger_accept_invalid_certs(true).build() else {
                    continue;
                };
                let _ = register_with(&client, &device, &state.identity).await;
            }
        }
    });
}

pub async fn multicast_announce(identity: &DeviceInfo) -> Result<()> {
    let socket = UdpSocket::bind(("0.0.0.0", 0)).await?;
    socket.set_multicast_loop_v4(false)?;
    let mut payload = identity.clone();
    payload.announce = Some(true);
    let bytes = serde_json::to_vec(&payload)?;
    socket
        .send_to(&bytes, SocketAddrV4::new(MULTICAST_ADDR, DEFAULT_PORT))
        .await?;
    Ok(())
}

pub async fn subnet_scan(
    tx: &mpsc::UnboundedSender<Event>,
    devices: &Arc<Mutex<HashMap<String, Device>>>,
    client: &Client,
    identity: &DeviceInfo,
) {
    let Ok(addrs) = if_addrs::get_if_addrs() else {
        return;
    };
    let mut probes = FuturesUnordered::new();
    for iface in addrs {
        let std::net::IpAddr::V4(ip) = iface.ip() else {
            continue;
        };
        if ip.is_loopback() {
            continue;
        }
        let octets = ip.octets();
        for host in 1..255u8 {
            let target = format!("{}.{}.{}.{}", octets[0], octets[1], octets[2], host);
            if target == ip.to_string() {
                continue;
            }
            for protocol in ["https", "http"] {
                let client = client.clone();
                let identity = identity.clone();
                let address = target.clone();
                probes.push(async move {
                    let device = Device {
                        id: String::new(),
                        alias: String::new(),
                        address: address.clone(),
                        port: DEFAULT_PORT,
                        protocol: protocol.to_string(),
                        device_type: None,
                        fingerprint: String::new(),
                        download: false,
                        last_seen_ms: 0,
                    };
                    let Ok(Ok(info)) = tokio::time::timeout(
                        Duration::from_millis(450),
                        register_with(&client, &device, &identity),
                    )
                    .await
                    else {
                        return None;
                    };
                    Some(device_from_info(&info, address, Instant::now()))
                });
            }
        }
        break;
    }

    while let Some(found) = probes.next().await {
        if let Some(device) = found {
            add_device(tx, devices, device).await;
            if devices.lock().await.len() >= 24 {
                break;
            }
        }
    }
}

pub async fn add_device(
    tx: &mpsc::UnboundedSender<Event>,
    devices: &Arc<Mutex<HashMap<String, Device>>>,
    mut device: Device,
) {
    if device.id.is_empty() {
        device.id = format!(
            "{}-{}-{}",
            device.protocol, device.address, device.fingerprint
        );
    }
    devices
        .lock()
        .await
        .insert(device.id.clone(), device.clone());
    emit(tx, Event::DeviceFound { device });
}

pub fn device_from_info(info: &DeviceInfo, address: String, start: Instant) -> Device {
    Device {
        id: format!("{}-{}-{}", info.protocol, address, info.fingerprint),
        alias: info.alias.clone(),
        address,
        port: info.port,
        protocol: info.protocol.clone(),
        device_type: info.device_type.clone(),
        fingerprint: info.fingerprint.clone(),
        download: info.download,
        last_seen_ms: start.elapsed().as_millis(),
    }
}
