import protocol Colors.RGBAComponent
#if os(macOS)
typealias NativeColor = NSColor
#elseif os(iOS)
typealias NativeColor = UIColor
#elseif os(WASI)
typealias NativeColor = Color
#endif
import struct Paths.Folder
import struct Paths.PathError
import PNG

/// A `Codable` representation of an asset used to create set of images for an
/// app.
public struct ImageSet {
 public var contents: Contents = {
  #if os(macOS)
  .macOS
  #elseif os(iOS)
  .iOS
  #endif
 }()

 public var images: [String: PNG.Image] = [:]
 /// A color-based icon set.
 public init?(color: some RGBAComponent) {
  for image in contents.images {
   guard let name = image.filename, images[name] == nil else {
    continue
   }
   let fill = (
    UInt8(color.red * 255),
    UInt8(color.green * 255),
    UInt8(color.blue * 255)
   )
   let pixels =
    [PNG.RGBA<UInt8>](
     repeating:
     PNG.RGBA(fill.0, fill.1, fill.2, UInt8(color.alpha * 255)),
     count: image.pixelCount
    )
   let size = (x: image.width, y: image.height)
   images[name] =
    PNG.Image(
     packing: pixels,
     size: size,
     layout: PNG.Layout(format: .rgba8(palette: [], fill: .none))
    )
  }
 }
}

extension ImageSet: AssetProtocol {
 // MARK: Types
 public struct Contents: AssetContents {
  public var images: [Image] = [
   // MARK: iPhone
   .image(of: 40, for: .iphone, scale: 2),
   .image(of: 60, for: .iphone, scale: 3),
   .image(of: 29, for: .iphone),
   .image(of: 58, for: .iphone, scale: 2),
   .image(of: 87, for: .iphone, scale: 3),
   .image(of: 80, for: .iphone, scale: 2),
   .image(of: 120, for: .iphone, scale: 3),
   .image(of: 57, for: .iphone),
   .image(of: 114, for: .iphone, scale: 2),
   .image(of: 120, for: .iphone, scale: 2),
   .image(of: 180, for: .iphone, scale: 3),
   // MARK: iPad
   .image(of: 20, for: .ipad),
   .image(of: 40, for: .ipad, scale: 2),
   .image(of: 29, for: .ipad),
   .image(of: 58, for: .ipad, scale: 2),
   .image(of: 40, for: .ipad),
   .image(of: 80, for: .ipad, scale: 2),
   .image(of: 50, for: .ipad),
   .image(of: 100, for: .ipad, scale: 2),
   .image(of: 72, for: .ipad),
   .image(of: 144, for: .ipad, scale: 2),
   .image(of: 76, for: .ipad),
   .image(of: 152, for: .ipad, scale: 2),
   .image(of: 167, for: .ipad, scale: 2),
   // MARK: Marketing
   .image(of: 1024, for: .iosMarketing)
  ]
  public var info = AssetInfo()
  public static var iOS: Self { Self() }
  public static var macOS: Self {
   Self(
    images: [
     .image(of: 16, for: .mac, scale: 1),
     .image(of: 16, for: .mac, scale: 2),
     .image(of: 32, for: .mac, scale: 1),
     .image(of: 32, for: .mac, scale: 2),
     .image(of: 128, for: .mac, scale: 1),
     .image(of: 128, for: .mac, scale: 2),
     .image(of: 256, for: .mac, scale: 1),
     .image(of: 256, for: .mac, scale: 2),
     .image(of: 512, for: .mac, scale: 1),
     .image(of: 512, for: .mac, scale: 2)
    ]
   )
  }
 }

 public struct Image: Hashable, Encodable {
  var filename: String?,
      idiom: String = AssetIdiom.universal.rawValue,
      platform: String?,
      role: String?,
      scale: String?,
      size: String!,
      subtype: String?
  public static func image(
   of size: Int,
   for idiom: AssetIdiom,
   name: String? = nil,
   platform: AssetPlatform? = nil,
   role: Role? = nil,
   scale: Int? = nil,
   subtype: Subtype? = nil
  ) -> Self {
   let defaultScale = scale ?? 1
   return
    self.init(
     filename:
     """
     \(name ?? size.description)\
     \(defaultScale > 1 ? "@\(defaultScale)x" : "").png
     """,
     idiom: idiom.rawValue,
     platform: platform?.rawValue,
     role: role?.rawValue,
     scale: scale == nil ? nil : "\(scale.unsafelyUnwrapped)x",
     size: "\(size)x\(size)",
     subtype: subtype?.rawValue
    )
  }

  public var width: Int {
   guard
    let first = size.components(separatedBy: "x").first,
    let size = Int(first)
   else {
    return 0
   }
   return size * Int(actualScale)
  }

  public var height: Int { width }

  public var actualScale: Float {
   if let scale {
    guard
     let first = scale.components(separatedBy: "x").first,
     let intValue = Int(first) else {
     return 0
    }
    return Float(intValue)

   } else {
    return 1
   }
  }

  public var pixelCount: Int {
   width * height
  }
 }

 public enum Role: String, Encodable {
  case
   notificationCenter,
   companionSettings,
   appLauncher,
   quickLook
 }

 public enum Subtype: String, Encodable {
  case _42mm = "42mm", _44mm = "44mm"
 }

