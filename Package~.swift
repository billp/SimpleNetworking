// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "TermiNetwork",
    platforms: [
      .macOS(.v10_15),
      .iOS(.v13),
      .tvOS(.v13),
      .watchOS(.v6)
    ],
    products: [
        .library(
            name: "TermiNetwork",
            targets: ["TermiNetwork"])
    ],
    targets: [
        .target(
            name: "TermiNetwork",
	    path: "Source")
    ],
    swiftLanguageVersions: [.v5]
)