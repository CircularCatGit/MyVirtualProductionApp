// ViewController.swift
import UIKit
import ARKit
import SceneKit

public class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    // Marked as public so ModelImporter can modify them
    public var sceneView: ARSCNView!
    public var recordButton: UIButton!
    public var importButton: UIButton!

    public var isRecording = false
    public var dataRecorder: DataRecorder?
    public var modelImporter = ModelImporter()
    
    public var pendingModelNode: SCNNode?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView(frame: self.view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(sceneView)
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        sceneView.layer.contents = nil
        sceneView.background.contents = UIColor.black 
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        recordButton = UIButton(type: .system)
        recordButton.frame = CGRect(x: 30, y: self.view.bounds.height - 100, width: 140, height: 50)
        recordButton.setTitle("Start Recording", for: .normal)
        recordButton.backgroundColor = UIColor.systemBlue
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.layer.cornerRadius = 10
        recordButton.addTarget(self, action: #selector(recordButtonTapped(_:)), for: .touchUpInside)
        self.view.addSubview(recordButton)
        
        importButton = UIButton(type: .system)
        importButton.frame = CGRect(x: self.view.bounds.width - 170, y: self.view.bounds.height - 100, width: 140, height: 50)
        importButton.setTitle("Import Model", for: .normal)
        importButton.backgroundColor = UIColor.darkGray
        importButton.setTitleColor(.white, for: .normal)
        importButton.layer.cornerRadius = 10
        importButton.addTarget(self, action: #selector(importButtonTapped(_:)), for: .touchUpInside)
        self.view.addSubview(importButton)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        dataRecorder = DataRecorder()
        modelImporter.delegate = self
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.scene.rootNode.eulerAngles = SCNVector3(0, 0, 0)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        guard let modelNode = pendingModelNode else { return }
        let tapLocation = gestureRecognize.location(in: sceneView)
        
        let query = sceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
        if let raycastQuery = query {
            let results = sceneView.session.raycast(raycastQuery)
            if let hitResult = results.first {
                
                modelNode.removeFromParentNode()
                
                let transform = hitResult.worldTransform
                modelNode.position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                modelNode.eulerAngles = SCNVector3(0, 0, 0)
                
                sceneView.scene.rootNode.addChildNode(modelNode)
                pendingModelNode = nil
                print("[ARKit] Model successfully anchored down straight-up!")
            }
        }
    }

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

    public func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session Failed: \(error.localizedDescription)")
    }

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if isRecording {
            dataRecorder?.recordFrame(frame)
        }
    }

    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            let planeGeometry = SCNPlane(width: CGFloat((anchor as! ARPlaneAnchor).extent.x), height: CGFloat((anchor as! ARPlaneAnchor).extent.z))
            let planeNode = SCNNode(geometry: planeGeometry)
            
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.15)
            planeNode.geometry?.firstMaterial?.isDoubleSided = true
            planeNode.eulerAngles.x = Float(-Double.pi / 2.0)
            planeNode.position = SCNVector3((anchor as! ARPlaneAnchor).center.x, (anchor as! ARPlaneAnchor).center.y, (anchor as! ARPlaneAnchor).center.z)
            node.addChildNode(planeNode)
        }
    }
}
