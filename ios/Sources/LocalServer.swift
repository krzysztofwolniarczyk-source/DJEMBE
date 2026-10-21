import Foundation
import Network

/// Minimalny serwer HTTP na pętli zwrotnej (127.0.0.1).
///
/// Istnieje z jednego powodu: stroik używa getUserMedia, a WebKit wymaga do tego
/// bezpiecznego kontekstu. `file://` nim nie jest — `http://127.0.0.1` jest.
/// Serwuje wyłącznie pliki z bundle'a, tylko GET/HEAD, nasłuchuje tylko na pętli
/// zwrotnej, więc nic nie wystaje na Wi-Fi.
///
/// Port jest stały: localStorage jest kluczowany po originie (host + port),
/// więc losowy port kasowałby postępy przy każdym uruchomieniu.
final class LocalServer {

    static let shared = LocalServer()
    static let port: UInt16 = 28417

    var baseURL: URL { URL(string: "http://127.0.0.1:\(LocalServer.port)/")! }

    private let queue = DispatchQueue(label: "pl.bartekjones.localserver")
    private var listener: NWListener?
    private var ready = false
    private var starting = false
    private var pending: [(Bool) -> Void] = []

    /// Idempotentne: gotowy serwer odpowiada od razu, w trakcie startu dopisuje
    /// wywołującego do kolejki, po awarii próbuje wystartować ponownie.
    func start(_ completion: @escaping (Bool) -> Void) {
        queue.async {
            if self.ready { DispatchQueue.main.async { completion(true) }; return }
            self.pending.append(completion)
            if self.starting { return }
            self.starting = true
            self.launch()
        }
    }

    private func finish(_ ok: Bool) {
        let callbacks = pending
        pending.removeAll()
        starting = false
        DispatchQueue.main.async { callbacks.forEach { $0(ok) } }
    }

    private func launch() {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.requiredLocalEndpoint = NWEndpoint.hostPort(
            host: "127.0.0.1",
            port: NWEndpoint.Port(rawValue: LocalServer.port)!)
        let l: NWListener
        do { l = try NWListener(using: params) } catch { finish(false); return }
        listener = l
        l.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.ready = true
                self.finish(true)
            case .failed, .cancelled:
                self.ready = false
                self.listener = nil
                self.finish(false)
            default:
                break
            }
        }
        l.newConnectionHandler = { [weak self] conn in self?.serve(conn) }
        l.start(queue: queue)
    }

    // MARK: - HTTP

    private func serve(_ conn: NWConnection) {
        conn.start(queue: queue)
        read(conn, Data())
    }

    private func read(_ conn: NWConnection, _ sofar: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, complete, error in
            guard let self = self else { conn.cancel(); return }
            var buf = sofar
            if let d = data { buf.append(d) }
            if let end = buf.range(of: Data("\r\n\r\n".utf8)) {
                self.respond(conn, head: String(decoding: buf[..<end.lowerBound], as: UTF8.self))
            } else if complete || error != nil || buf.count > 65_536 {
                conn.cancel()
            } else {
                self.read(conn, buf)
            }
        }
    }

    private func respond(_ conn: NWConnection, head: String) {
        let request = head.components(separatedBy: "\r\n").first ?? ""
        let parts = request.split(separator: " ")
        guard parts.count >= 2, parts[0] == "GET" || parts[0] == "HEAD" else {
            send(conn, "405 Method Not Allowed", "text/plain", Data()); return
        }
        var path = String(parts[1])
        if let q = path.firstIndex(of: "?") { path = String(path[..<q]) }
        if path == "/" { path = "/index.html" }
        let name = (path as NSString).lastPathComponent
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        guard !path.contains(".."), !base.isEmpty,
              let url = Bundle.main.url(forResource: base, withExtension: ext.isEmpty ? nil : ext),
              let body = try? Data(contentsOf: url) else {
            send(conn, "404 Not Found", "text/plain; charset=utf-8", Data("404".utf8)); return
        }
        send(conn, "200 OK", mime(ext), parts[0] == "HEAD" ? Data() : body, length: body.count)
    }

    private func send(_ conn: NWConnection, _ status: String, _ type: String, _ body: Data, length: Int? = nil) {
        var head = "HTTP/1.1 \(status)\r\n"
        head += "Content-Type: \(type)\r\n"
        head += "Content-Length: \(length ?? body.count)\r\n"
        head += "Cache-Control: no-store\r\n"
        head += "Connection: close\r\n\r\n"
        var out = Data(head.utf8)
        out.append(body)
        // .finalMessage zamyka stronę zapisu FIN-em po danych, zamiast urywać RST-em.
        conn.send(content: out, contentContext: .finalMessage, isComplete: true,
                  completion: .contentProcessed { _ in conn.cancel() })
    }

    private func mime(_ ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js": return "text/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "json": return "application/json"
        case "webmanifest": return "application/manifest+json"
        case "png": return "image/png"
        case "svg": return "image/svg+xml"
        default: return "application/octet-stream"
        }
    }
}
