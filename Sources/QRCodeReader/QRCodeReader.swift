//
//  QRCodeReader.swift
//  QRCodeReader
//
//  Created by Amir Daliri on 19/05/2022.
//

import SwiftUI
import AVFoundation
import SwiftUIExtras

public struct QRCodeReader: View {
    
    @StateObject private var viewModel: QRCodeReaderViewModel
    @Binding private var isScanning: Bool
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    
    private var receivedResult: (String) -> Void
    
    public init(readerTypes: [AVMetadataObject.ObjectType] = [.qr, .pdf417, .aztec],
    isScanning: Binding<Bool>, receivedResult: @escaping (String) -> Void) {
        self._viewModel = StateObject(wrappedValue: QRCodeReaderViewModel(readerObjectTypes: readerTypes))
        self._isScanning = isScanning
        self.receivedResult = receivedResult
    }
    
    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            self.viewModel.cameraPreview
                .ignoresSafeArea(.all, edges: .all)
                .background(
                        GeometryReader { _ in
                            Color.clear.onAppear {
                                if let preview = self.viewModel.cameraPreview.view as? CameraPreview.VideoPreviewView,
                                   let layer = preview.layer as? AVCaptureVideoPreviewLayer {
                                    self.viewModel.previewLayer = layer
                                    self.viewModel.previewLayerBounds = layer.bounds 
                                }
                            }
                        }
                    )
            
//            GeometryReader { geo in
//                if let bounds = viewModel.qrBounds {
//                    Rectangle()
//                        .stroke(Color.red, lineWidth: 2)
//                        .frame(width: bounds.width, height: bounds.height)
//                        .position(x: bounds.midX, y: bounds.midY)
//                        .animation(.easeInOut(duration: 0.2), value: bounds)
//                }
//            }
            
//                .overlay(
//                    GeometryReader { geo in
//                        if let bounds = viewModel.qrBounds {
//                            let safeTop = geo.safeAreaInsets.top   // usually ~47–60pts
//                            Rectangle()
//                                .stroke(Color.red, lineWidth: 3)
//                                .frame(width: bounds.width, height: bounds.height)
//                                .position(
//                                    x: bounds.midX,
//                                    y: bounds.midY - safeTop   // 🔑 shift up by inset
//                                )
//                        }
//                    }
//                )
            
                .overlay(
                    GeometryReader { geo in
                        let size: CGFloat = 260
                        
                        let scanRect = CGRect(
                            x: (geo.size.width - size) / 2,
                            y: (geo.size.height - size) / 2,
                            width: size,
                            height: size
                        )
                        
                        ZStack {
                            // Dimmed background with cutout
                            Path { path in
                                path.addRect(CGRect(origin: .zero, size: geo.size))
                                path.addRect(scanRect)
                            }
                            .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
                            
                            // Border
                            Rectangle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: scanRect.width, height: scanRect.height)
                                .position(x: scanRect.midX, y: scanRect.midY)
                        }
                        .onAppear {
                            viewModel.setScanRect(scanRect, viewSize: geo.size)
                        }
                        .onChange(of: viewModel.previewLayerBounds) { _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                viewModel.setScanRect(scanRect, viewSize: geo.size)
                            }
                        }
                        
                        if let bounds = viewModel.qrBounds {
                            let safeTop = geo.safeAreaInsets.top   // usually ~47–60pts
                            Rectangle()
                                .stroke(Color.red, lineWidth: 3)
                                .frame(width: bounds.width, height: bounds.height)
                                .position(
                                    x: bounds.midX,
                                    y: bounds.midY - safeTop   // 🔑 shift up by inset
                                )
                        }
                    }
                )
                .ignoresSafeArea(.all, edges: .all)
            
            //changes till now
            VStack {
                Spacer()
                HStack {
                   
                    Button(action: {
                        self.selectedImage = nil
                        self.isImagePickerPresented = true
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    .padding()
                    
                    Spacer()
                    
                    if self.viewModel.isTorchEnable {
                        Toggle(isOn: self.$viewModel.isTorchOn) {
                            Image(systemName: self.viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .frame(width: 20, height: 20)
                        }
                        .toggleStyle(.overlay)
                        .padding()
                    }
                }
                .padding(.bottom)
                
                Text("Please scan a valid QR code to initiate payment")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
        }
        .onChange(of: isScanning) { newValue in
                    if newValue {
                        viewModel.startCapturing()
                    } else {
                        viewModel.stopCapturing()
                    }
                }
        .onReceive(self.viewModel.result) {
            self.receivedResult($0)
        }
        .onAppear {
            //self.viewModel.startCapturing()
            self.viewModel.resetScanning()
            self.viewModel.restartCapturing()
        }
        .onDisappear {
            self.viewModel.stopCapturing()
            
            // Clear rectangle lines
            self.viewModel.qrBounds = nil
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: self.$selectedImage)
                .onChange(of: selectedImage) { image in
                    if let image = image {
                        self.viewModel.scanQRCodeFromImage(image: image)
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resumeScanner)) { _ in
            viewModel.resumeScanning(after: 2.5)
        }
    }
}

#if DEBUG
struct QRCodeReader_Previews: PreviewProvider {
    @State static var isScanning = true
    static var previews: some View {
        QRCodeReader(isScanning: $isScanning) { _ in
            
        }
    }
}
#endif
