import XCTest
@testable import NetworkKit

final class KeychainHelperTests: XCTestCase {
    private let testKey = "test_credentials_key"
    private let testValue = "secure_token_123"
    
    override func setUp() {
        super.setUp()
        // Clean up before test runs
        KeychainHelper.shared.delete(forKey: testKey)
    }
    
    override func tearDown() {
        KeychainHelper.shared.delete(forKey: testKey)
        super.tearDown()
    }
    
    func testKeychainSaveAndRead() {
        let saveSuccess = KeychainHelper.shared.save(testValue, forKey: testKey)
        XCTAssertTrue(saveSuccess)
        
        let retrievedValue = KeychainHelper.shared.read(forKey: testKey)
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    func testKeychainOverwrite() {
        KeychainHelper.shared.save(testValue, forKey: testKey)
        
        let newValue = "new_secure_token_456"
        let overwriteSuccess = KeychainHelper.shared.save(newValue, forKey: testKey)
        XCTAssertTrue(overwriteSuccess)
        
        let retrievedValue = KeychainHelper.shared.read(forKey: testKey)
        XCTAssertEqual(retrievedValue, newValue)
    }
    
    func testKeychainDelete() {
        KeychainHelper.shared.save(testValue, forKey: testKey)
        
        let deleteSuccess = KeychainHelper.shared.delete(forKey: testKey)
        XCTAssertTrue(deleteSuccess)
        
        let retrievedValue = KeychainHelper.shared.read(forKey: testKey)
        XCTAssertNil(retrievedValue)
    }
}
