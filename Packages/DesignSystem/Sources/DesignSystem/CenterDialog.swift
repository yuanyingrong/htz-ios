import SwiftUI
import UIKit

// Centered modal dialog (Android `Dialog` with `transparent_dialog` style): a dimmed backdrop over the
// whole screen — nav bar and tab bar included — and a card at 85% of the screen width. It is presented
// as an `.overFullScreen` view controller with a cross-dissolve, because SwiftUI's own covers slide up.

private struct CenterDialogBackdrop<Content: View>: View {
    let onTapOutside: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onTapOutside)
                content()
                    .frame(width: proxy.size.width * 0.85)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct CenterDialogPresenter<Dialog: View>: UIViewRepresentable {
    @Binding var isPresented: Bool
    let dialog: () -> Dialog

    final class Coordinator {
        var host: UIHostingController<AnyView>?
        var wantsPresented = false
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let coordinator = context.coordinator
        coordinator.wantsPresented = isPresented
        let root = AnyView(CenterDialogBackdrop(onTapOutside: { isPresented = false }, content: dialog))

        if isPresented {
            if let host = coordinator.host {
                host.rootView = root
                return
            }
            DispatchQueue.main.async {
                guard coordinator.wantsPresented, coordinator.host == nil,
                      let top = Self.topController(from: uiView.window) else { return }
                let host = UIHostingController(rootView: root)
                host.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
                host.modalPresentationStyle = .overFullScreen
                host.modalTransitionStyle = .crossDissolve
                coordinator.host = host
                top.present(host, animated: true)
            }
        } else if let host = coordinator.host {
            coordinator.host = nil
            host.dismiss(animated: true)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.host?.dismiss(animated: false)
        coordinator.host = nil
    }

    private static func topController(from window: UIWindow?) -> UIViewController? {
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

public extension View {
    /// Presents `dialog` as a centered, dimmed modal card. Tapping outside the card dismisses it.
    func htzCenterDialog<Dialog: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder dialog: @escaping () -> Dialog
    ) -> some View {
        background(CenterDialogPresenter(isPresented: isPresented, dialog: dialog).frame(width: 0, height: 0))
    }
}
