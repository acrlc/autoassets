// swift-tools-version: 5.9

import PackageDescription

let package = Package(
 name: "AutoAssets",
 platforms: [.macOS(.v12), .iOS(.v13)],
 products: [
  .library(
   name: "AutoAssets",
   targets: ["AutoAssets"]
  )
 ],
 dependencies: [
  .package(url: "https://github.com/acrlc/paths.git", from: "0.1.0"),
  .package(url: "https://github.com/acrlc/colors.git", from: "0.1.0"),
  .package(url: "https://github.com/tayloraswift/swift-png.git", from: "4.3.0")
 ],
 targets: [
  .target(
   name: "AutoAssets",
   dependencies: [
    .product(name: "Paths", package: "paths"),
    .product(name: "Colors", package: "colors"),
    .product(name: "PNG", package: "swift-png")
   ]
  ),
  .testTarget(
   name: "AutoAssetsTests",
   dependencies: [
    "AutoAssets", .product(name: "Paths", package: "paths")
   ]
  )
 ]
)
