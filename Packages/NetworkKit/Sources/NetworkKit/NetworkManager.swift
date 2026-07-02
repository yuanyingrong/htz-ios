import Foundation
import Moya
import Combine
import CombineMoya

public enum NetworkError: Error, Equatable {
    case decodingError(Error)
    case apiError(String)
    case unknown

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case let (.decodingError(lhsError), .decodingError(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case let (.apiError(lhsMsg), .apiError(rhsMsg)):
            return lhsMsg == rhsMsg
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}


public class NetworkManager<Target: TargetType> {
    private let provider: MoyaProvider<Target>
    private let decoder: JSONDecoder
    
    public init(
        provider: MoyaProvider<Target> = MoyaProvider<Target>(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.provider = provider
        self.decoder = decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    public func request<T: Codable>(_ target: Target) -> AnyPublisher<T, NetworkError> {
        return provider.requestPublisher(target)
            .filterSuccessfulStatusCodes()
            .map { (response: Response) -> Data in
                return response.data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> NetworkError in
                if let decodingError = error as? DecodingError {
                    return NetworkError.decodingError(decodingError)
                }
                return NetworkError.unknown
            }
            .eraseToAnyPublisher()
    }
}

public extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                }
            )
        }
    }
}

