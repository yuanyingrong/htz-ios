import AVFoundation
import ComposableArchitecture
import DesignSystem
import NetworkKit
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

public enum FeedbackCategory: String, CaseIterable, Equatable, Hashable, Sendable {
    case bug = "功能异常"
    case suggestion = "功能建议"
    case content = "内容相关"
    case other = "其他"
}

/// A picked attachment plus a JPEG thumbnail for the grid.
public struct FeedbackMedia: Equatable, Identifiable, Sendable {
    public let id = UUID()
    public let attachment: FeedbackAttachment
    public let thumbnail: Data

    public var isVideo: Bool {
        if case .video = attachment { return true }
        return false
    }
}

@Reducer
public struct FeedbackFeature {
    public static let maxContentLength = 1000
    public static let minContentLength = 5
    public static let maxImageCount = 9
    public static let maxVideoCount = 1
    public static let maxImageBytes = 10 * 1024 * 1024
    public static let maxVideoBytes = 50 * 1024 * 1024

    @ObservableState
    public struct State: Equatable {
        public var category: FeedbackCategory = .bug
        public var content = ""
        public var contact = ""
        public var media: [FeedbackMedia] = []
        public var isSubmitting = false
        /// 1-based index of the attachment currently uploading.
        public var uploadingIndex: Int?
        public var toast: String?

        public init() {}

        public var imageCount: Int { media.filter { !$0.isVideo }.count }
        public var videoCount: Int { media.filter(\.isVideo).count }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case categoryTapped(FeedbackCategory)
        case mediaPicked([FeedbackMedia])
        case removeMedia(Int)
        case showToast(String)
        case submitTapped
        case uploading(Int?)
        case submitted
        case failed(String)
    }

    @Dependency(\.library) var library
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.content):
                if state.content.count > Self.maxContentLength {
                    state.content = String(state.content.prefix(Self.maxContentLength))
                }
                return .none

            case .binding:
                return .none

            case let .categoryTapped(category):
                state.category = category
                return .none

            case let .mediaPicked(picked):
                for item in picked {
                    if item.isVideo {
                        guard state.videoCount < Self.maxVideoCount else { continue }
                    } else {
                        guard state.imageCount < Self.maxImageCount else { continue }
                    }
                    state.media.append(item)
                }
                return .none

            case let .removeMedia(index):
                guard state.media.indices.contains(index) else { return .none }
                if case let .video(url) = state.media[index].attachment {
                    try? FileManager.default.removeItem(at: url)
                }
                state.media.remove(at: index)
                return .none

            case let .showToast(text):
                state.toast = text
                return .none

            case .submitTapped:
                guard !state.isSubmitting else { return .none }
                let content = state.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if content.isEmpty {
                    state.toast = "请填写您的反馈内容"
                    return .none
                }
                if content.count < Self.minContentLength {
                    state.toast = "反馈内容太短，请至少输入 5 个字符"
                    return .none
                }
                state.isSubmitting = true
                let contact = state.contact.trimmingCharacters(in: .whitespacesAndNewlines)
                let category = state.category.rawValue
                let media = state.media
                return .run { send in
                    var imageURLs: [String] = []
                    var videoURL = ""
                    do {
                        for (index, item) in media.enumerated() {
                            await send(.uploading(index + 1))
                            let name: String
                            if case let .video(url) = item.attachment {
                                name = "feedback-video.\(url.pathExtension.isEmpty ? "mp4" : url.pathExtension)"
                            } else {
                                name = "feedback-\(index).jpg"
                            }
                            let url = try await library.uploadFeedbackAttachment(item.attachment, name)
                            if item.isVideo { videoURL = url } else { imageURLs.append(url) }
                        }
                    } catch {
                        await send(.failed("附件上传失败，请稍后重试"))
                        return
                    }
                    await send(.uploading(nil))
                    do {
                        try await library.submitFeedback(content, contact, category, imageURLs, videoURL)
                        await send(.submitted)
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        await dismiss()
                    } catch {
                        await send(.failed("提交失败，请检查网络后重试"))
                    }
                }

            case let .uploading(index):
                state.uploadingIndex = index
                return .none

            case .submitted:
                state.isSubmitting = false
                state.toast = "反馈提交成功，感谢您的支持！"
                return .none

            case let .failed(message):
                state.isSubmitting = false
                state.uploadingIndex = nil
                state.toast = message
                return .none
            }
        }
    }
}

