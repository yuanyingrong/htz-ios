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
        let items = response.data ?? []
        ItemsCache.shared.set(items, for: sutraId)
        return items
    }

    /// Cached chapter list for instant album open; `nil` when never fetched or expired.
    public static func cachedItems(sutraId: String) -> [SutraItem]? {
        ItemsCache.shared.get(sutraId)
    }

    /// Warms the items cache for albums the user is likely to open next (home / album tab).
    public static func prefetchItems(sutraIds: [String], limit: Int = 8) async {
        let targets = sutraIds.filter { !$0.isEmpty && ItemsCache.shared.get($0) == nil }.prefix(limit)
        await withTaskGroup(of: Void.self) { group in
            for id in targets {
                group.addTask {
                    _ = try? await items(sutraId: id)
                }
            }
        }
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

    /// Server history plus plays the server has not confirmed yet (e.g. made offline). Without a
    /// connection the last known list is shown.
    public static func histories() async throws -> [ListenHistoryItem] {
        let local = LocalHistory.shared
        // A slow or dead connection must not hold back plays that are already stored on the device.
        let fetched: Result<[ListenHistoryItem], Error>? = await withTaskGroup(of: Result<[ListenHistoryItem], Error>?.self) { group in
            group.addTask {
                do { return .success(try await serverHistories()) } catch { return .failure(error) }
            }
            group.addTask {
                try? await _Concurrency.Task.sleep(nanoseconds: 10_000_000_000)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        guard case let .success(rows)? = fetched else {
            let merged = local.merged(with: local.cachedRows())
            if merged.isEmpty {
                if case let .failure(error)? = fetched { throw error }
                throw URLError(.timedOut)
            }
            return merged
        }
        local.storeServerRows(rows)
        retryPendingHistory()
        return local.merged(with: rows)
    }

    /// The server returns history oldest-first, 200 rows per page, and every pause/switch adds a
    /// row, so the newest plays are on the last pages: walk them all (rows are sorted client-side).
    private static func serverHistories() async throws -> [ListenHistoryItem] {
        let pageSize = 200
        var records: [[String: Any]] = []
        var seen = Set<String>()
        for page in 0..<40 {
            let data = try await request(.listenHistories(pageIndex: page, pageSize: pageSize))
            let chunk = arrayPayload(try jsonObject(data))
            let fresh = chunk.filter { seen.insert(string($0, "id")).inserted || string($0, "id").isEmpty }
            if fresh.isEmpty { break }
            records.append(contentsOf: fresh)
            if chunk.count < pageSize { break }
        }
        let rows = records.map { row in
            let itemId = string(row, "sutra_item_id", "sutraItemId")
            let serverId = string(row, "id")
            return ListenHistoryItem(
                id: serverId.isEmpty ? itemId : serverId,
                sutraItemId: itemId,
                sutraId: string(row, "sutra_id", "sutraId"),
                title: string(row, "sutra_item_title", "title"),
                sutraName: string(row, "sutra_name", "sutraName"),
                cover: string(row, "sutra_cover", "cover"),
                lastPosition: intValue(row, "last_position", "lastPosition"),
                createdAt: epochSeconds(row, "created_at", "createdAt")
            )
        }.sortedNewestFirst()
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
        LocalHistory.shared.remove(id: id)
    }

    public static func deleteAllHistories() async throws {
        try ensureSuccess(await request(.deleteAllListenHistories))
        LocalHistory.shared.removeAll()
    }

    /// Lets the history list describe an episode that starts playing (title, album).
    public static func rememberForHistory(itemId: String, sutraId: String, title: String, sutraName: String) {
        LocalHistory.shared.remember(itemId: itemId, sutraId: sutraId, title: title, sutraName: sutraName)
    }

    /// Like Android: the play is recorded on the device and shown in the history lists at once,
    /// then uploaded; if the upload fails it stays pending and is retried on a later refresh.
    public static func reportHistory(itemId: String, position: Int) async {
        guard !itemId.isEmpty else { return }
        let stamp = LocalHistory.shared.record(itemId: itemId, position: position)
        if stamp != nil { NotificationCenter.default.post(name: .htzHistoryDidChange, object: nil) }
        await uploadHistory(itemId: itemId, position: position, stamp: stamp)
    }

    private static func uploadHistory(itemId: String, position: Int, stamp: Int?) async {
        let saved = (try? await request(.postListenHistory(itemId: itemId, position: position))) != nil
        guard saved else { return }
        if let stamp { LocalHistory.shared.markSynced(itemId: itemId, upTo: stamp) }
        NotificationCenter.default.post(name: .htzHistoryDidChange, object: nil)
    }

    /// Uploads plays that failed earlier (older than a few seconds, so in-flight ones are not doubled).
    private static func retryPendingHistory() {
        let stale = LocalHistory.shared.stalePending(olderThan: 15)
        guard !stale.isEmpty else { return }
        _Concurrency.Task {
            for entry in stale {
                await uploadHistory(itemId: entry.itemId, position: entry.position, stamp: entry.stamp)
            }
        }
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
        // The server may not have a record (yet): fall back to what WeChat gave us at login.
        let cached = WeChatProfileCache.load()
        if profile.nickname.isEmpty { profile.nickname = cached.nickname }
        if profile.avatar.isEmpty { profile.avatar = cached.avatar }
        return profile
    }

    /// Same as Android `WXEntryActivity`: first login creates the server record from WeChat's info;
    /// an existing record only has a stale WeChat avatar refreshed (custom avatars are left alone).
    public static func syncWeChatProfile(_ wx: WeChatLoginResponse?) async {
        guard let wx, let unionid = wx.unionid, !unionid.isEmpty else { return }
        WeChatProfileCache.save(nickname: wx.nickname ?? "", avatar: wx.headimgurl ?? "")

        let existing = (try? await request(.userInfo(unionid: unionid))).flatMap { data -> [String: Any]? in
            guard let json = try? jsonObject(data) else { return nil }
            let payload = objectPayload(json)
            return string(payload, "unionid", "union_id") == unionid ? payload : nil
        }

        guard var record = existing else {
            _ = try? await request(.addUserInfo(parameters: userInfoParameters(wx)))
            return
        }
        let serverAvatar = string(record, "headimgurl")
        let wxAvatar = wx.headimgurl ?? ""
        guard !wxAvatar.isEmpty, serverAvatar.isEmpty || serverAvatar.contains("qlogo.cn"), serverAvatar != wxAvatar else { return }
        record["headimgurl"] = wxAvatar
        record["sex"] = String(intValue(record, "sex"))
        record["note"] = (record["note"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "ios"
        _ = try? await request(.addUserInfo(parameters: record))
    }

    static func userInfoParameters(_ wx: WeChatLoginResponse) -> [String: Any] {
        [
            "unionid": wx.unionid ?? "",
            "openid": wx.openid ?? "",
            "nickname": wx.nickname ?? "",
            "headimgurl": wx.headimgurl ?? "",
            "sex": String(wx.sex ?? 0),
            "province": wx.province ?? "",
            "city": wx.city ?? "",
            "country": wx.country ?? "",
            "privilege": wx.privilege ?? [],
            "language": "",
            "group_id": "",
            "telephone": "",
            "pwd": "",
            "sign": "",
            "note": "ios"
        ]
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

    /// SMS codes go straight to Aliyun (same as Android); only the AK/SK comes from our server.
    public static func sendSms(telephone: String) async throws {
        try await AliyunSms.send(to: telephone, fetchKeys: fetchAliyunKeys)
    }

    public static func bindTelephone(telephone: String, code: String) async throws {
        let current = AuthManager.shared.unionid ?? ""
        try await AliyunSms.check(phone: telephone, code: code, fetchKeys: fetchAliyunKeys)
        if let bound = try await unionid(forTelephone: telephone), bound != current {
            throw NetworkError.apiError("该手机号已绑定其他账号")
        }
        // Best effort, like Android: write the number to the profile server and the main server.
        if var record = (try? await request(.userInfo(unionid: current))).flatMap({ try? jsonObject($0) }).map(objectPayload) {
            record["telephone"] = telephone
            if record["unionid"] == nil { record["unionid"] = current }
            _ = try? await request(.updateUserInfo(parameters: record))
        }
        _ = try? await request(.putUserMobile(mobile: telephone))
    }

    private static func fetchAliyunKeys() async throws -> (String, String) {
        let data = try await request(.secureKey(appName: "htz-oss"))
        let payload = objectPayload(try jsonObject(data))
        let id = string(payload, "accessKey")
        let secret = string(payload, "accessKeySecure")
        guard !id.isEmpty, !secret.isEmpty else { throw NetworkError.apiError("获取密钥失败，请稍后重试") }
        return (id, secret)
    }

    /// Phone login: the number must already belong to a WeChat account.
    /// The SMS code is checked with Aliyun, then `login/unionid` issues the token.
    public static func loginWithPhone(telephone: String, code: String) async throws {
        let data = try await request(.userInfoByPhone(telephone: telephone))
        let user = objectPayload(try jsonObject(data))
        let unionid = string(user, "unionid")
        guard !unionid.isEmpty, unionid != "null" else { throw PhoneLoginError.notRegistered }
        try await AliyunSms.check(phone: telephone, code: code, fetchKeys: fetchAliyunKeys)

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

    public static func submitFeedback(
        content: String,
        contact: String,
        category: String,
        imageURLs: [String],
        videoURL: String
    ) async throws {
        // Same wire format as Android: `image_urls` is a JSON-encoded array string.
        let imageField: String = {
            guard !imageURLs.isEmpty,
                  let data = try? JSONSerialization.data(withJSONObject: imageURLs, options: [.withoutEscapingSlashes]),
                  let text = String(data: data, encoding: .utf8) else { return "" }
            return text
        }()
        let profile = (try? await profile()) ?? UserProfile()
        let device = await MainActor.run { (UIDevice.current.model, UIDevice.current.systemVersion) }
        try ensureSuccess(await request(.feedbackAdd(parameters: [
            "user_id": AuthManager.shared.unionid ?? "",
            "nickname": profile.nickname,
            "contact": contact,
            "content": content,
            "category": category.isEmpty ? "其他" : category,
            "pkg": Bundle.main.bundleIdentifier ?? "cn.org.htz.next",
            "version": AppInfo.version,
            "phone_model": device.0,
            "engineering_model": device.0,
            "os_version": "iOS \(device.1)",
            "device_id": AuthManager.shared.unionid ?? "",
            "image_urls": imageField,
            "video_url": videoURL
        ])))
    }

    /// Uploads one attachment and returns the server-relative URL.
    public static func uploadFeedbackAttachment(_ attachment: FeedbackAttachment, filename: String) async throws -> String {
        let body = try await request(.feedbackUpload(attachment: attachment, filename: filename))
        let url = string(objectPayload(try jsonObject(body)), "url")
        if url.isEmpty {
            throw NetworkError.apiError("附件上传失败")
        }
        return url
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
        async let durationData = Result { try await request(.studyDuration(userId: userId)) }
        async let completedData = Result { try await request(.studyCompleted(userId: userId)) }
        let (durationResult, completedResult) = await (durationData, completedData)
        // The two endpoints are independent: one failing must not hide the other's data.
        var durations: [String: Int] = [:]
        var completed = 0
        var failures = 0
        do {
            for row in arrayPayload(try jsonObject(try durationResult.get())) {
                let date = String(string(row, "date").prefix(10))
                guard !date.isEmpty else { continue }
                durations[date] = intValue(row, "play_duration_ms")
            }
        } catch { failures += 1 }
        do {
            let completedJSON = try jsonObject(try completedResult.get())
            if let rows = completedJSON["data"] as? [Any] {
                completed = rows.count
            } else {
                completed = intValue(objectPayload(completedJSON), "count", "completed", "total")
            }
        } catch { failures += 1 }
        if failures == 2 { throw URLError(.cannotConnectToHost) }
        return StudyRecord(durations: durations, completedLessons: completed)
    }

    /// Uploads per-day play time (`yyyy-MM-dd` → ms). The server merges by (device, user, date) with MAX, so repeats are harmless.
    public static func reportStudyDuration(_ durations: [String: Int]) async -> Bool {
        let unionid = AuthManager.shared.unionid ?? ""
        guard !unionid.isEmpty, !durations.isEmpty else { return false }
        let device = await MainActor.run { (UIDevice.current.model, UIDevice.current.systemVersion, UIDevice.current.identifierForVendor?.uuidString ?? "") }
        let records: [[String: Any]] = durations.map { date, milliseconds in
            [
                "device_id": device.2,
                "user_id": unionid,
                "date": date,
                "open_count": 0,
                "duration_ms": milliseconds,
                "play_duration_ms": milliseconds,
                "version": AppInfo.version,
                "pkg": Bundle.main.bundleIdentifier ?? "cn.org.htz.next",
                "phone_model": device.0,
                "engineering_model": device.0,
                "os_version": "iOS \(device.1)",
                "network_type": "unknown",
                "source": "iOS"
            ]
        }
        guard let data = try? await request(.reportUsage(records: records)) else { return false }
        return (try? ensureSuccess(data)) != nil
    }

    public static func reportStudyCompleted(itemIds: [String]) async -> Bool {
        let unionid = AuthManager.shared.unionid ?? ""
        guard !unionid.isEmpty, !itemIds.isEmpty else { return false }
        guard let data = try? await request(.reportStudyCompleted(userId: unionid, itemIds: itemIds)) else { return false }
        return (try? ensureSuccess(data)) != nil
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

    /// Epoch seconds from a number/numeric string (seconds or milliseconds); 0 when absent.
    static func epochSeconds(_ row: [String: Any], _ keys: String...) -> Int {
        for key in keys {
            var raw: Double?
            if let value = row[key] as? Double { raw = value }
            else if let value = row[key] as? Int { raw = Double(value) }
            else if let value = row[key] as? String { raw = Double(value) }
            if let raw, raw > 0 { return Int(raw >= 100_000_000_000 ? raw / 1000 : raw) }
        }
        return 0
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


/// WeChat nickname/avatar from the last login, used until the server has a profile record.
enum WeChatProfileCache {
    private static let nicknameKey = "auth_wx_nickname"
    private static let avatarKey = "auth_wx_avatar"

    static func save(nickname: String, avatar: String) {
        UserDefaults.standard.set(nickname, forKey: nicknameKey)
        UserDefaults.standard.set(avatar, forKey: avatarKey)
    }

    static func load() -> (nickname: String, avatar: String) {
        (UserDefaults.standard.string(forKey: nicknameKey) ?? "", UserDefaults.standard.string(forKey: avatarKey) ?? "")
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: nicknameKey)
        UserDefaults.standard.removeObject(forKey: avatarKey)
    }
}


extension Array where Element == ListenHistoryItem {
    /// Newest first (Android orders by `created_at DESC`); entries without a time keep their server order.
    public func sortedNewestFirst() -> [ListenHistoryItem] {
        enumerated()
            .sorted { lhs, rhs in
                lhs.element.createdAt != rhs.element.createdAt
                    ? lhs.element.createdAt > rhs.element.createdAt
                    : lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}


public extension Notification.Name {
    /// Posted after a listen-history entry was written to the server, so history lists can refresh.
    static let htzHistoryDidChange = Notification.Name("htz.history.didChange")
}
