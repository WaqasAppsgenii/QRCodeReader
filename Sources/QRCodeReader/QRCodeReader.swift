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
                .ignoresSafeArea()
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
            self.viewModel.restartCapturing()
        }
        .onDisappear {
            self.viewModel.stopCapturing()
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: self.$selectedImage)
                .onChange(of: selectedImage) { image in
                    if let image = image {
                        self.viewModel.scanQRCodeFromImage(image: image)
                    }
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("resumeScanner"))) { _ in
            viewModel.resumeScanning(after: 5)
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
