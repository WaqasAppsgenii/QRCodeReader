# QRCodeReader

A simple QRCode reader made for SwiftUI

Usage:
```swift
import SwiftUI
import QRCodeReader

struct MyView: View {
    var body: some View {
        QRCodeReader { result in
            print(result)
        }
    }
}
```
