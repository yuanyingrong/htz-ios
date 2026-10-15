import XCTest
@testable import NetworkKit

final class SignedMediaResponsesTests: XCTestCase {
    func testSutraCoverURLResponseDecoding() throws {
        let json = """
        {
            "sutra_id": "68522e90bfd2bf2593d6fa63",
            "cover_id": "production/68ff7068bfd2bf16f3f1288e",
            "signed_url": "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/production/test.jpg?x-oss-signature=123",
            "expire_seconds": 3600
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let resp = try decoder.decode(SutraCoverURLResponse.self, from: json)
        
        XCTAssertEqual(resp.sutraId, "68522e90bfd2bf2593d6fa63")
        XCTAssertEqual(resp.coverId, "production/68ff7068bfd2bf16f3f1288e")
        XCTAssertTrue(resp.signedUrl?.contains("signature=123") == true)
        XCTAssertEqual(resp.expireSeconds, 3600)
    }
    
    func testSutraItemFileURLResponseDecoding() throws {
        let json = """
        {
            "sutra_id": "69faa6f8bfd2bf74f285808c",
            "sutra_item_id": "6a296007bfd2bf208ba0807d",
            "is_paid": 1,
            "is_trial": 1,
            "expire_seconds": 3600,
            "signed_urls": {
                "audio": "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/audio.mp3?x-oss-signature=abc",
                "explanation_lyric": "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/lyric.lrc?x-oss-signature=def"
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let resp = try decoder.decode(SutraItemFileURLResponse.self, from: json)
        
        XCTAssertEqual(resp.sutraId, "69faa6f8bfd2bf74f285808c")
        XCTAssertEqual(resp.sutraItemId, "6a296007bfd2bf208ba0807d")
        XCTAssertEqual(resp.isPaid, 1)
        XCTAssertEqual(resp.isTrial, 1)
        XCTAssertEqual(resp.signedUrls?.audio, "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/audio.mp3?x-oss-signature=abc")
        XCTAssertEqual(resp.signedUrls?.explanationLyric, "https://htz-sutra.oss-cn-shanghai.aliyuncs.com/lyric.lrc?x-oss-signature=def")
    }
}
