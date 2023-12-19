import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    let arObjectManager = ARObjectManager() // ARObjectManagerのインスタンス化

    var isRecording = false
    @IBOutlet weak var recordButton: UIButton!
    
    var isPreviewing = false
    @IBOutlet weak var previewButton: UIButton!
    
    @IBOutlet weak var previewON: UILabel!
    
    var isLighting = false
    @IBOutlet weak var lightButton: UIButton!
    
    @IBOutlet weak var lightON: UILabel!
    
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
    
    
    @IBAction func recordButtonTap(_ sender: Any) {
        
        if isRecording {
              UIView.animate(withDuration: 0.2) {
                self.recordButton.frame = CGRect(x:172,y:675,width:50,height:50)
                self.recordButton.layer.cornerRadius = 25
              }
            } else {
              UIView.animate(withDuration: 0.2) {
                self.recordButton.frame = CGRect(x:182,y:685,width:30,height:30)
                self.recordButton.layer.cornerRadius = 3.0
              }
            }
            isRecording = !isRecording
    }
    
    @IBAction func previewButtonTap(_ sender: Any) {
        if isPreviewing {
            previewON.backgroundColor = UIColor.clear
        } else {
            previewON.backgroundColor = UIColor.red
        }
        isPreviewing = !isPreviewing
    }
    
    @IBAction func lightButtonTap(_ sender: Any) {
        if isLighting {
            lightON.backgroundColor = UIColor.clear
        } else {
            lightON.backgroundColor = UIColor.yellow
        }
        isLighting = !isLighting
    }
    
}


