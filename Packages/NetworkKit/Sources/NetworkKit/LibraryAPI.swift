import Foundation
import UIKit

/// Live implementation of every HTZ server call. Features reach it through `LibraryClient`.
public enum LibraryAPI {
    // MARK: Library

    public static func loadAlbums() async throws -> [Album] {
        let response: APIResponse<[Album]> = try await NetworkManager<HTZAPI>()
            .request(.albums)
            .eraseToAnyPublisher()
            .async()
        return response.data ?? []
    }

    /// Albums with covers replaced by short-lived signed URLs, falling back to the public OSS path.
    public static func albumsWithCovers() async throws -> [Album] {
        let albums = try await loadAlbums()
        return await withTaskGroup(of: (Int, Album).self) { group in
            for (index, album) in albums.enumerated() {
                group.addTask {
                    let cover = await coverURL(sutraId: album.id) ?? MediaTime.ossURL(album.imageUrl)?.absoluteString
                    return (index, album.withImage(cover))
                }
            }
            var results: [(Int, Album)] = []
            for await entry in group { results.append(entry) }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    public static func items(sutraId: String) async throws -> [SutraItem] {
        let response: APIResponse<[SutraItem]> = try await NetworkManager<HTZAPI>()
            .request(.items(sutraId: sutraId, pageIndex: 0, pageSize: 500))
            .eraseToAnyPublisher()
            .async()
        return response.data ?? []
    }

    public static func coverURL(sutraId: String) async -> String? {
        if let cached = CoverCache.shared.get(sutraId) { return cached }
        let response: APIResponse<SutraCoverURLResponse>? = try? await NetworkManager<HTZAPI>()
            .request(.sutraCoverURL(sutraId: sutraId, expireSeconds: 3600))
            .eraseToAnyPublisher()
            .async()
        guard let signed = response?.data?.signedUrl, !signed.isEmpty else { return nil }
        CoverCache.shared.set(signed, for: sutraId, expireSeconds: response?.data?.expireSeconds ?? 3600)
        return signed
    }

    public static func recommendations() async throws -> [Recommendation] {
        let data = try await request(.recommendations)
        let rows = arrayPayload(try jsonObject(data))
        return rows
            .sorted { intValue($0, "sort") < intValue($1, "sort") }
            .compactMap { row in
                let sutraId = string(row, "sutra_id", "sutraId", "id")
                guard !sutraId.isEmpty else { return nil }
                let image = string(row, "recommendation_background_url", "background_url", "cover")
                return Recommendation(
                    sutraId: sutraId,
                    name: string(row, "sutra_name", "recommendation_name", "name"),
                    imageUrl: MediaTime.ossURL(image)?.absoluteString,
                    description: string(row, "sutra_desc", "description")
                )
            }
    }

    public static func purchase(sutraId: String) async throws -> AlbumPurchase {
        let data = try await request(.album(id: sutraId))
        let json = try jsonObject(data)
        let payload = objectPayload(json)
        return AlbumPurchase(
            isPaid: boolValue(payload, "is_paid", "isPaid"),
            isPurchased: boolValue(payload, "is_purchased", "isPurchased"),
            paidUrl: string(payload, "paid_url", "paidUrl").nilIfEmpty
        )
    }

    public static func fileURL(sutraId: String, itemId: String) async throws -> MediaFileURLs {
        let response: APIResponse<SutraItemFileURLResponse> = try await NetworkManager<HTZAPI>()
            .request(.sutraItemFileURL(sutraId: sutraId, sutraItemId: itemId, expireSeconds: 3600))
            .eraseToAnyPublisher()
            .async()
        let signed = response.data?.signedUrls
        return MediaFileURLs(
            audioURL: url(signed?.audio),
            originalLyricURL: url(signed?.originalLyric),
            explanationLyricURL: url(signed?.explanationLyric)
        )
    }

    public static func incrementPlayedCount(itemId: String) async {
        guard !itemId.isEmpty else { return }
        _ = try? await request(.playedCountInc(itemId: itemId))
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

    // MARK: Favorites & history

    public static func favorites() async throws -> [FavoriteItem] {
        let data = try await request(.favorites)
        let rows = arrayPayload(try jsonObject(data)).map { row in
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
        let missing = rows.filter { $0.title.isEmpty || $0.sutraName.isEmpty || $0.sutraId.isEmpty }
        guard !missing.isEmpty else { return rows }
        let directory = await ItemDirectory.shared.entries(for: missing.map { ($0.sutraItemId, $0.sutraId) })
        return rows.map { row in
            guard let entry = directory[row.sutraItemId] else { return row }
            var row = row
            if row.title.isEmpty { row.title = entry.title }
            if row.sutraName.isEmpty { row.sutraName = entry.sutraName }
            if row.sutraId.isEmpty { row.sutraId = entry.sutraId }
            if row.cover.isEmpty { row.cover = entry.cover }
            return row
        }
    }

    public static func addFavorite(itemId: String) async throws {
        try ensureSuccess(await request(.addFavorite(itemId: itemId)))
    }

    public static func deleteFavorite(serverId: String) async throws {
        try ensureSuccess(await request(.deleteFavorite(id: serverId)))
    }

    public static func deleteAllFavorites() async throws {
        try ensureSuccess(await request(.deleteAllFavorites))
    }

    public static func histories() async throws -> [ListenHistoryItem] {
        let data = try await request(.listenHistories(pageIndex: 0, pageSize: 200))
        let rows = arrayPayload(try jsonObject(data)).map { row in
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
        let missing = rows.filter { $0.title.isEmpty || $0.sutraName.isEmpty || $0.sutraId.isEmpty }
        guard !missing.isEmpty else { return rows }
        let directory = await ItemDirectory.shared.entries(for: missing.map { ($0.sutraItemId, $0.sutraId) })
        return rows.map { row in
            guard let entry = directory[row.sutraItemId] else { return row }
            var row = row
            if row.title.isEmpty { row.title = entry.title }
            if row.sutraName.isEmpty { row.sutraName = entry.sutraName }
            if row.sutraId.isEmpty { row.sutraId = entry.sutraId }
            if row.cover.isEmpty { row.cover = entry.cover }
            return row
        }
    }

    public static func deleteHistory(id: String) async throws {
        try ensureSuccess(await request(.deleteListenHistory(id: id)))
    }

    public static func deleteAllHistories() async throws {
        try ensureSuccess(await request(.deleteAllListenHistories))
    }

    public static func reportHistory(itemId: String, position: Int) async {
        guard !itemId.isEmpty else { return }
        _ = try? await request(.postListenHistory(itemId: itemId, position: position))
    }

    // MARK: Notifications

    public static func notifications() async throws -> [NoticeItem] {
        let data = try await request(.notifications(pageIndex: 0, pageSize: 200))
        return arrayPayload(try jsonObject(data)).map { row in
            NoticeItem(
                id: string(row, "id"),
                title: string(row, "title"),
                message: string(row, "msg", "message"),
                createdAt: string(row, "created_at", "createdAt"),
                isRead: boolValue(row, "is_read", "read")
            )
        }
    }

    public static func markNotificationsRead(ids: [String]) async {
        guard !ids.isEmpty else { return }
        _ = try? await request(.markNotificationsRead(ids: ids))
    }

    // MARK: Account

    public static func profile() async throws -> UserProfile {
        let unionid = AuthManager.shared.unionid ?? ""
        let data = try await request(.userInfo(unionid: unionid))
        let payload = objectPayload(try jsonObject(data))
        var profile = profile(from: payload)
        if profile.unionid.isEmpty { profile.unionid = unionid }
        return profile
    }

    public static func updateProfile(_ profile: UserProfile) async throws {
        try ensureSuccess(await request(.updateUserInfo(parameters: [
            "unionid": profile.unionid.isEmpty ? (AuthManager.shared.unionid ?? "") : profile.unionid,
            "nickname": profile.nickname,
            "sign": profile.signature,
            "headimgurl": profile.avatar,
            "mobile": profile.mobile,
            "sex": String(profile.sex),
            "province": profile.province,
            "city": profile.city
        ])))
    }

    public static func sendSms(telephone: String) async throws {
        try ensureSuccess(await request(.sendSms(telephone: telephone, unionid: AuthManager.shared.unionid ?? "")))
    }

    public static func bindTelephone(telephone: String, code: String) async throws {
        let current = AuthManager.shared.unionid ?? ""
        if let bound = try await unionid(forTelephone: telephone), bound != current {
            throw NetworkError.apiError("该手机号已绑定其他账号")
        }
        try ensureSuccess(await request(.bindTelephone(telephone: telephone, code: code, unionid: current)))
        _ = try? await request(.putUserMobile(mobile: telephone))
    }

    /// Phone login: the number must already belong to a WeChat account.
    /// The SMS code is checked server-side by `bindTelephone`, then `login/unionid` issues the token.
    public static func loginWithPhone(telephone: String, code: String) async throws {
        let data = try await request(.userInfoByPhone(telephone: telephone))
        let user = objectPayload(try jsonObject(data))
        let unionid = string(user, "unionid")
        guard !unionid.isEmpty, unionid != "null" else { throw PhoneLoginError.notRegistered }
        try ensureSuccess(await request(.bindTelephone(telephone: telephone, code: code, unionid: unionid)))

        let body: [String: Any] = [
            "unionid": unionid,
            "openid": string(user, "openid"),
            "nickname": string(user, "nickname"),
            "sex": intValue(user, "sex"),
            "province": string(user, "province"),
            "city": string(user, "city"),
            "country": string(user, "country"),
            "headimgurl": string(user, "headimgurl"),
            "privilege": [String]()
        ]
        let loginData = try await request(.loginWithUnionid(parameters: body))
        let token = string(objectPayload(try jsonObject(loginData)), "token")
        guard !token.isEmpty else { throw NetworkError.apiError("登录失败，请稍后重试") }
        AuthManager.shared.unionid = unionid
        AuthManager.shared.token = token
    }

    public static func submitFeedback(content: String, contact: String, imageData: [Data]) async throws {
        var urls: [String] = []
        for (index, data) in imageData.enumerated() {
            urls.append(try await uploadFeedbackImage(data, filename: "feedback-\(index).jpg"))
        }
        let profile = (try? await profile()) ?? UserProfile()
        let device = await MainActor.run { (UIDevice.current.model, UIDevice.current.systemVersion) }
        try ensureSuccess(await request(.feedbackAdd(parameters: [
            "user_id": AuthManager.shared.unionid ?? "",
            "nickname": profile.nickname,
            "contact": contact,
            "content": content,
            "category": "其他",
            "pkg": Bundle.main.bundleIdentifier ?? "cn.org.htz.next",
            "version": AppInfo.version,
            "phone_model": device.0,
            "engineering_model": device.0,
            "os_version": "iOS \(device.1)",
            "device_id": AuthManager.shared.unionid ?? "",
            "image_urls": urls.joined(separator: ","),
            "video_url": ""
        ])))
    }

    // MARK: Stats

    /// `yyyy-MM` of the check-in account's creation, used as the first month to fetch.
    public static func checkInStartMonth(userId: String) async -> String? {
        guard let data = try? await request(.checkInUser(id: userId)),
              let json = try? jsonObject(data) else { return nil }
        let raw = string(objectPayload(json), "createDate")
        return raw.count >= 7 ? String(raw.prefix(7)) : nil
    }

    /// Raw `date` strings of check-ins in `month` (`yyyy-MM`).
    public static func checkInDates(userId: String, month: String) async -> [String] {
        guard let data = try? await request(.checkInMonth(userId: userId, monthDate: month + "-")),
              let json = try? JSONSerialization.jsonObject(with: data) else { return [] }
        let rows = (json as? [[String: Any]]) ?? arrayPayload(json as? [String: Any] ?? [:])
        return rows.compactMap { $0["date"] as? String }
    }

    public static func studyRecord(userId: String) async throws -> StudyRecord {
        async let durationData = request(.studyDuration(userId: userId))
        async let completedData = request(.studyCompleted(userId: userId))
        var durations: [String: Int] = [:]
        for row in arrayPayload(try jsonObject(try await durationData)) {
            let date = String(string(row, "date").prefix(10))
            guard !date.isEmpty else { continue }
            durations[date] = intValue(row, "play_duration_ms")
        }
        let completedJSON = try jsonObject(try await completedData)
        let completed: Int
        if let rows = completedJSON["data"] as? [Any] {
            completed = rows.count
        } else {
            completed = intValue(objectPayload(completedJSON), "count", "completed", "total")
        }
        return StudyRecord(durations: durations, completedLessons: completed)
    }

    public static func helpDocument() async throws -> String {
        var request = URLRequest(url: WebPage.help)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? false else {
            throw NetworkError.apiError("帮助文档加载失败")
        }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: Helpers

    private static func unionid(forTelephone telephone: String) async throws -> String? {
        let data = try await request(.userInfoByPhone(telephone: telephone))
        let unionid = string(objectPayload(try jsonObject(data)), "unionid")
        return unionid.isEmpty || unionid == "null" ? nil : unionid
    }

    private static func profile(from payload: [String: Any]) -> UserProfile {
        UserProfile(
            nickname: string(payload, "nickname", "name"),
            avatar: string(payload, "headimgurl", "avatar"),
            signature: string(payload, "sign", "signature"),
            mobile: string(payload, "mobile", "telephone"),
            unionid: string(payload, "unionid", "union_id"),
            sex: intValue(payload, "sex"),
            province: string(payload, "province"),
            city: string(payload, "city")
        )
    }

    private static func uploadFeedbackImage(_ data: Data, filename: String) async throws -> String {
        let body = try await request(.feedbackUpload(data: data, filename: filename))
        let url = string(objectPayload(try jsonObject(body)), "url")
        if url.isEmpty {
            throw NetworkError.apiError("图片上传失败")
        }
        return url
    }

    private static func request(_ target: HTZAPI) async throws -> Data {
        try await NetworkManager<HTZAPI>().requestData(target).eraseToAnyPublisher().async()
    }

    private static func ensureSuccess(_ data: Data) throws {
        guard let json = try? jsonObject(data), json["code"] != nil else { return }
        let code = intCode(json)
        guard code == 200 || code == 0 else {
            let message = (json["msg"] as? String) ?? (json["data"] as? String) ?? "请求失败"
            throw NetworkError.apiError(message)
        }
    }

    private static func jsonObject(_ data: Data) throws -> [String: Any] {
        (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    /// The personal server sometimes returns `data` as a JSON-encoded string.
    private static func objectPayload(_ json: [String: Any]) -> [String: Any] {
        if let object = json["data"] as? [String: Any] { return object }
        if let text = json["data"] as? String,
           let data = text.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return object
        }
        return json
    }

    private static func arrayPayload(_ json: [String: Any]) -> [[String: Any]] {
        if let rows = json["data"] as? [Any] {
            return rows.compactMap { $0 as? [String: Any] }
        }
        if let text = json["data"] as? String,
           let data = text.data(using: .utf8),
           let rows = try? JSONSerialization.jsonObject(with: data) as? [Any] {
            return rows.compactMap { $0 as? [String: Any] }
        }
        if let object = json["data"] as? [String: Any], let rows = object["list"] as? [Any] {
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

    private static func boolValue(_ row: [String: Any], _ keys: String...) -> Bool {
        for key in keys {
            if let value = row[key] as? Bool { return value }
            if let value = row[key] as? Int { return value != 0 }
            if let value = row[key] as? String { return value == "1" || value.lowercased() == "true" }
        }
        return false
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

public enum PhoneLoginError: Error, Equatable {
    case notRegistered
}

public enum AppInfo {
    public static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    public static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

private final class CoverCache: @unchecked Sendable {
    static let shared = CoverCache()
    private let lock = NSLock()
    private var cache: [String: (url: String, expireAt: Date)] = [:]

    func get(_ sutraId: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = cache[sutraId], entry.expireAt > Date() else { return nil }
        return entry.url
    }

    func set(_ url: String, for sutraId: String, expireSeconds: Int) {
        lock.lock()
        defer { lock.unlock() }
        cache[sutraId] = (url, Date().addingTimeInterval(TimeInterval(max(60, expireSeconds - 60))))
    }
}

/// Episode titles and album names for records whose server row omits them
/// (older history/favorite rows only carry `sutra_item_id`).
private actor ItemDirectory {
    struct Entry: Sendable {
        var title: String
        var sutraId: String
        var sutraName: String
        var cover: String
    }

    static let shared = ItemDirectory()
    private var entries: [String: Entry] = [:]
    private var loadedAlbums: Set<String> = []
    private var albums: [Album]?

    func entries(for keys: [(itemId: String, sutraId: String)]) async -> [String: Entry] {
        let wanted = keys.filter { !$0.itemId.isEmpty }
        if wanted.contains(where: { entries[$0.itemId] == nil }) {
            let albums = await allAlbums()
            var albumIds = Set(wanted.filter { entries[$0.itemId] == nil }.map(\.sutraId).filter { !$0.isEmpty })
            if wanted.contains(where: { entries[$0.itemId] == nil && $0.sutraId.isEmpty }) {
                albumIds.formUnion(albums.map(\.id))
            }
            await load(albumIds.subtracting(loadedAlbums), albums: albums)
        }
        return entries.filter { key, _ in wanted.contains { $0.itemId == key } }
    }

    private func allAlbums() async -> [Album] {
        if let albums { return albums }
        let loaded = (try? await LibraryAPI.loadAlbums()) ?? []
        if !loaded.isEmpty { albums = loaded }
        return loaded
    }

    private func load(_ albumIds: Set<String>, albums: [Album]) async {
        guard !albumIds.isEmpty else { return }
        let byId = Dictionary(albums.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let fetched = await withTaskGroup(of: (String, [SutraItem]?).self) { group in
            for id in albumIds {
                group.addTask { (id, try? await LibraryAPI.items(sutraId: id)) }
            }
            var results: [(String, [SutraItem]?)] = []
            for await result in group { results.append(result) }
            return results
        }
        for (albumId, items) in fetched {
            guard let items else { continue }
            loadedAlbums.insert(albumId)
            let album = byId[albumId]
            for item in items {
                entries[item.id] = Entry(
                    title: item.title ?? "",
                    sutraId: albumId,
                    sutraName: album?.name ?? "",
                    cover: album?.imageUrl ?? ""
                )
            }
        }
    }
}

private extension Album {
    func withImage(_ imageUrl: String?) -> Album {
        Album(
            id: id,
            name: name,
            imageUrl: imageUrl,
            description: description,
            isPaid: isPaid,
            price: price,
            isPurchased: isPurchased,
            paidUrl: paidUrl
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
