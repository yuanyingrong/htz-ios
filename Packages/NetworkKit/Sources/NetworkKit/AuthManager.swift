import Foundation

public class AuthManager {
    public static let shared = AuthManager()
    
    public var token: String?
    public var unionid: String?
    
    private init() {}
    
    public func setupTestAccount() {
        self.unionid = "oJuR607eZwW3LlsaxcAExu1pOVpA"
        self.token = "c4626290-32c1-565d-a52d-bdad435206f1"
    }
}
