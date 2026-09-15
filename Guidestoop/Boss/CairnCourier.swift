import Foundation

/// Role: Boss. Typed hop failures. This product has no remote catalog.
enum CairnFault: Error, Equatable, Sendable {
    case vacantCamp
    case tornSlip
    case misted
    case cutCrossing
    case notHTTP
}

/// Role: Boss. Injected crossing so tests never leave the process.
protocol CairnCrossing: Sendable {
    func cross(_ request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Boss. URLSession hop with a 15 s timeout and the app User-Agent.
struct CairnMist: CairnCrossing {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": CairnCourier.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func cross(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Boss. Number or numeric string; missing stays nil. Never a domain field.
struct LooseMark: Sendable, Equatable, Decodable {
    var amount: Double?

    init(amount: Double?) {
        self.amount = amount
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.singleValueContainer()
        if box.decodeNil() {
            amount = nil
            return
        }
        if let number = try? box.decode(Double.self) {
            amount = number
            return
        }
        if let whole = try? box.decode(Int.self) {
            amount = Double(whole)
            return
        }
        if let text = try? box.decode(String.self) {
            amount = Double(text)
            return
        }
        amount = nil
    }
}

struct StatusSlip: Decodable, Sendable {
    var status: Int
}

/// Role: Boss. Owns the session. Contact URL is opened by Settings, not decoded here.
actor CairnCourier {
    static let userAgent = "Guidestoop/1.0 (iOS; +https://guidestoop-cairn.pro)"
    static let contactURL = URL(string: "https://guidestoop-cairn.pro/contact-us")!

    private let crossing: any CairnCrossing

    init(crossing: any CairnCrossing) {
        self.crossing = crossing
    }

    init() {
        self.crossing = CairnMist()
    }

    func readSlip<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await haul(ticket(for: url))
        do {
            return try JSONDecoder().decode(DTO.self, from: body)
        } catch is CancellationError {
            throw CairnFault.cutCrossing
        } catch {
            throw CairnFault.tornSlip
        }
    }

    func markStatus(from url: URL) async throws -> Int {
        let slip = try await readSlip(StatusSlip.self, from: url)
        if slip.status == 0 {
            throw CairnFault.vacantCamp
        }
        return slip.status
    }

    private func ticket(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func haul(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let fault as CairnFault {
            throw fault
        } catch is CancellationError {
            throw CairnFault.cutCrossing
        } catch {
            if Self.cutShort(error) {
                throw CairnFault.cutCrossing
            }
            guard Self.transient(error) else { throw CairnFault.misted }
            do {
                return try await send(request)
            } catch let fault as CairnFault {
                throw fault
            } catch is CancellationError {
                throw CairnFault.cutCrossing
            } catch {
                if Self.cutShort(error) { throw CairnFault.cutCrossing }
                throw CairnFault.misted
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (body, reply) = try await crossing.cross(request)
        guard let http = reply as? HTTPURLResponse else {
            throw CairnFault.notHTTP
        }
        if http.statusCode == 404 {
            throw CairnFault.vacantCamp
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw CairnFault.misted
        }
        return body
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cutShort(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
