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
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else { return }
        let cameraPosition = simd_make_float3(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        
        _ = movingAverage(size: 8292)
        
        //スロープ
        let angleAverage = movingAverage(size: 5)
        if time - lastSlopeCalculationTime >= slopeCalculationInterval {
            // 左右の点を定義
            let horizontalGap: CGFloat = 50 // この値は必要に応じて調整してください
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
            
            //            // 左角度のチェックとノードの追加
            //            if abs(leftAngle) >= 1.0 && abs(leftAngle) <= 10 {
            //                let triangleNode = arObjectManager.createLeftTriangleNode(color:UIColor.red)
            //                let textNode = arObjectManager.createTextNode(with: abs(leftAngle),color:UIColor.blue)
            //
            //                if let left3DPosition = self.performRaycast(from: leftPoint) {
            //                    // トライアングルノードの位置を設定
            //                    triangleNode.position = SCNVector3(left3DPosition.x, left3DPosition.y, left3DPosition.z)
            //                    //左向き用の三角形を設定
            //                    triangleNode.eulerAngles.z = .pi / 2
            //                    if leftAngle < 0 {
            //                        triangleNode.eulerAngles.y = .pi // 角度が負の場合は反対向きに設置
            //                    }
            //                    sceneView.scene.rootNode.addChildNode(triangleNode)
            //
            //                    // テキストノードの位置をトライアングルノードの上に設定
            //                    textNode.position = SCNVector3(left3DPosition.x, left3DPosition.y + 0.1, left3DPosition.z) // トライアングルの上に配置
            //                    sceneView.scene.rootNode.addChildNode(textNode)
            //                }
            //            }
            //            // 右角度のチェックとノードの追加
            //            if abs(rightAngle) >= 2 && abs(rightAngle) <= 10{
            //                let triangleNode = arObjectManager.createTriangleNode(color:UIColor.blue)
            //                let textNode = arObjectManager.createTextNode(with: abs(rightAngle),color:UIColor.blue)
            //
            //                if let right3DPosition = self.performRaycast(from: rightPoint) {
            //                    // トライアングルノードの位置を設定
            //                    triangleNode.position = SCNVector3(right3DPosition.x, right3DPosition.y, right3DPosition.z)
            //                    if leftAngle < 0 {
            //                        triangleNode.eulerAngles.y = .pi // 角度が負の場合は反対向きに設置
            //                    }
            //                    sceneView.scene.rootNode.addChildNode(triangleNode)
            //
            //                    // テキストノードの位置をトライアングルノードの上に設定
            //                    textNode.position = SCNVector3(right3DPosition.x, right3DPosition.y + 0.1, right3DPosition.z) // トライアングルの上に配置
            //                    sceneView.scene.rootNode.addChildNode(textNode)
            //                }
            //            }
            
            // 平均角度のチェックとノードの追加
//            if averageAngle.isNaN{
//                showWidthAlert()
//            }else{
            if abs(roundedAverageAngle) >= 1 {
                let triangleNode: SCNNode
                if roundedAverageAngle > 0 {
                    // 角度が正の場合、逆向きの三角形を生成
                    triangleNode = arObjectManager.createInvertedTriangleNode(color: UIColor.blue)
                } else {
                    // 角度が負または0の場合、通常の三角形を生成
                    triangleNode = arObjectManager.createTriangleNode(color: UIColor.blue)
                }
                let textNode = arObjectManager.createTextNode(with: abs(roundedAverageAngle), color: UIColor.blue)
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
            }

   

        
        
        
        
    }
    
    
    
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




    



