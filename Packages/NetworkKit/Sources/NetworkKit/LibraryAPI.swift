import Foundation

public struct LibraryFileURLs: Equatable, Sendable {
    public var audioURL: URL?
    public var originalLyricURL: URL?
    public var explanationLyricURL: URL?
}

public struct SearchHit: Equatable, Identifiable, Sendable {
    public var id: String
    public var sutraTitle: String
    public var title: String
    public var time: String
    public var content: String
    public var lrcType: String
}

public struct FavoriteItem: Equatable, Identifiable, Sendable {
    public var id: String
    public var serverId: String
    public var sutraItemId: String
    public var sutraId: String
    public var title: String
    public var sutraName: String
    public var cover: String
}

public struct ListenHistoryItem: Equatable, Identifiable, Sendable {
    public var id: String
    public var sutraItemId: String
    public var sutraId: String
    public var title: String
    public var sutraName: String
    public var cover: String
    public var lastPosition: Int
}

public struct NoticeItem: Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var message: String
    public var isRead: Bool
}

public struct UserProfile: Equatable, Sendable {
    public var nickname: String
    public var avatar: String
    public var signature: String
    public var mobile: String
    public var unionid: String

    public init(nickname: String = "", avatar: String = "", signature: String = "", mobile: String = "", unionid: String = "") {
        self.nickname = nickname
        self.avatar = avatar
        self.signature = signature
        self.mobile = mobile
        self.unionid = unionid
    }
}

public enum LibraryAPI {
    public static func loadAlbums() async throws -> [Album] {
        let response: APIResponse<[Album]> = try await NetworkManager<HTZAPI>()
            .request(.albums)
            .eraseToAnyPublisher()
            .async()
        return response.data ?? []
    }

    public static func fileURL(sutraId: String, itemId: String) async throws -> LibraryFileURLs {
        let data = try await request(.sutraItemFileURL(sutraId: sutraId, sutraItemId: itemId, expireSeconds: 3600))
        let json = try jsonObject(data)
        if intCode(json) == 90001 {
            throw NetworkError.accessDenied
        }
        let payload = json["data"] as? [String: Any] ?? json
        let signed = payload["signed_urls"] as? [String: Any] ?? payload["signedUrls"] as? [String: Any]
        return LibraryFileURLs(
            audioURL: url(signed?["audio"] as? String),
            originalLyricURL: url(signed?["original_lyric"] as? String ?? signed?["originalLyric"] as? String),
            explanationLyricURL: url(signed?["explanation_lyric"] as? String ?? signed?["explanationLyric"] as? String)
        )
    }

    public static func search(key: String, offset: Int = 0, limit: Int = 30) async throws -> [SearchHit] {
        let data = try await request(.search(key: key, offset: offset, limit: limit))
        let rows = arrayPayload(try jsonObject(data))
        return rows.enumerated().map { index, row in
            let sutraTitle = string(row, "sutraTitle", "sutra_title", "sutra_name")
            let title = string(row, "title", "sutra_item_title")
            let time = string(row, "time")
            return SearchHit(
                id: "\(index)-\(sutraTitle)-\(title)-\(time)",
                sutraTitle: sutraTitle,
                title: title,
                time: time,
                content: string(row, "content"),
                lrcType: string(row, "lrcType", "lrc_type")
            )
        }
    }

    public static func favorites() async throws -> [FavoriteItem] {
        let data = try await request(.favorites)
        return arrayPayload(try jsonObject(data)).map { row in
            let itemId = string(row, "sutra_item_id", "sutraItemId")
            return FavoriteItem(
                id: itemId.isEmpty ? string(row, "id") : itemId,
                serverId: string(row, "id"),
                sutraItemId: itemId,
                sutraId: string(row, "sutra_id", "sutraId"),
                title: string(row, "title", "sutra_item_title"),
                sutraName: string(row, "sutra_name", "sutraName"),
                cover: string(row, "sutra_cover", "cover")
            )
        }
    }

    public static func addFavorite(itemId: String) async throws {
        _ = try await request(.addFavorite(itemId: itemId))
    }

    public static func deleteFavorite(serverId: String) async throws {
        _ = try await request(.deleteFavorite(id: serverId))
    }

    public static func histories() async throws -> [ListenHistoryItem] {
        let data = try await request(.listenHistories(pageIndex: 0, pageSize: 200))
        return arrayPayload(try jsonObject(data)).map { row in
            let itemId = string(row, "sutra_item_id", "sutraItemId")
            let serverId = string(row, "id")
            return ListenHistoryItem(
                id: serverId.isEmpty ? itemId : serverId,
                sutraItemId: itemId,
                sutraId: string(row, "sutra_id", "sutraId"),
                title: string(row, "sutra_item_title", "title"),
                sutraName: string(row, "sutra_name", "sutraName"),
                cover: string(row, "sutra_cover", "cover"),
                lastPosition: intValue(row, "last_position", "lastPosition")
            )
        }
    }

    public static func deleteHistory(id: String) async throws {
        _ = try await request(.deleteListenHistory(id: id))
    }

