// DataRecorder.swift
import Foundation
import ARKit
import SceneKit

extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
    
    var quaternion: simd_quatf {
        return simd_quatf(self)
    }
}

class DataRecorder {
    var trackingData: [String] = []
    var frameCount = 0

    func startRecording() {
        trackingData = []
        frameCount = 0
        trackingData.append("Frame,Timestamp,PosX,PosY,PosZ,RotX,RotY,RotZ,RotW")
    }

    func stopRecording() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = "\(documentsPath)/tracking_data.csv"
        
        let dataString = trackingData.joined(separator: "\n")
        try? dataString.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8)
    }

    func recordFrame(_ frame: ARFrame) {
        frameCount += 1
        let timestamp = Date().timeIntervalSince1970
        
        let transformMatrix = frame.camera.transform
        let pos = transformMatrix.translation
        let rot = transformMatrix.quaternion
        
        let dataRow = String(format: "%d,%.4f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f",
                             frameCount, timestamp, 
                             pos.x, pos.y, pos.z, 
                             rot.vector.x, rot.vector.y, rot.vector.z, rot.vector.w)
        
        self.trackingData.append(dataRow)
    }
}