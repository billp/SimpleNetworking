// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "TermiNetwork",
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
