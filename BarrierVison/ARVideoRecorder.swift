//import Foundation
//import ARKit
//import ReplayKit
//
//class ARVideoRecorder: NSObject,RPPreviewViewControllerDelegate {
//    static let shared = ARVideoRecorder()
//    var isRecording: Bool {
//        return RPScreenRecorder.shared().isRecording
//    }
//    
//    func startRecording(completion: ((Error?) -> Void)? = nil) {
//        guard !isRecording else { return }
//        
//        let recorder = RPScreenRecorder.shared()
//        
//        recorder.startCapture(handler: { (sampleBuffer, bufferType, error) in
//            if let error = error {
//                print("Error during capture: \(error.localizedDescription)")
//                completion?(error)
//            } else {
//                // ここでsampleBufferを処理します（例：ビデオデータを保存）
//            }
//        }) { (error) in
//            if let error = error {
//                print("Recording failed to start with error: \(error.localizedDescription)")
//                completion?(error)
//            } else {
//                print("Recording started successfully.")
//                completion?(nil)
//            }
//        }
//    }
//    func stopRecording(completion: ((Error?) -> Void)? = nil) {
//            guard isRecording else { return }
//
//            let recorder = RPScreenRecorder.shared()
//            
//            recorder.stopRecording { previewViewController, error in
//                if let error = error {
//                    print("Recording failed to stop with error: \(error.localizedDescription)")
//                    completion?(error)
//                    return
//                }
//                
//                print("Recording stopped successfully.")
//
//                // プレビューコントローラーを提示する
//                if let previewController = previewViewController {
//                    previewController.previewControllerDelegate = self
//                    DispatchQueue.main.async {
//                        self.presentPreviewController(previewController)
//                    }
//                }
//
//                completion?(nil)
//            }
//        }
//    private func presentPreviewController(_ previewController: UIViewController) {
//        // 現在のシーンの最前面のViewControllerを取得
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let topController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
//            topController.present(previewController, animated: true, completion: nil)
//        }
//    }
//
//    // RPPreviewViewControllerDelegateのメソッド
//    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
//        // プレビューコントローラーを閉じる
//        previewController.dismiss(animated: true, completion: nil)
//    }
//}
////    func stopRecording(completion: ((Error?) -> Void)? = nil) {
////        guard isRecording else { return }
////        
////        let recorder = RPScreenRecorder.shared()
////        
////        recorder.stopCapture{ (error) in
////            if let error = error {
////                print("Recording failed to stop with error: \(error.localizedDescription)")
////                completion?(error)
////            } else {
////                print("Recording stopped successfully.")
////                completion?(nil)
////            }
////        }
////    }
//
//
