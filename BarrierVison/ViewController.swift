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
    var overlayPoints = [CGPoint]()
    
    var lastSlopeCalculationTime: TimeInterval = 0
    let slopeCalculationInterval: TimeInterval = 1 // 1秒ごとにスロープを計算

    //for Obstacles TimeInterval
    //var lastUpdateTime : TimeInterval = 0
    //let updateObstacleInterval : TimeInterval = 0.1
    
    //FIFO
    let forObstaclesNodes = FIFOforNode(size: 1000)
    let forWallNodes = FIFOforNode(size: 5)
    var createdNodes = [SCNNode]()
    var createdWallNodes = [simd_float4x4]()
    
    //size
    var wheelchairSize : Float = 1.2
    
    //rawFeaturePoints
    var processedPoints = Set<vector_float3>()
    
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var leftLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let sceneView = sceneView else { return }
        sceneView.delegate = self
        
        let scene = SCNScene()
        sceneView.scene = scene
        
        
        //スロープ計測
        let totalPoints = 3
        // 間隔をより適切に調整
        let gap = view.bounds.height / (CGFloat(totalPoints) * 2)
        // 開始点を画面中央付近に調整
        let startY = view.bounds.midY - gap * CGFloat(totalPoints / 2)
        
        overlayPoints = []
        
        for i in 0..<totalPoints {
            let y = startY + gap * CGFloat(i)
            let point = CGPoint(x: view.bounds.midX, y: y)
            overlayPoints.append(point)
        }
        
        addOverlayViews(points: overlayPoints)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        _ = movingAverage(size: 8292)
        
        //スロープ
        let angleAverage = movingAverage(size: 5)
        if time - lastSlopeCalculationTime >= slopeCalculationInterval {
            // 左右の点を定義
            let horizontalGap: CGFloat = 500 // この値は必要に応じて調整してください
            let centerIndex = overlayPoints.count / 2
            let centerPoint = overlayPoints[centerIndex]
            let leftPoint = CGPoint(x: centerPoint.x - horizontalGap, y: centerPoint.y)
            let rightPoint = CGPoint(x: centerPoint.x + horizontalGap, y: centerPoint.y)
            
            // 左右の点に対してレイキャストを実行
            let raycastedPointL = self.performRaycast(from: leftPoint)
            let raycastedPointR = self.performRaycast(from: rightPoint)
            
            // 左右の角度を初期化
            var leftAngle: Float = 0
            var rightAngle: Float = 0
            
            if let pL = raycastedPointL, let pC = self.performRaycast(from: centerPoint) {
                leftAngle = self.calculateAngle(pC, pL)
            }
            if let pR = raycastedPointR, let pC = self.performRaycast(from: centerPoint) {
                rightAngle = self.calculateAngle(pC, pR)
            }
            
            if overlayPoints.count >= 2 {
                for i in 0..<(overlayPoints.count - 1) {
                    let point1 = self.performRaycast(from: overlayPoints[i])
                    let point2 = self.performRaycast(from: overlayPoints[i + 1])
                    
                    if let p1 = point1, let p2 = point2 {
                        let angle = self.calculateAngle(p1, p2)
                        _ = angleAverage.add(angle) // 각도 추가 및 평균 업데이트
                    }
                }
            }
            
            let averageAngle = angleAverage.average() // 이동 평균 각도
            let roundedAverageAngle = round(averageAngle * 10)/10
            
            // 左角度のチェックとノードの追加
//            if abs(leftAngle) <= 8.5{
//                   
//                   DispatchQueue.main.async{
//                       self.leftLabel.text = "\(leftAngle)"
//                   }
//        
//           }
            if abs(leftAngle) <= 8.5 {
                DispatchQueue.main.async {
                    // 符号の追加と数値の絶対値化
                    let sign = leftAngle >= 0 ? "▼" : "▲"
                    let text = "L:\(sign) \(abs(leftAngle))"

                    // ラベルのフォントサイズの変更
                    self.leftLabel.font = UIFont.systemFont(ofSize: 25) // フォントサイズは適宜調整

                    // ラベルの背景色を透明に設定し、枠線を追加
                    self.leftLabel.textAlignment = .center
                    self.leftLabel.backgroundColor = UIColor.clear   // 背景色を透明に設定
                    self.leftLabel.layer.borderColor = UIColor.white.cgColor // 枠線の色を黒に設定
                    self.leftLabel.layer.borderWidth = 2.0          // 枠線の太さ
                    self.leftLabel.layer.cornerRadius = 5.0         // 角を丸くする場合
                    self.leftLabel.clipsToBounds = true             // 角丸設定を有効化
                    self.leftLabel.frame = CGRect(x: 10, y: 400, width: 100, height: 50) // 位置とサイズを設定
                    self.leftLabel.text = text
                }
            }
            
            // 右角度のチェックとノードの追加(完成)
            if abs(rightAngle) <= 8.5 {
                DispatchQueue.main.async {
                    // 符号の追加と数値の絶対値化
                    let sign = rightAngle >= 0 ? "▼" : "▲"
                    let text = "R:\(sign) \(abs(rightAngle))"

                    // ラベルのフォントサイズの変更
                    self.rightLabel.font = UIFont.systemFont(ofSize: 25) // フォントサイズは適宜調整

                    // ラベルの背景色を透明に設定し、枠線を追加
                    self.rightLabel.textAlignment = .center
                    self.rightLabel.backgroundColor = UIColor.clear   // 背景色を透明に設定
                    self.rightLabel.layer.borderColor = UIColor.white.cgColor // 枠線の色を黒に設定
                    self.rightLabel.layer.borderWidth = 2.0          // 枠線の太さ
                    self.rightLabel.layer.cornerRadius = 5.0         // 角を丸くする場合
                    self.rightLabel.clipsToBounds = true             // 角丸設定を有効化
                    self.rightLabel.frame = CGRect(x: 280, y: 400, width: 100, height: 50) // 位置とサイズを設定
                    self.rightLabel.text = text
                }
            }
            // 平均角度のチェックとノードの追加
//            if averageAngle.isNaN{
//                showWidthAlert()
//            }else{
            if abs(roundedAverageAngle) >= 2.0 && abs(roundedAverageAngle) <= 15 {
                let triangleNode: SCNNode
                let color: UIColor
                
                // 角度に応じて色を決定
                switch abs(roundedAverageAngle) {
                case 12.5...:
                    color = UIColor.red // 12.5以上の場合は赤色
                case 8.5...:
                    color = UIColor.yellow // 8.5以上の場合は黄色
                default:
                    color = UIColor.systemBlue // それ以外の場合は青色
                }
                //let triangleNode = arObjectManager.createTwoSidesTriangleNode(color: UIColor.blue)
                if roundedAverageAngle > 0 {
                    // 角度が正の場合、逆向きの三角形を生成
                    triangleNode = arObjectManager.createInvertedTriangleNode(color: color)
                    //triangleNode.eulerAngles.y = .pi // 下り坂の時
                }else {
                    // 角度が負または0の場合、通常の三角形を生成
                    triangleNode = arObjectManager.createTriangleNode(color: color)
                }
                // 三角形ノードにビルボード制約を追加
                let billboardConstraint = SCNBillboardConstraint()
                triangleNode.constraints = [billboardConstraint]
                //テキストノードを設定
                let textNode = arObjectManager.createTextNode(with: abs(roundedAverageAngle), color: color)
                // テキストノードにもビルボード制約を追加
                textNode.constraints = [billboardConstraint]

                // 適切な3D座標を設定する
                if let center3DPosition = self.performRaycast(from: centerPoint) {
                    print("Raycast Position: \(center3DPosition)")
                    // トライアングルノードの位置を設定
                    triangleNode.position = SCNVector3(center3DPosition.x, center3DPosition.y, center3DPosition.z-1.0)
                    // テキストノードの位置をトライアングルノードの上に設定
                    textNode.position = SCNVector3(center3DPosition.x, center3DPosition.y + 0.15, center3DPosition.z-1.0)
                    // ノードをシーンに追加
                    sceneView.scene.rootNode.addChildNode(triangleNode)
                    sceneView.scene.rootNode.addChildNode(textNode)
                }
            }
                    lastSlopeCalculationTime = time
            //}
            
            
            //for obstacles
            //if time - lastUpdateTime > updateObstacleInterval{
                
                guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else { return }
                let cameraPosition = simd_make_float3(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
                
                
                
                guard let currentFrame = self.sceneView.session.currentFrame,
                                       let featurePointsArray = currentFrame.rawFeaturePoints?.points else { return }
                // 重複しない特徴点のみを取得
                let pointCloudBefore = featurePointsArray.filter { processedPoints.insert($0).inserted }
                let maxDistance: Float = 5.0
                let pointCloud = pointCloudBefore.filter { point in
                    let distance = simd_distance(cameraPosition, point)
                    return distance <= maxDistance && point.y <= (cameraPosition.y-0.7)
                }
                
                
                // for obstacles ==========================================================================================================================================
                let heightsForObstacles = pointCloud.map{$0.y}
                //_ = filterPointCloud(pointCloud, cameraPosition: cameraPosition)
                let ave = movingAverage(size: 4000)
                
                let obstacleIndex = heightsForObstacles.enumerated().compactMap { index, height in
                    let avg = ave.add(height)
                    return height > avg ? index : nil
                }
                
                let obstaclePoints = obstacleIndex.map { pointCloud[$0] }
                
                let obstacleLimit: Int = 0
                //DispatchQueue.main.async {
                //    self.textLowest.text = "obstacle limit = \(obstacleLimit)"
                //}
                
                if obstaclePoints.count > obstacleLimit{
                    self.sceneView.scene.rootNode.addChildNode(createSpearNodeWithStride(pointCloud: obstaclePoints,
                                                                                         basePoint: cameraPosition,
                                                                                         size: wheelchairSize))

                }else{
                    print("OK!")
                }
                
                // for floor ==========================================================================================================================================
                /*
                 
                //functions
                 
                */
                
                //lastUpdateTime = time
            //}
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            // Wall (vertical)
            if planeAnchor.alignment == .vertical {
                //node.addChildNode(createWallNode(planeAnchor: planeAnchor)) //will use for appear anchor
                let node = createWallNode(planeAnchor: planeAnchor)
                forWallNodes.addNodeList(node)

                if let closestPair = findFacingWalls() {
                    let transform1 = createdWallNodes[closestPair.0]
                    let transform2 = createdWallNodes[closestPair.1]
                    drawLineAndLength(transform1: transform1, transform2: transform2)
                }
            }
            // floor (horizontal)
            if planeAnchor.alignment == .horizontal {
                
                
            }
        }
    }
                                                                                         
                                                                                        
    //for obstacles
     func createSpearNodeWithStride(pointCloud: [simd_float3], basePoint: simd_float3, size: Float) -> SCNNode {
         let spearNode = SCNNode()
         for i in stride(from: 0, to: pointCloud.count, by: 1) {
             let point = pointCloud[i]

             // basePoint의 x 좌표로부터 wheelchairSize / 2 거리 내에 있는지 확인
             // basePoint（カメラ）のx座標からwheelChairSize/2距離内に物体があるかを確認
             //
             let distanceX = abs(point.x - basePoint.x)
             let distanceZ = abs(point.z - basePoint.z)
             if distanceX <= wheelchairSize / 2 && distanceZ <= 2.0{
                 let node = SCNNode()
                 let material = SCNMaterial()
                 material.diffuse.contents = UIColor.red
                 material.transparency = 0.3  // 透明度を設定 (0.0 完全透明, 1.0 完全不透明)
                 material.isDoubleSided = true  // 両面レンダリングを有効にする

                 node.geometry = SCNSphere(radius: 0.02)
                 node.geometry?.firstMaterial = material
                 node.position = SCNVector3(point.x, point.y, point.z)
                 node.name = "spear"
                 forObstaclesNodes.addNodeList(node)
                 spearNode.addChildNode(node)
             }
         }
         return spearNode
     }
    