// MARK: - View

private struct PickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mp4" : received.file.pathExtension
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("feedback-\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: dest)
            return PickedMovie(url: dest)
        }
    }
}

struct FeedbackView: View {
    @Perception.Bindable var store: StoreOf<FeedbackFeature>
    @State private var showPickDialog = false
    @State private var showImagePicker = false
    @State private var showVideoPicker = false
    @State private var imagePicks: [PhotosPickerItem] = []
    @State private var videoPicks: [PhotosPickerItem] = []

    private let accent = HTZColor.orange
    private let selectedFill = Color(hex: 0xFFF3E0)
    private let fieldStroke = Color(hex: 0xDDDDDD)

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionTitle("反馈类型")
                        categoryRow.padding(.top, 10)

                        sectionTitle("您的意见").padding(.top, 20)
                        contentEditor.padding(.top, 10)
                        Text(verbatim: "\(store.content.count)/\(FeedbackFeature.maxContentLength)")
                            .font(.system(size: 12))
                            .foregroundColor(HTZColor.hint)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 6)

                        HStack {
                            sectionTitle("附件")
                            Spacer()
                            Text("最多 \(FeedbackFeature.maxImageCount) 张图片 + \(FeedbackFeature.maxVideoCount) 段视频")
                                .font(.system(size: 12))
                                .foregroundColor(HTZColor.hint)
                        }
                        .padding(.top, 20)
                        mediaGrid.padding(.top, 8)

                        sectionTitle("联系方式（选填）").padding(.top, 14)
                        TextField("手机号 / 微信号 / 邮箱，方便我们与您联系", text: $store.contact)
                            .font(.system(size: 14))
                            .foregroundColor(HTZColor.title)
                            .padding(12)
                            .background(Color.white)
                            .padding(.top, 10)

                        Text("您的每一条反馈我们都会认真对待")
                            .font(.system(size: 12))
                            .foregroundColor(HTZColor.hint)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .scrollDismissesKeyboard(.interactively)

                Button {
                    store.send(.submitTapped)
                } label: {
                    Text(submitTitle)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(HTZColor.cta, in: RoundedRectangle(cornerRadius: 8))
                        .opacity(store.isSubmitting ? 0.6 : 1)
                }
                .buttonStyle(.plain)
                .disabled(store.isSubmitting)
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .htzPage("意见反馈")
            .htzToast($store.toast)
            .photosPicker(
                isPresented: $showImagePicker,
                selection: $imagePicks,
                maxSelectionCount: max(1, FeedbackFeature.maxImageCount - store.imageCount),
                matching: .images
            )
            .photosPicker(
                isPresented: $showVideoPicker,
                selection: $videoPicks,
                maxSelectionCount: 1,
                matching: .videos
            )
            .onChange(of: imagePicks) { items in
                guard !items.isEmpty else { return }
                imagePicks = []
                Task { await loadImages(items) }
            }
            .onChange(of: videoPicks) { items in
                guard let item = items.first else { return }
                videoPicks = []
                Task { await loadVideo(item) }
            }
        }
    }

    private var submitTitle: String {
        guard store.isSubmitting else { return "提交" }
        if let index = store.uploadingIndex {
            return "附件上传中 \(index)/\(store.media.count)…"
        }
        return "提交中…"
    }

    // MARK: Sections

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(HTZColor.title)
    }

    private var categoryRow: some View {
        HStack(spacing: 8) {
            ForEach(FeedbackCategory.allCases, id: \.self) { category in
                let selected = store.category == category
                Button {
                    store.send(.categoryTapped(category))
                } label: {
                    Text(category.rawValue)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .minimumScaleFactor(0.77)
                        .foregroundColor(selected ? accent : HTZColor.title)
                        .padding(.horizontal, 2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selected ? selectedFill : Color.white, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(selected ? accent : fieldStroke, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var contentEditor: some View {
        TextEditor(text: $store.content)
            .font(.system(size: 14))
            .foregroundColor(HTZColor.title)
            .scrollContentBackground(.hidden)
            .frame(height: 180)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color.white)
            .overlay(alignment: .topLeading) {
                if store.content.isEmpty {
                    Text("请详细描述您遇到的问题或建议（必填）")
                        .font(.system(size: 14))
                        .foregroundColor(HTZColor.hint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
    }

    private var mediaGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(Array(store.media.enumerated()), id: \.element.id) { index, item in
                mediaCell(item, index: index)
            }
            if store.media.count < FeedbackFeature.maxImageCount + FeedbackFeature.maxVideoCount {
                Button {
                    showPickDialog = true
                } label: {
                    Color(hex: 0xF0F0F0)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 30, weight: .light))
                                .foregroundColor(HTZColor.secondary.opacity(0.6))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 2]))
                                .foregroundColor(fieldStroke)
                        )
                }
                .buttonStyle(.plain)
                .confirmationDialog("", isPresented: $showPickDialog, titleVisibility: .hidden) {
                    Button("选择图片") { pickImages() }
                    Button("选择视频") { pickVideo() }
                    Button("取消", role: .cancel) {}
                }
            }
        }
    }

    private func mediaCell(_ item: FeedbackMedia, index: Int) -> some View {
        Color(hex: 0xEEEEEE)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image = UIImage(data: item.thumbnail) {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .clipped()
            .overlay {
                if item.isVideo {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white, .black.opacity(0.45))
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    store.send(.removeMedia(index))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white, .black.opacity(0.55))
                        .padding(2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
    }

    // MARK: Picking

    private func pickImages() {
        guard store.imageCount < FeedbackFeature.maxImageCount else {
            store.send(.showToast("最多只能添加 9 张图片"))
            return
        }
        showImagePicker = true
    }

    private func pickVideo() {
        guard store.videoCount < FeedbackFeature.maxVideoCount else {
            store.send(.showToast("仅支持 1 段视频，请先删除已选视频"))
            return
        }
        showVideoPicker = true
    }

    private func loadImages(_ items: [PhotosPickerItem]) async {
        var loaded: [FeedbackMedia] = []
        var tooLarge = false
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            if data.count > FeedbackFeature.maxImageBytes {
                tooLarge = true
                continue
            }
            guard let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.7) else { continue }
            loaded.append(FeedbackMedia(attachment: .image(jpeg), thumbnail: jpeg))
        }
        if !loaded.isEmpty { store.send(.mediaPicked(loaded)) }
        if tooLarge { store.send(.showToast("图片不能超过 10MB")) }
    }

    private func loadVideo(_ item: PhotosPickerItem) async {
        guard let movie = try? await item.loadTransferable(type: PickedMovie.self) else { return }
        let size = (try? FileManager.default.attributesOfItem(atPath: movie.url.path)[.size] as? Int) ?? 0
        if size > FeedbackFeature.maxVideoBytes {
            try? FileManager.default.removeItem(at: movie.url)
            store.send(.showToast("视频不能超过 50MB"))
            return
        }
        let thumbnail = await Self.thumbnail(for: movie.url)
        store.send(.mediaPicked([FeedbackMedia(attachment: .video(movie.url), thumbnail: thumbnail)]))
    }

    private static func thumbnail(for url: URL) async -> Data {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)
        if let cgImage = try? await generator.image(at: .zero).image {
            return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.7) ?? Data()
        }
        return Data()
    }
}
