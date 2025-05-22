// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Welling",
    platforms: [ .macOS(.v11) ],
    targets: [ .executableTarget(name: "AppModule", path: ".") ]
)