import Foundation.NSJSONSerialization

public protocol AssetProtocol {
 /// A `Codable`instance of the `Contents.json`
 /// file used for generating an assets folder structure.
 associatedtype Contents: AssetContents
 var contents: Contents { get set }
 func write(to path: String, name: String) throws
}

public extension AssetProtocol {
 static var encoder: JSONEncoder { JSONEncoder() }
 static var decoder: JSONDecoder { JSONDecoder() }
}
