# Zip
A Zip/Unzip implementation for Swift

## Example
```swift
.package(url: "https://github.com/sinoru/swift-zip.git", .upToNextMajor(from: "0.0.1")),
```

```swift
import Zip

let zip = try Zip(contentsOf: URL(fileURLWithPath: "#{Zip file path}"))

try zip.unzip(toPath: "#{Unzip path}")
```
