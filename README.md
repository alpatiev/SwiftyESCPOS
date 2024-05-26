# SwiftyESCPOS

A simple swift library to connect your device to ESC/POS printer via local network.

# Description

SwiftyESCPOS is a Swift library that provides a simple and straightforward way to connect your iOS device to an ESC/POS printer via a local network. With this library, you can easily print text, images, and receipts to your printer directly from your iOS app.
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

# Usage

## 1. First thing first, you need to declare printer class somewhere (and scanner, which is optional), for example within our virtual OurViewModel:
```swift
final class OurViewModel {
    private lazy var scanner = LanScanner(delegate: self)
    private lazy var printer: SwiftyESCPOS
}
```

## 2. The next step is to configure delegates and confirm our class to protocols:
```swift
init(printer: SwiftyESCPOS)
    self.printer = printer
    printer.delegate = self
}
```

These are necessary SwiftyESCPOSDelegate methods.
```swift
extension OurViewModel: SwiftyESCPOSDelegate {
    func devices(didUpdatePrinters models: [PrinterConnectionModel]) {
      // Do something if you want to show printers state,
      // or just observe when one of printers disconnects.
    }
    
    func devices(didFindOpentPorts model: PrinterConnectionModel) {
      // Do something if you decide to connect new printer.
      // This functions returns PrinterConnectionModel of printer
      // if one of the devices is available for connection.
      // There should be logic for processing the connection, you should choose this yourself -
      // either show the user a confirmation window, or connect automatically.
    }
}
```

Well, here are the methods for the scanner. Don't forget, this is optional and you can use any other library to search for devices, or even implement the search manually (and pass a string with the address to the "pingPortsForHost(host: String)" method). Don't forget call scanner.start().
```swift
extension OurViewModel: LanScannerDelegate {
    func lanScanHasUpdatedProgress(_ progress: CGFloat, address: String) {
       // Show the user progress of scanning.
    }

    func lanScanDidFindNewDevice(_ device: LanDevice) {
       // Here are new devices if found.
       // For example, you can pass it directly to the printer:
       printer.pingPortsForHost(host: String(device.ipAddress.formatted()))
    }

    func lanScanDidFinishScanning() {
        // Notifies when scanning has been finished.
    }
}
```

## 3. And the last step is working directly to the printers.
The essential model for this library is PrinterConnectionModel.
You need to pass it if you want to connect device, or print something.

For example, let's save and connect this model:
```swift
let device = PrinterConnectionModel(host: "192.168.0.1", port: "8100")
printer.create(new: device)
printer.connect(with: .selected(device))
```

And print some check:
```swift
let check = CheckModel(success: Bool?, data: DataClass?, checkoutShift: CheckoutShift?)
printer.printCheck(with: .selected(device), from: check)
```

If we need to disconnect device in some point:
```swift
printer.disconnect(with: .selected(device))
```
Or even simple:
```swift
printer.disconnect(with: .all))
```

## * Additional info on reciept structure.
```swift
public struct CheckModel: Decodable {
    public let success: Bool? // Just leave it "true".
    public var data: DataClass? // Contains all check positions, headers, footers, etc.
    public let checkoutShift: CheckoutShift? // Optional.
}
```
```swift
public struct DataClass: Decodable {
    public let header: Header? // Obviously, top titles.
    public let body: [Body]? // Some lines about restaraunt, discounts, greetings..
    public let tableBody: [TableBody]? // Each element describe order's position. Name, count and sum.
    public var tableFooter: TableFooter? // Use property ".total" to show overall sum.
    public let footer: [String]? // Some additional small text.
}
```
