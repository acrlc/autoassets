import struct Paths.Folder
import struct Paths.PathError
import Foundation

public struct ColorSet {
 public var contents: Contents = .empty
}

extension ColorSet: AssetProtocol, Codable {
 // MARK: Types
 public struct Contents: AssetContents, Codable {
  public var colors: [ColorContext] = []
  public var info = AssetInfo()
  public static var empty: Self { Self() }
 }

 public struct Color: Codable {
  public var colorSpace: ColorSpace = .srgb
  public var components = Components()
  public struct Components: Codable {
   var alpha: Double = 1
   var blue: Double = 1
   var green: Double = 1
   var red: Double = 1
  }

  enum CodingKeys: String, CodingKey {
   case colorSpace = "color-space", components
  }
 }

 public enum ColorSpace: String, Codable {
  case srgb
 }

 public struct AppearanceContext: Codable {
  var appearance: String, value: String
  public static let dark = Self(appearance: "luminosity", value: "dark")
 }

 public struct ColorContext: Codable {
  var appearances: [AppearanceContext]?
  var color = Color()
  var idiom: AssetIdiom = .universal
 }

 // MARK: Functions
 public func write(
  to path: String, name: String = "AccentColor.colorset"
 ) throws {
  guard let baseURL = URL(string: path) else {
   throw POSIXError(.ENOTDIR)
  }
  let data = try Self.encoder.encode(contents)
  do {
   let baseFolder = try Folder(path: baseURL.absoluteString)
   let subFolder = try baseFolder.createSubfolderIfNeeded(withName: name)
   try subFolder.createFile(named: "Contents.json", contents: data)
  } catch let error as PathError {
   fatalError(error.description)
  }
 }
}

import protocol Colors.RGBAComponent
public extension ColorSet {
 init(_ color: some RGBAComponent) {
  let components =
   Color.Components(
    alpha: color.alpha,
    blue: color.blue,
    green: color.green,
    red: color.red
   )
  let context =
   ColorContext(
    color: Color(components: components)
   )
  self.init(
   contents: Contents(colors: [context])
  )
 }

 init<A: RGBAComponent>(any: A, dark: A) {
  let anyContext =
   ColorContext(
    color: Color(
     components:
     Color.Components(
      alpha: any.alpha,
      blue: any.blue,
      green: any.green,
      red: any.red
     )
    )
   )
  let darkContext =
   ColorContext(
    appearances: [.dark],
    color: Color(
     components:
     Color.Components(
      alpha: dark.alpha,
      blue: dark.blue,
      green: dark.green,
      red: dark.red
     )
    )
   )

  self.init(
   contents: Contents(colors: [anyContext, darkContext])
  )
 }

 /// Replaces a `colorset` folder in a bundle's `Assets.xcassets`.
 func replace(in bundle: Bundle, name: String = "AccentColor") throws {
  guard
   let basePath = bundle.path(forResource: name, ofType: "colorset")
  else {
   throw POSIXError(.ENOENT)
  }
  try write(to: basePath, name: name + "colorset")
 }
}
