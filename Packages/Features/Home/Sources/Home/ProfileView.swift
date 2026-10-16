import Foundation
import SwiftUI
import PhotosUI
import WebKit
import ComposableArchitecture
import DesignSystem
import NetworkKit
import PlayerFeature

private enum LegalURL {
    static let agreement = URL(string: "http://android.neixinchan.com/resources/agreement.html")!
    static let privacy = URL(string: "http://android.neixinchan.com/resources/privacy.html")!
    static let tenYears = URL(string: "http://app.htzchina.org/tenyears/#/tenyearsHome")!
}

@Reducer
public struct ProfileFeature {
    @ObservableState
    public struct State: Equatable {
        public var profile = UserProfile()
        public var favorites: [FavoriteItem] = []
        public var histories: [ListenHistoryItem] = []
        public var notices: [NoticeItem] = []
        public var nickname: String = ""
        public var signature: String = ""
        public var phone: String = ""
        public var smsCode: String = ""
        public var feedback: String = ""
        public var contact: String = ""
        public var message: String?
        public var isLoading = false
        public init() {}
    }

    public enum Action: Equatable {
        case onAppear
        case profileLoaded(UserProfile)
        case favoritesLoaded([FavoriteItem])
        case historiesLoaded([ListenHistoryItem])
        case noticesLoaded([NoticeItem])
        case deleteFavorite(FavoriteItem)
        case favoriteRemoved(String)
        case deleteHistory(ListenHistoryItem)
        case historyRemoved(String)
        case deleteAllHistories
        case openNotice(NoticeItem)
        case nicknameChanged(String)
        case signatureChanged(String)
        case saveProfile
        case phoneChanged(String)
        case codeChanged(String)
        case sendSms
        case bindPhone
        case feedbackChanged(String)
        case contactChanged(String)
        case submitFeedback([Data])
        case failed(String)
        case message(String)
        case clearMessage
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .merge(
                    .run { send in
                        if let profile = try? await LibraryAPI.profile() {
                            await send(.profileLoaded(profile))
                        }
                    },
                    .run { send in
                        await send(.favoritesLoaded((try? await LibraryAPI.favorites()) ?? []))
                    },
                    .run { send in
                        await send(.historiesLoaded((try? await LibraryAPI.histories()) ?? []))
                    },
                    .run { send in
                        await send(.noticesLoaded((try? await LibraryAPI.notifications()) ?? []))
                    }
                )
            case let .profileLoaded(profile):
                state.isLoading = false
                state.profile = profile
                state.nickname = profile.nickname
                state.signature = profile.signature
                state.phone = profile.mobile
                return .none
            case let .favoritesLoaded(items):
                state.favorites = items
                state.isLoading = false
                return .none
            case let .historiesLoaded(items):
                state.histories = items
                return .none
            case let .noticesLoaded(items):
                state.notices = items
                return .none
            case let .deleteFavorite(item):
                return .run { send in
                    do {
                        try await LibraryAPI.deleteFavorite(serverId: item.serverId)
                        await send(.favoriteRemoved(item.id))
                    } catch {
                        await send(.failed("删除收藏失败"))
                    }
                }
            case let .favoriteRemoved(id):
                state.favorites.removeAll { $0.id == id }
                return .none
            case let .deleteHistory(item):
                return .run { send in
                    do {
                        try await LibraryAPI.deleteHistory(id: item.id)
                        await send(.historyRemoved(item.id))
                    } catch {
                        await send(.failed("删除记录失败"))
                    }
                }
            case let .historyRemoved(id):
                state.histories.removeAll { $0.id == id }
                return .none
            case .deleteAllHistories:
                return .run { send in
                    do {
                        try await LibraryAPI.deleteAllHistories()
                        await send(.historiesLoaded([]))
                    } catch {
                        await send(.failed("清空记录失败"))
                    }
                }
            case let .openNotice(item):
                if let index = state.notices.firstIndex(where: { $0.id == item.id }) {
                    state.notices[index].isRead = true
                }
                return .run { _ in await LibraryAPI.markNotificationRead(id: item.id) }
            case let .nicknameChanged(value):
                state.nickname = value
                return .none
            case let .signatureChanged(value):
                state.signature = value
                return .none
            case .saveProfile:
                let nickname = state.nickname
                let signature = state.signature
                return .run { send in
                    do {
                        try await LibraryAPI.updateProfile(nickname: nickname, signature: signature)
                        var profile = (try? await LibraryAPI.profile()) ?? UserProfile()
                        profile.nickname = nickname
                        profile.signature = signature
                        await send(.profileLoaded(profile))
                        await send(.message("资料已保存"))
                    } catch {
                        await send(.failed("保存失败"))
                    }
                }
            case let .phoneChanged(value):
                state.phone = value
                return .none
            case let .codeChanged(value):
                state.smsCode = value
                return .none
            case .sendSms:
                let phone = state.phone
                return .run { send in
                    do {
                        try await LibraryAPI.sendSms(telephone: phone)
                        await send(.message("验证码已发送"))
                    } catch {
                        await send(.failed("验证码发送失败"))
                    }
                }
            case .bindPhone:
                let phone = state.phone
                let code = state.smsCode
                return .run { send in
                    do {
                        try await LibraryAPI.bindTelephone(telephone: phone, code: code)
                        await send(.message("手机号已绑定"))
                    } catch {
                        await send(.failed("绑定失败"))
                    }
                }
            case let .feedbackChanged(value):
                state.feedback = value
                return .none
            case let .contactChanged(value):
                state.contact = value
                return .none
            case let .submitFeedback(images):
                let content = state.feedback
                let contact = state.contact
                guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.message = "请填写反馈内容"
                    return .none
                }
                return .run { send in
                    do {
                        try await LibraryAPI.submitFeedback(content: content, contact: contact, imageData: images)
                        await send(.message("反馈已提交"))
                    } catch {
                        await send(.failed("反馈提交失败"))
                    }
                }
            case let .failed(message), let .message(message):
                state.message = message
                state.isLoading = false
                return .none
            case .clearMessage:
                state.message = nil
                return .none
            }
        }
    }
}

