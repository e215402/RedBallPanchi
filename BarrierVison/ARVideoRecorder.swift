
import Foundation
import ARKit
import ReplayKit

class ARVideoRecorder {
    static let shared = ARVideoRecorder()

    private var isRecording = false

    func startRecording() {
        guard !isRecording else { return }

        let recorder = RPScreenRecorder.shared()

        recorder.startRecording { [weak self] (error) in
            if let error = error {
                print("Recording failed to start with error: \(error.localizedDescription)")
            } else {
                self?.isRecording = true
                print("Recording started successfully.")
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        let recorder = RPScreenRecorder.shared()

        recorder.stopRecording { [weak self] (previewController, error) in
            if let error = error {
                print("Recording failed to stop with error: \(error.localizedDescription)")
            } else {
                self?.isRecording = false
                print("Recording stopped successfully.")
                // Handle the preview controller and save the video if needed
            }
        }
    }
}

