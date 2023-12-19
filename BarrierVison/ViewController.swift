import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
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

    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        let location = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if let hitResult = hitResults.first {
            let position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
            arObjectManager.placeObjects(at: position, in: sceneView.scene)
        }
    }
                                                                                        
    @IBAction func toggleLightButtonPressed(_ sender: UIButton) {
        isTorchOn.toggle() // トーチの状態を切り替える
        cameraLight.toggleTorch(on: isTorchOn)
        if isTorchOn {
            lightON.backgroundColor = UIColor.yellow
        } else {
            lightON.backgroundColor = UIColor.clear
        }
    }
    
    @IBAction func recordButtonTap(_ sender: Any) {
        isRecordOn = !isRecordOn
        if isRecordOn {
            UIView.animate(withDuration: 0.2) {
                self.recordButton.frame = CGRect(x:182,y:705,width:30,height:30)
                self.recordButton.layer.cornerRadius = 3.0
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.recordButton.frame = CGRect(x:172,y:695,width:50,height:50)
                self.recordButton.layer.cornerRadius = 25
            }
        }
    }
    
    
}


