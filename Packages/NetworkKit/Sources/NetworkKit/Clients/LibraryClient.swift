import ComposableArchitecture
import Foundation

@DependencyClient
public struct LibraryClient: Sendable {
    public var albums: @Sendable () async throws -> [Album]
    public var recommendations: @Sendable () async throws -> [Recommendation]
    public var items: @Sendable (_ sutraId: String) async throws -> [SutraItem]
    public var cachedItems: @Sendable (_ sutraId: String) -> [SutraItem]? = { _ in nil }
    public var prefetchItems: @Sendable (_ sutraIds: [String]) async -> Void = { _ in }
    public var coverURL: @Sendable (_ sutraId: String) async -> String? = { _ in nil }
    public var purchase: @Sendable (_ sutraId: String) async throws -> AlbumPurchase
    public var fileURL: @Sendable (_ sutraId: String, _ itemId: String) async throws -> MediaFileURLs
    public var search: @Sendable (_ key: String, _ offset: Int, _ limit: Int) async throws -> [SearchHit]
    public var incrementPlayedCount: @Sendable (_ itemId: String) async -> Void

    public var favorites: @Sendable () async throws -> [FavoriteItem]
    public var addFavorite: @Sendable (_ itemId: String) async throws -> Void
    public var deleteFavorite: @Sendable (_ serverId: String) async throws -> Void
    public var deleteAllFavorites: @Sendable () async throws -> Void

    public var histories: @Sendable () async throws -> [ListenHistoryItem]
    public var deleteHistory: @Sendable (_ id: String) async throws -> Void
    public var deleteAllHistories: @Sendable () async throws -> Void
    public var reportHistory: @Sendable (_ itemId: String, _ position: Int) async -> Void

    public var notifications: @Sendable () async throws -> [NoticeItem]
    public var markNotificationsRead: @Sendable (_ ids: [String]) async -> Void

    public var profile: @Sendable () async throws -> UserProfile
    public var updateProfile: @Sendable (_ profile: UserProfile) async throws -> Void
    public var sendSms: @Sendable (_ telephone: String) async throws -> Void
    public var bindTelephone: @Sendable (_ telephone: String, _ code: String) async throws -> Void
    public var loginWithPhone: @Sendable (_ telephone: String, _ code: String) async throws -> Void
    public var submitFeedback: @Sendable (
        _ content: String,
        _ contact: String,
        _ category: String,
        _ imageURLs: [String],
        _ videoURL: String
    ) async throws -> Void
    public var uploadFeedbackAttachment: @Sendable (
        _ attachment: FeedbackAttachment,
        _ filename: String
    ) async throws -> String

    public var checkInStartMonth: @Sendable (_ userId: String) async -> String? = { _ in nil }
    public var checkInDates: @Sendable (_ userId: String, _ month: String) async -> [String] = { _, _ in [] }
    public var studyRecord: @Sendable (_ userId: String) async throws -> StudyRecord
    public var reportStudyDuration: @Sendable (_ durations: [String: Int]) async -> Bool = { _ in false }
    public var reportStudyCompleted: @Sendable (_ itemIds: [String]) async -> Bool = { _ in false }
    public var helpDocument: @Sendable () async throws -> String
}

extension LibraryClient: DependencyKey {
    public static let liveValue = LibraryClient(
        albums: { try await LibraryAPI.albumsWithCovers() },
        recommendations: { try await LibraryAPI.recommendations() },
        items: { try await LibraryAPI.items(sutraId: $0) },
        cachedItems: { LibraryAPI.cachedItems(sutraId: $0) },
        prefetchItems: { await LibraryAPI.prefetchItems(sutraIds: $0) },
        coverURL: { await LibraryAPI.coverURL(sutraId: $0) },
        purchase: { try await LibraryAPI.purchase(sutraId: $0) },
        fileURL: { try await LibraryAPI.fileURL(sutraId: $0, itemId: $1) },
        search: { try await LibraryAPI.search(key: $0, offset: $1, limit: $2) },
        incrementPlayedCount: { await LibraryAPI.incrementPlayedCount(itemId: $0) },
        favorites: { try await LibraryAPI.favorites() },
        addFavorite: { try await LibraryAPI.addFavorite(itemId: $0) },
        deleteFavorite: { try await LibraryAPI.deleteFavorite(serverId: $0) },
        deleteAllFavorites: { try await LibraryAPI.deleteAllFavorites() },
        histories: { try await LibraryAPI.histories() },
        deleteHistory: { try await LibraryAPI.deleteHistory(id: $0) },
        deleteAllHistories: { try await LibraryAPI.deleteAllHistories() },
        reportHistory: { await LibraryAPI.reportHistory(itemId: $0, position: $1) },
        notifications: { try await LibraryAPI.notifications() },
        markNotificationsRead: { await LibraryAPI.markNotificationsRead(ids: $0) },
        profile: { try await LibraryAPI.profile() },
        updateProfile: { try await LibraryAPI.updateProfile($0) },
        sendSms: { try await LibraryAPI.sendSms(telephone: $0) },
        bindTelephone: { try await LibraryAPI.bindTelephone(telephone: $0, code: $1) },
        loginWithPhone: { try await LibraryAPI.loginWithPhone(telephone: $0, code: $1) },
        submitFeedback: {
            try await LibraryAPI.submitFeedback(content: $0, contact: $1, category: $2, imageURLs: $3, videoURL: $4)
        },
        uploadFeedbackAttachment: { try await LibraryAPI.uploadFeedbackAttachment($0, filename: $1) },
        checkInStartMonth: { await LibraryAPI.checkInStartMonth(userId: $0) },
        checkInDates: { await LibraryAPI.checkInDates(userId: $0, month: $1) },
        studyRecord: { try await LibraryAPI.studyRecord(userId: $0) },
        reportStudyDuration: { await LibraryAPI.reportStudyDuration($0) },
        reportStudyCompleted: { await LibraryAPI.reportStudyCompleted(itemIds: $0) },
        helpDocument: { try await LibraryAPI.helpDocument() }
    )

    public static let testValue = LibraryClient()
}

public extension DependencyValues {
    var library: LibraryClient {
        get { self[LibraryClient.self] }
        set { self[LibraryClient.self] = newValue }
    }
}
