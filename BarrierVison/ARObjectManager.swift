import ARKit

class ARObjectManager {
    // オブジェクトを生成するメソッド
    func createTriangleNode(color:UIColor) -> SCNNode {
        let scale: Float = 0.1  // 二等辺三角形の底辺と高さの長さ
        
        let vertices: [SCNVector3] = [
            SCNVector3(-scale, 0, 0),                                   // 頂点1
            SCNVector3(scale, 0, 0),                               // 頂点2
            SCNVector3(0, scale, 0),       // 頂点3
        ]
        
        let indices: [Int32] = [0, 1, 2]

        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = color // 三角形の色を緑に設定
        material.isDoubleSided = true     // 両面をレンダリングする
        geometry.materials = [material]

        return SCNNode(geometry: geometry)
    }
    func createInvertedTriangleNode(color:UIColor) -> SCNNode {
        let scale: Float = 0.1
        let xx:Float = -0.01

        let vertices: [SCNVector3] = [
            SCNVector3(0, 0, 0),                                  // 頂点1 (底辺の中央)
            SCNVector3(-scale, scale, xx),       // 頂点2 (底辺の一端)
            SCNVector3(scale, scale, xx)         // 頂点3 (底辺のもう一端)
        ]

        let indices: [Int32] = [0, 1, 2]

        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = color // 三角形の色を緑に設定
        material.isDoubleSided = true     // 両面をレンダリングする
        geometry.materials = [material]

        return SCNNode(geometry: geometry)
    }
    func createLeftTriangleNode(color:UIColor) -> SCNNode {
        let scale: Float = 0.1  // 二等辺三角形の底辺と高さの長さ
        
        let vertices: [SCNVector3] = [
            SCNVector3(0, 0, 0),
            SCNVector3(scale, 0, 0),
            SCNVector3(0, scale, 0)// 頂点3 (y軸上)
            ]

        let indices: [Int32] = [0, 1, 2]

        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = color // 三角形の色を緑に設定
        geometry.materials = [material]

        return SCNNode(geometry: geometry)
    }

//    func createTwoSidesTriangleNode(color: UIColor) -> SCNNode {
//        let scale: Float = 0.1
//
//        // 表面の頂点
//        let frontVertices: [SCNVector3] = [
//            SCNVector3(-scale, 0, 0),                                   // 頂点1
//            SCNVector3(scale, 0, 0),                               // 頂点2
//            SCNVector3(0, scale, 0),       // 頂点3
//        ]
//
//        // 裏面の頂点（y軸方向に反転）
//        let backVertices:[SCNVector3] = [
//            SCNVector3(0, 0, 0),                                  // 頂点1 (底辺の中央)
//            SCNVector3(-scale, scale, 0),       // 頂点2 (底辺の一端)
//            SCNVector3(scale, scale, 0)         // 頂点3 (底辺のもう一端)
//        ]
//
//        // 表面のジオメトリ
//        let frontGeometry = createGeometry(vertices: frontVertices, color: color)
//        // 裏面のジオメトリ
//        let backGeometry = createGeometry(vertices: backVertices, color: color)
//
//        // ノードに表面のジオメトリを設定
//        let node = SCNNode()
//        node.geometry = frontGeometry
//
//        // 裏面のジオメトリを別のノードとして作成して追加
//        let backNode = SCNNode(geometry: backGeometry)
//        node.addChildNode(backNode)
//
//        return node
//    }

    // ジオメトリを作成するヘルパー関数
    func createTwoSidesTriangleNode(color: UIColor) -> SCNNode {
        let scale: Float = 0.1

        // 表面の頂点
        let frontVertices: [SCNVector3] = [
            SCNVector3(-scale, 0, 0),
            SCNVector3(scale, 0, 0),
            SCNVector3(0, scale, 0)
        ]

        // 裏面の頂点（y軸方向に反転）
        let backVertices: [SCNVector3] = [
            SCNVector3(-scale, 0, 0),
            SCNVector3(scale, 0, 0),
            SCNVector3(0, -scale, 0)
        ]

        // 表面のジオメトリ
        let frontGeometry = createGeometry(vertices: frontVertices, color: color, cullMode: .back)
        // 裏面のジオメトリ
        let backGeometry = createGeometry(vertices: backVertices, color: color, cullMode: .front)

        // ノードに表面のジオメトリを設定
        let node = SCNNode()
        node.geometry = frontGeometry

        // 裏面のジオメトリを別のノードとして作成して追加
        let backNode = SCNNode(geometry: backGeometry)
        node.addChildNode(backNode)

        return node
    }

    // ジオメトリを作成するヘルパー関数
    func createGeometry(vertices: [SCNVector3], color: UIColor, cullMode: SCNCullMode) -> SCNGeometry {
        let indices: [Int32] = [0, 1, 2]
        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.isDoubleSided = false
        material.cullMode = cullMode
        geometry.materials = [material]

        return geometry
    }

    func createTextNode(with angle: Float,color:UIColor) -> SCNNode {
        let textGeometry = SCNText(string: "\(angle)%", extrusionDepth: 0.01)
        textGeometry.firstMaterial?.diffuse.contents = color
        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        return textNode
    }
    

}

