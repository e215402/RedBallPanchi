import ARKit

class ARObjectManager {
    // オブジェクトを生成するメソッド
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
        let textGeometry = SCNText(string: "3°", extrusionDepth: 0.01)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.green // テキストの色を緑に設定
        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01) // テキストのサイズ調整
        return textNode
    }

    // 指定された位置にオブジェクトを配置するメソッド
    func placeObjects(at position: SCNVector3, in scene: SCNScene) {
        let triangleNode = createTriangleNode()
        triangleNode.position = position
        scene.rootNode.addChildNode(triangleNode)

        let textNode = createTextNode()
        textNode.position = SCNVector3(position.x, position.y + 0.1, position.z)
        scene.rootNode.addChildNode(textNode)
    }
}

