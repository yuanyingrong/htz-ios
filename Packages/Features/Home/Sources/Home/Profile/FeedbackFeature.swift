import ComposableArchitecture
import DesignSystem
import NetworkKit
import PhotosUI
import SwiftUI

@Reducer
public struct FeedbackFeature {
    @ObservableState
    public struct State: Equatable {
        public var content = ""
        public var contact = ""
        public var images: [Data] = []
        public var isSubmitting = false
        public var toast: String?

        public init() {}

        public var canSubmit: Bool {
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case imagesPicked([Data])
        case removeImage(Int)
        case submitTapped
        case submitted
        case failed
    }

    @Dependency(\.library) var library
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .imagesPicked(images):
                state.images = Array(images.prefix(3))
                return .none

            case let .removeImage(index):
                guard state.images.indices.contains(index) else { return .none }
                state.images.remove(at: index)
                return .none

            case .submitTapped:
                guard state.canSubmit else {
                    state.toast = "请填写反馈内容"
                    return .none
                }
                state.isSubmitting = true
                let content = state.content
                let contact = state.contact
                let images = state.images
                return .run { send in
                    do {
                        try await library.submitFeedback(content, contact, images)
                        await send(.submitted)
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        await dismiss()
                    } catch {
                        await send(.failed)
                    }
                }

            case .submitted:
                state.isSubmitting = false
                state.toast = "感谢您的反馈"
                return .none

            case .failed:
                state.isSubmitting = false
                state.toast = "反馈提交失败"
                return .none
            }
        }
    }
}

struct FeedbackView: View {
    @Perception.Bindable var store: StoreOf<FeedbackFeature>
    @State private var picks: [PhotosPickerItem] = []

    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("请描述您遇到的问题或建议", text: $store.content, axis: .vertical)
                        .lineLimit(6...10)
                        .padding(14)
                        .background(HTZColor.card, in: RoundedRectangle(cornerRadius: 12))

                    HStack(spacing: 10) {
                        ForEach(Array(store.images.enumerated()), id: \.offset) { index, data in
                            if let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            store.send(.removeImage(index))
                                            if picks.indices.contains(index) { picks.remove(at: index) }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white, .black.opacity(0.5))
                                        }
                                        .padding(2)
                                    }
                            }
                        }
                        if store.images.count < 3 {
                            PhotosPicker(selection: $picks, maxSelectionCount: 3, matching: .images) {
                                Image(systemName: "plus")
                                    .font(.system(size: 22))
                                    .foregroundColor(HTZColor.hint)
                                    .frame(width: 72, height: 72)
                                    .background(HTZColor.card, in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    Text("最多上传3张图片")
                        .font(.system(size: 12))
                        .foregroundColor(HTZColor.hint)

                    TextField("联系方式（选填）", text: $store.contact)
                        .padding(14)
                        .background(HTZColor.card, in: RoundedRectangle(cornerRadius: 12))

                    Button {
                        store.send(.submitTapped)
                    } label: {
                        if store.isSubmitting { ProgressView().tint(.white) } else { Text("提交") }
                    }
                    .buttonStyle(HTZPrimaryButtonStyle())
                    .disabled(!store.canSubmit)
                    .opacity(store.canSubmit ? 1 : 0.5)
                    .padding(.top, 12)
                }
                .font(.system(size: 15))
                .padding(16)
            }
            .htzPage("意见反馈")
            .htzToast($store.toast)
            .onChange(of: picks) { items in
                Task {
                    var loaded: [Data] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data),
                           let jpeg = image.jpegData(compressionQuality: 0.7) {
                            loaded.append(jpeg)
                        }
                    }
                    store.send(.imagesPicked(loaded))
                }
            }
        }
    }
}