//    func filterPointCloud(_ pointCloud: [simd_float3], cameraPosition: simd_float3) -> [simd_float3] {
//        // 最も低い点の高さを探す
//        let minHeight = pointCloud.min(by: { $0.y < $1.y })?.y ?? 0
//        let heightThreshold = minHeight + 0.2
//
//        var filteredPoints = [simd_float3]()
//
//        for point in pointCloud {
//            //カメラの位置から-1mの点群のみ取得
//            let isBelowCamera = point.y <= (cameraPosition.y - 0.7)
//            
//            if isBelowCamera && point.y <= heightThreshold {
//                filteredPoints.append(point)
//            }
//        }
//        return filteredPoints
//    }
                                                                                         
    //for Wall detection
    func findFacingWalls() -> (Int, Int)? {
        var closestWallPair: (Int, Int)?
        var minDistance: Float = Float.greatestFiniteMagnitude

        for i in 0..<createdWallNodes.count {
            for j in (i+1)..<createdWallNodes.count {
                let nodeA = createdWallNodes[i]
                let nodeB = createdWallNodes[j]

                let distance = distanceBetweenNodes(nodeA: nodeA, nodeB: nodeB)
                if distance <= 2.5 && distance >= 0.3 {
                    if areNodesAligned(nodeTransformA: nodeA, nodeTransformB: nodeB) {
                        let angleA = nodeA.columns.1
                        let angleB = nodeB.columns.1
                        if areWallsFacingEachOther(angleA: angleA, angleB: angleB) {
                            if distance < minDistance {
                                minDistance = distance
                                closestWallPair = (i, j)
                            }
                        }
                    }
                }
            }
        }
        return closestWallPair
    }
    
    
    func areWallsFacingEachOther(angleA: simd_float4, angleB: simd_float4) -> Bool {
        
        let dotProduct = dot(angleA, angleB)
        //return dotProduct < -0.95 || dotProduct > 0.95 //同じ方向または逆方向
        return dotProduct < -0.95//逆方向のみ
    }
    
    func areNodesAligned(nodeTransformA: simd_float4x4, nodeTransformB: simd_float4x4, tolerance: Float = 0.5) -> Bool {
        let angle = angleBetweenNodes(nodeTransformA: nodeTransformA, nodeTransformB: nodeTransformB)

        // 각도가 매우 작거나 (거의 같은 방향) 또는 매우 크면 (거의 반대 방향)
        return angle < tolerance || abs(angle - .pi) < tolerance
    }
    
    func angleBetweenNodes(nodeTransformA: simd_float4x4, nodeTransformB: simd_float4x4) -> Float {
        let positionA = nodeTransformA.columns.3
        let positionB = nodeTransformB.columns.3
        let vectorA = SCNVector3(positionA.x, positionA.y, positionA.z)
        let vectorB = SCNVector3(positionB.x, positionB.y, positionB.z)
        let dotProduct = vectorA.x * vectorB.x + vectorA.y * vectorB.y + vectorA.z * vectorB.z
        let magnitudeA = sqrt(vectorA.x * vectorA.x + vectorA.y * vectorA.y + vectorA.z * vectorA.z)
        let magnitudeB = sqrt(vectorB.x * vectorB.x + vectorB.y * vectorB.y + vectorB.z * vectorB.z)
        let cosTheta = dotProduct / (magnitudeA * magnitudeB)
        return acos(cosTheta) // 라디안 단위의 각도 반환
    }
    
    
    func distanceBetweenNodes(nodeA: simd_float4x4, nodeB: simd_float4x4) -> Float {
        let positionA = SCNVector3(nodeA.columns.3.x, nodeA.columns.3.y, nodeA.columns.3.z)
        let positionB = SCNVector3(nodeB.columns.3.x, nodeB.columns.3.y, nodeB.columns.3.z)

        return sqrt(pow(positionB.x - positionA.x, 2) + pow(positionB.z - positionA.z, 2))
    }
    
    
    func createWallNode(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let width = CGFloat(planeAnchor.planeExtent.width)
        let height = CGFloat(planeAnchor.planeExtent.height)
        let center = planeAnchor.center
        let plane = SCNPlane(width: width, height: height)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        let planeNode = SCNNode(geometry: plane)
        planeNode.geometry?.materials = [material]
        
        planeNode.eulerAngles.x = -.pi / 2 // set the angle to attach to the wall
        planeNode.position = SCNVector3(center.x, 0, center.z)
        planeNode.name = "wall"
        
        createdWallNodes.append(planeAnchor.transform)
        
        if createdWallNodes.count >= forWallNodes.history.count{
            createdWallNodes.removeFirst()
        }
        

        return planeNode
    }
    
    // Draw Line and Length
    func drawLineAndLength(transform1: matrix_float4x4, transform2: matrix_float4x4) {
        let nodeLine1 = SCNNode()
        let nodeLine2 = SCNNode()
        nodeLine1.simdTransform = transform1
        nodeLine2.simdTransform = transform2
        
        let length = simd_distance(transform1.columns.3, transform2.columns.3)
        let lengthText = "\(String(format: "%.2f", length))m"
        
        // 長さによる色の決定
        let lineColor = length <= wheelchairSize ? UIColor.red : UIColor.green
        
        let lineGeometry = SCNGeometry.line(from: nodeLine1.position, to: nodeLine2.position, color: lineColor)
        
        let textGeometry = SCNText(string: lengthText, extrusionDepth: 0.01)
        textGeometry.font = UIFont.systemFont(ofSize: 0.15)
        textGeometry.flatness = 1
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = lineColor
        textGeometry.materials = [textMaterial]

        let lineNode = SCNNode(geometry: lineGeometry)
        let lengthNode = SCNNode(geometry: textGeometry)
        lengthNode.position = SCNVector3((nodeLine1.position.x + nodeLine2.position.x) / 2, -0.9, (nodeLine1.position.z + nodeLine2.position.z) / 2)
        
        let billboardConstraint = SCNBillboardConstraint()
        lengthNode.constraints = [billboardConstraint]
        
        lineNode.name = "line"
        lengthNode.name = "length"
        
        DispatchQueue.main.async{
            self.sceneView.scene.rootNode.addChildNode(lineNode)
            self.sceneView.scene.rootNode.addChildNode(lengthNode)
        }
    }
    
    
    
    //
    func showWidthAlert() {
        let alertController = UIAlertController(title: "注意", message: "ポインターを道路に向けてください", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
//        let location = gestureRecognize.location(in: sceneView)
//        // 新しいレイキャストクエリを作成
//        guard let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .horizontal) else { return }
//        // セッションでレイキャストを実行
//        let results = sceneView.session.raycast(query)
//        if let firstResult = results.first {
//            // レイキャストの結果を使用してAR体験を更新
//            let position = SCNVector3(firstResult.worldTransform.columns.3.x, firstResult.worldTransform.columns.3.y, firstResult.worldTransform.columns.3.z)
//            arObjectManager.placeObjects(at: position, in: sceneView.scene)
//        }
        // デバッグ用の道幅用ポップアップ表示
        //showWidthAlert()
    }
    
    //for angle view
    func addOverlayViews(points: [CGPoint]) {
        for point in points {
            createAndAddView(at: point)
        }
    }
    //raycastのオーバーレイの見た目
    func createAndAddView(at point: CGPoint) {
        let size: CGFloat = 8 // プラス記号のサイズ
        let thickness: CGFloat = 2 // プラス記号の線の太さ

        // 水平な線を作成
        let horizontalView = UIView()
        horizontalView.backgroundColor = .green
        horizontalView.frame = CGRect(x: point.x - size / 2, y: point.y - thickness / 2, width: size, height: thickness)

        // 垂直な線を作成
        let verticalView = UIView()
        verticalView.backgroundColor = .green
        verticalView.frame = CGRect(x: point.x - thickness / 2, y: point.y - size / 2, width: thickness, height: size)

        // ビューを追加
        view.addSubview(horizontalView)
        view.addSubview(verticalView)
    }
    //for raycast
    func performRaycast(from point: CGPoint) -> simd_float4? {
            if let raycastQuery = sceneView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .any),
               let result = sceneView.session.raycast(raycastQuery).first {
                return result.worldTransform.columns.3
            }
            return nil
        }

    //２点間の角度を計算する関数
    func calculateAngle(_ point1: simd_float4, _ point2: simd_float4) -> Float {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        let dz = point2.z - point1.z
        let horizontalDistance = sqrt(dx*dx + dz*dz)
//        let angleForFloor = atan2(dy, horizontalDistance)
//        let angleInDegrees = angleForFloor * (180.0 / .pi)
        
        let gradient = (dy / horizontalDistance) * 100
        
        return round(gradient * 10) / 10
    }

    //スロープ用のUIを呼び出す関数
    

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

// MARK: Classes

class movingAverage{
    private var size: Int
    private var history: [Float] = []
    
    init(size:Int){
        self.size = size
    }
    func add(_ value: Float) -> Float{
        history.append(value)
        if history.count > size{
            history.removeFirst()
        }
        return average()
    }
    
    func average() -> Float{
        return history.reduce(0, +) / Float(history.count)
    }
}


class FIFOforNode {
    private var size: Int
    var history: [SCNNode] = []
    
    init(size: Int) {
        self.size = size
    }
    
    func addNodeList(_ value: SCNNode) {
        DispatchQueue.main.async {
            self.history.append(value)
            if self.history.count > self.size {
                let nodeForRemove = self.history.removeFirst()
                nodeForRemove.removeFromParentNode()
            }
        }
    }
}


// MARK: extensions

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3, color: UIColor) -> SCNGeometry {
        let indices: [UInt32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)

        let geometry = SCNGeometry(sources: [source], elements: [element])
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        geometry.materials = [material]

        return geometry
    }
}



extension Array where Element: Numeric & Comparable {
    func percentile(_ percentile: Double) -> Element? {
        let sorted = self.sorted()
        let index = Int(Double(count) * percentile / 100.0)
        return index < count ? sorted[index] : nil
    }
}
    



