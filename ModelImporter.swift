// ModelImporter.swift
import UIKit
import SceneKit
import UniformTypeIdentifiers

class ModelImporter: NSObject, UIDocumentPickerDelegate {

    var delegate: ViewController?

    func importModel() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item, .data, .content])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.modalPresentationStyle = .fullScreen
        delegate?.present(documentPicker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let sceneKitScene = try SCNScene(url: url, options: nil)
                
                DispatchQueue.main.async {
                    let importedNode = SCNNode()
                    
                    // Pull all inner child elements together into one root node block container
                    for child in sceneKitScene.rootNode.childNodes {
                        importedNode.addChildNode(child)
                    }
                    
                    // Normalize model scaling (Some models compile incredibly massive or tiny out of Blender)
                    importedNode.scale = SCNVector3(1.0, 1.0, 1.0)
                    
                    // Save into standby memory tracking slot
                    self.delegate?.pendingModelNode = importedNode
                    
                    // Instruct the user with an on-screen alert banner
                    let alert = UIAlertController(title: "Model Loaded", message: "Tap anywhere on a detected green surface mesh grid to anchor the 3D object down!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Got it", style: .default))
                    self.delegate?.present(alert, animated: true)
                }
            } catch {
                print("Error parsing 3D model asset layout: \(error.localizedDescription)")
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.dismiss(animated: true, completion: nil)
    }
}
