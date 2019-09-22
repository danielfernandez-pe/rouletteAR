//
//  ViewController.swift
//  ARKitTest
//
//  Created by Daniel Gustavo Fernandez Yopla on 19/09/2019.
//  Copyright © 2019 Daniel Gustavo Fernandez Yopla. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var numberTextField: UITextField!
    
    // Nodes
    var rouletteNode: SCNNode!
    var ballNode: SCNNode!
    var ballNodeParent: SCNNode!
    
    // General rotation properties
    var isRotating = false
    var totalSlotsInRoulette = 37.0
    var totalSecondsToSpin = 15.0
    var additionalSpeedToAdd = 0.01
    
    // Rotation properties for roulette
    var rouletteCurrentAngleY: Float = 0
    var rouletteCurrentSecondsSpinning = 0.0
    var rouletteSecondsPerSpin = 0.5
    var rouletteSecondsPerSlot: TimeInterval = 0.0
    
    // Rotation properties for roulette
    var ballCurrentAngleY: Float = 0
    var ballCurrentSecondsSpinning = 0.0
    var ballSecondsPerSpin = 0.5
    var ballSecondsPerSlot: TimeInterval = 0.0
    var ballInRoulette = false

    // Timers
    var rouletteTimer: Timer!
    var ballTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(gesture:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @IBAction func spinPressed(_ sender: Any) {
        guard rouletteNode != nil,
            !isRotating,
            let numberToStopText = numberTextField.text,
            !numberToStopText.isEmpty,
            let numberToStop = Int(numberToStopText),
            numberToStop >= 0 && numberToStop <= 36 else { return }
        dropBall()
        startRotation()
        view.endEditing(true)
    }
    
    @objc
    func handleTap(gesture: UITapGestureRecognizer) {
        guard rouletteNode == nil else { return }
        let sceneView = gesture.view as! ARSCNView
        let touchLocation = gesture.location(in: sceneView)
        
        let hitResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        
        if !hitResult.isEmpty {
            addRoulette(hitResult: hitResult)
            addBall()
        }
    }
    
    private func setupSceneView() {
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    private func addRoulette(hitResult: [ARHitTestResult]) {
        guard let rouletteScene = SCNScene(named: "wood.usdz"),
            let node = rouletteScene.rootNode.childNode(withName: "roulette", recursively: false),
            let firstResult = hitResult.first else { return }
        
        rouletteNode = node
        _ = rouletteNode.childNodes.map({ $0.scale = SCNVector3(0.03, 0.03, 0.03) })
        let height = rouletteNode.boundingBox.max.y - rouletteNode.boundingBox.min.y
        rouletteNode.position = SCNVector3(firstResult.worldTransform.columns.3.x, firstResult.worldTransform.columns.3.y + height / 2, firstResult.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(rouletteNode)
        createBallNodeParent()
    }
    
    private func createBallNodeParent() {
        ballNodeParent = SCNNode()
        ballNodeParent.position = rouletteNode.position
        sceneView.scene.rootNode.addChildNode(ballNodeParent)
    }
    
    private func addBall() {
        let ballGeometry = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.purple
        ballGeometry.materials = [material]
        ballNode = SCNNode(geometry: ballGeometry)
        ballNode.position = SCNVector3(0.05, 0.05, 0)
        ballNodeParent.addChildNode(ballNode)
    }
    
    private func resetValues() {
        isRotating = false
        rouletteCurrentSecondsSpinning = 0.0
        ballCurrentSecondsSpinning = 0.0
        rouletteSecondsPerSpin = 0.5
        ballSecondsPerSpin = 0.5
        
        rouletteCurrentAngleY = 0.0
        ballCurrentAngleY = 0.0
        
        ballTimer.invalidate()
        rouletteTimer.invalidate()
    }
    
}

// Roulette Rotation

extension ViewController {
    
    private func startRotation() {
        isRotating = true
        rouletteSecondsPerSlot = TimeInterval(rouletteSecondsPerSpin / totalSlotsInRoulette)
        ballSecondsPerSlot = TimeInterval(ballSecondsPerSpin / totalSlotsInRoulette)
        setupTimerAndRotateForRoulette(timeInterval: rouletteSecondsPerSlot)
        setupTimerAndRotateForBall(timeInterval: ballSecondsPerSlot)
    }
    
    private func setupTimerAndRotateForRoulette(timeInterval: TimeInterval) {
        rouletteTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(rotateRoulette), userInfo: nil, repeats: false)
    }
    
    @objc
    func rotateRoulette() {
        if rouletteCurrentAngleY.radiansToDegrees >= 360 {
            rouletteCurrentAngleY = 0.0
        }
        
        if rouletteCurrentSecondsSpinning >= totalSecondsToSpin {
            return
        }
        
        rouletteCurrentSecondsSpinning += rouletteSecondsPerSlot
        
        let anglePerSlot: Float = Float(360 / totalSlotsInRoulette)
        rouletteCurrentAngleY += anglePerSlot.degreesToRadians
        rouletteNode.eulerAngles.y = rouletteCurrentAngleY
        
        rouletteSecondsPerSpin += additionalSpeedToAdd
        rouletteSecondsPerSlot = TimeInterval(rouletteSecondsPerSpin / totalSlotsInRoulette)
        setupTimerAndRotateForRoulette(timeInterval: rouletteSecondsPerSlot)
    }
    
}

// Ball Rotation

extension ViewController {
    
    private func dropBall() {
        guard !ballInRoulette else { return }
        ballInRoulette = true
        let newPosition = SCNVector3(0.02, -0.06, 0)
        let dropBallAction = SCNAction.move(by: newPosition, duration: 0.3)
        ballNode.runAction(dropBallAction)
    }
    
    private func setupTimerAndRotateForBall(timeInterval: TimeInterval) {
        ballTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(startRotationForBall), userInfo: nil, repeats: false)
    }
    
    private func slotIsInFinalPosition() -> Bool {
        guard let numberToStopText = numberTextField.text,
            let numberToStop = Int(numberToStopText),
            let selectedNumberDegrees = numbersDic[numberToStop] else { return false }
        
        let twoDecimalAngle = (abs(ballCurrentAngleY.radiansToDegrees) * 100).rounded() / 100
        return twoDecimalAngle == selectedNumberDegrees
    }
    
    @objc
    func startRotationForBall() {
        if ballCurrentAngleY.radiansToDegrees <= -360 {
            ballCurrentAngleY = 0.0
//            ballNodeParent.eulerAngles.y = 0.0
        }
        
        if ballCurrentSecondsSpinning >= totalSecondsToSpin && slotIsInFinalPosition() {
            resetValues()
            return
        }

        ballCurrentSecondsSpinning += ballSecondsPerSlot
        
//        print(ballCurrentAngleY.radiansToDegrees)
        
        let anglePerSlot: Float = Float(360 / totalSlotsInRoulette)
        ballCurrentAngleY -= anglePerSlot.degreesToRadians
        ballNodeParent.eulerAngles.y = ballCurrentAngleY
        
        ballSecondsPerSpin += additionalSpeedToAdd
        ballSecondsPerSlot = TimeInterval(ballSecondsPerSpin / totalSlotsInRoulette)
        setupTimerAndRotateForBall(timeInterval: ballSecondsPerSlot)
    }
    
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        plane.materials.first?.diffuse.contents = UIColor(red: 0, green: 0, blue: 1, alpha: 0.8)
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: plane, options: nil))
        planeNode.physicsBody?.isAffectedByGravity = false
        
        node.addChildNode(planeNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }

}

extension Float {
    var degreesToRadians: Float { return self * .pi / 180 }
    var radiansToDegrees: Float { return self * 180 / .pi }
}
