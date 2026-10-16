import Foundation

public class AuthManager {
    public static let shared = AuthManager()
    
    private let tokenKey = "auth_token"
    private let unionidKey = "auth_unionid"
    private let appleUserIdKey = "auth_apple_user_id"
    
    public var token: String? {
        get {
            return KeychainHelper.shared.read(forKey: tokenKey)
        }
        set {
            if let newValue = newValue {
                KeychainHelper.shared.save(newValue, forKey: tokenKey)
            } else {
                KeychainHelper.shared.delete(forKey: tokenKey)
            }
        }
    }
    
    public var unionid: String? {
        get {
            return UserDefaults.standard.string(forKey: unionidKey)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: unionidKey)
            } else {
                UserDefaults.standard.removeObject(forKey: unionidKey)
            }
        }
    }
    
    /// Reserved for Sign in with Apple. The login button is present; the certificate flow is not connected yet.
    public var appleUserId: String? {
        get { UserDefaults.standard.string(forKey: appleUserIdKey) }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: appleUserIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: appleUserIdKey)
            }
        }
    }

    public var isLoggedIn: Bool {
        return token != nil
    }
    
    private init() {}
    
    public func setupTestAccount() {
        self.unionid = "oJuR607eZwW3LlsaxcAExu1pOVpA"
        self.token = "c4626290-32c1-565d-a52d-bdad435206f1"
    }
    
    public func logout() {
        self.token = nil
        self.unionid = nil
        self.appleUserId = nil
    }
}
