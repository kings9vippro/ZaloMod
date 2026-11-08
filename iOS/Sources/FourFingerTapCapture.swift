import SwiftUI
import UIKit

/// Attaches one passive four-finger recognizer to this application's foreground UIWindow.
/// It does not intercept touches in other applications or the system UI.
struct FourFingerTapCapture: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.onFourFingerTap = action
        return view
    }
    func updateUIView(_ uiView: CaptureView, context: Context) {
        uiView.onFourFingerTap = action
    }

    final class CaptureView: UIView, UIGestureRecognizerDelegate {
        var onFourFingerTap: (() -> Void)?
        private weak var registeredWindow: UIWindow?
        private lazy var recognizer: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleGesture))
            recognizer.numberOfTouchesRequired = 4
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
            if sender.state == .ended { onFourFingerTap?() }
        }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
        deinit { registeredWindow?.removeGestureRecognizer(recognizer) }
    }
}
