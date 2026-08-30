// ViewController.swift
import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    var sceneView: ARSCNView!
    var recordButton: UIButton!
    var importButton: UIButton!

    var isRecording = false
    var dataRecorder: DataRecorder?
    var modelImporter = ModelImporter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Programmatically initialize the ARSCNView canvas layer to fit the device bounds
        sceneView = ARSCNView(frame: self.view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(sceneView)
        
        // Configure standard AR layout view parameters
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        // 2. Programmatically construct a clean Record Toggle button
        recordButton = UIButton(type: .system)
        recordButton.frame = CGRect(x: 30, y: self.view.bounds.height - 100, width: 140, height: 50)
        recordButton.setTitle("Start Recording", for: .normal)
        recordButton.backgroundColor = UIColor.systemBlue
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.layer.cornerRadius = 10
        recordButton.addTarget(self, action: #selector(recordButtonTapped(_:)), for: .touchUpInside)
        self.view.addSubview(recordButton)
        
        // 3. Programmatically construct a clean 3D Model Import button
        importButton = UIButton(type: .system)
        importButton.frame = CGRect(x: self.view.bounds.width - 170, y: self.view.bounds.height - 100, width: 140, height: 50)
        importButton.setTitle("Import Model", for: .normal)
        importButton.backgroundColor = UIColor.darkGray
        importButton.setTitleColor(.white, for: .normal)
        importButton.layer.cornerRadius = 10
        importButton.addTarget(self, action: #selector(importButtonTapped(_:)), for: .touchUpInside)
        self.view.addSubview(importButton)
        
        // Force the camera configuration tracking engine to detect environments
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        dataRecorder = DataRecorder()
        modelImporter.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let orientation = windowScene?.interfaceOrientation ?? .portrait
        
        if orientation == .portrait {
            sceneView.scene.rootNode.eulerAngles = SCNVector3(0, 0, 0)
        } else {
            sceneView.scene.rootNode.eulerAngles = SCNVector3(0, Float.pi, 0)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // MARK: - Action Methods

    @objc func recordButtonTapped(_ sender: UIButton) {
        isRecording.toggle()
        if isRecording {
            recordButton.setTitle("Stop Recording", for: .normal)
            recordButton.backgroundColor = UIColor.systemRed
            dataRecorder?.startRecording()
        } else {
            recordButton.setTitle("Start Recording", for: .normal)
            recordButton.backgroundColor = UIColor.systemBlue
            dataRecorder?.stopRecording()
            
            let exportedCSVString = dataRecorder?.trackingData.joined(separator: "\n") ?? ""
            let activityViewController = UIActivityViewController(activityItems: [exportedCSVString], applicationActivities: nil)
            
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = sender
                popoverController.sourceRect = sender.bounds
            }
            
            present(activityViewController, animated: true, completion: nil)
        }
    }

    @objc func importButtonTapped(_ sender: UIButton) {
        modelImporter.importModel()
    }

    // MARK: - ARSession and Plane Detection Delegates

    func session(_ session: ARSession, didFailWithError error: Error) {
        let alertController = UIAlertController(title: "Session Failed", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if isRecording {
            dataRecorder?.recordFrame(frame)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            let planeNode = createPlaneNode(anchor: anchor as! ARPlaneAnchor)
            node.addChildNode(planeNode)
        }
    }

    func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
        let planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        let planeNode = SCNNode(geometry: planeGeometry)
        
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.4)
        planeNode.geometry?.firstMaterial?.isDoubleSided = true
        planeNode.eulerAngles.x = Float(-Double.pi / 2.0)
        planeNode.position = SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z)
        return planeNode
    }
}
