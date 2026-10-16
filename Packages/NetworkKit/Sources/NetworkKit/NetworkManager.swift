import Foundation
import Moya
import Combine
import CombineMoya

public enum NetworkError: Error, Equatable {
    case decodingError(Error)
    case apiError(String)
    case accessDenied
    case unknown

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case let (.decodingError(lhsError), .decodingError(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case let (.apiError(lhsMsg), .apiError(rhsMsg)):
            return lhsMsg == rhsMsg
        case (.accessDenied, .accessDenied):
            return true
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
    
    public func requestData(_ target: Target) -> AnyPublisher<Data, NetworkError> {
        provider.requestPublisher(target)
            .tryMap { (response: Response) -> Data in
                if response.statusCode == 403 {
                    throw NetworkError.accessDenied
                }
                if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any] {
                    let code = (json["code"] as? Int) ?? Int(json["code"] as? String ?? "")
                    if code == 90001 {
                        throw NetworkError.accessDenied
                    }
                }
                guard (200...299).contains(response.statusCode) else {
                    throw NetworkError.apiError("HTTP status \(response.statusCode)")
                }
                return response.data
            }
            .mapError { error -> NetworkError in
                if let netErr = error as? NetworkError { return netErr }
                return NetworkError.unknown
            }
            .eraseToAnyPublisher()
    }

    public func request<T: Codable>(_ target: Target) -> AnyPublisher<T, NetworkError> {
        return provider.requestPublisher(target)
            .tryMap { (response: Response) -> Data in
                if response.statusCode == 403 {
                    throw NetworkError.accessDenied
                }
                
                // Inspect response for API error code 90001
                if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any],
                   let code = json["code"] as? Int {
                    if code == 90001 {
                        throw NetworkError.accessDenied
                    } else if code != 200 && code != 0 {
                        let msg = json["data"] as? String ?? json["msg"] as? String ?? "Request failed"
                        throw NetworkError.apiError(msg)
                    }
                }
                
                guard (200...299).contains(response.statusCode) else {
                    throw NetworkError.apiError("HTTP status \(response.statusCode)")
                }
                return response.data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error -> NetworkError in
                if let netErr = error as? NetworkError {
                    return netErr
                } else if let decodingError = error as? DecodingError {
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

