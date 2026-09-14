import Darwin
import Foundation
import SpeakCore

@MainActor final class ControlServer {
    private var fd: Int32 = -1
    private var path: String?
    private var worker: Task<Void, Never>?
    func start(model: AppModel) throws {
        let endpoint = try LocalControl.path()
        let listener = try LocalControl.listenSocket(path: endpoint)
        fd = listener; path = endpoint
        worker = Task.detached {
            while !Task.isCancelled {
                let client = accept(listener, nil, nil)
                if client < 0 {
                    if errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK { continue }
                    break
                }
                defer { close(client) }
                var uid: uid_t = 0; var gid: gid_t = 0
                guard getpeereid(client, &uid, &gid) == 0, uid == getuid() else { continue }
                var timeout = timeval(tv_sec: 3, tv_usec: 0); var one: Int32 = 1
                setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                setsockopt(client, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &one, socklen_t(MemoryLayout<Int32>.size))
                do {
                    let request = try JSONDecoder().decode(ControlRequest.self, from: LocalControl.readLine(client))
                    try request.validate()
                    let reply = await model.handle(request)
                    try LocalControl.writeLine(JSONEncoder().encode(reply), to: client)
                } catch {
                    let reply = ControlReply(ok: false, message: "Invalid or incomplete control request.")
                    if let data = try? JSONEncoder().encode(reply) { try? LocalControl.writeLine(data, to: client) }
                }
            }
        }
    }
    func stop() {
        worker?.cancel(); worker = nil
        if fd >= 0 { shutdown(fd, SHUT_RDWR); close(fd); fd = -1 }
        if let path { unlink(path); self.path = nil }
    }
}

extension AppModel {
    func handle(_ request: ControlRequest) -> ControlReply {
        switch request.action {
        case .status: break
        case .read:
            guard !hasActiveDictation, !reading else { return ControlReply(ok: false, message: "Stop the current session before starting new text.", reading: reading, paused: paused, speed: speed, dictation: session.phase.rawValue) }
            readerText = request.text!; readText()
        case .pause: if reading && !paused { togglePause() }
        case .resume: if reading && paused { togglePause() }
        case .stop: stopReading()
        case .speed: setSpeed(request.speed!)
        case .toggleDictation: toggleDictation()
        case .cancelDictation: cancelDictation()
        case .open: showWindow?()
        }
        return ControlReply(ok: true, message: request.action == .read ? "Speech queued" : readerStatus, reading: reading, paused: paused, speed: speed, dictation: session.phase.rawValue)
    }
}