public struct ProfileView: View {
    @ComposableArchitecture.Bindable var store: StoreOf<ProfileFeature>
    let onLogout: () -> Void

    public init(store: StoreOf<ProfileFeature>, onLogout: @escaping () -> Void) {
        self.store = store
        self.onLogout = onLogout
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                List {
                    Section {
                        HStack(spacing: HTZSpacing.md) {
                            profileAvatar(store.profile.avatar)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.profile.nickname.isEmpty ? "未设置昵称" : store.profile.nickname)
                                    .font(.htzHeadline)
                                if !store.profile.signature.isEmpty {
                                    Text(store.profile.signature)
                                        .font(.htzCaption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        NavigationLink("个人资料") { ProfileEditView(store: store) }
                        NavigationLink("绑定手机") { BindPhoneView(store: store) }
                    }
                    Section {
                        NavigationLink("收藏") { FavoriteListView(store: store) }
                        NavigationLink("播放历史") { HistoryListView(store: store) }
                        NavigationLink("下载") { DownloadListView() }
                        NavigationLink("通知") { NoticeListView(store: store) }
                    }
                    Section {
                        NavigationLink("十年持志") { TenYearCheckInView() }
                        NavigationLink("意见反馈") { FeedbackFormView(store: store) }
                        NavigationLink("设置") { SettingsView() }
                    }
                    Section {
                        Button("退出登录", role: .destructive, action: onLogout)
                    }
                }
                .navigationTitle("我的")
                .onAppear { store.send(.onAppear) }
            }
            .alert("提示", isPresented: Binding(
                get: { store.message != nil },
                set: { if !$0 { store.send(.clearMessage) } }
            )) {
                Button("好的", role: .cancel) { store.send(.clearMessage) }
            } message: {
                Text(store.message ?? "")
            }
        }
    }
}

private struct ProfileEditView: View {
    let store: StoreOf<ProfileFeature>
    var body: some View {
        WithPerceptionTracking {
            Form {
                profileAvatar(store.profile.avatar)
                    .frame(maxWidth: .infinity)
                TextField("昵称", text: Binding(get: { store.nickname }, set: { store.send(.nicknameChanged($0)) }))
                TextField("签名", text: Binding(get: { store.signature }, set: { store.send(.signatureChanged($0)) }))
                Button("保存") { store.send(.saveProfile) }
            }
            .navigationTitle("个人资料")
        }
    }
}

private struct BindPhoneView: View {
    let store: StoreOf<ProfileFeature>
    var body: some View {
        WithPerceptionTracking {
            Form {
                TextField("手机号", text: Binding(get: { store.phone }, set: { store.send(.phoneChanged($0)) }))
                    .keyboardType(.phonePad)
                TextField("验证码", text: Binding(get: { store.smsCode }, set: { store.send(.codeChanged($0)) }))
                Button("发送验证码") { store.send(.sendSms) }
                Button("绑定") { store.send(.bindPhone) }
            }
            .navigationTitle("绑定手机")
        }
    }
}

private struct FavoriteListView: View {
    let store: StoreOf<ProfileFeature>
    var body: some View {
        WithPerceptionTracking {
            List(store.favorites) { item in
                VStack(alignment: .leading) {
                    Text(item.title).font(.htzHeadline)
                    Text(item.sutraName).font(.htzCaption).foregroundColor(.secondary)
                }
                .swipeActions {
                    Button("删除", role: .destructive) { store.send(.deleteFavorite(item)) }
                }
            }
            .navigationTitle("收藏")
            .overlay { if store.favorites.isEmpty { Text("还没有收藏") } }
        }
    }
}

