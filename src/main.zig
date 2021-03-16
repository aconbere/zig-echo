const std = @import("std");
const os = std.os;

const ListenError = error{
    GetAddrInfoError,
};

pub fn main() anyerror!void {
    const port = "9999";
    const host = "0.0.0.0";
    const buffer_size = 100;

    const hints = os.addrinfo{
        .flags = os.system.AI_NUMERICSERV,
        .family = os.AF_UNSPEC,
        .socktype = os.SOCK_STREAM,
        .protocol = os.IPPROTO_TCP,
        .canonname = null,
        .addr = null,
        .addrlen = 0,
        .next = null,
    };

    var res: *os.addrinfo = undefined;

    var status = os.system.getaddrinfo("0.0.0.0", "9999", &hints, &res);

    if (status != @intToEnum(os.system.EAI, 0)) {
        std.debug.print("ERROR: {}\n", .{status});
        return ListenError.GetAddrInfoError;
    }

    defer os.system.freeaddrinfo(res);

    const sockfd = try os.socket(@intCast(u32, res.family), @intCast(u32, res.socktype), 0);
    defer os.closeSocket(sockfd);

    try os.bind(sockfd, res.addr.?, res.addrlen);

    // This is the accept queue
    const backlog = 20;
    try os.listen(sockfd, backlog);

    std.debug.print("Starting echo server {s}:{s}\n", .{ host, port });

    var incoming_addr: os.sockaddr = undefined;
    var addr_len: os.socklen_t = @sizeOf(os.sockaddr);
    const new_sockfd = try os.accept(sockfd, &incoming_addr, &addr_len, 0);
    defer os.closeSocket(new_sockfd);

    var buffer: [buffer_size]u8 = undefined;

    while (true) {
        const bytes_received = try os.recv(new_sockfd, &buffer, 0);
        if (bytes_received == 0) {
            std.debug.print("Client hung up, closing", .{});
            break;
        }

        const msg = buffer[0..bytes_received];
        std.debug.print("Received: {any} bytes: {s}\n", .{ bytes_received, msg });

        const bytes_sent = try os.send(new_sockfd, msg, 0);
        std.debug.print("Sent: {any} bytes: {s}\n", .{ bytes_sent, msg });
    }
}
