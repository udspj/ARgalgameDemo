//
//  Created by udspj
//  Copyright (c) udspj. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
	@IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dialogLabel: UILabel!
    
    lazy var configuration = { () -> ARWorldTrackingConfiguration in
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        return configuration
    }()
    
    var source: SCNAudioSource?
    
    let scene = SCNScene()
    let charaNode = SCNNode()
    
    lazy var selectNode1 = selectionNode(label:"嗯，是的。",name:"select1",position:SCNVector3Make(0, 0.1, -0.5))
    lazy var selectNode2 = selectionNode(label:"不是的，你听错了。",name:"select2",position:SCNVector3Make(0, 0, -0.5))
    
    let charaText = [["name":"shion","say":"嗯？","voice":"chara1.mp3"],
                     ["name":"shion","say":"好像是邮件呢。","voice":"chara2.mp3"],
                     ["name":"","say":"","voice":"","selection":[3,4]],
                     ["name":"shion","say":"啊～","voice":"chara3.mp3"],
                     ["name":"shion","say":"没关系。","voice":"chara4.mp3"],
                     ["name":"shion","say":"我会删除掉的。","voice":"chara5.mp3"]]
    var textPosition = 0
    var isReady = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("ARKit is not available on this device.")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        sceneView.isJitteringEnabled = true
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = false
        sceneView.scene = scene
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupCharacter()
        
        setupBGM()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
        
    func setupCharacter() {
        let boxGeometry = SCNBox()
        boxGeometry.width = 1.75
        boxGeometry.height = 1.75
        boxGeometry.length = 0.0001
        boxGeometry.chamferRadius = 0.0
        
        charaNode.geometry = boxGeometry
        charaNode.position = SCNVector3Make(0, -0.6, -2.0)
        
        let material2 = SCNMaterial()
        material2.diffuse.contents = UIImage(named: "chara_front.png")
        let material3 = SCNMaterial()
        material3.diffuse.contents = UIImage(named: "chara_back.png")
        let empty = SCNMaterial()
        charaNode.geometry?.materials = [material2,empty,material3,empty,empty,empty]
        scene.rootNode.addChildNode(charaNode)
        
        setupLights(model:charaNode)
    }
    
    func selectionNode(label:String,name:String,position:SCNVector3) -> SCNNode{
        let material1 = SCNMaterial()
        material1.diffuse.contents = selection(label: label)
        let materialback = SCNMaterial()
        materialback.diffuse.contents = selection() // no light
        let empty = SCNMaterial()
        
        let boxGeometry1 = SCNBox()
        boxGeometry1.width = 0.3
        boxGeometry1.height = 0.07
        boxGeometry1.length = 0.0001
        boxGeometry1.chamferRadius = 0.0
        
        let selectNode1 = SCNNode()
        selectNode1.geometry = boxGeometry1
        selectNode1.name = name
        selectNode1.position = position
        selectNode1.geometry?.materials = [material1,empty,materialback,empty,empty,empty]
        return selectNode1
    }
    
    func selection(label:String = "") -> SKScene {
        let skScene = SKScene(size: CGSize(width: 300, height: 70))
        skScene.backgroundColor = UIColor.clear
        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 300, height: 70), cornerRadius: 10)
        rectangle.fillColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        rectangle.strokeColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        rectangle.lineWidth = 5
        rectangle.alpha = 0.5
        skScene.addChild(rectangle)
        if(label != "") {
            let labelNode = SKLabelNode(text: label)
            labelNode.fontSize = 20
            labelNode.fontName = "San Fransisco"
            labelNode.position = CGPoint(x:150,y:45)
            labelNode.zRotation = CGFloat.pi
            labelNode.xScale = labelNode.xScale * -1;
            skScene.addChild(labelNode)
        }
        return skScene
    }
    
    func setupBGM() {
        let music = SCNAudioSource(fileNamed: "Assets.scnassets/bgm.mp3")!
        music.volume = 0.2;
        music.loops = true
        music.shouldStream = true
        music.isPositional = true
        let musicPlayer = SCNAudioPlayer(source: music)
        scene.rootNode.addAudioPlayer(musicPlayer)
    }
    
    @IBAction func next(sender: UIButton) {
        if(!isReady) { return }
        if(textPosition >= charaText.count - 1){
            textPosition = 0
        }else{
            textPosition = textPosition + 1
        }
        if(charaText[textPosition]["selection"] != nil) {
            dialogLabel.text = ""
            nameLabel.text = ""
            isReady = false
            scene.rootNode.addChildNode(selectNode1)
            scene.rootNode.addChildNode(selectNode2)
            return
        }
        playCharacter()
    }
    
    @objc func tapAction(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: view)
        guard let result = sceneView.hitTest(tapLocation, options: nil).first else {
            return
        }
        if result.node.name == "select1" {
            textPosition = 3
            selectNode1.removeFromParentNode()
            selectNode2.removeFromParentNode()
            isReady = true
            playCharacter()
        }else if result.node.name == "select2" {
            textPosition = 4
            selectNode1.removeFromParentNode()
            selectNode2.removeFromParentNode()
            isReady = true
            playCharacter()
        }
    }
    
    func setupLights(model:SCNNode) {
        let light = SCNLight()
        light.type = .spot
        light.castsShadow = true
        light.shadowRadius = 150
        light.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        light.shadowMode = .deferred
        let constraint = SCNLookAtConstraint(target: model)
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(model.position.x + 30, model.position.y + 30, model.position.z+30)
        lightNode.eulerAngles = SCNVector3(45.0, 0, 0)
        lightNode.constraints = [constraint]
        model.addChildNode(lightNode)
    }
    
    func setupRoomLight(intensity:CGFloat) {
        let roomLight = SCNLight()
        roomLight.intensity = intensity//466.88
        roomLight.type = .ambient
        let roomLightNode = SCNNode()
        roomLightNode.light = roomLight
        roomLightNode.position = SCNVector3(x: 0.0, y: 0, z: -20.0)
        scene.rootNode.addChildNode(roomLightNode)
    }
    
    func playCharacter() {
        dialogLabel.text = (charaText[textPosition]["say"] as! String)
        nameLabel.text = (charaText[textPosition]["name"] as! String)
        let voicepath = (charaText[textPosition]["voice"] as! String)
        let action = SCNAction.playAudio(SCNAudioSource(fileNamed: "Assets.scnassets/"+voicepath)!, waitForCompletion: true)
        isReady = false
        charaNode.runAction(action) {
            [weak self] in
            if let strongSelf = self {
                strongSelf.isReady = true
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        let baseIntensity: CGFloat = 40
        let lightingEnvironment = sceneView.scene.lightingEnvironment
        if let lightEstimate = sceneView.session.currentFrame?.lightEstimate {
            lightingEnvironment.intensity = lightEstimate.ambientIntensity / baseIntensity
        } else {
            lightingEnvironment.intensity = baseIntensity
        }
    }
	
	// MARK: - ARSCNViewDelegate
    
    /// - Tag: PlaceARContent
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let _ = anchor as? ARPlaneAnchor else { return }
        
        let floor = SCNFloor()
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(x: 0, y: -1.5, z: 0)
        floor.reflectivity = 0
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        floor.materials = [material]
        self.sceneView.scene.rootNode.addChildNode(floorNode)
	}

    /// - Tag: UpdateARContent
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updatedialogLabel(for: frame, trackingState: frame.camera.trackingState)
        if let lightEstimate = frame.lightEstimate {
            setupRoomLight(intensity: lightEstimate.ambientIntensity)
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updatedialogLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updatedialogLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }

    // MARK: - ARSessionObserver
	
	func sessionWasInterrupted(_ session: ARSession) {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay.
		dialogLabel.text = "Session was interrupted"
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		// Reset tracking and/or remove existing anchors if consistent tracking is required.
		dialogLabel.text = "Session interruption ended"
		resetTracking()
	}
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        dialogLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }

    // MARK: - Private methods

    private func updatedialogLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        isReady = false
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal surfaces."
            
        case .normal:
            // No feedback needed when tracking is normal and planes are visible.
            message = ""
            isReady = true
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing):
            message = "Initializing AR session."
        }

        dialogLabel.text = message
        nameLabel.text = ""
        if(message == "") {
            playCharacter()
        }
    }

    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's AR session.
        sceneView.session.pause()
    }
}
