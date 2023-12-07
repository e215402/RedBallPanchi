import AVFoundation

class UseCameraLight {
    private var device: AVCaptureDevice? {
        return AVCaptureDevice.default(for: .video)
    }

    func toggleTorch(on: Bool) {
        guard let device = device, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("トーチが使用できません: \(error)")
        }
    }
}

