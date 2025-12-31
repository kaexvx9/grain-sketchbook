const std = @import("std");
const testing = std.testing;
const file_transfer = @import("grain_core").file_transfer;

test "transfer progress init" {
    const progress = file_transfer.TransferProgress.init();
    std.debug.assert(progress.bytes_transferred == 0);
    std.debug.assert(progress.total_bytes == 0);
    std.debug.assert(progress.percentage == 0.0);
    std.debug.assert(progress.transfer_rate == 0);
}

test "transfer progress calculate percentage" {
    var progress = file_transfer.TransferProgress.init();
    progress.bytes_transferred = 500;
    progress.total_bytes = 1000;
    progress.calculate_percentage();
    std.debug.assert(progress.percentage == 50.0);
}

test "transfer progress calculate percentage - zero total" {
    var progress = file_transfer.TransferProgress.init();
    progress.bytes_transferred = 100;
    progress.total_bytes = 0;
    progress.calculate_percentage();
    std.debug.assert(progress.percentage == 0.0);
}

test "file transfer init" {
    const transfer = file_transfer.FileTransfer.init();
    std.debug.assert(transfer.transfer_id == 0);
    std.debug.assert(transfer.direction == file_transfer.TransferDirection.upload);
    std.debug.assert(transfer.state == file_transfer.TransferState.pending);
    std.debug.assert(transfer.file_size == 0);
    std.debug.assert(transfer.active == false);
}

test "file transfer set local path" {
    var transfer = file_transfer.FileTransfer.init();
    const path = "/home/user/file.txt";
    const set = transfer.set_local_path(path);
    std.debug.assert(set);
    std.debug.assert(transfer.local_path_len == path.len);
}

test "file transfer set remote url" {
    var transfer = file_transfer.FileTransfer.init();
    const url = "https://example.com/upload";
    const set = transfer.set_remote_url(url);
    std.debug.assert(set);
    std.debug.assert(transfer.remote_url_len == url.len);
}

test "file transfer update progress" {
    var transfer = file_transfer.FileTransfer.init();
    transfer.file_size = 1000;
    transfer.started_at = 0;
    transfer.update_progress(500, 1000);
    std.debug.assert(transfer.progress.bytes_transferred == 500);
    std.debug.assert(transfer.progress.total_bytes == 1000);
    std.debug.assert(transfer.progress.percentage == 50.0);
}

test "file transfer manager init" {
    const manager = file_transfer.FileTransferManager.init();
    std.debug.assert(manager.transfers_len == 0);
    std.debug.assert(manager.next_transfer_id == 1);
}

test "file transfer manager create upload" {
    var manager = file_transfer.FileTransferManager.init();
    const local_path = "/home/user/file.txt";
    const remote_url = "https://example.com/upload";
    const file_size: u64 = 1024;
    const current_time: u64 = 1000;
    const transfer_id = manager.create_upload(
        local_path,
        remote_url,
        file_size,
        current_time,
    );
    std.debug.assert(transfer_id != null);
    std.debug.assert(manager.transfers_len == 1);
    std.debug.assert(manager.transfers[0].transfer_id == transfer_id.?);
    std.debug.assert(manager.transfers[0].direction ==
        file_transfer.TransferDirection.upload);
}

test "file transfer manager create download" {
    var manager = file_transfer.FileTransferManager.init();
    const remote_url = "https://example.com/file.txt";
    const local_path = "/home/user/download.txt";
    const file_size: u64 = 2048;
    const current_time: u64 = 1000;
    const transfer_id = manager.create_download(
        remote_url,
        local_path,
        file_size,
        current_time,
    );
    std.debug.assert(transfer_id != null);
    std.debug.assert(manager.transfers_len == 1);
    std.debug.assert(manager.transfers[0].transfer_id == transfer_id.?);
    std.debug.assert(manager.transfers[0].direction ==
        file_transfer.TransferDirection.download);
}

test "file transfer manager get transfer" {
    var manager = file_transfer.FileTransferManager.init();
    const local_path = "/home/user/file.txt";
    const remote_url = "https://example.com/upload";
    const file_size: u64 = 1024;
    const current_time: u64 = 1000;
    const transfer_id = manager.create_upload(
        local_path,
        remote_url,
        file_size,
        current_time,
    );
    std.debug.assert(transfer_id != null);
    const transfer = manager.get_transfer(transfer_id.?);
    std.debug.assert(transfer != null);
    std.debug.assert(transfer.?.transfer_id == transfer_id.?);
}

