import SwiftUI
import UIKit

/// Attaches one passive three-finger recognizer to this application's foreground UIWindow.
/// It does not intercept touches in other applications or the system UI.
struct ThreeFingerTapCapture: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.onThreeFingerTap = action
        return view
    }
    func updateUIView(_ uiView: CaptureView, context: Context) {
        uiView.onThreeFingerTap = action
    }

    final class CaptureView: UIView, UIGestureRecognizerDelegate {
        var onThreeFingerTap: (() -> Void)?
        private weak var registeredWindow: UIWindow?
        private lazy var recognizer: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleGesture))
            recognizer.numberOfTouchesRequired = 3
            recognizer.numberOfTapsRequired = 1
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            return recognizer
        }()
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if registeredWindow !== window {
                registeredWindow?.removeGestureRecognizer(recognizer)
                registeredWindow = window
                window?.addGestureRecognizer(recognizer)
            }
        }
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { false }
        @objc private func handleGesture(_ sender: UITapGestureRecognizer) {
            if sender.state == .ended { onThreeFingerTap?() }
        }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
        deinit { registeredWindow?.removeGestureRecognizer(recognizer) }
    }
}
