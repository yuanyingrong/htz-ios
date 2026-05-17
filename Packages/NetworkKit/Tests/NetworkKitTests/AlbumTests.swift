import XCTest
@testable import NetworkKit

final class AlbumTests: XCTestCase {
    func testAlbumDecoding() throws {
        let json = """
        {
            "albumId": "123",
            "albumName": "Test Album",
            "imageUrl": "https://example.com/image.jpg"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let album = try decoder.decode(Album.self, from: json)
        
        XCTAssertEqual(album.id, "123")
        XCTAssertEqual(album.name, "Test Album")
        XCTAssertEqual(album.imageUrl, "https://example.com/image.jpg")
    }
    
    func testAlbumListDecoding() throws {
        let json = """
        [
            {
                "albumId": "1",
                "albumName": "Album 1"
            },
            {
                "albumId": "2",
                "albumName": "Album 2",
                "imageUrl": "url2"
            }
        ]
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let albums = try decoder.decode([Album].self, from: json)
        
        XCTAssertEqual(albums.count, 2)
        XCTAssertEqual(albums[0].id, "1")
        XCTAssertEqual(albums[1].name, "Album 2")
    }
}
