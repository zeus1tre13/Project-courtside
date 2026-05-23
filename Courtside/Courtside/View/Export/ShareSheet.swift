import UIKit

/// Presents the native iOS share sheet (UIActivityViewController) directly
/// through UIKit. We intentionally do NOT wrap this in a SwiftUI `.sheet` —
/// nesting a UIActivityViewController inside a SwiftUI sheet (especially with
/// `presentationDetents`) leaves the activity controller unable to render,
/// producing an empty white sheet.
enum ShareSheet {
    static func present(items: [Any]) {
        guard let presenter = topViewController() else { return }
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = activityVC.popoverPresentationController,
           let sourceView = presenter.view {
            pop.sourceView = sourceView
            pop.sourceRect = CGRect(x: sourceView.bounds.midX,
                                    y: sourceView.bounds.midY,
                                    width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        presenter.present(activityVC, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let root = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
                ?? scene?.windows.first?.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
