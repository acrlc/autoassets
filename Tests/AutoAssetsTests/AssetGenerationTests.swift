import AutoAssets
import Paths
import SwiftUI
import XCTest

final class AssetGenerationTests: XCTestCase {
 let currentFolder: String = {
  var url = URL(fileURLWithPath: #filePath)
  url.deleteLastPathComponent()
  return url.path(percentEncoded: false)
 }()

 @MainActor
 func testViewImageGeneration() throws {
  print("generating icons")
  // unwrap the icon set to see if images are being generated
  let iconSet = try XCTUnwrap(
   ImageSet(contents: .macOS) { length in
    Image(systemName: "photo.fill").resizable(resizingMode: .stretch)
     .aspectRatio(contentMode: .fit)
     .frame(height: length / 2.75)
     .frame(width: length, height: length)
     .foregroundStyle(.purple)
     .blendMode(.overlay)
     .background(Color.mint.opacity(0.75))
   }
  )
  
  print("saving icons")
  try iconSet.write(to: currentFolder, name: "TestIcon.appiconset")
  
  print("deleting iconset")
  try Folder(path: currentFolder).subfolder(named: "TestIcon.appiconset").delete()
 }

 func testColorGeneration() throws {
  print("initializing colors")
  let color = ColorSet(Color.accentColor)
  try color.write(to: currentFolder, name: "TestAccentColor.colorset")
  let lumen = Color(red: 0.388, green: 0.902, blue: 0.886, alpha: 1)
  let accentColors = ColorSet(
   any: lumen,
   dark: lumen.unsafeMap(transform: { $0 * 0.88 })
  )
  
  print("saving colors")
  try accentColors.write(to: currentFolder, name: "TestAccentColor.colorset")
  
  print("deleting colorset")
  try Folder(path: currentFolder)
   .subfolder(named: "TestAccentColor.colorset").delete()
 }
}
