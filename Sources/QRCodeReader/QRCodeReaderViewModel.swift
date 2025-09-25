//
//  QRCodeReaderViewModel.swift
//  QRCodeReader
//
//  Created by Amir Daliri on 19/05/2022.
//

import UIKit
import AVFoundation
import Combine
import SwiftUIExtras

class QRCodeReaderViewModel: NSObject, ObservableObject {
    
    @Published var previewLayerBounds: CGRect = .zero
    @Published var qrBounds: CGRect? = nil
    weak var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let captureSession: AVCaptureSession = AVCaptureSession()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isTorchEnable: Bool = false
    @Published var isTorchOn: Bool = false
    
    lazy var cameraPreview = CameraPreview(session: self.captureSession)
    var result = PassthroughSubject<String, Never>()
    
    private var isProcessingScan = false
    
    init(readerObjectTypes: [AVMetadataObject.ObjectType]) {
        super.init()
        
        self.captureSession.sessionPreset = .high
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard self.captureSession.canAddInput(captureDeviceInput) else { return }
        self.captureSession.addInput(captureDeviceInput)
        
        self.isTorchEnable = captureDevice.hasTorch
        self.isTorchOn = false
        
        let metadataOutput = AVCaptureMetadataOutput()
        guard self.captureSession.canAddOutput(metadataOutput) else { return }
        self.captureSession.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = readerObjectTypes
        
        self.$isTorchOn
            .sink { [unowned self] isOn in
                self.toggleTorch(isOn)
            }
            .store(in: &self.cancellables)
    }
    
    func startCapturing() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                guard !self.captureSession.isRunning else { return }
                self.captureSession.startRunning()
            }
    }
    
    func stopCapturing() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
               guard let self else { return }
               guard self.captureSession.isRunning else { return }
               self.captureSession.stopRunning()
           }
    }
    
    func restartCapturing() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            
            // Fully stop and start again
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.captureSession.startRunning()
            
            // Re-assign delegate (sometimes it gets lost after stop)
            if let output = self.captureSession.outputs.first as? AVCaptureMetadataOutput {
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            }
        }
    }
    
    func resumeScanning(after delay: TimeInterval = 0) {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                self.isProcessingScan = false
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
            }
        }
    
    func resetScanning() {
        isProcessingScan = false
    }
    
    func scanQRCodeFromImage(image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        if let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] {
            for feature in features {
                if let result = feature.messageString {
                    // Send the result, but don't send the completion event
                    self.result.send(result)
                }
            }
        }
    }
}

extension QRCodeReaderViewModel: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
//        guard !isProcessingScan else { return }   // 🚀 ignore duplicates
//               isProcessingScan = true
//        
//        if let metadataObject = metadataObjects.first {
//            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
//            guard let stringValue = readableObject.stringValue else { return }
//            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
//            
//            self.result.send(stringValue)
//            
//            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//                           self?.captureSession.stopRunning()
//                       }
//        }
        
        // Get first QR object
               guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {
                   DispatchQueue.main.async { self.qrBounds = nil } // clear rectangle if nothing found
                   return
               }
               
               // --- 🔴 Convert QR metadata to screen coordinates
//               if let previewLayer = previewLayer,
//                  let transformedObject = previewLayer.transformedMetadataObject(for: metadataObject) {
//                   DispatchQueue.main.async {
//                       self.qrBounds = transformedObject.bounds
//                   }
//               }
        
        if let previewLayer = previewLayer,
           let transformed = previewLayer.transformedMetadataObject(for: metadataObject) {
            
            let layerBounds = previewLayer.bounds
            let normalized = CGRect(
                x: transformed.bounds.origin.x / layerBounds.width,
                y: transformed.bounds.origin.y / layerBounds.height,
                width: transformed.bounds.width / layerBounds.width,
                height: transformed.bounds.height / layerBounds.height
            )
            
            DispatchQueue.main.async {
                self.qrBounds = normalized   // store as percentages (0–1)
            }
        }
               
               // --- 🚀 Handle QR string only once
               guard !isProcessingScan else { return }
               isProcessingScan = true
               
               if let stringValue = metadataObject.stringValue {
                   AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                   self.result.send(stringValue)
                   
                   DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                       self?.captureSession.stopRunning()
                   }
               }
    }
}

fileprivate extension QRCodeReaderViewModel {
    
    func toggleTorch(_ on: Bool) {
        guard self.isTorchEnable else { return }
        guard let input = self.captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        
        try? input.device.lockForConfiguration()
        if on {
            try? input.device.setTorchModeOn(level: 1.0)
        }
        else {
            input.device.torchMode = .off
        }
        input.device.unlockForConfiguration()
    }
}


extension Notification.Name {
    public static let resumeScanner = Notification.Name("resumeScanner")
}
