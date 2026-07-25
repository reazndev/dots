use anyhow::Result;
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use tokio::fs;
use uuid::Uuid;

pub fn normalize_file_url(raw: &str) -> Option<PathBuf> {
    if raw.starts_with("file://") {
        Some(PathBuf::from(raw.trim_start_matches("file://")))
    } else if raw.starts_with('/') {
        Some(PathBuf::from(raw))
    } else {
        None
    }
}

pub fn hex_sha256(bytes: &[u8]) -> String {
    let digest = Sha256::digest(bytes);
    digest.iter().map(|b| format!("{b:02x}")).collect()
}

pub async fn persisted_fingerprint() -> Result<String> {
    let path = dirs_state().join("localsend-bridge-fingerprint");
    if let Ok(value) = fs::read_to_string(&path).await {
        let trimmed = value.trim();
        if !trimmed.is_empty() {
            return Ok(trimmed.to_string());
        }
    }
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).await.ok();
    }
    let fingerprint = Uuid::new_v4().to_string();
    fs::write(path, &fingerprint).await.ok();
    Ok(fingerprint)
}

pub fn dirs_state() -> PathBuf {
    std::env::var_os("XDG_STATE_HOME")
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("HOME").map(|h| PathBuf::from(h).join(".local/state")))
        .unwrap_or_else(|| PathBuf::from("."))
        .join("quickshell")
}

pub fn dirs_download() -> Option<PathBuf> {
    std::env::var_os("HOME").map(|h| PathBuf::from(h).join("Downloads"))
}

pub async fn available_port(preferred: u16) -> Option<u16> {
    for port in preferred..preferred + 20 {
        if tokio::net::TcpListener::bind(("0.0.0.0", port))
            .await
            .is_ok()
        {
            return Some(port);
        }
    }
    None
}

pub async fn unique_path(dir: &Path, name: &str) -> PathBuf {
    let clean = sanitize_filename(name);
    let candidate = dir.join(&clean);
    if fs::metadata(&candidate).await.is_err() {
        return candidate;
    }
    let path = Path::new(&clean);
    let stem = path.file_stem().and_then(|s| s.to_str()).unwrap_or("file");
    let ext = path.extension().and_then(|s| s.to_str()).unwrap_or("");
    for idx in 1..1000 {
        let next = if ext.is_empty() {
            format!("{stem} ({idx})")
        } else {
            format!("{stem} ({idx}).{ext}")
        };
        let candidate = dir.join(next);
        if fs::metadata(&candidate).await.is_err() {
            return candidate;
        }
    }
    dir.join(format!("{}-{}", Uuid::new_v4(), clean))
}

pub fn sanitize_filename(name: &str) -> String {
    let cleaned = name.replace(['/', '\\', '\0'], "_").trim().to_string();
    if cleaned.is_empty() {
        "file".to_string()
    } else {
        cleaned
    }
}

pub fn ratio(done: u64, total: u64) -> f64 {
    if total == 0 {
        0.0
    } else {
        (done as f64 / total as f64).clamp(0.0, 1.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sanitizes_unsafe_file_names() {
        assert_eq!(sanitize_filename("../bad\\name.txt"), ".._bad_name.txt");
        assert_eq!(sanitize_filename(""), "file");
    }

    #[test]
    fn ratio_is_bounded() {
        assert_eq!(ratio(5, 0), 0.0);
        assert_eq!(ratio(5, 10), 0.5);
        assert_eq!(ratio(15, 10), 1.0);
    }

    #[test]
    fn normalizes_file_urls_and_paths() {
        assert_eq!(
            normalize_file_url("file:///tmp/example.txt"),
            Some(PathBuf::from("/tmp/example.txt"))
        );
        assert_eq!(
            normalize_file_url("/tmp/example.txt"),
            Some(PathBuf::from("/tmp/example.txt"))
        );
        assert_eq!(normalize_file_url("https://example.test/file"), None);
    }
}
