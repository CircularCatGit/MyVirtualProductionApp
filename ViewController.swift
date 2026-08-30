// ViewController.swift
import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var importButton: UIButton!

    var isRecording = false
    var dataRecorder: DataRecorder?
    var modelImporter = ModelImporter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        dataRecorder = DataRecorder()
        modelImporter.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (sceneView.session.currentFrame?.camera.imageOrientation == .rightUp) {
            sceneView.scene.rootNode.eulerAngles = SCNVector3(0, 0, 0)
        } else {
            sceneView.scene.rootNode.eulerAngles = SCNVector3(0, .pi, 0)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @IBAction func recordButtonTapped(_ sender: UIButton) {
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

    @IBAction func importButtonTapped(_ sender: UIButton) {
        modelImporter.importModel()
    }

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
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.position = SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z)
        return planeNode
    }
}