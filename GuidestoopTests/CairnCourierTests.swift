import XCTest
@testable import Guidestoop

private struct ProbeDTO: Decodable {
    var marks: LooseMark
}

private actor ScriptedCrossing: CairnCrossing {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func cross(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class CairnCourierTests: XCTestCase {
    private let url = URL(string: "https://guidestoop-cairn.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let channel = ScriptedCrossing(results: [
            .success((Data("{\"marks\":1}".utf8), http(200))),
        ])
        let courier = CairnCourier(crossing: channel)
        _ = try await courier.readSlip(ProbeDTO.self, from: url)
        let request = await channel.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), CairnCourier.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(CairnCourier.userAgent, "Guidestoop/1.0 (iOS; +https://guidestoop-cairn.pro)")
        XCTAssertEqual(CairnCourier.contactURL.absoluteString, "https://guidestoop-cairn.pro/contact-us")
    }

    func test_retriesTransientTransportOnce() async throws {
        let channel = ScriptedCrossing(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"marks\":\"4.5\"}".utf8), http(200))),
        ])
        let courier = CairnCourier(crossing: channel)
        let dto = try await courier.readSlip(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.marks.amount, 4.5)
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let channel = ScriptedCrossing(results: [
            .success((Data(), http(404))),
            .success((Data("{\"marks\":1}".utf8), http(200))),
        ])
        let courier = CairnCourier(crossing: channel)
        do {
            _ = try await courier.readSlip(ProbeDTO.self, from: url)
            XCTFail("expected vacant camp")
        } catch {
            XCTAssertEqual(error as? CairnFault, .vacantCamp)
        }
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsTornSlip() async {
        let channel = ScriptedCrossing(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let courier = CairnCourier(crossing: channel)
        do {
            _ = try await courier.readSlip(ProbeDTO.self, from: url)
            XCTFail("expected torn slip")
        } catch {
            XCTAssertEqual(error as? CairnFault, .tornSlip)
        }
    }

    func test_statusZeroMapsToVacantCamp() async {
        let channel = ScriptedCrossing(results: [
            .success((Data("{\"status\":0}".utf8), http(200))),
        ])
        let courier = CairnCourier(crossing: channel)
        do {
            _ = try await courier.markStatus(from: url)
            XCTFail("expected vacant camp")
        } catch {
            XCTAssertEqual(error as? CairnFault, .vacantCamp)
        }
    }

    func test_looseMarkAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"marks\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"marks\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"marks\":null}".utf8))
        XCTAssertEqual(number.marks.amount, 12.5)
        XCTAssertEqual(string.marks.amount, 12.5)
        XCTAssertNil(missing.marks.amount)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