    public static func deleteAllHistories() async throws {
        _ = try await request(.deleteAllListenHistories)
    }

    public static func reportHistory(itemId: String, position: Int) async {
        guard !itemId.isEmpty else { return }
        _ = try? await request(.postListenHistory(itemId: itemId, position: position))
    }

    public static func notifications() async throws -> [NoticeItem] {
        let data = try await request(.notifications(pageIndex: 0, pageSize: 200))
        return arrayPayload(try jsonObject(data)).map { row in
            NoticeItem(
                id: string(row, "id"),
                title: string(row, "title"),
                message: string(row, "msg", "message"),
                isRead: intValue(row, "read", "is_read") != 0 || (row["read"] as? Bool ?? false)
            )
        }
    }

    public static func markNotificationRead(id: String) async {
        _ = try? await request(.markNotificationsRead(ids: [id]))
    }

    public static func profile() async throws -> UserProfile {
        let unionid = AuthManager.shared.unionid ?? ""
        let data = try await request(.userInfo(unionid: unionid))
        let json = try jsonObject(data)
        let payload = json["data"] as? [String: Any] ?? json
        return UserProfile(
            nickname: string(payload, "nickname", "name"),
            avatar: string(payload, "headimgurl", "avatar"),
            signature: string(payload, "sign", "signature"),
            mobile: string(payload, "mobile", "telephone"),
            unionid: string(payload, "unionid", "union_id").isEmpty ? unionid : string(payload, "unionid", "union_id")
        )
    }

    public static func updateProfile(nickname: String, signature: String) async throws {
        let current = (try? await profile()) ?? UserProfile(unionid: AuthManager.shared.unionid ?? "")
        _ = try await request(.updateUserInfo(parameters: [
            "unionid": current.unionid,
            "nickname": nickname,
            "sign": signature,
            "headimgurl": current.avatar,
            "mobile": current.mobile
        ]))
    }

    public static func sendSms(telephone: String) async throws {
        _ = try await request(.sendSms(telephone: telephone, unionid: AuthManager.shared.unionid ?? ""))
    }

    public static func bindTelephone(telephone: String, code: String) async throws {
        _ = try await request(.bindTelephone(telephone: telephone, code: code, unionid: AuthManager.shared.unionid ?? ""))
        _ = try? await request(.putUserMobile(mobile: telephone))
    }

    public static func submitFeedback(content: String, contact: String, imageData: [Data]) async throws {
        var urls: [String] = []
        for (index, data) in imageData.enumerated() {
            let uploaded = try await uploadFeedbackImage(data, filename: "feedback-\(index).jpg")
            urls.append(uploaded)
        }
        let profile = (try? await profile()) ?? UserProfile()
        _ = try await request(.feedbackAdd(parameters: [
            "user_id": AuthManager.shared.unionid ?? "",
            "nickname": profile.nickname,
            "contact": contact,
            "content": content,
            "category": "其他",
            "pkg": "cn.org.htz.next",
            "version": "1.0",
            "phone_model": "iPhone",
            "engineering_model": "iPhone",
            "os_version": "iOS",
            "device_id": AuthManager.shared.unionid ?? "",
            "image_urls": urls.joined(separator: ","),
            "video_url": ""
        ]))
    }

    private static func uploadFeedbackImage(_ data: Data, filename: String) async throws -> String {
        let body = try await request(.feedbackUpload(data: data, filename: filename))
        let json = try jsonObject(body)
        let payload = json["data"] as? [String: Any] ?? [:]
        let url = string(payload, "url")
        if url.isEmpty {
            throw NetworkError.apiError("图片上传失败")
        }
        return url
    }

    private static func request(_ target: HTZAPI) async throws -> Data {
        try await NetworkManager<HTZAPI>().requestData(target).eraseToAnyPublisher().async()
    }

    private static func jsonObject(_ data: Data) throws -> [String: Any] {
        (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private static func arrayPayload(_ json: [String: Any]) -> [[String: Any]] {
        if let rows = json["data"] as? [[String: Any]] { return rows }
        if let rows = json["data"] as? [Any] {
            return rows.compactMap { $0 as? [String: Any] }
        }
        return []
    }

    private static func string(_ row: [String: Any], _ keys: String...) -> String {
        for key in keys {
            if let value = row[key] as? String, !value.isEmpty { return value }
            if let value = row[key] as? Int { return String(value) }
        }
        return ""
    }

    private static func intValue(_ row: [String: Any], _ keys: String...) -> Int {
        for key in keys {
            if let value = row[key] as? Int { return value }
            if let value = row[key] as? Double { return Int(value) }
            if let value = row[key] as? String, let intValue = Int(value) { return intValue }
        }
        return 0
    }

    private static func intCode(_ json: [String: Any]) -> Int {
        if let code = json["code"] as? Int { return code }
        if let code = json["code"] as? String { return Int(code) ?? -1 }
        return -1
    }

    private static func url(_ value: String?) -> URL? {
        guard let value, !value.isEmpty else { return nil }
        return URL(string: value)
    }
}
