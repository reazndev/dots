use anyhow::{Context, Result};
use std::process::Stdio;
use tokio::{io::AsyncWriteExt, process::Command as TokioCommand};

use crate::types::FileMeta;

pub fn is_clipboard_text(file: &FileMeta) -> bool {
    let file_type = file.file_type.to_lowercase();
    let file_name = file.file_name.to_lowercase();
    file_type == "text"
        || file_type.starts_with("text/")
        || file_type == "application/json"
        || file_type == "application/xml"
        || file_name == "clipboard.txt"
        || file_name == "text.txt"
        || file_name.ends_with(".txt")
}

pub async fn copy_text_to_clipboard(text: &str) -> Result<()> {
    let mut child = TokioCommand::new("wl-copy")
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .context("failed to start wl-copy")?;

    if let Some(stdin) = child.stdin.as_mut() {
        stdin
            .write_all(text.as_bytes())
            .await
            .context("failed to write to wl-copy")?;
    }

    let status = child.wait().await.context("failed waiting for wl-copy")?;
    if !status.success() {
        anyhow::bail!("wl-copy exited with {status}");
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_clipboard_text_payloads() {
        let text = FileMeta {
            id: "1".to_string(),
            file_name: "clipboard.txt".to_string(),
            size: 12,
            file_type: "text/plain".to_string(),
            sha256: None,
            preview: None,
            metadata: None,
        };
        let binary = FileMeta {
            file_name: "image.png".to_string(),
            file_type: "image/png".to_string(),
            ..text.clone()
        };

        assert!(is_clipboard_text(&text));
        assert!(!is_clipboard_text(&binary));
    }
}
