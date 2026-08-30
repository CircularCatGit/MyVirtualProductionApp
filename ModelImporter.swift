// ModelImporter.swift
import UIKit
import SceneKit
import UniformTypeIdentifiers

public class ModelImporter: NSObject, UIDocumentPickerDelegate {

    public var delegate: ViewController?

    public func importModel() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item, .data, .content])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.modalPresentationStyle = .fullScreen
        delegate?.present(documentPicker, animated: true, completion: nil)
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let sceneKitScene = try SCNScene(url: url, options: nil)
                
                DispatchQueue.main.async {
                    let importedNode = SCNNode()
                    
                    for child in sceneKitScene.rootNode.childNodes {
                        importedNode.addChildNode(child)
                    }
                    
                    importedNode.scale = SCNVector3(1.0, 1.0, 1.0)
                    self.delegate?.pendingModelNode = importedNode
                    
                    let alert = UIAlertController(title: "Model Loaded", message: "Tap anywhere on a detected surface grid layout to anchor the 3D object down!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Got it", style: .default))
                    self.delegate?.present(alert, animated: true)
                }
            } catch {
                print("Error parsing 3D model asset layout: \(error.localizedDescription)")
            }
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.dismiss(animated: true, completion: nil)
    }
}
