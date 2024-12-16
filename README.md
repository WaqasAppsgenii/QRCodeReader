# QRCodeReader

A Swift Package for reading QR codes in iOS applications. `QRCodeReader` leverages `AVFoundation` to scan QR codes in real-time and provides a user-friendly interface with additional features like image picker support for QR code images.

## Features

- Real-time QR code scanning using the camera.
- Torch control for scanning in low-light conditions.
- Image picker for selecting QR codes from the photo library.
- SwiftUI and UIKit interoperability.

## Requirements

- iOS 14.0+
- Swift 5.3+
- Xcode 12+

## Installation

### Swift Package Manager

To add `QRCodeReader` to your project:

1. Open your project in Xcode.
2. Go to **File > Swift Packages > Add Package Dependency**.
3. Enter the repository URL: `https://github.com/yourusername/QRCodeReader.git`
4. Choose the latest version or a specific version as needed.

## Usage

### Importing QRCodeReader

After installation, import `QRCodeReader` into your Swift files:

```swift
import QRCodeReader
```

### Example: Using QRCodeReader View

To display the `QRCodeReader` view in your SwiftUI application:

```swift
import SwiftUI
import QRCodeReader

struct ContentView: View {
    @State private var qrCodeResult: String = ""
    
    var body: some View {
        VStack {
            Text("QR Code Result: \(qrCodeResult)")
                .padding()
            
            QRCodeReader { result in
                qrCodeResult = result
            }
            .frame(width: 300, height: 400)
            .cornerRadius(10)
        }
    }
}
```

### Torch Toggle & Image Picker

- **Torch Toggle**: When `QRCodeReader` detects that a torch is available on the device, it will display a toggle button for enabling and disabling the torch.
- **Image Picker**: A button is provided to select a QR code image from the photo library. The QR code is then processed, and the result is displayed.

### Customizing Toggle Styles

`QRCodeReader` includes two toggle styles for enhanced customization:

1. **CheckboxToggleStyle**:
   ```swift
   Toggle("Enable Option", isOn: $isChecked)
       .toggleStyle(CheckboxToggleStyle())
   ```

2. **OverlayToggleStyle**:
   ```swift
   Toggle("Enable Dark Mode", isOn: $isDarkMode)
       .toggleStyle(.overlay)
   ```

## Components

### QRCodeReader
The main view for scanning QR codes using the camera or an image.

### QRCodeReaderViewModel
Handles QR code detection and manages the camera session.

### CameraPreview
A `UIViewRepresentable` component to render the camera feed in SwiftUI.

### VisualEffectView
A customizable `UIVisualEffectView` wrapper for applying blur effects in SwiftUI.

## License

`QRCodeReader` is available under the MIT license. See the [LICENSE](https://raw.githubusercontent.com/AmirDaliri/QRCodeReader/refs/heads/main/LICENSE) file for more info.
