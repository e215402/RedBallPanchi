import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // sceneViewがnilでないことを確認する
        guard let sceneView = sceneView else { return }

        // ARSCNViewのデリゲートを設定
        sceneView.delegate = self
        
        // 新しいシーンを作成
        let scene = SCNScene()
        sceneView.scene = scene
        
        // ARセッションを開始
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // sceneViewがnilでないことを確認し、三角形とテキストのノードを追加
        if let sceneView = sceneView {
            addTriangleAndTextToScene()
        }
    }

    func addTriangleAndTextToScene() {
        // このメソッドが呼ばれた時、sceneViewがnilでないことを確認
        guard let sceneView = sceneView else { return }

        let triangleNode = createTriangleNode()
        triangleNode.position = SCNVector3(0, 0, -0.5) // カメラの前方に配置
        sceneView.scene.rootNode.addChildNode(triangleNode)

        let textNode = createTextNode()
        textNode.position = SCNVector3(0, 0.1, -0.5) // 三角形の上に配置
        sceneView.scene.rootNode.addChildNode(textNode)
    }

    func createTriangleNode() -> SCNNode {
        let vertices: [SCNVector3] = [
            SCNVector3(0, 0.1, 0),   // 頂点1
            SCNVector3(-0.1, -0.1, 0), // 頂点2
            SCNVector3(0.1, -0.1, 0)  // 頂点3
        ]

        let indices: [Int32] = [0, 1, 2]

        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green // 三角形の色を緑に設定
        geometry.materials = [material]

        return SCNNode(geometry: geometry)
    }

    func createTextNode() -> SCNNode {
        let textGeometry = SCNText(string: "10°", extrusionDepth: 0.01)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.green // テキストの色を緑に設定
        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01) // テキストのサイズ調整
        return textNode
    }
}