test "file transfer manager pause transfer" {
    var manager = file_transfer.FileTransferManager.init();
    const local_path = "/home/user/file.txt";
    const remote_url = "https://example.com/upload";
    const file_size: u64 = 1024;
    const current_time: u64 = 1000;
    const transfer_id = manager.create_upload(
        local_path,
        remote_url,
        file_size,
        current_time,
    );
    std.debug.assert(transfer_id != null);
    const transfer = manager.get_transfer(transfer_id.?);
    std.debug.assert(transfer != null);
    transfer.?.state = file_transfer.TransferState.in_progress;
    const paused = manager.pause_transfer(transfer_id.?);
    std.debug.assert(paused);
    std.debug.assert(transfer.?.state == file_transfer.TransferState.paused);
}

test "file transfer manager resume transfer" {
    var manager = file_transfer.FileTransferManager.init();
    const local_path = "/home/user/file.txt";
    const remote_url = "https://example.com/upload";
    const file_size: u64 = 1024;
    const current_time: u64 = 1000;
    const transfer_id = manager.create_upload(
        local_path,
        remote_url,
        file_size,
        current_time,
    );
    std.debug.assert(transfer_id != null);
    const transfer = manager.get_transfer(transfer_id.?);
    std.debug.assert(transfer != null);
    transfer.?.state = file_transfer.TransferState.paused;
    const resumed = manager.resume_transfer(transfer_id.?);
    std.debug.assert(resumed);
    std.debug.assert(transfer.?.state == file_transfer.TransferState.in_progress);
}

test "file transfer manager cancel transfer" {
    var manager = file_transfer.FileTransferManager.init();
    const local_path = "/home/user/file.txt";
    const remote_url = "https://example.com/upload";
    const file_size: u64 = 1024;
    const current_time: u64 = 1000;
    const transfer_id = manager.create_upload(
        local_path,
        remote_url,
        file_size,
        current_time,
    );
    std.debug.assert(transfer_id != null);
    const cancelled = manager.cancel_transfer(transfer_id.?);
    std.debug.assert(cancelled);
    const transfer = manager.get_transfer(transfer_id.?);
    std.debug.assert(transfer == null);
}

test "file transfer manager get progress" {
    var manager = file_transfer.FileTransferManager.init();
    const local_path = "/home/user/file.txt";
    const remote_url = "https://example.com/upload";
    const file_size: u64 = 1000;
    const current_time: u64 = 1000;
    const transfer_id = manager.create_upload(
        local_path,
        remote_url,
        file_size,
        current_time,
    );
    std.debug.assert(transfer_id != null);
    const transfer = manager.get_transfer(transfer_id.?);
    std.debug.assert(transfer != null);
    transfer.?.update_progress(500, 2000);
    const progress = manager.get_progress(transfer_id.?);
    std.debug.assert(progress != null);
    std.debug.assert(progress.?.bytes_transferred == 500);
    std.debug.assert(progress.?.percentage == 50.0);
}

test "file transfer manager multiple transfers" {
    var manager = file_transfer.FileTransferManager.init();
    const current_time: u64 = 1000;
    const id1 = manager.create_upload(
        "/home/user/file1.txt",
        "https://example.com/upload1",
        1000,
        current_time,
    );
    const id2 = manager.create_download(
        "https://example.com/file2.txt",
        "/home/user/file2.txt",
        2000,
        current_time + 1,
    );
    std.debug.assert(id1 != null);
    std.debug.assert(id2 != null);
    std.debug.assert(manager.transfers_len == 2);
    const transfer1 = manager.get_transfer(id1.?);
    const transfer2 = manager.get_transfer(id2.?);
    std.debug.assert(transfer1 != null);
    std.debug.assert(transfer2 != null);
    std.debug.assert(transfer1.?.direction ==
        file_transfer.TransferDirection.upload);
    std.debug.assert(transfer2.?.direction ==
        file_transfer.TransferDirection.download);
}
