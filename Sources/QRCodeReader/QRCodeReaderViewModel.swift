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
    
    private let captureSession: AVCaptureSession = AVCaptureSession()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isTorchEnable: Bool = false
    @Published var isTorchOn: Bool = false
    
    lazy var cameraPreview = CameraPreview(session: self.captureSession)
    var result = PassthroughSubject<String, Never>()
    
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.captureSession.startRunning()
        }
        
    }
    
    func stopCapturing() {
        self.captureSession.stopRunning()
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
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            self.result.send(stringValue)
            
            // Restart capture session after a short delay to allow continuous scanning
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.captureSession.startRunning()
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
