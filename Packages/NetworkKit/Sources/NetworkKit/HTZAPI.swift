import Foundation
import Moya

public enum HTZAPI {
    case albums
    case items(sutraId: String, pageIndex: Int, pageSize: Int)
    case recommendations
}

extension HTZAPI: TargetType {
    public var baseURL: URL {
        // In a real scenario, this would come from a configuration object
        return URL(string: "http://htzshanghai.top/get") ?? URL(string: "http://localhost")!
    }
    
    public var path: String {
        switch self {
        case .albums:
            return "/sutras"
        case .items:
            return "/sutra/items"
        case .recommendations:
            return "/recommendations" // Simplified for now
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .albums, .items, .recommendations:
            return .get
        }
    }
    
    public var task: Task {
        switch self {
        case .albums:
            return .requestParameters(parameters: ["page_index": 0, "page_size": 500], encoding: URLEncoding.default)
        case let .items(sutraId, pageIndex, pageSize):
            return .requestParameters(parameters: [
                "sutra_id": sutraId,
                "page_index": pageIndex,
                "page_size": pageSize
            ], encoding: URLEncoding.default)
        case .recommendations:
            return .requestPlain
        }
    }
    
    public var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    public var sampleData: Data {
        return Data()
    }
}