 // MARK: Functions
 public func write(to path: String, name: String) throws {
  do {
   guard
    let baseURL = URL(string: path)
   else {
    throw POSIXError(.ENOTDIR)
   }
   let contentsData = try Self.encoder.encode(contents)
   do {
    let baseFolder = try Folder(path: baseURL.absoluteString)
    let subFolder = try baseFolder.createSubfolderIfNeeded(withName: name)
    try subFolder.createFile(at: "Contents.json", contents: contentsData)
    for (name, image) in images {
     do {
      try image.compress(path: subFolder.path + name, level: 0)
     } catch {
      print(error.localizedDescription)
     }
     continue
    }
   } catch let error as PathError {
    fatalError(error.description)
   }
  } catch {
   throw error
  }
 }
}

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 13.0, *)
public extension ImageSet {
 @MainActor
 init?(view: some View, contents: Contents? = nil) {
  if let contents {
   self.contents = contents
  }

  let renderer = ImageRenderer(content: view)

  for image in self.contents.images {
   guard let name = image.filename, images[name] == nil else {
    continue
   }

   renderer.scale = CGFloat(image.actualScale)

   guard let cgImage = renderer.cgImage else {
    print("unknown error while rendering image: \(name)")
    return nil
   }

   let size = (x: image.width, y: image.height)
   let pixelCount = image.pixelCount
   let dataCount = pixelCount * 4
   var pixelArray = [UInt8](repeating: 0, count: Int(dataCount))

   let context = CGContext(
    data: &pixelArray,
    width: Int(size.x),
    height: Int(size.y),
    bitsPerComponent: 8,
    bytesPerRow: 4 * Int(size.x),
    space: CGColorSpace(name: CGColorSpace.sRGB) ??
     CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
   )

   context?.draw(
    cgImage, in: CGRect(x: 0, y: 0, width: size.x, height: size.y)
   )

   var pixels = [PNG.RGBA<UInt8>](
    repeating: PNG.RGBA<UInt8>(.zero), count: pixelCount
   )

   var offset: Int = .zero
   while offset < pixelCount {
    let pixelOffset = offset * 4
    pixels[offset] =
     PNG.RGBA<UInt8>(
      pixelArray[pixelOffset],
      pixelArray[pixelOffset + 1],
      pixelArray[pixelOffset + 2],
      pixelArray[pixelOffset + 3]
     )
    offset += 1
   }

   images[name] = PNG.Image(
    packing: pixels,
    size: size,
    layout: PNG.Layout(format: .rgba8(palette: [], fill: .none))
   )
  }
 }

 @MainActor
 init?(
  contents: Contents? = nil,
  @ViewBuilder content: @escaping (_ length: CGFloat) -> some View
 ) {
  if let contents {
   self.contents = contents
  }

  for image in self.contents.images {
   guard let name = image.filename, images[name] == nil else {
    continue
   }

   let width = image.width
   let content = content(CGFloat(width))
   let renderer = ImageRenderer(content: content.clipped(antialiased: true))

   renderer.scale = CGFloat(image.actualScale)

   guard let cgImage = renderer.cgImage else {
    print("unknown error while rendering image: \(name)")
    return nil
   }

   let size = (x: width, y: image.height)
   let pixelCount = image.pixelCount
   let dataCount = pixelCount * 4
   var pixelArray = [UInt8](repeating: 0, count: Int(dataCount))

   let context = CGContext(
    data: &pixelArray,
    width: Int(size.x),
    height: Int(size.y),
    bitsPerComponent: 8,
    bytesPerRow: 4 * Int(size.x),
    space: CGColorSpace(name: CGColorSpace.sRGB) ??
     CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
   )

   context?.draw(
    cgImage, in: CGRect(x: 0, y: 0, width: size.x, height: size.y)
   )

   var pixels = [PNG.RGBA<UInt8>](
    repeating: PNG.RGBA<UInt8>(.zero), count: pixelCount
   )

   var offset: Int = .zero
   while offset < pixelCount {
    let pixelOffset = offset * 4
    pixels[offset] =
     PNG.RGBA<UInt8>(
      pixelArray[pixelOffset],
      pixelArray[pixelOffset + 1],
      pixelArray[pixelOffset + 2],
      pixelArray[pixelOffset + 3]
     )
    offset += 1
   }

   images[name] = PNG.Image(
    packing: pixels,
    size: size,
    layout: PNG.Layout(format: .rgba8(palette: [], fill: .none))
   )
  }
 }
}

#if os(iOS)
extension PNG.Data.Rectangular {
 func compress(path: String, level: Int = 9, hint: Int = 1 << 15) throws {
  try iOSByteStreamDestination.open(path: path) {
   try self.compress(stream: &$0, level: level, hint: hint)
  }
 }
}

struct iOSByteStreamDestination: _PNGBytestreamDestination {
 let descriptor: UnsafeMutablePointer<FILE>
 public static func open<R>(
  path: String, _ body: (inout Self) throws -> R
 ) rethrows -> R? {
  guard
   let descriptor: UnsafeMutablePointer<FILE> = fopen(path, "wb")
  else {
   return nil
  }
  var file = Self(descriptor: descriptor)
  defer { fclose(file.descriptor) }
  return try body(&file)
 }

 mutating func write(_ buffer: [UInt8]) -> Void? {
  let count: Int = buffer.withUnsafeBufferPointer {
   fwrite($0.baseAddress, MemoryLayout<UInt8>.stride, $0.count, descriptor)
  }
  guard count == buffer.count
  else {
   return nil
  }
  return ()
 }
}
#endif
@available(iOS 13.0, macOS 10.13, *)
public extension ImageSet {
 static func accent() -> Self? {
  Self(color: Color.accentColor)
 }

 /// Replaces an `AppIcon.appiconset` folder in a bundle's `Assets.xcassets`.
 func replace(in bundle: Bundle) throws {
  guard
   let basePath = bundle.url(
    forResource: "Assets",
    withExtension: "xcassets",
    subdirectory: "AppIcon.appiconset"
   )
  else {
   throw POSIXError(.ENOENT)
  }
  try write(to: basePath.absoluteString, name: "AppIcon.appiconset")
 }
}
#endif
