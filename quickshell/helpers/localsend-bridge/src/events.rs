use crate::types::{Command, Event, SelectedFile};
use futures_util::StreamExt;
use tokio::{
    io::{AsyncWriteExt, BufReader},
    sync::mpsc,
};
use tokio_util::codec::{FramedRead, LinesCodec};

pub fn emit(tx: &mpsc::UnboundedSender<Event>, event: Event) {
    let _ = tx.send(event);
}

pub fn emit_files_set(tx: &mpsc::UnboundedSender<Event>, files: &[SelectedFile]) {
    let total_size = files.iter().map(|file| file.size).sum();
    emit(
        tx,
        Event::FilesSet {
            files: files.to_vec(),
            total_size,
        },
    );
}

pub fn spawn_stdout_writer(rx: &mut mpsc::UnboundedReceiver<Event>) {
    let mut rx = std::mem::replace(rx, mpsc::unbounded_channel().1);
    tokio::spawn(async move {
        let mut stdout = tokio::io::stdout();
        while let Some(event) = rx.recv().await {
            if let Ok(line) = serde_json::to_string(&event) {
                let _ = stdout.write_all(line.as_bytes()).await;
                let _ = stdout.write_all(b"\n").await;
                let _ = stdout.flush().await;
            }
        }
    });
}

pub fn spawn_stdin_reader(tx: mpsc::UnboundedSender<Command>) {
    tokio::spawn(async move {
        let stdin = tokio::io::stdin();
        let mut lines = FramedRead::new(BufReader::new(stdin), LinesCodec::new());
        while let Some(Ok(line)) = lines.next().await {
            match serde_json::from_str::<Command>(&line) {
                Ok(cmd) => {
                    let _ = tx.send(cmd);
                }
                Err(err) => eprintln!("bad command: {err}: {line}"),
            }
        }
    });
}
