import UIKit
import ReplayKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate ,RPPreviewViewControllerDelegate{
    
    let recorder = RPScreenRecorder.shared()
       
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var lightON: UILabel!
    
    @IBOutlet weak var recordButton: UIButton!
    
    let arObjectManager = ARObjectManager() // ARObjectManagerのインスタンス化
    let cameraLight = UseCameraLight()
    var isTorchOn = false // トーチの状態を追跡する変数
    var isRecordOn = false //Recの状態を追跡する変数
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let sceneView = sceneView else { return }
        sceneView.delegate = self
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    func showWidthAlert() {
        let alertController = UIAlertController(title: "注意", message: "通路が狭すぎます", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        let location = gestureRecognize.location(in: sceneView)
        // 新しいレイキャストクエリを作成
        guard let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal) else { return }
        // セッションでレイキャストを実行
        let results = sceneView.session.raycast(query)
        if let firstResult = results.first {
            // レイキャストの結果を使用してAR体験を更新
            let position = SCNVector3(firstResult.worldTransform.columns.3.x, firstResult.worldTransform.columns.3.y, firstResult.worldTransform.columns.3.z)
            arObjectManager.placeObjects(at: position, in: sceneView.scene)
        }
        // デバッグ用の道幅用ポップアップ表示
        showWidthAlert()
    }

    
//    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
//        showWidthAlert()
//        let location = gestureRecognize.location(in: sceneView)
//        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
//        if let hitResult = hitResults.first {
//            let position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
//            arObjectManager.placeObjects(at: position, in: sceneView.scene)
//        }
//    }
    
    @IBAction func toggleLightButtonPressed(_ sender: UIButton) {
        isTorchOn.toggle() // トーチの状態を切り替える
        cameraLight.toggleTorch(on: isTorchOn)
        if isTorchOn {
            lightON.backgroundColor = UIColor.yellow
        } else {
            lightON.backgroundColor = UIColor.clear
        }
    }
    @objc func startRecording() {
            recorder.startRecording { (error) in
                if let error = error {
                    print(error)
            }
        }
    }

    @objc func endRecording() {
        recorder.stopRecording { (previewVC, error) in
            if let previewVC = previewVC {
                previewVC.previewControllerDelegate = self
                self.present(previewVC, animated: true)
            }
            
            if let error = error {
                print(error)
            }
        }
    }
    @IBAction func recordButtonTap(_ sender: Any) {
        isRecordOn = !isRecordOn
        if isRecordOn {
            UIView.animate(withDuration: 0.2) {
                self.recordButton.frame = CGRect(x:182, y:705, width:30, height:30)
                self.recordButton.layer.cornerRadius = 3.0
            }
            startRecording()
//            { error in
//                if let error = error {
//                    print("Error starting recording: \(error.localizedDescription)")
//                }
//            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.recordButton.frame = CGRect(x:172, y:695, width:50, height:50)
                self.recordButton.layer.cornerRadius = 25
            }
            endRecording()
            //{ error in
            //  if let error = error {
            //    print("Error stopping recording: \(error.localizedDescription)")
            //}
            }
        }
    // RPPreviewViewControllerDelegateのメソッド
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
}






    