private struct HistoryListView: View {
    let store: StoreOf<ProfileFeature>
    @State private var confirmClear = false

    var body: some View {
        WithPerceptionTracking {
            List(store.histories) { item in
                VStack(alignment: .leading) {
                    Text(item.title.isEmpty ? "未命名章节" : item.title).font(.htzHeadline)
                    Text("听到 \(item.lastPosition) 秒").font(.htzCaption).foregroundColor(.secondary)
                }
                .swipeActions {
                    Button("删除", role: .destructive) { store.send(.deleteHistory(item)) }
                }
            }
            .navigationTitle("播放历史")
            .toolbar {
                Button("清空") { confirmClear = true }
            }
            .confirmationDialog("清空播放历史？", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清空", role: .destructive) { store.send(.deleteAllHistories) }
                Button("取消", role: .cancel) {}
            }
            .overlay { if store.histories.isEmpty { Text("还没有播放记录") } }
        }
    }
}

private func profileAvatar(_ urlString: String) -> some View {
    AsyncImage(url: URL(string: urlString)) { image in
        image.resizable().scaledToFill()
    } placeholder: {
        Image(systemName: "person.crop.circle")
            .resizable()
            .scaledToFit()
            .padding(8)
            .foregroundStyle(.secondary)
    }
    .frame(width: 56, height: 56)
    .background(Color.secondary.opacity(0.12))
    .clipShape(Circle())
}

private struct NoticeListView: View {
    let store: StoreOf<ProfileFeature>
    var body: some View {
        WithPerceptionTracking {
            List(store.notices) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.htzHeadline)
                    Text(item.message).font(.htzCaption).foregroundColor(.secondary)
                    if !item.isRead { Text("未读").font(.htzCaption).foregroundColor(.htzAccent) }
                }
                .onTapGesture { store.send(.openNotice(item)) }
            }
            .navigationTitle("通知")
            .overlay { if store.notices.isEmpty { Text("暂无通知") } }
        }
    }
}

private struct DownloadListView: View {
    @State private var records: [DownloadRecord] = DownloadCenter.shared.recordsSnapshot()
    var body: some View {
        List(records) { record in
            VStack(alignment: .leading) {
                Text(record.title).font(.htzHeadline)
                Text(label(record.state)).font(.htzCaption).foregroundColor(.secondary)
            }
        }
        .navigationTitle("下载")
        .task {
            for await snapshot in DownloadCenter.shared.updates() {
                records = snapshot
            }
        }
        .overlay { if records.isEmpty { Text("还没有下载") } }
    }

    private func label(_ state: DownloadRecord.State) -> String {
        switch state {
        case .queued: return "等待中"
        case let .downloading(progress): return "下载中 \(Int(progress * 100))%"
        case .finished: return "已完成"
        case let .failed(message): return message
        }
    }
}

private struct SettingsView: View {
    var body: some View {
        List {
            Section("关于") {
                Text("黄庭书院")
                Text("iOS 1.0")
            }
            Section {
                Link("用户协议", destination: LegalURL.agreement)
                Link("隐私政策", destination: LegalURL.privacy)
            }
        }
        .navigationTitle("设置")
    }
}

private struct FeedbackFormView: View {
    let store: StoreOf<ProfileFeature>
    @State private var photos: [PhotosPickerItem] = []
    @State private var images: [Data] = []

    var body: some View {
        WithPerceptionTracking {
            Form {
                TextField("联系方式", text: Binding(get: { store.contact }, set: { store.send(.contactChanged($0)) }))
                TextField("反馈内容", text: Binding(get: { store.feedback }, set: { store.send(.feedbackChanged($0)) }), axis: .vertical)
                    .lineLimit(4...8)
                PhotosPicker(selection: $photos, maxSelectionCount: 3, matching: .images) {
                    Label("添加图片 \(images.count)", systemImage: "photo")
                }
                Button("提交") { store.send(.submitFeedback(images)) }
            }
            .navigationTitle("意见反馈")
            .onChange(of: photos) { items in
                Task {
                    var loaded: [Data] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            loaded.append(data)
                        }
                    }
                    images = loaded
                }
            }
        }
    }
}

private struct TenYearCheckInView: View {
    var body: some View {
        TenYearWebView(url: LegalURL.tenYears, unionid: AuthManager.shared.unionid ?? "")
            .navigationTitle("十年持志")
            .ignoresSafeArea(edges: .bottom)
    }
}

private struct TenYearWebView: UIViewRepresentable {
    let url: URL
    let unionid: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(unionid: unionid) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let unionid: String
        init(unionid: String) { self.unionid = unionid }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let script = "localStorage.setItem('unionid', JSON.stringify('\(unionid)'));"
            webView.evaluateJavaScript(script)
        }
    }
}
