import Foundation
import Moya
import Combine
import CombineMoya

public enum NetworkError: Error {
    case decodingError(Error)
    case apiError(String)
    case unknown
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
