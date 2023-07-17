# SwiftyESCPOS

A simple swift library to connect your device to ESC/POS printer via local network.

# Description

SwiftyESCPOS is a Swift library that provides a simple and straightforward way to connect your iOS device to an ESC/POS printer via a local network. With this library, you can easily print text, images, and receipts to your ESC/POS printer directly from your iOS app.
Here is a class (SwiftyESCPOS) that provides a simple way to connect any printers that you need. Note that at this stage, the library only supports printing from one model of receipt, but custom receipt printing will be added in version 2.0.0 of this library.
The class includes a delegate protocol, SwiftyESCPOSDelegate, which provides two methods for updating the list of available printers and notifying when an open port is confirmed. The class also includes a NetworkScanner object for discovering available printers on the local network, a Reciept object for generating receipt data, and an array of PrinterConnectionModel objects to keep track of connected printers.

# Requirements
- iOS 10.0+
- Xcode 12+
- Swift 5.0+

# Installation

You can use Swift Package Manager to install SwiftyESCPOS into your project. Simply add the following dependency to your Package.swift
 
```swift
dependencies: [
    .package(url: "https://github.com/example/SwiftyESCPOS.git", from: "1.0.0")
]
```


