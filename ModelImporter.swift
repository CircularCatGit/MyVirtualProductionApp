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
                    self.delegate?.sceneView.scene.rootNode.addChildNode(sceneKitScene.rootNode)
                }
            } catch {
                print("Error parsing 3D model container asset layout: \(error.localizedDescription)")
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.dismiss(animated: true, completion: nil)
    }
}