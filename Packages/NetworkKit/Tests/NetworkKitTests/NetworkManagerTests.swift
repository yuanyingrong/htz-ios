import XCTest
import Combine
import Moya
@testable import NetworkKit

private enum StubTarget: TargetType {
    case ping

    var baseURL: URL { URL(string: "https://example.com")! }
    var path: String { "ping" }
    var method: Moya.Method { .post }
    var task: Moya.Task { .requestPlain }
    var headers: [String: String]? { nil }
    var sampleData: Data { Data(#"{"code":200,"data":"pong"}"#.utf8) }
}

final class NetworkManagerTests: XCTestCase {
    func testTemporaryManagerStillCompletesRequest() {
        let done = expectation(description: "request completes")
        var body: Data?
        let publisher = NetworkManager<StubTarget>(
            provider: MoyaProvider<StubTarget>(stubClosure: MoyaProvider.delayedStub(0.1))
        ).requestData(.ping)
        let cancellable = publisher.sink(
            receiveCompletion: { _ in done.fulfill() },
            receiveValue: { body = $0 }
        )
        wait(for: [done], timeout: 3)
        cancellable.cancel()
        XCTAssertEqual(body.map { String(decoding: $0, as: UTF8.self) }, #"{"code":200,"data":"pong"}"#)
    }
}
