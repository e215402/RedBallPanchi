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
    func createTextNode(with angle: Float,color:UIColor) -> SCNNode {
        let textGeometry = SCNText(string: "\(angle)%", extrusionDepth: 0.01)
        textGeometry.firstMaterial?.diffuse.contents = color
        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        return textNode
    }
    

}

