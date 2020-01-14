// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "MXScroll",
    platforms: [.iOS(.v10)],
    products: [
        .library(name: "MXScroll", targets: ["MXScroll"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/nakiostudio/EasyPeasy",
            .upToNextMajor(from: "1.9.2")
        ),
        .package(
            url: "https://github.com/ReactiveX/RxSwift",
            .upToNextMajor(from: "5.0.1")
        )
    ],
    targets: [
        .target(
            name: "MXScroll",
            dependencies: ["RxSwift", "RxCocoa", "EasyPeasy"],
            path: "MXScroll/Classes"
        )
    ]
)
