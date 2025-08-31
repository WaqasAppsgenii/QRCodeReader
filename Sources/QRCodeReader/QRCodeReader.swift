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
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    
    private var receivedResult: (String) -> Void
    
    public init(readerTypes: [AVMetadataObject.ObjectType] = [.qr, .pdf417, .aztec], receivedResult: @escaping (String) -> Void) {
        self._viewModel = StateObject(wrappedValue: QRCodeReaderViewModel(readerObjectTypes: readerTypes))
        self.receivedResult = receivedResult
    }
    
    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            self.viewModel.cameraPreview
                .ignoresSafeArea()
            VStack {
                Spacer()
                HStack {
                    if self.viewModel.isTorchEnable {
                        Toggle(isOn: self.$viewModel.isTorchOn) {
                            Image(systemName: self.viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .frame(width: 20, height: 20)
                        }
                        .toggleStyle(.overlay)
                        .padding()
                    }
                    Spacer()
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
                }
                .padding(.bottom)
            }
            
        }
        .onReceive(self.viewModel.result) {
            self.receivedResult($0)
        }
        .onAppear {
            self.viewModel.startCapturing()
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
    }
}

#if DEBUG
struct QRCodeReader_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeReader { _ in
            
        }
    }
}
#endif
